from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr
from app.services.supabase_client import supabase, supabase_admin
from app.schemas.auth import RegisterRequest, LoginRequest

router = APIRouter(prefix="/auth", tags=["auth"])

# -------- ENDPOINTS --------
@router.post("/register")
def register_user(data: RegisterRequest):
    try:
        # 1. Crear usuario en auth
        auth_response = supabase_admin.auth.admin.create_user({
            "email": data.email,
            "password": data.password,
            "email_confirm": True
        })
        if auth_response.user is None:
            raise HTTPException(status_code=400, detail="No se pudo crear el usuario")

        user_id = auth_response.user.id

        # 2. Crear perfil en profiles
        profile_response = supabase_admin.table("profiles").insert({
            "id": user_id,
            "role": data.role,
            "name": data.name,
            "email": data.email,
            "phone": data.phone,
            "avatar_url": data.avatar_url
        }).execute()

        # 3. Si es negocio → crear también en businesses
        if data.role == "negocio":
            # OJO: necesitarás ampliar RegisterRequest con los campos de negocio
            business_data = {
                "user_id": user_id,
                "name": getattr(data, "business_name", None),
                "nit": getattr(data, "nit", None),
                "address": getattr(data, "address", None),
                "description": getattr(data, "description", None),
                "logo_url": getattr(data, "avatar_url", None)
            }
            business_response = supabase_admin.table("businesses").insert(business_data).execute()

            return {
                "message": "Negocio registrado correctamente",
                "user_id": user_id,
                "business": business_response.data[0]
            }

        return {
            "message": "Cliente registrado correctamente",
            "user_id": user_id
        }

    except Exception as e:
        if 'user_id' in locals():
            try:
                supabase_admin.auth.admin.delete_user(user_id)
            except:
                pass
        raise HTTPException(status_code=400, detail=f"Error al registrar usuario: {str(e)}")


@router.post("/login")
def login_user(data: LoginRequest):
    # Use regular client for login (user operations)
    response = supabase.auth.sign_in_with_password(
        {"email": data.email, "password": data.password}
    )

    if response.user is None:
        raise HTTPException(status_code=401, detail="Credenciales inválidas")

    return {
        "access_token": response.session.access_token,
        "refresh_token": response.session.refresh_token,
        "user": {
            "id": response.user.id,
            "email": response.user.email
        }
    }