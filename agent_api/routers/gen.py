import re
from fastapi import APIRouter, HTTPException
import httpx
import agent_api.schemas.gen as gen_schema
from google import genai
import vertexai
from google.cloud import aiplatform
from langchain_google_vertexai import VertexAIEmbeddings, ChatVertexAI
from langchain_chroma import Chroma
import curriculum_maker_api.api.youtube_to_db.getYoutube as getYoutube
import curriculum_maker_api.api.youtube_to_db.updateChromaDB as updateChromaDB

YOUTUBE_API_KEY = ""
GEMINI_API_KEY = ""
PROJECT_ID = ""
REGION = ""
PERSIST_DIRECTORY = ""
COLLECTION_NAME = "youtube_videos_vertex_ai_test20250607"
DRF_URL = ""


GEN_YOUTUBE_QUERY_PROMPT = """ユーザの要望に基づいて、YouTubeから適切な動画を選びたいです。YouTubeに入力する適切な検索キーワードを出力してください。検索キーワードのみ出力してください。20文字以内にしてください。以下はユーザの要望です。
ユーザの要望："""

CURRICULUM_INSTRUCTION_PROMPT = """ユーザの要望に基づいて、YouTubeから以下の動画候補を選びました。ユーザの要望に応えられるように、以下の動画候補から適切な動画を選択し順番を考え、よいカリキュラムを組んでください。また、その順番にした理由とカリキュラムのタイトルも考えてください。カリキュラムのタイトル、カリキュラム、理由は下記のMarkdown形式に沿って出力してください。カリキュラムのタイトル、カリキュラム、理由のみ出力してください。
動画候補:
"""
CURRICULUM_FORMAT = """# タイトル:[実際のカリキュラムのタイトル]

# カリキュラム:
## 動画１
タイトル:...
動画説明:...

## 動画２
タイトル:...
動画説明:...

（カリキュラムに含まれるすべての動画を上記のように出力してください。）


# 理由:
......"""


genai_client = genai.Client(api_key=GEMINI_API_KEY)

vertexai.init(project=PROJECT_ID, location=REGION)
embeddings = VertexAIEmbeddings(model_name="text-multilingual-embedding-002")
try:
    vectorstore = Chroma(
        embedding_function=embeddings,
        persist_directory=PERSIST_DIRECTORY,
        collection_name=COLLECTION_NAME
    )
    print(f"既存のChromaDBコレクション '{COLLECTION_NAME}' をロードしました。")
except Exception:
    # コレクションが存在しない場合は、空の状態で初期化
    vectorstore = Chroma.from_documents(
        documents=[], # 最初は空のドキュメントリスト
        embedding=embeddings,
        persist_directory=PERSIST_DIRECTORY,
        collection_name=COLLECTION_NAME
    )
    print(f"新しいChromaDBコレクション '{COLLECTION_NAME}' を作成しました。")

router = APIRouter()


@router.post("/gen")
async def gen(user_request: gen_schema.UserRequest):
    youtube_query = genai_client.models.generate_content(
        model="gemma-3-27b-it",
        contents=[f"{GEN_YOUTUBE_QUERY_PROMPT}{user_request.user_message}"]
    ).text
    print(youtube_query)
    df_youtube_data = getYoutube.getYoutubeData(YOUTUBE_API_KEY, youtube_query, 10)
    updateChromaDB.updateChromaDB(df_youtube_data, vectorstore)
    search_results = vectorstore.similarity_search_with_score(youtube_query, k=10) # kは取得するドキュメント数

    if search_results:
        videos = ""
        title_url_dict = {}
        for doc, score in search_results:
            print("-" * 20)
            print(f"スコア: {score}")
            print(f"タイトル: {doc.metadata.get('title', 'N/A')}")
            print(f"チャンネル: {doc.metadata.get('channel_title', 'N/A')}")
            print(f"URL: {doc.metadata.get('source', 'N/A')}")
            print(f"説明の冒頭: {doc.page_content[:150]}...") # 説明の冒頭を表示
            print(f"検索キーワード: {doc.metadata.get('search_keywords', 'N/A')}")
            videos += f"タイトル:{doc.metadata.get('title', 'N/A')}\n"
            videos += f"動画説明:{doc.page_content[:150]}\n\n\n"
            title_url_dict[doc.metadata.get('title', 'N/A')] = doc.metadata.get('source', 'N/A')
    else:
        print("関連するドキュメントは見つかりませんでした。")
        videos = "関連する動画は見つかりませんでした。"

    if videos != "関連する動画は見つかりませんでした。":
        message = genai_client.models.generate_content(
            model="gemma-3-27b-it",
            contents=[f"{CURRICULUM_INSTRUCTION_PROMPT}{videos}\n{CURRICULUM_FORMAT}"]
        ).text
        final_movie_titles = re.findall(r'タイトル:(.*?)\n動画説明', message) #list
        final_movie_titles = [title.strip() for title in final_movie_titles]
        print(final_movie_titles)
        movies = [{"title":movie_title, "url":title_url_dict[movie_title]} for movie_title in final_movie_titles]
        title = re.findall(r'# タイトル:(.*?)\n', message)[0]
    else:
        message = videos
        movies = [{"title": "no title", "url": "no_url"}]
        title = "カリキュラムのタイトルはありません"
    print(message)
    print(movies)
    print(title)
    
    headers = {"Content-Type": "application/json"}
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(DRF_URL, json={"title":title, "movies":movies, "message":message}, headers=headers, timeout=60.0)
            response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            raise HTTPException(
                status_code=exc.response.status_code,
                detail=f"Upstream API error: {exc.response.text}"
            )
        except httpx.RequestError as exc:
            raise HTTPException(
                status_code=502,
                detail=f"Error connecting to upstream API: {exc}")

    return {"status": "success", "upstream_response": response.json()}


@router.get("/test")
async def test():
    return gen_schema.ModelResponse(message="以下はおすすめの動画一覧です。理由は～。",
                                    video_urls=["https://www.youtube.com/watch?v=jZqTz1G8G04",
                                                "https://www.youtube.com/watch?v=nB2qTzs2HTk"],
                                    video_lengths=["4:14","3:16"],
                                    titles=["title1", "title2"])