from typing import Annotated
from fastapi import APIRouter, Depends, Request
from starlette import status
from .models import  *
from . import service
from . import auth
from fastapi.security import OAuth2PasswordRequestForm
from ..database.main import DB

router = APIRouter(
    prefix='/auth',
    tags=['auth']
)

@router.post('/register', status_code=status.HTTP_201_CREATED)
async def register_user(db: DB, user: RegisterUserRequest) -> RegisterUserResponse | dict:
    new_user = await service.register_user(db, user)
    return new_user


@router.get("/login") #, response_model=models.Token)
async def login_user(db: DB, data: LogInUserRequest) -> LogInUserResponse | dict:
    return await service.login_user(db, data)