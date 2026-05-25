from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserResponse, Token, LoginRequest, UserCreateByAdmin
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    get_current_user,
    require_role,
)

router = APIRouter(prefix="/auth", tags=["Autenticación"])

@router.post("/register", response_model=UserResponse)
def register(user: UserCreate, db: Session = Depends(get_db)):
    """Registra un nuevo usuario. El primero será admin, los siguientes employee."""
    existing = db.query(User).filter(User.email == user.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email ya registrado")
    
    # El primer usuario es admin, los siguientes son employee
    user_count = db.query(User).count()
    role = "admin" if user_count == 0 else "employee"
    
    db_user = User(
        name=user.name,
        email=user.email,
        hashed_password=hash_password(user.password),
        role=role
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@router.post("/login", response_model=Token)
def login(credentials: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == credentials.email).first()
    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")
    token = create_access_token({"sub": user.email, "role": user.role})
    return {"access_token": token, "token_type": "bearer"}

@router.post("/users", response_model=UserResponse)
def create_user_by_admin(
    user: UserCreateByAdmin,
    db: Session = Depends(get_db),
    admin_user = Depends(require_role("admin"))
):
    """Crea un nuevo usuario. Solo admins pueden crear usuarios."""
    existing = db.query(User).filter(User.email == user.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email ya registrado")
    
    # Validar que el rol sea válido
    if user.role not in ["admin", "manager", "employee"]:
        raise HTTPException(
            status_code=400,
            detail="Rol inválido. Valores permitidos: admin, manager, employee"
        )
    
    db_user = User(
        name=user.name,
        email=user.email,
        hashed_password=hash_password(user.password),
        role=user.role
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@router.get("/me", response_model=UserResponse)
def get_current_user_info(user = Depends(get_current_user)):
    """Obtiene la información del usuario actual."""
    return user