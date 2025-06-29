from typing import List

from pydantic import BaseModel, Field


class UserRequest(BaseModel):
    message: str
    # category: str
    period: str
    accessToken:str
    refreshToken:str


class ModelResponse(BaseModel):
    message: str
    video_urls: List[str]
    video_lengths: List[str]
    titles: List[str]