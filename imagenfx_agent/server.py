"""
Servidor FastAPI del Agente Portable ImagenFX.
Expone:
- POST /generar-imagen : Genera la imagen con Vertex AI, guarda copia e historial local, y devuelve Base64.
- GET  /memoria        : Devuelve el historial de imágenes generadas y prompts del proyecto actual.
"""

import asyncio
import os
import secrets
from contextlib import asynccontextmanager
from typing import Any, Dict, Literal, Optional

from agent_core import cargar_entorno, core_agent, leer_memoria, logger
from fastapi import Depends, FastAPI, HTTPException, Request, Security, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.security import APIKeyHeader
from google.api_core import exceptions as google_exceptions
from pydantic import BaseModel, Field, field_validator


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        core_agent.inicializar_vertex()
    except Exception as exc:
        logger.warning(
            "Servidor FastAPI iniciado, pero Vertex AI aún requiere configurar credenciales: %s",
            exc,
        )
    yield


app = FastAPI(
    title="ImagenFX Portable Project Agent API",
    description="API REST local por proyecto con memoria, historial de imágenes y logs para Antigravity y Apps Móviles.",
    version="2.0.0",
    lifespan=lifespan,
)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errores = "; ".join([f"{err['loc'][-1]}: {err['msg']}" for err in exc.errors()])
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={"detail": f"Payload o prompt inválido ({errores})."},
    )


api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


async def verificar_api_key(
    api_key: Optional[str] = Security(api_key_header),
) -> str:
    cargar_entorno()
    expected_api_key = os.getenv("AGENT_API_KEY")

    if not expected_api_key:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="AGENT_API_KEY no está configurada en el archivo .env.",
        )

    if not api_key or not secrets.compare_digest(api_key, expected_api_key):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API Key inválida o ausente en el header 'X-API-Key'.",
        )

    return api_key


AspectRatioType = Literal["1:1", "3:4", "4:3", "9:16", "16:9"]


class GenerarImagenRequest(BaseModel):
    prompt: str = Field(
        ...,
        description="Descripción textual de la imagen que se desea generar.",
    )
    aspect_ratio: Optional[AspectRatioType] = Field(
        default="1:1",
        description="Relación de aspecto soportada por Imagen en Vertex AI.",
    )
    nombre_archivo: Optional[str] = Field(
        default=None,
        description="Nombre corto opcional para identificar la imagen en historial_imagenes/.",
    )
    ruta_destino: Optional[str] = Field(
        default=None,
        description="Ruta relativa al proyecto donde guardar una copia directa (ej. 'assets/icon.png').",
    )
    notas_contexto: Optional[str] = Field(
        default=None,
        description="Contexto opcional de por qué se solicitó la imagen.",
    )

    @field_validator("prompt")
    @classmethod
    def validar_prompt(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("El campo 'prompt' no puede estar vacío.")
        if len(cleaned) > 2000:
            raise ValueError("El campo 'prompt' excede el límite de 2000 caracteres.")
        return cleaned


class GenerarImagenResponse(BaseModel):
    status: str = "success"
    id: str
    model: str
    aspect_ratio: str
    mime_type: str = "image/png"
    archivo_guardado: str
    ruta_destino_proyecto: Optional[str] = None
    image_base64: str


@app.post(
    "/generar-imagen",
    response_model=GenerarImagenResponse,
    status_code=status.HTTP_200_OK,
)
async def generar_imagen(
    payload: GenerarImagenRequest,
    _api_key: str = Depends(verificar_api_key),
) -> GenerarImagenResponse:
    if len(payload.prompt) < 3:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El prompt es demasiado corto. Proporciona una descripción más detallada.",
        )

    try:
        resultado = await asyncio.to_thread(
            core_agent.generar_y_registrar,
            prompt=payload.prompt,
            aspect_ratio=payload.aspect_ratio or "1:1",
            nombre_archivo=payload.nombre_archivo,
            ruta_destino_extra=payload.ruta_destino,
            origen="api_rest_local",
            notas_contexto=payload.notas_contexto,
        )
        reg = resultado["registro"]
        return GenerarImagenResponse(
            id=reg["id"],
            model=reg["modelo"],
            aspect_ratio=reg["aspect_ratio"],
            archivo_guardado=reg["archivo_historial"],
            ruta_destino_proyecto=reg["ruta_destino_proyecto"],
            image_base64=resultado["image_base64"],
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    except google_exceptions.InvalidArgument as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Solicitud rechazada por Vertex AI: {exc.message}",
        ) from exc
    except google_exceptions.GoogleAPICallError as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error de comunicación con Vertex AI: {exc.message}",
        ) from exc
    except Exception as exc:
        logger.exception("Error inesperado en POST /generar-imagen:")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error interno del agente local: {str(exc)}",
        ) from exc


@app.get(
    "/memoria",
    status_code=status.HTTP_200_OK,
    summary="Consulta el historial de prompts e imágenes generadas en este proyecto",
)
async def obtener_memoria(
    _api_key: str = Depends(verificar_api_key),
) -> Dict[str, Any]:
    return leer_memoria()


if __name__ == "__main__":
    import uvicorn

    cargar_entorno()
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run("server:app", host=host, port=port, reload=True)
