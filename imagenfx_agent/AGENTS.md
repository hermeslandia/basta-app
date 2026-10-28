# Regla de Uso de Generación de Imágenes para Antigravity (ImagenFX Local Agent)

> **IMPORTANTE PARA EL AGENTE DE IA DE ANTIGRAVITY:**
> En este proyecto **NO debes usar el subagente interno `image-generator` de Antigravity** para evitar consumir créditos internos del IDE. Toda generación de imágenes, iconos, fondos, mockups o recursos gráficos debe delegarse a este agente local conectado a **Vertex AI (`imagegeneration@006`)**.

---

## 1. Cómo funciona esta carpeta (`imagenfx_agent`)

Esta carpeta es autónoma por proyecto y mantiene su propio estado local:
- `historial_imagenes/`: Contiene todas las imágenes `.png` generadas en este proyecto.
- `memoria/historial_prompts.json`: Memoria persistente con cada prompt solicitado, fecha, relación de aspecto, notas de contexto y rutas donde se guardaron las imágenes.
- `logs/agente.log`: Registro técnico detallado de llamadas a Vertex AI y posibles errores.

Además, **reutiliza automáticamente el entorno virtual y las credenciales maestras** ubicadas en `C:\Users\herme\Documents\Agentes\ImagenFX\.venv` y `C:\Users\herme\Documents\Agentes\ImagenFX\.env` (a menos que exista un archivo `.env` local dentro de esta carpeta para sobrescribir la configuración en este proyecto).

---

## 2. Cómo debe usarlo la IA de Antigravity

### Opción A: Ejecución directa por CLI (Recomendado cuando la IA necesita crear assets para el proyecto)

Antes de generar una imagen nueva, puedes revisar qué imágenes ya se han creado en este proyecto ejecutando:

```powershell
C:\Users\herme\Documents\Agentes\ImagenFX\.venv\Scripts\python.exe .\imagenfx_agent\generar_cli.py memoria
```

Para generar una imagen nueva, guardarla automáticamente en el historial del proyecto y opcionalmente copiarla directamente a una carpeta de assets de la app:

```powershell
C:\Users\herme\Documents\Agentes\ImagenFX\.venv\Scripts\python.exe .\imagenfx_agent\generar_cli.py generar `
  --prompt "Minimalist modern app icon for a fitness tracker, neon green and dark slate, vector flat style" `
  --aspect-ratio "1:1" `
  --nombre "icono_fitness" `
  --destino "./assets/images/icono_fitness.png" `
  --notas "Icono principal solicitado para la pantalla de inicio"
```

Relaciones de aspecto soportadas (`--aspect-ratio`): `"1:1"`, `"3:4"`, `"4:3"`, `"9:16"`, `"16:9"`.

---

### Opción B: Servidor API REST Local (Para consumo desde Apps Móviles Android / iOS)

Cuando la aplicación móvil en desarrollo necesite generar imágenes dinámicamente en tiempo de ejecución y recibirlas en **Base64**, levanta el servidor local desde esta carpeta:

```powershell
C:\Users\herme\Documents\Agentes\ImagenFX\.venv\Scripts\python.exe .\imagenfx_agent\server.py
```

- **Endpoint de Generación:** `POST http://localhost:8000/generar-imagen` (o `http://10.0.2.2:8000/generar-imagen` desde el emulador de Android).
  - **Header obligatorio:** `X-API-Key: <valor de AGENT_API_KEY en .env>`
  - **Body JSON:**
    ```json
    {
      "prompt": "Fondo abstracto oscuro con ondas azules suaves",
      "aspect_ratio": "9:16",
      "nombre_archivo": "fondo_login",
      "notas_contexto": "Generado desde la vista de Login en Android"
    }
    ```
  - **Respuesta JSON:** Incluye `image_base64` listo para renderizar en la app móvil y además guarda automáticamente el archivo `.png` en `imagenfx_agent/historial_imagenes/` y el registro en `imagenfx_agent/memoria/historial_prompts.json`.

- **Endpoint de Memoria:** `GET http://localhost:8000/memoria` (con el header `X-API-Key`).
