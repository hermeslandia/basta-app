"""
Herramienta CLI para que el Agente de IA de Antigravity genere imágenes y consulte
la memoria/historial del proyecto directamente desde la terminal sin gastar créditos del IDE.
"""

import argparse
import json
import sys
from pathlib import Path

from agent_core import LOG_FILE, MEMORY_FILE, core_agent, leer_memoria, logger


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Agente Local ImagenFX (Vertex AI) para proyectos en Antigravity."
    )
    subparsers = parser.add_subparsers(dest="comando", help="Comandos disponibles")

    # Subcomando: generar
    gen_parser = subparsers.add_parser(
        "generar", help="Genera una nueva imagen con Vertex AI y la guarda en el proyecto."
    )
    gen_parser.add_argument(
        "--prompt",
        "-p",
        required=True,
        help="Descripción detallada de la imagen a generar (preferiblemente en inglés o español claro).",
    )
    gen_parser.add_argument(
        "--aspect-ratio",
        "-a",
        default="1:1",
        choices=["1:1", "3:4", "4:3", "9:16", "16:9"],
        help="Relación de aspecto (por defecto: 1:1).",
    )
    gen_parser.add_argument(
        "--nombre",
        "-n",
        default=None,
        help="Nombre descriptivo corto para identificar el archivo en historial_imagenes/.",
    )
    gen_parser.add_argument(
        "--destino",
        "-d",
        default=None,
        help="Ruta opcional dentro del proyecto donde copiar la imagen lista para usar (ej. './assets/images/ splash.png').",
    )
    gen_parser.add_argument(
        "--notas",
        default=None,
        help="Notas de contexto sobre por qué o para qué vista/componente se solicitó esta imagen.",
    )
    gen_parser.add_argument(
        "--incluir-base64",
        action="store_true",
        help="Si se incluye, imprime también la cadena base64 en la salida JSON.",
    )

    # Subcomando: memoria
    mem_parser = subparsers.add_parser(
        "memoria", help="Consulta el historial de imágenes y prompts solicitados en este proyecto."
    )
    mem_parser.add_argument(
        "--ultimos",
        "-u",
        type=int,
        default=10,
        help="Número de registros recientes a mostrar (por defecto: 10).",
    )

    # Subcomando: modelos
    subparsers.add_parser(
        "modelos", help="Lista los modelos disponibles en Vertex AI para este proyecto."
    )

    args = parser.parse_args()

    if args.comando == "modelos":
        client = core_agent.inicializar_vertex()
        modelos = [m.name for m in client.models.list()]
        print(json.dumps({"modelos": modelos}, ensure_ascii=False, indent=2))
        return 0

    if args.comando == "memoria":
        memoria = leer_memoria()
        historial = memoria.get("historial", [])
        resumen = {
            "proyecto_ruta": memoria.get("proyecto_ruta"),
            "total_imagenes_generadas": memoria.get("total_imagenes_generadas", 0),
            "archivo_memoria": str(MEMORY_FILE),
            "archivo_logs": str(LOG_FILE),
            "ultimos_registros": historial[-args.ultimos :] if args.ultimos > 0 else historial,
        }
        print(json.dumps(resumen, ensure_ascii=False, indent=2))
        return 0

    if args.comando == "generar":
        try:
            resultado = core_agent.generar_y_registrar(
                prompt=args.prompt,
                aspect_ratio=args.aspect_ratio,
                nombre_archivo=args.nombre,
                ruta_destino_extra=args.destino,
                origen="antigravity_cli",
                notas_contexto=args.notas,
            )
            salida = {
                "status": "success",
                "mensaje": "Imagen generada con Vertex AI y registrada en la memoria del proyecto.",
                "datos": resultado["registro"],
            }
            if args.incluir_base64:
                salida["image_base64"] = resultado["image_base64"]

            print(json.dumps(salida, ensure_ascii=False, indent=2))
            return 0
        except Exception as exc:
            logger.error("Error en ejecución CLI: %s", exc)
            error_out = {
                "status": "error",
                "detalle": str(exc),
                "logs": str(LOG_FILE),
            }
            print(json.dumps(error_out, ensure_ascii=False, indent=2), file=sys.stderr)
            return 1

    parser.print_help()
    return 0


if __name__ == "__main__":
    sys.exit(main())
