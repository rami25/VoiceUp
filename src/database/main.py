from typing import Annotated
from fastapi import Depends
from pymongo import MongoClient
from dotenv import load_dotenv
from pathlib import Path
import os

parent_dir = Path(__file__).parent.parent
env_path = parent_dir / ".env"
load_dotenv(dotenv_path=env_path)

MONGO_URI = os.getenv('MONGO_URI')
MONGO_DB_NAME = os.getenv('MONGO_DB_NAME')
client = MongoClient(MONGO_URI)

db = client.get_database(MONGO_DB_NAME)

async def get_db():
    return db

DB = Annotated[type(db), Depends(get_db)]