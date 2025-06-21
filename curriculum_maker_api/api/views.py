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
    def post(self, request):
        id = request.data.get('id')
        curriculum = Curriculum.objects.get(id=id)
        movie_titles = request.data.get('movie_titles', [])
        quizes = request.data.get('quizes', [])
        print(quizes)

        if len(movie_titles) != len(quizes):
            return Response(
                {"detail": "movie_titlesとquizesの長さが一致していません"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            for i in range(len(movie_titles)):
                movie = Movie.objects.get(curriculum=curriculum, title=movie_titles[i])

                for quize in quizes[i]:
                    # クイズ作成
                    question = QuizQuestion.objects.create(
                        movie=movie,
                        prompt=quize['question']
                    )

                    correct_answer = quize['answer'].strip()

                    for choice_text in quize['choices']:
                        is_correct = (choice_text.strip() == correct_answer)
                        QuizChoice.objects.create(
                            question=question,
                            text=choice_text,
                            is_correct=is_correct
                        )
        except Movie.DoesNotExist:
            return Response(
                {"detail": f"Movie '{movie_titles[i]}' が見つかりません"},
                status=status.HTTP_400_BAD_REQUEST
            )
        except KeyError as e:
            return Response(
                {"detail": f"リクエストに '{str(e)}' が含まれていません"},
                status=status.HTTP_400_BAD_REQUEST
            )
        print('登録完了')

        return Response({"detail": "クイズ登録に成功しました"}, status=status.HTTP_201_CREATED)

        