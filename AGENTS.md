# Reglas del Proyecto ¡BASTA! (Caduceo Antigravity Studio)

## Generación de Imágenes (ImagenFX Local Agent)

> **REGLA OBLIGATORIA:**
> En este proyecto **NUNCA debes usar el subagente interno `image-generator` de Antigravity** para evitar consumir créditos internos del IDE. Toda generación de imágenes, iconos, fondos, portadas de temas, avatares o recursos gráficos debe realizarse exclusivamente a través del agente local en `./imagenfx_agent` conectado a **Vertex AI**.

### Cómo generar imágenes por CLI:
1. **Consultar historial/memoria antes de generar:**
   ```powershell
   C:\Users\herme\Documents\Agentes\ImagenFX\.venv\Scripts\python.exe .\imagenfx_agent\generar_cli.py memoria
   ```
2. **Generar una imagen nueva:**
   ```powershell
   C:\Users\herme\Documents\Agentes\ImagenFX\.venv\Scripts\python.exe .\imagenfx_agent\generar_cli.py generar --prompt "<prompt>" --aspect-ratio "1:1" --nombre "<nombre_corto>" --destino "<ruta_en_assets>" --notas "<contexto>"
   ```
   Relaciones de aspecto soportadas (`--aspect-ratio`): `"1:1"`, `"3:4"`, `"4:3"`, `"9:16"`, `"16:9"`.
   Documentación completa en [imagenfx_agent/AGENTS.md](./imagenfx_agent/AGENTS.md).
