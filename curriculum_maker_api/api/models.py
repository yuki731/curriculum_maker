from django.db import models
from django.contrib.auth.models import User

class Curriculum(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='curriculums')
    name = models.CharField(max_length=255)
    progress = models.IntegerField(default=0)
    status = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} - {self.progress}%"

class Movie(models.Model):
    curriculum = models.ForeignKey(Curriculum, on_delete=models.CASCADE, related_name='movie')
    url = models.CharField(max_length=255)
    title = models.CharField(max_length=255)
    