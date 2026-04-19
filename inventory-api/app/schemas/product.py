from pydantic import BaseModel
from typing import Optional

class ProductBase(BaseModel):
    name: str
    sku: Optional[str] = None
    description: Optional[str] = None
    category_id: Optional[int] = None
    price: Optional[float] = 0.0
    cost: Optional[float] = 0.0
    stock: Optional[int] = 0
    min_stock: Optional[int] = 5
    unit: Optional[str] = "unidad"
    supplier: Optional[str] = None
    image_url: Optional[str] = None

class ProductCreate(ProductBase):
    pass

class ProductResponse(ProductBase):
    id: int

    class Config:
        from_attributes = True