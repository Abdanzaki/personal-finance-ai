from datetime import timedelta
from typing import Optional
import uuid
import jwt
from fastapi import APIRouter, Depends, Form, HTTPException, Request, status
from sqlalchemy.orm import Session
from app.core.deps import get_current_user
from app.core.security import (
    create_access_token,
    create_refresh_token,
    create_token,
    decode_token,
    get_password_hash,
    validate_password_strength,
    verify_password,
)
from app.db.database import get_db
from app.models.account import Account
from app.models.user import User
from app.schemas.auth import (
    MessageResponse,
    PasswordResetRequest,
    PasswordResetResponse,
    RefreshTokenRequest,
    RefreshTokenResponse,
    TokenResponse,
    UserLoginRequest,
    UserSignupRequest,
)
from app.schemas.user import UserResponse

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/signup", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def signup(
    signup_data: UserSignupRequest,
    db: Session = Depends(get_db),
):
    # Validate password strength
    is_valid, error_msg = validate_password_strength(signup_data.password)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error_msg,
        )

    # Check for existing user
    clean_email = signup_data.email.lower().strip()
    existing_user = db.query(User).filter(User.email == clean_email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email is already registered",
        )

    # Create user
    user = User(
        email=clean_email,
        hashed_password=get_password_hash(signup_data.password),
        full_name=signup_data.full_name.strip(),
        phone=signup_data.phone.strip() if signup_data.phone else None,
        currency="INR",
    )
    db.add(user)
    db.flush()

    # Create default primary account
    default_account = Account(
        user_id=user.id,
        name="Primary Account",
        account_type="bank",
        opening_balance=0.0,
        current_balance=0.0,
        currency="INR",
        is_primary=True,
    )
    db.add(default_account)
    db.commit()
    db.refresh(user)

    # Generate tokens
    access_token = create_access_token(subject=str(user.id))
    refresh_token = create_refresh_token(subject=str(user.id))

    return TokenResponse(
        user=UserResponse.model_validate(user),
        access_token=access_token,
        refresh_token=refresh_token,
    )


@router.post("/login", response_model=TokenResponse)
async def login(
    request: Request,
    db: Session = Depends(get_db),
):
    """
    Login endpoint supporting both JSON payload {"email": "...", "password": "..."}
    and OAuth2 form-data (username/password) for Swagger UI compatibility.
    """
    email = None
    password = None

    content_type = request.headers.get("content-type", "")
    if "application/json" in content_type:
        body = await request.json()
        email = body.get("email") or body.get("username")
        password = body.get("password")
    else:
        form = await request.form()
        email = form.get("username") or form.get("email")
        password = form.get("password")

    if not email or not password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email and password are required",
        )

    user = db.query(User).filter(User.email == email.lower().strip()).first()
    if not user or not verify_password(password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated",
        )

    access_token = create_access_token(subject=str(user.id))
    refresh_token = create_refresh_token(subject=str(user.id))

    return TokenResponse(
        user=UserResponse.model_validate(user),
        access_token=access_token,
        refresh_token=refresh_token,
    )


@router.post("/refresh", response_model=RefreshTokenResponse)
def refresh_token(
    request_data: RefreshTokenRequest,
    db: Session = Depends(get_db),
):
    try:
        payload = decode_token(request_data.refresh_token)
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type",
            )
        user_id_str = payload.get("sub")
        if not user_id_str:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token subject",
            )
        user_id = uuid.UUID(user_id_str)
    except (jwt.PyJWTError, ValueError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )

    user = db.query(User).filter(User.id == user_id, User.is_active.is_(True)).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive",
        )

    new_access_token = create_access_token(subject=str(user.id))
    new_refresh_token = create_refresh_token(subject=str(user.id))

    return RefreshTokenResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
    )


@router.post("/logout", response_model=MessageResponse)
def logout(
    current_user: User = Depends(get_current_user),
):
    # In stateless JWT, client deletes stored tokens; token revocation table can be added in production
    return MessageResponse(message="Successfully logged out")


@router.post("/password-reset", response_model=PasswordResetResponse)
def request_password_reset(
    data: PasswordResetRequest,
    db: Session = Depends(get_db),
):
    # Note per PLAN.md: Generate secure token; document email sending as TODO since no SMTP in dev
    user = db.query(User).filter(User.email == data.email.lower().strip()).first()
    if not user:
        # Avoid leaking user existence
        return PasswordResetResponse(
            message="If your email is registered, you will receive password reset instructions.",
        )

    reset_token = create_token(
        subject=str(user.id),
        token_type="reset",
        expires_delta=timedelta(hours=2),
    )

    # TODO: Dispatch email via SMTP/SendGrid/SES in production environment
    return PasswordResetResponse(
        message="If your email is registered, you will receive password reset instructions.",
        reset_token=reset_token,
    )


@router.get("/me", response_model=UserResponse)
def get_me(
    current_user: User = Depends(get_current_user),
):
    return UserResponse.model_validate(current_user)
