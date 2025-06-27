from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import IsAuthenticated
from django.db.models import Avg
from django.shortcuts import get_object_or_404
from .models import Curriculum, Movie
from .serializers import SignupSerializer, CurriculumSerializer, MovieSerializer, QuizQuestion, QuizChoice

class SignupView(APIView):
    def post(self, request):
        serializer = SignupSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()

            # JWTトークンの生成
            refresh = RefreshToken.for_user(user)

            return Response({
                'message': 'User created successfully',
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class HomeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response({
            'username': request.user.username
        })
        
class CurriculumListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        curriculums = Curriculum.objects.filter(user=request.user)
        serializer = CurriculumSerializer(curriculums, many=True)
        return Response(serializer.data)

    def post(self, request):
        title = request.data['title']
        movies = request.data['movies']
        message = request.data['message']
        user = request.user
        
        curriculum = Curriculum.objects.create(
            user = user,
            name = title,
            detail = message
        )
        
        for movie in movies:
            Movie.objects.create(
                curriculum = curriculum,
                url = movie['url'],
                title = movie['title']
            )
        serializer = CurriculumSerializer(curriculum)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class MovieView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request, pk):
        curriculum = get_object_or_404(Curriculum, pk=pk)
        movies = Movie.objects.filter(curriculum=curriculum)
        serializer = MovieSerializer(movies, many=True)
        return Response(serializer.data, status=200)
    
    def post(self, request):
        curriculum_id = request.data['curriculum_id']
        movie_id = request.data['movie_id']
        movie_status = request.data['status']
        rating = request.data['rating']
        
        movie = Movie.objects.get(id=movie_id)
        movie.status = movie_status
        movie.feedback = rating
        movie.save()
        
        curriculum = Curriculum.objects.get(id=curriculum_id)
        movies = Movie.objects.filter(curriculum=curriculum)
        
        fin = 0
        for m in movies:
            fin += m.status
        
        progress = (fin / len(movies)) * 100
        curriculum.progress = int(progress)
        if progress > 99:
            curriculum.status = True
        else:
            curriculum.status = False
        curriculum.save()
        return Response({"message": "Status updated"}, status=status.HTTP_200_OK)

class FeedbackView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        url = request.query_params.get('url')
        data = Movie.objects.filter(url=url).aggregate(avg=Avg('feedback'))
        score = data['avg']  # 該当行が無いときは None

        if score is None:
            return Response({"score": 3}, status=status.HTTP_200_OK)
        return Response({"score": score}, status=status.HTTP_200_OK)

    def post(self, request):
        feedback = request.data['feedback']
        movie_id = request.data['movie_id']
        movie = Movie.objects.get(id=movie_id)
        movie.feedback = feedback
        movie.save()
        return Response({'message': 'Success to save feedback!'}, status=status.HTTP_200_OK)
    
class QuizBulkCreateView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        movie_id = request.query_params.get("movie_id")
        if not movie_id or not movie_id.isdigit():
            return Response(
                {"detail": "`movie_id` must be integer."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        movie = get_object_or_404(Movie, pk=int(movie_id))

        questions = (
            QuizQuestion.objects.filter(movie=movie)
            .prefetch_related("choices")
            .order_by("id")
        )

        result = []
        for q in questions:
            result.append(
                {
                    "question_id": q.id,
                    "prompt": q.prompt,
                    "choices": [
                        {
                            "choice_id": c.id,
                            "text": c.text,
                            "is_correct": c.is_correct,
                        }
                        for c in q.choices.all()
                    ],
                }
            )

        return Response({"questions": result})
        
    def post(self, request):
        curriculum_id = request.data.get('id')
        curriculum = Curriculum.objects.get(id=curriculum_id)
        movie_titles = request.data.get('movie_titles', [])
        quizes = request.data.get('quizes', [])
        print(quizes)

        if len(movie_titles) != len(quizes):
            return Response(
                {"detail": "movie_titlesとquizesの長さが一致していません"},
                status=status.HTTP_400_BAD_REQUEST
            )

        errors = []  # ← エラーを集める

        for i in range(len(movie_titles)):
            try:
                movie = Movie.objects.get(curriculum=curriculum, title=movie_titles[i])
            except Movie.DoesNotExist:
                errors.append(f"Movie '{movie_titles[i]}' が見つかりません")
                continue

            if not quizes[i]:
                continue

            for quiz in quizes[i]:
                question = None
                try:
                    question = QuizQuestion.objects.create(
                        movie=movie,
                        prompt=quiz['question']
                    )

                    correct_answer = quiz['answer'].strip() if isinstance(quiz['answer'], str) else None
                    if not correct_answer:
                        errors.append(f"正解が不正または空: {quiz}")
                        continue

                    choices = [choice.strip() for choice in quiz['choices']]
                    if correct_answer not in choices:
                        errors.append(f"正解 '{correct_answer}' が選択肢に含まれていません")
                        continue

                    for choice_text in quiz['choices']:
                        is_correct = (choice_text.strip() == correct_answer)
                        QuizChoice.objects.create(
                            question=question,
                            text=choice_text,
                            is_correct=is_correct
                        )
                except KeyError as e:
                    if question:
                        question.delete()
                    errors.append(f"クイズの構造が不正: キー '{e}' がありません（{quiz}）")
                    continue

        print('登録完了')

        return Response(
            {
                "detail": "登録処理が完了しました",
                "errors": errors  # 必要に応じてエラー内容も返す
            },
            status=status.HTTP_200_OK if not errors else status.HTTP_207_MULTI_STATUS
        )

        