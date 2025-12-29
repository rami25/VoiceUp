from . import models
from ..auth import service, models as auth_models

from typing import Annotated
from fastapi import Depends, HTTPException
from ..exceptions import AuthenticationError
from bson import ObjectId

from fastapi.concurrency import run_in_threadpool

async def get_user_by_id(db, user) -> models.User | None:
  try:
    return await run_in_threadpool(db["users"].find_one, {"_id": ObjectId(user.get_id())})
  except Exception:
    return None
    raise HTTPException(status_code=400, detail="Invalid user ID")

async def add_user(db, new_user: models.User, _user: auth_models.TokenData) -> models.UpdateUserRequest | dict:
  user = await get_user_by_id(db, _user)
  if user and user.get('role') == 1:
    return await service.register_user(db, new_user)
  else:
    return {'msg' : 'failed'}


async def update_user_util(db, user):
  if not ObjectId.is_valid(user.id):
    raise HTTPException(status_code=400, detail="Invalid user ID")

  update_dict = {k: v for k, v in user.dict().items() if k != "id" and v is not None}

  if not update_dict:
      raise HTTPException(status_code=400, detail="No fields to update")

  result = await run_in_threadpool(
      db["users"].update_one,
      {"_id": ObjectId(user.id)},
      {"$set": update_dict}
  )

  if result.matched_count == 0:
      raise HTTPException(status_code=404, detail="User not found")

  ret = await run_in_threadpool(db["users"].find_one, {"_id": ObjectId(user.id)})
  ret["_id"] = str(ret["_id"])
  return ret
  # return {"message": "User updated successfully"}


async def update_user(db, new_user: models.UpdateUserRequest, _user: auth_models.TokenData) -> models.UpdateUserRequest | dict:
  user = await get_user_by_id(db, _user)
  if user and user.get('role') == 1:
    return await update_user_util(db, new_user)
  else:
    return {'msg' : 'failed'}




async def delete_user_util(db, user):
  if not ObjectId.is_valid(user.id):
      raise HTTPException(status_code=400, detail="Invalid user ID")

  result = await run_in_threadpool(
      db["users"].delete_one,
      {"_id": ObjectId(user.id)}
  )

  if result.deleted_count == 0:
      raise HTTPException(status_code=404, detail="User not found")

  return {"message": "User deleted successfully"}

async def delete_user(db, duser: models.DeleteUserRequest, _user: auth_models.TokenData) -> dict:
  user = await get_user_by_id(db, _user)
  if user and user.get('role') == 1:
    return await delete_user_util(db, duser)
  else:
    return {'msg' : 'failed'}