from django.db import models
from django.contrib.auth.models import User

class Curriculum(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='curriculums')
    name = models.CharField(max_length=255)
    progress = models.IntegerField(default=0)
    status = models.BooleanField(default=False)
    detail = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} - {self.progress}%"

class Movie(models.Model):
    curriculum = models.ForeignKey(Curriculum, on_delete=models.CASCADE, related_name='movie')
    url = models.CharField(max_length=255)
    title = models.CharField(max_length=255)
    status = models.BooleanField(default=False)
    feedback = models.IntegerField(default=3)

class QuizQuestion(models.Model):
    movie = models.ForeignKey(Movie, on_delete=models.CASCADE, related_name="questions")
    prompt = models.TextField(help_text="問題文")

    # created_at / updated_at を入れておくと便利
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.movie.title}: {self.prompt[:30]}..."


class QuizChoice(models.Model):
    """
    選択肢。問題ごとに複数行。
    1 行だけ is_correct=True にしておく。
    """
    question = models.ForeignKey(
        QuizQuestion, on_delete=models.CASCADE, related_name="choices"
    )
    text = models.CharField(max_length=255)
    is_correct = models.BooleanField(default=False)

    class Meta:
        # 1 問の中では is_correct=True は 1 つだけにしたい場合
        constraints = [
            models.UniqueConstraint(
                fields=["question"],
                condition=models.Q(is_correct=True),
                name="unique_correct_per_question",
            )
        ]

    def __str__(self):
        return f"{'[正解]' if self.is_correct else ''}{self.text}"