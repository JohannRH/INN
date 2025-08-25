from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr
from app.services.supabase_client import supabase, supabase_admin

router = APIRouter(prefix="/auth", tags=["auth"])

# -------- SCHEMAS --------
class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str
    role: str  # "cliente" o "negocio"
    phone: str | None = None
    avatar_url: str | None = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


# -------- ENDPOINTS --------
@router.post("/register")
def register_user(data: RegisterRequest):
    try:
        # First, check if user already exists in auth
        auth_users = supabase_admin.auth.admin.list_users()
        existing_user = None
        for user in auth_users:
            if user.email == data.email:
                existing_user = user
                break
        
        if existing_user:
            # Check if profile exists
            profile_response = supabase_admin.table("profiles").select("*").eq("id", existing_user.id).execute()
            
            if profile_response.data:
                raise HTTPException(status_code=400, detail="El usuario ya existe completamente")
            else:
                # User exists in auth but not in profiles, create profile only
                profile_response = supabase_admin.table("profiles").insert({
                    "id": existing_user.id,
                    "role": data.role,
                    "name": data.name,
                    "email": data.email,
                    "phone": data.phone,
                    "avatar_url": data.avatar_url
                }).execute()
                
                return {
                    "message": "Perfil creado para usuario existente", 
                    "user_id": existing_user.id
                }
        
        # User doesn't exist, create new user
        auth_response = supabase_admin.auth.admin.create_user({
            "email": data.email,
            "password": data.password,
            "email_confirm": True
        })

        if auth_response.user is None:
            raise HTTPException(status_code=400, detail="No se pudo crear el usuario")

        user_id = auth_response.user.id

        # Create profile
        profile_response = supabase_admin.table("profiles").insert({
            "id": user_id,
            "role": data.role,
            "name": data.name,
            "email": data.email,
            "phone": data.phone,
            "avatar_url": data.avatar_url
        }).execute()

        return {
            "message": "Usuario registrado correctamente", 
            "user_id": user_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        # If user creation succeeded but profile creation failed, clean up
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