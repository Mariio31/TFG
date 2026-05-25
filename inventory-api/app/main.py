from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import Base, engine
from app.models import User, Category, Product, Movement
from app.routers import categories, products, movements, auth, users

Base.metadata.create_all(bind=engine)

# ---------------------------------------------------------------------------
# Migraciones manuales – se ejecutan al arrancar, solo si son necesarias
# ---------------------------------------------------------------------------
def run_migrations():
    """Aplica migraciones SQL idempotentes sobre la base de datos SQLite."""
    with engine.connect() as conn:
        # Comprueba si la columna image_path ya existe en la tabla products
        columns = conn.execute(
            __import__("sqlalchemy").text("PRAGMA table_info(products)")
        ).fetchall()
        existing_columns = [col[1] for col in columns]  # col[1] = nombre de columna

        if "image_path" not in existing_columns:
            conn.execute(
                __import__("sqlalchemy").text(
                    "ALTER TABLE products ADD COLUMN image_path VARCHAR"
                )
            )
            conn.commit()
            print("[migración] Columna 'image_path' añadida a la tabla 'products'.")
        else:
            print("[migración] Columna 'image_path' ya existe, nada que hacer.")

        # Comprueba si la columna role ya existe en la tabla users
        columns = conn.execute(
            __import__("sqlalchemy").text("PRAGMA table_info(users)")
        ).fetchall()
        existing_columns = [col[1] for col in columns]

        if "role" not in existing_columns:
            conn.execute(
                __import__("sqlalchemy").text(
                    "ALTER TABLE users ADD COLUMN role VARCHAR DEFAULT 'employee'"
                )
            )
            conn.commit()
            print("[migración] Columna 'role' añadida a la tabla 'users'.")
        else:
            print("[migración] Columna 'role' ya existe, nada que hacer.")

run_migrations()

app = FastAPI(
    title="Inventory API",
    description="API para gestión de inventario",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://10.0.2.2:8000", "*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(categories.router)
app.include_router(products.router)
app.include_router(movements.router)

@app.get("/")
def root():
    return {"message": "Inventory API funcionando ✅"}