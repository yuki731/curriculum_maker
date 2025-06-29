from django.contrib import admin
from .models import Curriculum, Movie, QuizQuestion, QuizChoice

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
    
class QuizChoiceInline(admin.TabularInline):
    model = QuizChoice
    extra = 3  # 新規追加フォームを3行分表示
    min_num = 1  # 選択肢は最低1つ以上必須にできる
    max_num = 10  # 必要に応じて最大数を制限


@admin.register(QuizQuestion)
class QuizQuestionAdmin(admin.ModelAdmin):
    list_display = ("id", "movie", "prompt", "created", "updated")
    search_fields = ("prompt", "movie__title")
    list_filter = ("movie", "created")

    # QuizChoiceをインラインで編集できるようにする
    inlines = [QuizChoiceInline]