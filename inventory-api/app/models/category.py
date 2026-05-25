from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func
from app.database import Base

class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)
    color = Column(String, default="#6B7F5B")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    @property
    def product_count(self) -> int:
        return len(self.products) if hasattr(self, 'products') and self.products else 0