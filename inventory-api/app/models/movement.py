from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base

class Movement(Base):
    __tablename__ = "movements"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    product_name = Column(String, nullable=False)  # snapshot del nombre
    type = Column(String, nullable=False)  # entrada, salida, ajuste
    quantity = Column(Integer, nullable=False)
    reason = Column(String, nullable=True)
    notes = Column(String, nullable=True)
    reference = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    product = relationship("Product", backref="movements")