#!/usr/bin/env python3
"""
tool/publicar_tema.py
=====================
Método 2 Automatizado:
Empaqueta un tema desde dlc_src/<id>, genera el archivo ZIP optimizado en dist_dlc/<id>.zip,
lo sube a la Release de GitHub (hermeslandia/basta-dlc), actualiza su downloadUrl
y publica automáticamente los datos en Firebase Realtime Database.

Uso:
  python tool/publicar_tema.py --id <id> [--tag <tag>] [--repo <usuario/repo>]

Ejemplo:
  python tool/publicar_tema.py --id dia_muertos
  python tool/publicar_tema.py --id navidad --tag v1.0.0
"""

import argparse
import json
import os
import subprocess
import sys
import zipfile
from pathlib import Path

# Configurar salida UTF-8 segura en Windows
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

BASE_DIR = Path(__file__).resolve().parent.parent
DEFAULT_REPO = "hermeslandia/basta-dlc"
DEFAULT_TAG = "v1.0.0"
GH_CLI = Path(r"C:\Program Files\GitHub CLI\gh.exe")


def ejecutar_comando(cmd: list[str], descripcion: str, check: bool = True) -> subprocess.CompletedProcess:
    """Ejecuta un comando en consola e imprime retroalimentación."""
    print(f"\n⚙️  {descripcion}...")
    try:
        res = subprocess.run(cmd, cwd=str(BASE_DIR), capture_output=True, text=True, check=check)
        return res
    except subprocess.CalledProcessError as e:
        print(f"❌ Error en {descripcion}:")
        print(f"   Stdout: {e.stdout}")
        print(f"   Stderr: {e.stderr}")
        if check:
            sys.exit(1)
        return e


def empaquetar_zip(source_dir: Path, zip_dest: Path) -> int:
    """Comprime el directorio en un archivo ZIP con compresión DEFLATED."""
    print(f"\n📦 Empaquetando {source_dir.relative_to(BASE_DIR)} -> {zip_dest.relative_to(BASE_DIR)}...")
    zip_dest.parent.mkdir(parents=True, exist_ok=True)

    if zip_dest.exists():
        zip_dest.unlink()

    total_archivos = 0
    with zipfile.ZipFile(zip_dest, "w", zipfile.ZIP_DEFLATED) as zipf:
        for root, _, files in os.walk(source_dir):
            for file in files:
                file_path = Path(root) / file
                arcname = file_path.relative_to(source_dir).as_posix()
                zipf.write(file_path, arcname)
                total_archivos += 1
                # print(f"   + {arcname}")

    size_mb = zip_dest.stat().st_size / 1024 / 1024
    print(f"   ✓ ZIP generado con {total_archivos} archivos ({size_mb:.2f} MB)")
    return total_archivos


def asegurar_release_github(repo: str, tag: str):
    """Verifica si la release existe en GitHub; si no, la crea."""
    gh_cmd = str(GH_CLI) if GH_CLI.exists() else "gh"
    res = subprocess.run(
        [gh_cmd, "release", "view", tag, "-R", repo],
        cwd=str(BASE_DIR),
        capture_output=True,
        text=True,
    )
    if res.returncode != 0:
        print(f"ℹ️  La release '{tag}' no existe en {repo}. Creándola...")
        ejecutar_comando(
            [gh_cmd, "release", "create", tag, "-R", repo, "--title", f"Release {tag}", "--notes", "Temas descargables para ¡BASTA!"],
            f"Crear release {tag} en {repo}",
        )


def subir_a_github(repo: str, tag: str, archivo_zip: Path, portada_png: Path | None) -> str:
    """Sube el ZIP y la portada a GitHub Releases y devuelve la URL de descarga directa."""
    gh_cmd = str(GH_CLI) if GH_CLI.exists() else "gh"
    asegurar_release_github(repo, tag)

    archivos_a_subir = [str(archivo_zip)]
    if portada_png and portada_png.exists():
        archivos_a_subir.append(str(portada_png))

    ejecutar_comando(
        [gh_cmd, "release", "upload", tag, *archivos_a_subir, "--clobber", "-R", repo],
        f"Subir {archivo_zip.name} a GitHub Release ({repo} @ {tag})",
    )

    url_descarga = f"https://github.com/{repo}/releases/download/{tag}/{archivo_zip.name}"
    print(f"   ✓ Enlace de descarga directo generado:\n     {url_descarga}")
    return url_descarga


def publicar_en_firebase(theme_id: str, theme_json_path: Path):
    """Publica la metadata del tema en Firebase Realtime Database bajo /themes_catalog/<id>."""
    cmd = [
        "firebase.cmd" if os.name == "nt" else "firebase",
        "database:set",
        f"/themes_catalog/{theme_id}",
        str(theme_json_path),
        "--project", "basta-f1e25",
        "--force",
    ]
    ejecutar_comando(cmd, f"Publicar en Firebase Realtime Database (/themes_catalog/{theme_id})")


def main():
    parser = argparse.ArgumentParser(description="Empaquetador y publicador de temas DLC para ¡BASTA!")
    parser.add_argument("--id", required=True, help="ID técnico del tema en dlc_src/<id>")
    parser.add_argument("--tag", default=DEFAULT_TAG, help=f"Tag de la release en GitHub (por defecto: {DEFAULT_TAG})")
    parser.add_argument("--repo", default=DEFAULT_REPO, help=f"Repositorio de GitHub (por defecto: {DEFAULT_REPO})")
    parser.add_argument("--omitir-firebase", action="store_true", help="Solo empaqueta y sube a GitHub sin tocar Firebase")

    args = parser.parse_args()
    theme_id = args.id.strip().lower()

    source_dir = BASE_DIR / "dlc_src" / theme_id
    theme_json_path = source_dir / "theme.json"

    if not source_dir.exists():
        print(f"❌ Error: El directorio {source_dir.relative_to(BASE_DIR)} no existe.")
        print(f"   Crea primero el tema con: python tool/generar_tema.py --id {theme_id} ...")
        return 1

    if not theme_json_path.exists():
        print(f"❌ Error: No se encontró {theme_json_path.relative_to(BASE_DIR)}.")
        return 1

    print("=" * 70)
    print(f"🚀 INICIANDO PUBLICACIÓN DEL TEMA: {theme_id.upper()}")
    print("=" * 70)

    # 1. Empaquetar a ZIP
    zip_dest = BASE_DIR / "dist_dlc" / f"{theme_id}.zip"
    empaquetar_zip(source_dir, zip_dest)

    # 2. Portada (opcional para subir a release si se quiere preview directa)
    portada_path = source_dir / "images" / f"{theme_id}_cover.png"
    if not portada_path.exists():
        portada_path = None

    # 3. Subir a GitHub Releases
    download_url = subir_a_github(args.repo, args.tag, zip_dest, portada_path)

    # 4. Actualizar theme.json con la downloadUrl generada
    with open(theme_json_path, "r", encoding="utf-8") as f:
        theme_data = json.load(f)

    theme_data["downloadUrl"] = download_url
    if portada_path:
        # URL remota de portada para preview en dispositivos sin requerir assets en APK
        theme_data["coverPath"] = f"https://github.com/{args.repo}/releases/download/{args.tag}/{portada_path.name}"

    with open(theme_json_path, "w", encoding="utf-8") as f:
        json.dump(theme_data, f, indent=2, ensure_ascii=False)
    print(f"   ✓ theme.json actualizado con la URL de descarga.")

    # 5. Publicar en Firebase Realtime Database
    if not args.omitir_firebase:
        publicar_en_firebase(theme_id, theme_json_path)

    print("\n" + "=" * 70)
    print(f"🎉 ¡TEMA '{theme_id.upper()}' PUBLICADO Y DISPONIBLE EN VIVO!")
    print(f"📦 Paquete ZIP: {zip_dest.relative_to(BASE_DIR)}")
    print(f"🔗 Descarga directa: {download_url}")
    print(f"🔥 Firebase Catalog: /themes_catalog/{theme_id}")
    print("✨ Todos los usuarios verán este tema en la app al abrir el carrusel.")
    print("=" * 70)
    return 0


if __name__ == "__main__":
    sys.exit(main())
