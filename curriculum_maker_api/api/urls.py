from django.urls import path
from .views import SignupView, HomeView, CurriculumListCreateView, MovieView, FeedbackView, QuizBulkCreateView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('signup/', SignupView.as_view(), name='signup'),

    # ログイン用JWTトークン取得
    path('login/', TokenObtainPairView.as_view()),
    
    # アクセストークンのリフレッシュ
    path('token/refresh/', TokenRefreshView.as_view()),
    path('home/', HomeView.as_view()),
    path('curriculum/', CurriculumListCreateView.as_view()),
    path('movie/<int:pk>/', MovieView.as_view()),
    path('movie/', MovieView.as_view()),
    path('feedback/', FeedbackView.as_view()),
    path('quiz/', QuizBulkCreateView.as_view()),
]
