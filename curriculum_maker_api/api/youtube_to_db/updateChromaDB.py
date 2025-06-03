import pandas as pd
from googleapiclient.discovery import build
import vertexai
from langchain_google_vertexai import VertexAIEmbeddings, ChatVertexAI
from langchain_chroma import Chroma
from langchain.schema import Document

PROJECT_ID = "utopian-rush-461605-f5"
LOCATION = "asia-northeast1"
vertexai.init(project=PROJECT_ID, location=LOCATION)

def updateChromaDB(df: pd.DataFrame, vectorstore: Chroma):
    """
    DataFrameの動画データをChromaDBに追加または更新します。
    動画が既に存在する場合は、検索キーワードを更新します。
    Parameter
    ----------
    df : pd.DataFrame
        動画情報を含むDataFrame
    vectorstore : Chroma
        ChromaDBのインスタンス
    """
    new_documents = []
    updated_ids = []
    updated_metadatas = []

    # ChromaDBの内部コレクションにアクセス
    collection = vectorstore._collection
    # 既存の動画IDを効率的にチェックするために、新しく取得したvideo_idリストでwhere句を使う
    # ChromaDBのgetメソッドは、idsとmetadatasを返します。
    existing_videos_in_db = collection.get(
        where={"video_id": {"$in": df['videoId'].tolist()}},
        include=['metadatas']
    )
    # 既存の動画情報をvideo_idをキーとするマップに変換
    existing_video_map = {meta['video_id']: {'id': doc_id, 'metadata': meta}
                          for doc_id, meta in zip(existing_videos_in_db['ids'], existing_videos_in_db['metadatas'])}

    print(f"追加予定の動画数: {len(df)}")
    for index, row in df.iterrows():
        video_id = row["videoId"]
        # ベクトル化するテキスト (タイトルと説明を結合)
        content = f"タイトル: {row['title']}\n説明: {row['description']}"
        current_keyword = row['searchKeyword']

        if video_id in existing_video_map:
            # 動画が既に存在する場合、キーワードを更新
            existing_info = existing_video_map[video_id]
            doc_id = existing_info['id']
            existing_metadata = existing_info['metadata']

            # 既存の検索キーワード文字列を取得し、新しいキーワードを追加
            # 既存のキーワードが文字列として保存されていると仮定
            existing_keywords_str = existing_metadata.get('search_keywords', '')
            # キーワードをリストに分割し、新しいキーワードを追加してから再度文字列に結合
            existing_keywords_list = existing_keywords_str.split(',') if existing_keywords_str else []
            if current_keyword not in existing_keywords_list:
                existing_keywords_list.append(current_keyword)
                # キーワードをカンマ区切りの文字列として保存
                updated_keyword_str = ','.join(existing_keywords_list)
                updated_ids.append(doc_id)
                # メタデータを更新するために、既存のメタデータに新しいキーワードリストをマージ
                updated_metadatas.append({**existing_metadata, 'search_keywords': updated_keyword_str})
            # else: キーワードが既に存在する場合は何もしない
        else:
            # 新しい動画を追加
            metadata = {
                "video_id": video_id,
                "title": row["title"],
                "channel_title": row["channelTitle"],
                "published_at": row["publishedAt"],
                "view_count": row["viewCount"],
                "like_count": row["likeCount"],
                "comment_count": row["commentCount"],
                "subscriber_count": row["subscriberCount"],
                "source": f"https://www.youtube.com/watch?v={video_id}",
                "search_keywords": current_keyword
            }
            new_documents.append(Document(page_content=content, metadata=metadata))

    if new_documents:
        vectorstore.add_documents(new_documents)
        print(f"{len(new_documents)}件の新しい動画をChromaDBに追加しました。")

    if updated_ids:
        # ChromaDBのupdateメソッドを直接呼び出してメタデータを更新
        collection.update(ids=updated_ids, metadatas=updated_metadatas)
        print(f"{len(updated_ids)}件の既存動画のキーワードを更新しました。")

    print("ChromaDBへのデータ処理が完了しました。")