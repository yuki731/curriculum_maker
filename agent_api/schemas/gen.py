from typing import List

from pydantic import BaseModel, Field


class UserRequest(BaseModel):
    keyword: str
    category: str
    period: str


class ModelResponse(BaseModel):
    message: str
    video_urls: List[str]
    video_lengths: List[str]