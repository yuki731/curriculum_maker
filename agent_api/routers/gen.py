import re
import json
from fastapi import APIRouter, HTTPException
import httpx
import agent_api.schemas.gen as gen_schema
from google import genai
import vertexai
from google.cloud import aiplatform
from langchain_google_vertexai import VertexAIEmbeddings, ChatVertexAI
from langchain_chroma import Chroma
from youtube_transcript_api import YouTubeTranscriptApi, TranscriptsDisabled, NoTranscriptFound
import curriculum_maker_api.api.youtube_to_db.getYoutube as getYoutube
import curriculum_maker_api.api.youtube_to_db.updateChromaDB as updateChromaDB

YOUTUBE_API_KEY = ""
GEMINI_API_KEY = ""
PROJECT_ID = ""
REGION = ""
PERSIST_DIRECTORY = ""
COLLECTION_NAME = "youtube_videos_vertex_ai_test20250625"
DRF_BASE   = "http://127.0.0.1:8000"
POST_EP    = f"{DRF_BASE}/curriculum/"
POST_EP2    = f"{DRF_BASE}/quiz/"
REFRESH_EP = f"{DRF_BASE}/token/refresh/"



GEN_YOUTUBE_QUERY_PROMPT = """ユーザの要望に基づいて、YouTubeから適切な動画を選びたいです。YouTubeに入力する適切な検索キーワードを出力してください。検索キーワードは20文字以内でかつ改行を含まない一行の文字列です。検索キーワードに複数単語が必要な場合は全角スペースで複数単語を区切ってください。検索キーワードのみ出力してください。以下はユーザの要望です。
ユーザの要望："""

CURRICULUM_INSTRUCTION_PROMPT = """ユーザの要望に基づいて、YouTubeから以下の動画候補を選びました。ユーザの要望に応えられるように、以下の動画候補から適切な動画を選択し順番を考え、よいカリキュラムを組んでください。また、その順番にした理由とカリキュラムのタイトルも考えてください。カリキュラムのタイトル、カリキュラム、理由は下記のMarkdown形式に沿って出力してください。カリキュラムのタイトル、カリキュラム、理由のみ出力してください。
動画候補:
"""
CURRICULUM_FORMAT = """# タイトル:[実際のカリキュラムのタイトル]

# カリキュラム:
## 動画１
識別番号:...
タイトル:...
動画説明:...

## 動画２
識別番号:...
タイトル:...
動画説明:...

（カリキュラムに含まれるすべての動画を上記のように出力してください。）


# 理由:
......"""


genai_client = genai.Client(api_key=GEMINI_API_KEY)
client = httpx.AsyncClient(base_url=DRF_BASE, follow_redirects=True, timeout=httpx.Timeout(300.0))

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
    
async def drf_post(url, json_body: dict, access_token: str) -> httpx.Response:
    return await client.post(
        url,
        json=json_body,
        headers={"Authorization": f"Bearer {access_token}"},
        timeout=10,
    )
    
async def refresh_access_token(refresh_token: str) -> str:
    r = await client.post(REFRESH_EP, json={"refresh": refresh_token}, timeout=10)
    r.raise_for_status()
    return r.json()["access"]

router = APIRouter()

@router.post("/gen/")
async def gen(user_request: gen_schema.UserRequest):
    youtube_query = genai_client.models.generate_content(
        model="gemma-3-27b-it",
        contents=[f"{GEN_YOUTUBE_QUERY_PROMPT}{user_request.message}"]
    ).text
    print(youtube_query)
    df_youtube_data = getYoutube.getYoutubeData(YOUTUBE_API_KEY, youtube_query, 10)
    print(df_youtube_data)
    updateChromaDB.updateChromaDB(df_youtube_data, vectorstore)
    search_results = vectorstore.similarity_search_with_score(youtube_query, k=10) # kは取得するドキュメント数

    if search_results:
        videos = ""
        #title_url_dict = {}
        #title_id_dict = {}
        tmp_id_url_dict = {}
        tmp_id_id_dict = {}
        tmp_id_title_dict = {}
        tmp_id = 0
        for doc, score in search_results:
            print("-" * 20)
            print(f"スコア: {score}")
            print(f"タイトル: {doc.metadata.get('title', 'N/A')}")
            print(f"チャンネル: {doc.metadata.get('channel_title', 'N/A')}")
            print(f"URL: {doc.metadata.get('source', 'N/A')}")
            print(f"説明の冒頭: {doc.page_content[:150]}...") # 説明の冒頭を表示
            print(f"検索キーワード: {doc.metadata.get('search_keywords', 'N/A')}")
            videos += f"識別番号:{tmp_id}\n"
            videos += f"タイトル:{doc.metadata.get('title', 'N/A')}\n"
            videos += f"動画説明:{doc.page_content[:150]}\n\n\n"
            #title_url_dict[doc.metadata.get('title', 'N/A').strip()] = doc.metadata.get('source', 'N/A')
            #title_id_dict[doc.metadata.get('title', 'N/A').strip()] = doc.metadata.get('video_id')
            tmp_id_url_dict[str(tmp_id)] = doc.metadata.get('source', 'N/A')
            tmp_id_id_dict[str(tmp_id)] = doc.metadata.get('video_id')
            tmp_id_title_dict[str(tmp_id)] = doc.metadata.get('title', 'N/A')
            tmp_id += 1
    else:
        print("関連するドキュメントは見つかりませんでした。")
        videos = "関連する動画は見つかりませんでした。"

    if videos != "関連する動画は見つかりませんでした。":
        message = genai_client.models.generate_content(
            model="gemma-3-27b-it",
            contents=[f"{CURRICULUM_INSTRUCTION_PROMPT}{videos}\n{CURRICULUM_FORMAT}"]
        ).text
        #final_movie_titles = re.findall(r'タイトル:(.*?)\n動画説明', message) #list
        #final_movie_titles = [title.strip() for title in final_movie_titles]
        final_movie_tmp_ids = re.findall(r'識別番号:(.*?)\nタイトル', message) #list
        final_movie_tmp_ids = [tmp_id.strip() for tmp_id in final_movie_tmp_ids]
        message = re.sub(r'^識別番号:.*\n?', '', message, flags=re.MULTILINE)
        final_movie_titles = [tmp_id_title_dict[tmp_id] for tmp_id in final_movie_tmp_ids]
        #print(final_movie_titles)
        #print(title_url_dict)
        print(final_movie_tmp_ids)
        print(tmp_id_url_dict)
        print(tmp_id_title_dict)
        print(message)
        #movies = [{"title":movie_title, "url":title_url_dict[movie_title.strip()]} for movie_title in final_movie_titles]
        movies = [{"title":tmp_id_title_dict[tmp_id], "url":tmp_id_url_dict[tmp_id]} for tmp_id in final_movie_tmp_ids]
        title = re.findall(r'# タイトル:(.*?)\n', message)[0]
    else:
        message = videos
        movies = [{"title": "no title", "url": "no_url"}]
        title = "カリキュラムのタイトルはありません"
        return {"message": "該当する動画が見つかりませんでした"}
    
    quizes = []
    #video_ids = [title_id_dict[movie_title.strip()] for movie_title in final_movie_titles]
    video_ids = [tmp_id_id_dict[tmp_id] for tmp_id in final_movie_tmp_ids]
    for i, video_id in enumerate(video_ids):
        try:
            # まず日本語字幕を取得しに行く
            transcript = YouTubeTranscriptApi.get_transcript(video_id, languages=['ja'])
        except NoTranscriptFound:
            # 日本語字幕がなければ英語字幕を取得し、翻訳する
            try:
                transcript = YouTubeTranscriptApi.get_transcript(video_id, languages=['en'])
            except (NoTranscriptFound, TranscriptsDisabled) as e:
                print(f"字幕が取得できませんでした: {e}")
                transcript = None

        if transcript is not None:
            # 字幕表示や処理
            for entry in transcript:
                print(entry)
        else:
            print("字幕が存在しません。")
            quizes.append([])
            continue
            


        text = " ".join([entry["text"] for entry in transcript])
        if len(text) > 2000:
            text = text[:2000]
        prompt = f"""
        以下の内容は学習動画の字幕です。この内容から簡単な選択問題を5問を日本語で作ってください。

        要件:
        - JSON形式で出力してください。
        - フィールドは: "question", "choices", "answer"
        - choices は文字列のリスト（3〜4択）
        - answer は正解の文字列と一致するようにしてください。

        対象情報:
        {text}

        出力形式:
        {{
        "question": "～？",
        "choices": ["～", "～", "～"],
        "answer": "～"
        }}

        {CURRICULUM_FORMAT}
        """

        message2 = genai_client.models.generate_content(
            model="gemma-3-27b-it",
            contents=[prompt]
        ).text

        print(message2)

        message2 = message2.replace('```json', '')
        message2 = message2.replace('```', '')

        data = json.loads(message2)

        for item in data:
            print(f"Q: {item['question']}")
            for choice in item['choices']:
                print(f" - {choice}")
            print(f"A: {item['answer']}")
        
        quizes.append(data)

    print("リクエスト")
    res = await drf_post(POST_EP, {"title":title, "movies":movies, "message":message}, user_request.accessToken)
    print("リクエスト１成功")
    res2 = await drf_post(POST_EP2, {'id': res.json().get('id'), 'movie_titles': final_movie_titles, 'quizes': quizes}, user_request.accessToken)
    print(res2.json().get('detail'))
    # for i in range(len(quizes)):
    #     await drf_post(POST_EP2, {'id': res.json().get('id'),'movie_titles': final_movie_titles, 'quizes': quizes}, user_request.accessToken)

    if res.status_code in (401, 403):
        try:
            new_access = await refresh_access_token(user_request.refreshToken)
        except httpx.HTTPStatusError as e:
            raise HTTPException(e.response.status_code, e.response.text)

        res = await drf_post(POST_EP, {"title":title, "movies":movies, "message":message}, new_access)
        res2 = await drf_post(POST_EP2, {'id': res.json().get('id'), 'movie_titles': final_movie_titles, 'quizes': quizes}, user_request.accessToken)
        print(res2.json().get('detail'))
        # for i in range(len(quizes)):
        #     await drf_post(POST_EP2, {'id': res.json().get('id'), 'movie_titles': final_movie_titles[i], 'quizes': quizes[i]}, user_request.accessToken)

    try:
        return res.json()
    finally:
        res.raise_for_status()


@router.get("/test")
async def test():
    return gen_schema.ModelResponse(message="以下はおすすめの動画一覧です。理由は～。",
                                    video_urls=["https://www.youtube.com/watch?v=jZqTz1G8G04",
                                                "https://www.youtube.com/watch?v=nB2qTzs2HTk"],
                                    video_lengths=["4:14","3:16"],
                                    titles=["title1", "title2"])