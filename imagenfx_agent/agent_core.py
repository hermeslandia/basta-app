"""
Módulo central de ImagenFX Portable Agent.
Gestiona la conexión con Vertex AI (usando el SDK oficial google-genai incluido en google-cloud-aiplatform),
el guardado automático del historial de imágenes, la memoria persistente de prompts por proyecto y los logs locales.
"""

import base64
import datetime
import json
import logging
import os
import re
import shutil
import socket
import uuid
from pathlib import Path
from typing import Any, Dict, Optional

from dotenv import load_dotenv
from google import genai
from google.genai import types

# Directorio base de esta carpeta portable (en el proyecto donde haya sido copiada)
AGENT_DIR = Path(__file__).resolve().parent

# Directorio central maestro (fallback para credenciales si no se copian a cada proyecto)
CENTRAL_MASTER_DIR = Path(r"C:\Users\herme\Documents\Agentes\ImagenFX")

# Carpetas de estado por proyecto (se crean automáticamente dentro de la carpeta copiada)
IMAGES_DIR = AGENT_DIR / "historial_imagenes"
MEMORY_DIR = AGENT_DIR / "memoria"
LOGS_DIR = AGENT_DIR / "logs"

IMAGES_DIR.mkdir(parents=True, exist_ok=True)
MEMORY_DIR.mkdir(parents=True, exist_ok=True)
LOGS_DIR.mkdir(parents=True, exist_ok=True)

MEMORY_FILE = MEMORY_DIR / "historial_prompts.json"
LOG_FILE = LOGS_DIR / "agente.log"

# Configuración de Logging persistente en archivo + consola
logger = logging.getLogger("ImagenFX-Agent")
logger.setLevel(logging.INFO)
if not logger.handlers:
    formatter = logging.Formatter(
        "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
    )
    file_handler = logging.FileHandler(LOG_FILE, encoding="utf-8")
    file_handler.setFormatter(formatter)
    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(formatter)
    logger.addHandler(file_handler)
    logger.addHandler(stream_handler)


def cargar_entorno() -> Path:
    """
    Carga el archivo .env local de la carpeta del proyecto; si no existe o está incompleto,
    usa como respaldo el .env central en C:\\Users\\herme\\Documents\\Agentes\\ImagenFX.
    """
    local_env = AGENT_DIR / ".env"
    central_env = CENTRAL_MASTER_DIR / ".env"

    if central_env.is_file():
        load_dotenv(dotenv_path=central_env, override=False)
    if local_env.is_file():
        load_dotenv(dotenv_path=local_env, override=True)

    creds = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "./service-account-key.json")
    creds_path = Path(creds)
    if not creds_path.is_absolute():
        if (AGENT_DIR / creds_path).is_file():
            creds_path = (AGENT_DIR / creds_path).resolve()
        elif (CENTRAL_MASTER_DIR / creds_path).is_file():
            creds_path = (CENTRAL_MASTER_DIR / creds_path).resolve()
        else:
            creds_path = (AGENT_DIR / creds_path).resolve()

    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(creds_path)
    return creds_path


def leer_memoria() -> Dict[str, Any]:
    """Lee el archivo JSON de memoria del proyecto actual."""
    if not MEMORY_FILE.is_file():
        initial_data = {
            "proyecto_ruta": str(AGENT_DIR.parent),
            "creado_en": datetime.datetime.now().isoformat(),
            "total_imagenes_generadas": 0,
            "historial": [],
        }
        guardar_memoria(initial_data)
        return initial_data

    try:
        with open(MEMORY_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as exc:
        logger.warning("No se pudo leer historial_prompts.json, reiniciando estructura: %s", exc)
        return {
            "proyecto_ruta": str(AGENT_DIR.parent),
            "creado_en": datetime.datetime.now().isoformat(),
            "total_imagenes_generadas": 0,
            "historial": [],
        }


def guardar_memoria(data: Dict[str, Any]) -> None:
    """Guarda el estado actualizado en memoria/historial_prompts.json."""
    with open(MEMORY_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def _slugify(texto: str, max_len: int = 40) -> str:
    limpio = re.sub(r"[^a-zA-Z0-9_-]+", "_", texto.strip().lower()).strip("_")
    return limpio[:max_len] or "imagen"


class ImagenFXCore:
    """Motor principal para generar imágenes en Vertex AI y persistir memoria por proyecto."""

    def __init__(self) -> None:
        self._client: Optional[genai.Client] = None
        self._model_name: Optional[str] = None

    def inicializar_vertex(self) -> genai.Client:
        creds_path = cargar_entorno()
        project_id = os.getenv("GCP_PROJECT_ID")
        location = os.getenv("GCP_LOCATION", "us-central1")
        model_name = os.getenv("VERTEX_IMAGE_MODEL", "gemini-2.5-flash-image")

        if not creds_path.is_file():
            raise RuntimeError(
                f"No se encontró el archivo JSON de Service Account en: '{creds_path}'. "
                f"Colócalo en '{AGENT_DIR}' o en la carpeta maestra '{CENTRAL_MASTER_DIR}'."
            )

        if not project_id or project_id == "tu-proyecto-gcp-id":
            raise RuntimeError(
                "GCP_PROJECT_ID no está configurado con un ID de proyecto real en el archivo .env."
            )

        endpoint_host = f"{location}-aiplatform.googleapis.com"
        try:
            socket.getaddrinfo(endpoint_host, 443)
        except OSError as exc:
            raise ConnectionError(
                f"No hay resolución DNS hacia '{endpoint_host}': {exc}"
            ) from exc

        self._client = genai.Client(
            vertexai=True,
            project=project_id,
            location=location,
        )
        self._model_name = model_name
        logger.info(
            "Cliente Vertex AI (google-genai) inicializado (Proyecto=%s, Región=%s, Modelo preferido=%s)",
            project_id,
            location,
            model_name,
        )
        return self._client

    def generar_y_registrar(
        self,
        prompt: str,
        aspect_ratio: str = "1:1",
        nombre_archivo: Optional[str] = None,
        ruta_destino_extra: Optional[str] = None,
        origen: str = "cli_antigravity",
        notas_contexto: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Genera una imagen en Vertex AI, la guarda en historial_imagenes/,
        actualiza memoria/historial_prompts.json y devuelve los metadatos + Base64.
        """
        if self._client is None:
            self.inicializar_vertex()

        logger.info(
            "Solicitando imagen a Vertex AI | Origen=%s | AspectRatio=%s | Prompt='%s'",
            origen,
            aspect_ratio,
            prompt,
        )

        candidatos = [
            self._model_name or "gemini-2.5-flash-image",
            "gemini-2.5-flash-image",
            "gemini-3.1-flash-image",
            "gemini-3-pro-image",
            "gemini-3.1-flash-lite-image",
        ]
        modelos_a_probar = list(dict.fromkeys(candidatos))

        image_bytes: Optional[bytes] = None
        ultimo_error = None
        modelo_usado = self._model_name

        for mod_id in modelos_a_probar:
            try:
                response = self._client.models.generate_content(
                    model=mod_id,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        response_modalities=["IMAGE"],
                        image_config=types.ImageConfig(
                            aspect_ratio=aspect_ratio,
                            output_mime_type="image/png",
                        ),
                    ),
                )
                # Extraer los bytes de la imagen desde inline_data en parts
                if response and response.candidates:
                    for candidate in response.candidates:
                        if candidate.content and candidate.content.parts:
                            for part in candidate.content.parts:
                                if part.inline_data and part.inline_data.data:
                                    image_bytes = part.inline_data.data
                                    break
                        if image_bytes:
                            break

                if image_bytes:
                    modelo_usado = mod_id
                    self._model_name = mod_id
                    break
            except Exception as exc:
                ultimo_error = exc
                msg = str(exc).lower()
                if "404" in msg or "not found" in msg or "not_found" in msg:
                    logger.warning(
                        "Modelo '%s' no disponible en esta región (404), probando siguiente candidato...",
                        mod_id,
                    )
                    continue
                raise

        if not image_bytes:
            if ultimo_error is not None:
                raise ultimo_error
            logger.warning("Vertex AI devolvió 0 imágenes (posible filtro de seguridad).")
            raise ValueError(
                "Vertex AI no devolvió ninguna imagen. Es posible que el prompt haya activado los filtros de seguridad."
            )

        img_b64 = base64.b64encode(image_bytes).decode("utf-8")

        # Construir nombre único de archivo para el historial del proyecto
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        short_id = uuid.uuid4().hex[:6]
        slug = _slugify(nombre_archivo if nombre_archivo else prompt)
        filename = f"{timestamp}_{slug}_{short_id}.png"
        filepath = IMAGES_DIR / filename

        with open(filepath, "wb") as f:
            f.write(image_bytes)

        ruta_copia_final: Optional[str] = None
        if ruta_destino_extra:
            dest_path = Path(ruta_destino_extra)
            if not dest_path.is_absolute():
                dest_path = (AGENT_DIR.parent / dest_path).resolve()
            dest_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(filepath, dest_path)
            ruta_copia_final = str(dest_path)
            logger.info("Imagen copiada adicionalmente a: %s", ruta_copia_final)

        # Registrar en la memoria del proyecto
        memoria = leer_memoria()
        registro = {
            "id": short_id,
            "fecha": datetime.datetime.now().isoformat(),
            "origen": origen,
            "modelo": modelo_usado,
            "prompt": prompt,
            "aspect_ratio": aspect_ratio,
            "archivo_historial": str(filepath.relative_to(AGENT_DIR)),
            "ruta_absoluta": str(filepath),
            "ruta_destino_proyecto": ruta_copia_final,
            "notas_contexto": notas_contexto,
        }
        memoria["historial"].append(registro)
        memoria["total_imagenes_generadas"] = len(memoria["historial"])
        memoria["ultima_generacion"] = registro["fecha"]
        guardar_memoria(memoria)

        logger.info("Imagen guardada con éxito en '%s' (ID=%s, Modelo=%s)", filepath.name, short_id, modelo_usado)

        return {
            "registro": registro,
            "image_base64": img_b64,
        }


core_agent = ImagenFXCore()
