from django.contrib import admin
from .models import Curriculum, Movie

@admin.register(Curriculum)
class CurriculumAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'user', 'progress', 'created_at', 'updated_at')
    list_filter = ('user', 'created_at')
    search_fields = ('name', 'user__username')

@admin.register(Movie)
class MoviesAdmin(admin.ModelAdmin):
    list_display = ('id', 'curriculum', 'url', 'status')
    list_filter = ('curriculum',)
    search_fields = ('url',)