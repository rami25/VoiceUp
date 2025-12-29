from pydantic import BaseModel, EmailStr

class RegisterUserRequest(BaseModel):
    user_name: str
    email: EmailStr
    password: str

class RegisterUserResponse(BaseModel):
    id: str
    user_name: str
    email: EmailStr

class LogInUserRequest(BaseModel):
    login: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class LogInUserResponse(RegisterUserResponse):
    token: Token

class TokenData(BaseModel):
    user_id: str | None = None
    def get_id(self) -> str | None:
        return self.user_id