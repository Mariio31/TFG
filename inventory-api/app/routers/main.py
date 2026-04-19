from fastapi import FastAPI
from app.database import Base, engine
from app.models import User, Category, Product, Movement
from app.routers import categories, products, movements

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Inventory API",
    description="API para gestión de inventario",
    version="1.0.0"
)

app.include_router(categories.router)
app.include_router(products.router)
app.include_router(movements.router)

@app.get("/")
def root():
    return {"message": "Inventory API funciona correctamente"}