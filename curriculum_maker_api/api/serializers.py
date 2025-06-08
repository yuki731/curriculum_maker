from django.contrib.auth.models import User
from rest_framework import serializers
from .models import Curriculum, Movie

class SignupSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['username', 'email', 'password']

    def create(self, validated_data):
        return User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password']
        )

class CurriculumSerializer(serializers.ModelSerializer):
    class Meta:
        model = Curriculum
        fields = ['id', 'user', 'name', 'progress', 'created_at', 'updated_at', 'status']
        read_only_fields = ['id', 'user', 'created_at', 'updated_at', 'status']

class MovieSerializer(serializers.ModelSerializer):
    class Meta:
        model = Movie
        fields = ['id', 'curriculum', 'url', 'title', 'status']
