from pydantic import BaseModel
from typing import Optional

class BusinessCreate(BaseModel):
    name: str
    nit: str
    address: str
    description: Optional[str] = None
    type_id: int
    logo_url: Optional[str] = None
