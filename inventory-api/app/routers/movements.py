from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.movement import Movement
from app.models.product import Product
from app.schemas.movement import MovementCreate, MovementResponse
from typing import List

router = APIRouter(prefix="/movements", tags=["Movimientos"])

@router.get("/", response_model=List[MovementResponse])
def get_movements(db: Session = Depends(get_db)):
    return db.query(Movement).all()

@router.get("/{movement_id}", response_model=MovementResponse)
def get_movement(movement_id: int, db: Session = Depends(get_db)):
    movement = db.query(Movement).filter(Movement.id == movement_id).first()
    if not movement:
        raise HTTPException(status_code=404, detail="Movimiento no encontrado")
    return movement

@router.post("/", response_model=MovementResponse)
def create_movement(movement: MovementCreate, db: Session = Depends(get_db)):
    # Verificar que el producto existe
    product = db.query(Product).filter(Product.id == movement.product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Producto no encontrado")

    # Actualizar el stock según el tipo de movimiento
    if movement.type == "entrada":
        product.stock += movement.quantity
    elif movement.type == "salida":
        if product.stock < movement.quantity:
            raise HTTPException(status_code=400, detail="Stock insuficiente")
        product.stock -= movement.quantity
    elif movement.type == "ajuste":
        product.stock = movement.quantity

    # Guardar el movimiento
    db_movement = Movement(**movement.model_dump())
    db.add(db_movement)
    db.commit()
    db.refresh(db_movement)
    return db_movement