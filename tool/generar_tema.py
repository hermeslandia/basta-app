#!/usr/bin/env python3
"""
tool/generar_tema.py
====================
Método 1 Automatizado:
Genera la estructura completa, carpetas, plantilla de configuración y recursos
gráficos (portada, fondos, ruleta y 20 avatares) para un nuevo tema DLC de ¡BASTA!
utilizando el agente local de Vertex AI (ImagenFX).

Uso:
  python tool/generar_tema.py --id <id> --nombre "<nombre>" --descripcion "<desc>" --estilo "<estilo>" [opciones]

Ejemplo:
  python tool/generar_tema.py --id navidad --nombre "Navidad" --descripcion "Nieve y espíritu navideño" --estilo "Navidad acogedora, nieve, árboles decorados y estilo 3D Pixar" --color-primario "0xFFB71C1C" --color-titulo "0xFFFFD700" --color-borde "0xFF2E7D32"
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

# Configurar salida UTF-8 segura en Windows
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

BASE_DIR = Path(__file__).resolve().parent.parent
PYTHON_VENV = Path(r"C:\Users\herme\Documents\Agentes\ImagenFX\.venv\Scripts\python.exe")
CLI_GENERAR = BASE_DIR / "imagenfx_agent" / "generar_cli.py"

OCUPACIONES = [
    ("doctor", "doctor with medical coat and stethoscope", "female doctor with medical coat and stethoscope"),
    ("policia", "police officer with police badge and cap", "female police officer with police badge and cap"),
    ("bombero", "firefighter with red firefighter helmet", "female firefighter with red helmet"),
    ("panadero", "baker chef with white toque chef hat and rolling pin", "female baker chef with white toque chef hat and rolling pin"),
    ("maestro", "school teacher with glasses holding a book", "female school teacher with glasses holding a book"),
    ("constructor", "construction worker with yellow hardhat helmet", "female construction worker with yellow hardhat helmet"),
    ("cartero", "mail courier with mail bag and postal cap", "female mail courier with mail bag and postal cap"),
    ("veterinario", "veterinarian holding a cute small animal", "female veterinarian holding a cute small animal"),
    ("marinero", "navy sailor with captain sailor cap and anchor badge", "female navy sailor with sailor cap"),
    ("enfermera", "nurse with medical scrub and caring smile", "female nurse with medical scrub and caring smile"),
]


def ejecutar_generador_imagen(prompt: str, aspect_ratio: str, nombre: str, destino: Path, notas: str) -> bool:
    """Invoca el generador CLI de Vertex AI para crear una imagen y guardarla en destino."""
    print(f"\n🎨 Generando: {destino.name} [{aspect_ratio}]...")
    print(f"   Prompt: {prompt[:90]}...")

    py_exe = str(PYTHON_VENV) if PYTHON_VENV.exists() else sys.executable
    cmd = [
        py_exe,
        str(CLI_GENERAR),
        "generar",
        "--prompt", prompt,
        "--aspect-ratio", aspect_ratio,
        "--nombre", nombre,
        "--destino", str(destino),
        "--notas", notas,
    ]

    try:
        res = subprocess.run(cmd, cwd=str(BASE_DIR), capture_output=True, text=True, check=True)
        print(f"   ✓ Guardado en {destino.relative_to(BASE_DIR)}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"   ✗ Error al generar imagen: {e.stderr or e.stdout}")
        return False


def copiar_audio_base(destino_audio: Path, tema_origen: str = "dia_muertos"):
    """Copia los efectos de sonido y música base si no existen en el tema destino."""
    origen = BASE_DIR / "dlc_src" / tema_origen / "audio"
    if not origen.exists():
        origen = BASE_DIR / "assets" / "themes" / "default" / "audio"

    if origen.exists():
        print(f"\n🎵 Copiando plantilla de audio desde {origen.relative_to(BASE_DIR)}...")
        for archivo in origen.glob("*.*"):
            destino_archivo = destino_audio / archivo.name
            if not destino_archivo.exists():
                shutil.copy2(archivo, destino_archivo)
                print(f"   + {archivo.name}")
    else:
        print("⚠️ No se encontró carpeta de audio base para copiar.")


def main():
    parser = argparse.ArgumentParser(description="Scaffolder y generador de recursos para temas DLC de ¡BASTA!")
    parser.add_argument("--id", required=True, help="ID técnico único del tema (ej. navidad, piratas, cyberpunk)")
    parser.add_argument("--nombre", required=True, help="Nombre visible para la UI (ej. 'Navidad Festiva')")
    parser.add_argument("--descripcion", default="", help="Descripción del tema")
    parser.add_argument("--estilo", required=True, help="Descripción del estilo visual y temática para guiar la IA")
    parser.add_argument("--color-primario", default="0xFF2B0A3D", help="Color primario de contenedores en formato hex (ej. 0xFFB71C1C)")
    parser.add_argument("--color-titulo", default="0xFFFFD700", help="Color de títulos (ej. 0xFFFFD700)")
    parser.add_argument("--color-texto", default="0xFFFFFFFF", help="Color de texto principal (ej. 0xFFFFFFFF)")
    parser.add_argument("--color-borde", default="0xFF2E7D32", help="Color de bordes y acentos (ej. 0xFF2E7D32)")
    parser.add_argument("--audio-base", default="dia_muertos", help="Tema desde donde clonar los efectos de sonido base")
    parser.add_argument("--solo-estructura", action="store_true", help="Solo crea las carpetas y el theme.json sin llamar a la IA")
    parser.add_argument("--omitir-avatares", action="store_true", help="Genera solo fondos, portada y centro, omitiendo los 20 avatares")

    args = parser.parse_args()
    theme_id = args.id.strip().lower()

    # 1. Crear directorios
    theme_dir = BASE_DIR / "dlc_src" / theme_id
    images_dir = theme_dir / "images"
    avatars_dir = theme_dir / "avatars"
    audio_dir = theme_dir / "audio"

    for d in [images_dir, avatars_dir, audio_dir]:
        d.mkdir(parents=True, exist_ok=True)

    print("=" * 70)
    print(f"🚀 INICIALIZANDO NUEVO TEMA DLC: {args.nombre.upper()} ({theme_id})")
    print(f"📁 Directorio de trabajo: {theme_dir.relative_to(BASE_DIR)}")
    print("=" * 70)

    # 2. Copiar plantilla de audio
    copiar_audio_base(audio_dir, args.audio_base)

    # 3. Generar theme.json
    theme_json_path = theme_dir / "theme.json"
    theme_data = {
        "id": theme_id,
        "name": args.nombre,
        "description": args.descripcion or f"Tema visual y sonoro de {args.nombre}.",
        "version": 1,
        "backgroundPath": f"images/{theme_id}_bg.png",
        "rouletteBackgroundPath": f"images/{theme_id}_roulette_bg.png",
        "coverPath": f"images/{theme_id}_cover.png",
        "catrinaCenterPath": f"images/{theme_id}_center.png",
        "avatarFolder": "avatars",
        "primaryContainerColor": args.color_primario,
        "titleColor": args.color_titulo,
        "textColor": args.color_texto,
        "borderColor": args.color_borde,
        "isPremium": False,
        "price": 0.0,
    }

    with open(theme_json_path, "w", encoding="utf-8") as f:
        json.dump(theme_data, f, indent=2, ensure_ascii=False)
    print(f"\n📝 theme.json generado en: {theme_json_path.relative_to(BASE_DIR)}")

    if args.solo_estructura:
        print("\n✨ Estructura creada con éxito (--solo-estructura activo). Listo para agregar imágenes manualmente.")
        return 0

    # 4. Generar Recursos Gráficos con Vertex AI
    estilo = args.estilo

    # A) Portada de Carrusel (16:9)
    cover_file = images_dir / f"{theme_id}_cover.png"
    if not cover_file.exists():
        prompt_cover = (
            f"Vibrant horizontal mobile game theme cover banner illustration for '{args.nombre}', "
            f"Pixar 3D stylized cartoon aesthetic, {estilo}, highly detailed, cheerful festive mood, "
            f"clean studio lighting, warm vibrant colors, child friendly, no text"
        )
        ejecutar_generador_imagen(prompt_cover, "16:9", f"{theme_id}_cover", cover_file, f"Portada carrusel {args.nombre}")

    # B) Fondo Principal de Juego (9:16)
    bg_file = images_dir / f"{theme_id}_bg.png"
    if not bg_file.exists():
        prompt_bg = (
            f"Vertical mobile game background wallpaper for '{args.nombre}', Pixar 3D stylized cartoon style, "
            f"{estilo}, subtle decorative elements framing the screen borders, smooth gradient lighting, "
            f"open clean space in the center for UI overlays, colorful, child friendly, no text"
        )
        ejecutar_generador_imagen(prompt_bg, "9:16", f"{theme_id}_bg", bg_file, f"Fondo principal {args.nombre}")

    # C) Fondo Oscuro/Opaco Exclusivo para Ruleta (9:16)
    roulette_bg_file = images_dir / f"{theme_id}_roulette_bg.png"
    if not roulette_bg_file.exists():
        prompt_roulette_bg = (
            f"Vertical moody atmospheric mobile game background for game wheel, Pixar 3D stylized style, "
            f"{estilo}, darker muted tones with deep shadows and soft subtle magical glow so a foreground "
            f"colorful game roulette wheel pops out with high contrast, lower center saturation, child friendly, no text"
        )
        ejecutar_generador_imagen(prompt_roulette_bg, "9:16", f"{theme_id}_roulette_bg", roulette_bg_file, f"Fondo ruleta {args.nombre}")

    # D) Medallón Central Giratorio de la Ruleta (1:1)
    center_file = images_dir / f"{theme_id}_center.png"
    if not center_file.exists():
        prompt_center = (
            f"Circular centerpiece medallion icon for a game wheel, Pixar 3D stylized character or mascot emblem, "
            f"{estilo}, centered front-facing emblem inside a circular golden border, vibrant colors, "
            f"clean studio lighting, high contrast, clean silhouette, child friendly, no text"
        )
        ejecutar_generador_imagen(prompt_center, "1:1", f"{theme_id}_center", center_file, f"Centro ruleta {args.nombre}")

    # E) Los 20 Avatares Temáticos (10 Masculinos y 10 Femeninos)
    if not args.omitir_avatares:
        print("\n" + "=" * 70)
        print("🎭 GENERANDO 20 AVATARES TEMÁTICOS (10 Femeninos + 10 Masculinos)")
        print("=" * 70)

        for clave, desc_m, desc_f in OCUPACIONES:
            # Masculino
            dest_m = avatars_dir / f"avatar_m_{clave}.png"
            if not dest_m.exists():
                prompt_m = (
                    f"Cute child-friendly 3D cartoon character portrait, Pixar 3D avatar style, "
                    f"half-body chest-up framing facing forward, cheerful friendly smiling expression, "
                    f"centered inside a circular emblem, {estilo}, character is a {desc_m}, "
                    f"vibrant colors, clean lighting, no text"
                )
                ejecutar_generador_imagen(prompt_m, "1:1", f"{theme_id}_m_{clave}", dest_m, f"Avatar M {clave} {args.nombre}")

            # Femenino
            dest_f = avatars_dir / f"avatar_f_{clave}.png"
            if not dest_f.exists():
                prompt_f = (
                    f"Cute child-friendly 3D cartoon character portrait, Pixar 3D avatar style, "
                    f"half-body chest-up framing facing forward, cheerful friendly smiling expression, "
                    f"centered inside a circular emblem, {estilo}, character is a {desc_f}, "
                    f"vibrant colors, clean lighting, no text"
                )
                ejecutar_generador_imagen(prompt_f, "1:1", f"{theme_id}_f_{clave}", dest_f, f"Avatar F {clave} {args.nombre}")

    print("\n" + "=" * 70)
    print(f"🎉 ¡TEMA '{args.nombre.upper()}' GENERADO CON ÉXITO!")
    print(f"📁 Revisa y edita los recursos en: {theme_dir.relative_to(BASE_DIR)}")
    print(f"👉 Cuando estés listo, publícalo ejecutando:")
    print(f"   python tool/publicar_tema.py --id {theme_id}")
    print("=" * 70)
    return 0


if __name__ == "__main__":
    sys.exit(main())
