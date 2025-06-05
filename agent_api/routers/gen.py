from fastapi import APIRouter
import agent_api.schemas.gen as gen_schema
from google import genai
import curriculum_maker_api.api.youtube_to_db.getYoutube as getYoutube
import curriculum_maker_api.api.youtube_to_db.updateChromaDB as updateChromaDB

YOUTUBE_API_KEY = ""
GEMINI_API_KEY = ""

GEN_YOUTUBE_QUERY_PROMPT = """ユーザの要望に基づいて、YouTubeから適切な動画を選びたいです。YouTubeに入力する適切な検索キーワードを出力してください。以下はユーザの要望です。
ユーザの要望："""

router = APIRouter()


@router.post("/gen")
async def gen(user_request: gen_schema.UserRequest):
    # gemma-3-27b-itを呼び出す。
    client = genai.Client(api_key=GEMINI_API_KEY)
    youtube_query = client.models.generate_content(
        model="gemma-3-27b-it",
        contents=[f"{GEN_YOUTUBE_QUERY_PROMPT}{user_request.user_message}"]
    )

    df_youtube_data = getYoutube.getYoutubeData(YOUTUBE_API_KEY, youtube_query, 50)
    
    #chat = client.chats.create(model="gemma-3-27b-it")
    #response = chat.send_message("こんにちは！")
    #response = chat.send_message("海老名駅の近くにあるおいしいお店を教えて！")
    return gen_schema.ModelResponse(message="以下はおすすめの動画一覧です。理由は～。",
                                    video_urls=["https://www.youtube.com/watch?v=jZqTz1G8G04",
                                                "https://www.youtube.com/watch?v=nB2qTzs2HTk"],
                                    video_lengths=["4:14","3:16"])


@router.get("/test")
async def test():
    return gen_schema.ModelResponse(message="以下はおすすめの動画一覧です。理由は～。",
                                    video_urls=["https://www.youtube.com/watch?v=jZqTz1G8G04",
                                                "https://www.youtube.com/watch?v=nB2qTzs2HTk"],
                                    video_lengths=["4:14","3:16"])