from typing import Annotated
from fastapi import Depends
from .models import *
from . import auth
from ..exceptions import AuthenticationError
from bson import ObjectId

from fastapi.concurrency import run_in_threadpool

async def register_user(db, user: RegisterUserRequest) -> RegisterUserResponse | dict:
    try:
        user_dict = user.dict()
        user_dict["password"] = auth.hash_password(user.password)
        result = await run_in_threadpool(db["users"].insert_one, user_dict)
        created = await run_in_threadpool(db["users"].find_one, {"_id": result.inserted_id})
        return RegisterUserResponse(
            id = str(created["_id"]),
            user_name = created["user_name"],
            email = created["email"],
        )
    except Exception as e:
        return { 'msg' : f'Failed to register user. {str(e)}' }

async def authenticate_user(db, data: LogInUserRequest | dict) -> LogInUserResponse | None:
    query = {
        "$or": [
            {"user_name": data.login},
            {"email": data.login}
        ]
    }
    user = await run_in_threadpool(db["users"].find_one, query)
    if not user:
        return None
    if not auth.verify_password(data.password, user.get("password")):
        return None
    return user

async def login_user(db, data: LogInUserRequest) -> LogInUserResponse | dict:
    user = await authenticate_user(db, data)
    if not user:
        return { 'msg' : 'failed' }
    _token = auth.create_access_token(user["user_name"], str(user["_id"]))
    return LogInUserResponse(
        id = str(user["_id"]),
        user_name = user["user_name"],
        email = user["email"],
        token = Token(
            access_token = _token,
            token_type = 'bearer'
        )
    )