import pandas as pd
from apiclient.discovery import build

def getStatistics(youtube, video_id):
    '''
    動画の詳細情報を取得
    Parameters
    ----------
    youtube : object
        YoutubeのAPIクライアント
    video_id : str
        動画のID

    Returns
    -------
    statistics : dict
      動画の再生数、イイね数、コメント数
    '''
    # 初期値を設定
    statistics = {
        'videoId': video_id,
        'viewCount': '0',
        'likeCount': '0',
        'commentCount': '0'
    }

    # 動画の詳細情報を取得
    video_response = youtube.videos().list(
        part='statistics',
        id=video_id
    ).execute()

    try:
        # 動画の詳細情報を取得
        video_response = youtube.videos().list(
            part='statistics',
            id=video_id
        ).execute()

        # レスポンスにアイテムが存在し、統計情報が含まれているか確認
        if video_response and video_response.get('items'):
            item = video_response['items'][0]
            if 'statistics' in item:
                stats = item['statistics']
                statistics['viewCount'] = stats.get('viewCount', '0')
                statistics['likeCount'] = stats.get('likeCount', '0')
                statistics['commentCount'] = stats.get('commentCount', '0')

    except Exception as e:
        # API呼び出しでエラーが発生した場合（ネットワークエラー、無効なIDなど）
        print(f"Error fetching statistics for video ID {video_id}: {e}")
        # この場合でも、初期化されたstatisticsが返される

    return statistics

def getSubscriberCount(youtube, channel_id):
    """
    指定されたチャンネルIDの登録者数を取得します。

    Parameters
    ----------
    youtube : object
        YoutubeのAPIクライアント
    channel_id : str
        チャンネルのID

    Returns
    -------
    subscriber_count : str
        登録者数
    """
    try:
        channel_response = youtube.channels().list(
            part='statistics',
            id=channel_id
        ).execute()

        if channel_response and channel_response.get('items'):
            statistics = channel_response['items'][0].get('statistics', {})
            return statistics.get('subscriberCount', '0')
    except Exception as e:
        print(f"Error fetching subscriber count for channel ID {channel_id}: {e}")
    return '0'

# youtubeデータをpandasに変換する関数
def getYoutubeData(api_key: str, keyword: str, maxResults: int=5):
    '''
    Youtubeからキーワードで検索してDataFrameで返す
    Parameters
    ----------
    api_key : str
        APIキー
    keyword : str
        検索キーワード
    maxResults : int
        検索結果の最大数
    Returns
    -------
    df_youtube_data : pandas.DataFrame
        動画情報、統計情報、チャンネル登録者数を含むDataFrame
    '''
    youtube = build('youtube', 'v3', developerKey=api_key)
    search_responses = youtube.search().list(
        q=keyword,
        part='snippet',
        type='video',
        videoCategoryId = '27', # 27:Education
        regionCode="jp",
        maxResults=maxResults,# 5~50まで
    ).execute()

    df = pd.DataFrame(search_responses["items"])

    #各動画毎のvideoIdを取得
    df1 = pd.DataFrame(list(df['id']))['videoId']

    #各動画毎の動画情報取得
    df2 = pd.DataFrame(list(df['snippet']))[['channelTitle','publishedAt','channelId','title','description']]

    # 結合
    df_youtube_data = pd.concat([df1,df2], axis = 1)

    # 動画情報の追加
    df_static = df_youtube_data['videoId'].apply(lambda x: pd.Series(getStatistics(youtube, x)))
    df_youtube_data = df_youtube_data.merge(df_static, on='videoId')

    # チャンネル登録者数を取得
    # ユニークなchannelIdに対してのみAPIを呼び出す
    unique_channel_ids = df_youtube_data['channelId'].unique()
    subscriber_counts = {
        cid: getSubscriberCount(youtube, cid) for cid in unique_channel_ids
    }
    df_youtube_data['subscriberCount'] = df_youtube_data['channelId'].map(subscriber_counts)

    # 検索時の条件追加
    df_youtube_data['searchKeyword'] = keyword

    return df_youtube_data
