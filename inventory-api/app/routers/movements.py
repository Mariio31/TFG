from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.movement import Movement
from app.models.product import Product
from app.schemas.movement import MovementCreate, MovementResponse
from app.core.security import require_role
from typing import List

router = APIRouter(prefix="/movements", tags=["Movimientos"])
authenticated_user = require_role("admin", "manager", "employee")

@router.get("/", response_model=List[MovementResponse])
def get_movements(
    db: Session = Depends(get_db),
    user = Depends(authenticated_user),
    skip: int = Query(0, ge=0),
    limit: int | None = Query(None, ge=1),
):
    """Todos los roles pueden ver movimientos."""
    query = db.query(Movement).order_by(Movement.id.desc()).offset(skip)
    if limit is not None:
        query = query.limit(limit)
    return query.all()

@router.get("/{movement_id}", response_model=MovementResponse)
def get_movement(movement_id: int, db: Session = Depends(get_db), user = Depends(authenticated_user)):
    """Todos los roles pueden ver un movimiento."""
    movement = db.query(Movement).filter(Movement.id == movement_id).first()
    if not movement:
        raise HTTPException(status_code=404, detail="Movimiento no encontrado")
    return movement

@router.post("/", response_model=MovementResponse)
def create_movement(
    movement: MovementCreate,
    db: Session = Depends(get_db),
    user = Depends(authenticated_user)
):
    """Todos los roles pueden crear movimientos."""
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

@router.put("/{movement_id}", response_model=MovementResponse)
def update_movement(
    movement_id: int,
    movement_update: MovementCreate,
    db: Session = Depends(get_db),
    user = Depends(authenticated_user)
):
    """Todos los roles pueden actualizar movimientos."""
    db_movement = db.query(Movement).filter(Movement.id == movement_id).first()
    if not db_movement:
        raise HTTPException(status_code=404, detail="Movimiento no encontrado")

    old_product = db.query(Product).filter(Product.id == db_movement.product_id).first()
    new_product = db.query(Product).filter(Product.id == movement_update.product_id).first()
    
    if not new_product:
        raise HTTPException(status_code=404, detail="Producto no encontrado")

    # Revertir el efecto del movimiento anterior
    if old_product:
        if db_movement.type == "entrada":
            old_product.stock -= db_movement.quantity
        elif db_movement.type == "salida":
            old_product.stock += db_movement.quantity

    # Aplicar el nuevo efecto
    if movement_update.type == "entrada":
        new_product.stock += movement_update.quantity
    elif movement_update.type == "salida":
        if new_product.stock < movement_update.quantity:
            raise HTTPException(status_code=400, detail="Stock insuficiente")
        new_product.stock -= movement_update.quantity
    elif movement_update.type == "ajuste":
        new_product.stock = movement_update.quantity

    # Actualizar solo los campos editables (preservar created_at)
    editable_fields = ['product_id', 'product_name', 'type', 'quantity', 'reason', 'notes', 'reference']
    for key, value in movement_update.model_dump().items():
        if key in editable_fields:
            setattr(db_movement, key, value)

    db.commit()
    db.refresh(db_movement)
    return db_movement

@router.delete("/{movement_id}")
def delete_movement(
    movement_id: int,
    db: Session = Depends(get_db),
    user = Depends(authenticated_user)
):
    """Todos los roles pueden eliminar movimientos."""
    db_movement = db.query(Movement).filter(Movement.id == movement_id).first()
    if not db_movement:
        raise HTTPException(status_code=404, detail="Movimiento no encontrado")
    db.delete(db_movement)
    db.commit()
    return {"message": "Movimiento eliminado correctamente"}
