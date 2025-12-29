from fastapi import HTTPException, status

# class AuthenticationError(HTTPException):
#   def __init__(self, message: str = "Could not validate user"):
#     super().__init__(status_code=401, detail=message)
#     return message

class AuthenticationError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )