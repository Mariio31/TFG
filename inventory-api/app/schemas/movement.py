from pydantic import BaseModel
from typing import Optional
from enum import Enum

class MovementType(str, Enum):
    entrada = "entrada"
    salida = "salida"
    ajuste = "ajuste"

class MovementBase(BaseModel):
    product_id: int
    product_name: str
    type: MovementType
    quantity: int
    reason: Optional[str] = None
    notes: Optional[str] = None
    reference: Optional[str] = None

class MovementCreate(MovementBase):
    pass

class MovementResponse(MovementBase):
    id: int

    class Config:
        from_attributes = True