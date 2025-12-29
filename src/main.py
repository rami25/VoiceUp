from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from src.api import routes

app = FastAPI()

# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["*"],  # or ["http://localhost:xxxxx"] for Flutter web
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

routes(app)
