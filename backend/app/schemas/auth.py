from pydantic import BaseModel, EmailStr
from typing import Optional

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str
    role: str  # "cliente" o "negocio"
    phone: Optional[str] = None
    avatar_url: Optional[str] = None

    # Solo si es negocio
    business_name: Optional[str] = None
    nit: Optional[str] = None
    address: Optional[str] = None
    description: Optional[str] = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
