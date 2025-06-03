from fastapi import APIRouter
import agent_api.schemas.gen as gen_schema
from google import genai

router = APIRouter()


@router.post("/gen")
async def gen(user_request: gen_schema.UserRequest):
    # gemma-3-27b-itを呼び出す。
    #client = genai.Client(api_key="")
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