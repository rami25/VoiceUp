from datetime import timedelta, datetime, timezone
from typing import Annotated
from fastapi import Depends
from passlib.context import CryptContext
import jwt
from jwt import PyJWTError
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
import logging
from . import models
from ..exceptions import AuthenticationError

from dotenv import load_dotenv
from pathlib import Path
import os

parent_dir = Path(__file__).parent.parent
env_path = parent_dir / ".env"
load_dotenv(dotenv_path=env_path)

SECRET_KEY = os.getenv('SECRET_KEY')
ALGORITHM = os.getenv('ALGORITHM')
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv('ACCESS_TOKEN_EXPIRE_MINUTES'))

oauth2_bearer = OAuth2PasswordBearer(tokenUrl='auth/token')
bcrypt_context = CryptContext(schemes=['bcrypt'], deprecated='auto')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt_context.verify(plain_password, hashed_password)

def hash_password(password: str) -> str:
    return bcrypt_context.hash(password)

def create_access_token(name: str, user_id: str) -> str:
    encode = {
        'sub': name,
        'id': user_id,
        'exp': datetime.now(timezone.utc) + timedelta(ACCESS_TOKEN_EXPIRE_MINUTES)
    }
    return jwt.encode(encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(token: str) -> models.TokenData:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get('id')
        return models.TokenData(user_id=user_id)
    except PyJWTError as e:
        logging.warning(f"Token verification failed: {str(e)}")
        raise AuthenticationError()

def get_current_user(token: Annotated[str, Depends(oauth2_bearer)]) -> models.TokenData:
    return verify_token(token)
