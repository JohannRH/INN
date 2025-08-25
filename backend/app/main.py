from fastapi import FastAPI
from app.routes import auth

app = FastAPI(title="Comuhub API")

# Registrar rutas
app.include_router(auth.router)