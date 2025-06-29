# YouTube × Gemma 学習支援アプリ

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=flat&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/ja/)
[![Django](https://img.shields.io/badge/Django-%23092E20.svg?style=flat&logo=django&logoColor=white)](https://www.djangoproject.com/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![SQLite](https://img.shields.io/badge/SQLite-003B57?style=flat&logo=sqlite&logoColor=white)](https://sqlite.org/)
[![NGINX](https://img.shields.io/badge/NGINX-%23009639.svg?style=flat&logo=nginx&logoColor=white)](https://nginx.org/en/)

このアプリケーションは、Google製の軽量生成AI「Gemma」を活用し、YouTube動画から自動で学習カリキュラムと確認問題を生成する学習支援アプリです。

## 概要

本アプリケーションは、YouTubeという膨大な学習リソースを活用し、Gemmaによる自然言語処理で最適な学習カリキュラムと確認問題を自動生成します。

これにより、現代の学習者に対して以下のような新しい学習体験を提供します：

- ❌ 学ぶべき順序が分からない → 「迷わない」
- ⏱ ムダな時間が多い → 「効率よく学べる」
- 🎯 習得できているかわからない → 「アウトプットで確認できる」

## 技術スタック

- **Front**: Flutter（Web）  
- **Backend①**: FastAPI（YouTube API・Gemma連携）  
- **Backend②**: Django REST Framework（DB・認証）  
- **DB**: SQLite  
- **Proxy**: NGINX（HTTPS・CORS）

## アプリケーションの特徴

|特徴|説明|
| :--- | :--- |
|🎓 学習構成自動化|動画内容を理解した上で、Gemmaが順序や分量を調整|
|🧠 確認問題生成|各動画ごとに理解度チェック用の問題を提示|
|🔍 YouTube活用|学習者に身近な無料リソース（YouTube）を最大限活用|
|🧩 カスタマイズ性|学習目的に応じてカリキュラムを自由に調整可能|
|📊 進捗トラッキング|学習進度の可視化・モチベーション維持を支援|
  
## デモ動画

[YouTube デモを見る](https://youtu.be/ufbpTiq-AxM)

## インストール & 実行方法

> 事前にFlutter, Django REST FrameworkのインストールおよびYouTube Data API v3とGemmaのAPIキーが必要です。

### 実行方法

1. フロントエンドの起動

    ```sh
    cd curriculum_maker/curriculum_maker_api/
    python manage.py runserver 3000
    ```
