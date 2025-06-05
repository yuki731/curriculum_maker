from langchain_google_vertexai import VertexAIEmbeddings, ChatVertexAI
from langchain_chroma import Chroma
import pandas as pd

import sys
import os
script_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(script_dir)
print(f"Current working directory: {os.getcwd()}")

from getYoutube import getYoutubeData
from updateChromaDB import updateChromaDB

args = sys.argv
YOUTUBE_API_KEY = args[1]
keyword = args[2]
test_query = args[3]
print(f'YOUTUBE_API_KEY:{YOUTUBE_API_KEY}, keyword:{keyword}, test_query:{test_query}')

'''
動作確認用
VertexAIとYoutube APIの設定が必要
'''

try:
    embeddings = VertexAIEmbeddings(model_name="text-multilingual-embedding-002")
    print("Vertex AI 埋め込みモデルが正常に初期化されました。")
except Exception as e:
    print(f"Vertex AI 埋め込みモデルの初期化に失敗しました: {e}")
    print("Google Cloud プロジェクトID、ロケーション、認証設定を確認してください。")
    exit()

# ChromaDBクライアントを初期化し、永続化ディレクトリを指定
PERSIST_DIRECTORY = "/content/drive/MyDrive/curriculum/chroma_db_youtube"
COLLECTION_NAME = "youtube_videos_vertex_ai"

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


df = getYoutubeData(YOUTUBE_API_KEY, keyword, 10)
updateChromaDB(df, vectorstore)

# vectorstoreから関連性の高いドキュメントを検索 (LLMなし)
print(f"\n'{test_query}' に基づいてChromaDBを検索します...")
search_results = vectorstore.similarity_search_with_score(test_query, k=3) # kは取得するドキュメント数

# 検索結果の表示
print("\n検索結果:")
if search_results:
    for doc, score in search_results:
        print("-" * 20)
        print(f"スコア: {score}")
        print(f"タイトル: {doc.metadata.get('title', 'N/A')}")
        print(f"チャンネル: {doc.metadata.get('channel_title', 'N/A')}")
        print(f"URL: {doc.metadata.get('source', 'N/A')}")
        print(f"説明の冒頭: {doc.page_content[:150]}...") # 説明の冒頭を表示
        print(f"検索キーワード: {doc.metadata.get('search_keywords', 'N/A')}")
else:
    print("関連するドキュメントは見つかりませんでした。")

# ChromaDBに保存されているドキュメント数を取得（確認用）
print("\nChromaDBに保存されているドキュメント数:", vectorstore._collection.count())