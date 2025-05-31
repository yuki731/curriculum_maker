from django.urls import path
from .views import SignupView, HomeView, CurriculumListCreateView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('signup/', SignupView.as_view(), name='signup'),

    # ログイン用JWTトークン取得
    path('login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    
    # アクセストークンのリフレッシュ
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('home/', HomeView.as_view(), name='home'),
    path('curriculum/', CurriculumListCreateView.as_view(), name='curriculum'),
]
