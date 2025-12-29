from fastapi import APIRouter, Depends, status
from ..auth import auth, models as auth_models
from . import service, models
from ..database.main import DB

router = APIRouter(
  prefix="/users",
  tags=["users"]
)

@router.post("/add_user")
async def add_user(db: DB, new_user: models.User, user : auth_models.TokenData = Depends(auth.get_current_user)) -> models.UpdateUserRequest | dict:
  return await service.add_user(db, new_user, user)

@router.patch("/update_user")
async def update_user(db: DB, new_user: models.UpdateUserRequest, user : auth_models.TokenData = Depends(auth.get_current_user)) -> models.UpdateUserRequest | dict:
  return await service.update_user(db, new_user, user)

@router.delete("/delete_user")
async def delete_user(db: DB, user: models.DeleteUserRequest, _user : auth_models.TokenData = Depends(auth.get_current_user)) -> dict:
  return await service.delete_user(db, user, _user)