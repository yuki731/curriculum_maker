from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from .models import Curriculum, Movie
from .serializers import SignupSerializer, CurriculumSerializer, MovieSerializer

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
        serializer = CurriculumSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)  # ログインユーザーを自動設定
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class MovieView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request, pk):
        curriculum = get_object_or_404(Curriculum, pk=pk)
        movies = Movie.objects.filter(curriculum=curriculum)
        serializer = MovieSerializer(movies, many=True)
        return Response(serializer.data, status=200)