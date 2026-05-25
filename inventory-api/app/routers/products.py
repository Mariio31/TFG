import os
import shutil
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.product import Product
from app.schemas.product import ProductCreate, ProductResponse
from app.core.security import get_current_user, require_role
from typing import List

router = APIRouter(prefix="/products", tags=["Productos"])

@router.get("/", response_model=List[ProductResponse])
def get_products(
    db: Session = Depends(get_db),
    skip: int = Query(0, ge=0),
    limit: int | None = Query(None, ge=1),
):
    """Todos los roles pueden ver productos."""
    query = db.query(Product).order_by(Product.id).offset(skip)
    if limit is not None:
        query = query.limit(limit)
    return query.all()

@router.get("/low-stock", response_model=List[ProductResponse])
def get_low_stock(db: Session = Depends(get_db)):
    """Todos los roles pueden ver stock bajo."""
    return db.query(Product).filter(Product.stock <= Product.min_stock).all()

@router.get("/{product_id}", response_model=ProductResponse)
def get_product(product_id: int, db: Session = Depends(get_db)):
    """Todos los roles pueden ver un producto."""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    return product

@router.post("/", response_model=ProductResponse)
def create_product(
    product: ProductCreate,
    db: Session = Depends(get_db),
    user = Depends(require_role("admin", "manager"))
):
    """Solo admin y manager pueden crear productos."""
    db_product = Product(**product.model_dump())
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product

@router.put("/{product_id}", response_model=ProductResponse)
def update_product(
    product_id: int,
    product: ProductCreate,
    db: Session = Depends(get_db),
    user = Depends(require_role("admin", "manager"))
):
    """Solo admin y manager pueden editar productos."""
    db_product = db.query(Product).filter(Product.id == product_id).first()
    if not db_product:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    for key, value in product.model_dump().items():
        setattr(db_product, key, value)
    db.commit()
    db.refresh(db_product)
    return db_product

@router.delete("/{product_id}")
def delete_product(
    product_id: int,
    db: Session = Depends(get_db),
    user = Depends(require_role("admin"))
):
    """Solo admin puede eliminar productos."""
    db_product = db.query(Product).filter(Product.id == product_id).first()
    if not db_product:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    db.delete(db_product)
    db.commit()
    return {"message": "Producto eliminado correctamente"}

UPLOAD_DIR = "static/images"

@router.post("/{product_id}/image")
def upload_image(
    product_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user = Depends(require_role("admin", "manager"))
):
    """Solo admin y manager pueden subir imágenes."""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
        
    # Validate extension
    allowed_extensions = {".jpg", ".jpeg", ".png", ".webp"}
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in allowed_extensions:
        raise HTTPException(status_code=400, detail="Formato de imagen no soportado. Solo JPG, PNG y WEBP.")
        
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    file_path = os.path.join(UPLOAD_DIR, f"product_{product_id}{ext}")
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    product.image_path = file_path
    db.commit()
    return {"message": "Imagen subida correctamente", "image_path": file_path}

@router.get("/{product_id}/image")
def get_image(product_id: int, db: Session = Depends(get_db)):
    """Todos los roles pueden ver imágenes."""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product or not product.image_path or not os.path.exists(product.image_path):
        raise HTTPException(status_code=404, detail="Imagen no encontrada")
    return FileResponse(product.image_path)

@router.delete("/{product_id}/image")
def delete_image(
    product_id: int,
    db: Session = Depends(get_db),
    user = Depends(require_role("admin", "manager"))
):
    """Solo admin y manager pueden eliminar imágenes."""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    if product.image_path and os.path.exists(product.image_path):
        os.remove(product.image_path)
    product.image_path = None
    db.commit()
    return {"message": "Imagen eliminada correctamente"}
