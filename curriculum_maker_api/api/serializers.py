from django.contrib.auth.models import User
from rest_framework import serializers
from .models import Curriculum, Movie, QuizQuestion, QuizChoice

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
        fields = ['id', 'user', 'name', 'progress', 'detail', 'created_at', 'updated_at', 'status']
        read_only_fields = ['id', 'user', 'created_at', 'updated_at', 'status']

class MovieSerializer(serializers.ModelSerializer):
    class Meta:
        model = Movie
        fields = ['id', 'curriculum', 'url', 'title', 'status', 'feedback']


class QuizChoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuizChoice
        fields = ("id", "text", "is_correct")


class QuizQuestionSerializer(serializers.ModelSerializer):
    choices = QuizChoiceSerializer(many=True)

    class Meta:
        model = QuizQuestion
        fields = ("id", "movie", "prompt", "choices")

    # ネストされた create / update を自前実装
    def create(self, validated_data):
        choice_data = validated_data.pop("choices")
        question = QuizQuestion.objects.create(**validated_data)
        for c in choice_data:
            QuizChoice.objects.create(question=question, **c)
        return question

    def update(self, instance, validated_data):
        choice_data = validated_data.pop("choices", None)

        # 質問文などを更新
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if choice_data is not None:
            # 既存選択肢を一旦全削除→再作成でも可。
            instance.choices.all().delete()
            for c in choice_data:
                QuizChoice.objects.create(question=instance, **c)

        return instance