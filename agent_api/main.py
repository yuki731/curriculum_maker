from fastapi import FastAPI

from agent_api.routers import gen

app = FastAPI()
app.include_router(gen.router)