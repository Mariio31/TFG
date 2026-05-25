from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.security import hash_password, require_role
from app.database import get_db
from app.models.user import User
from app.schemas.user import UserCreateByAdmin, UserResponse

router = APIRouter(prefix="/users", tags=["Usuarios"])


@router.get("/", response_model=List[UserResponse])
def list_users(
    db: Session = Depends(get_db),
    _admin=Depends(require_role("admin")),
):
    """Lista todos los usuarios. Solo admin."""
    return db.query(User).order_by(User.id).all()


@router.post("/", response_model=UserResponse)
def create_user(
    user: UserCreateByAdmin,
    db: Session = Depends(get_db),
    _admin=Depends(require_role("admin")),
):
    """Crea un nuevo usuario. Solo admin."""
    existing = db.query(User).filter(User.email == user.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email ya registrado")

    if user.role not in ["admin", "manager", "employee"]:
        raise HTTPException(
            status_code=400,
            detail="Rol inválido. Valores permitidos: admin, manager, employee",
        )

    db_user = User(
        name=user.name,
        email=user.email,
        hashed_password=hash_password(user.password),
        role=user.role,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


@router.delete("/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    admin=Depends(require_role("admin")),
):
    """Elimina un usuario. Solo admin; no puede eliminarse a sí mismo."""
    if user_id == admin.id:
        raise HTTPException(
            status_code=400,
            detail="No puedes eliminar tu propia cuenta",
        )

    db_user = db.query(User).filter(User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    db.delete(db_user)
    db.commit()
    return {"message": "Usuario eliminado"}
