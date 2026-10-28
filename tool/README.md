# 🎨 Herramientas Automatizadas de Temas DLC — ¡BASTA!

Este directorio contiene los scripts y herramientas automatizadas para crear, diseñar, empaquetar y publicar temas descargables (DLC) para el juego **¡BASTA! (Caduceo Antigravity Studio)** sin necesidad de recompilar la aplicación ni actualizar la versión en Google Play / App Store.

---

## 🚀 Flujo de Trabajo en 2 Fases

El ciclo de vida de un tema se divide en dos fases sencillas:

```
┌────────────────────────────────────────────────────────┐
│  FASE 1: CREACIÓN, GENERACIÓN Y REVISIÓN LOCAL         │
│  Comando: python tool/generar_tema.py                   │
│                                                        │
│  • Crea la estructura de carpetas en dlc_src/<id>/     │
│  • Genera theme.json con los colores y metadata        │
│  • Clona la plantilla de audio base (sfx + bgm)        │
│  • Genera con Vertex AI (ImagenFX):                    │
│    - Portada horizontal 16:9                           │
│    - Fondo principal vertical 9:16                     │
│    - Fondo de ruleta sombrío vertical 9:16             │
│    - Medallón central giratorio 1:1                    │
│    - 20 Avatares temáticos (10 M + 10 F)               │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼  (Revisas, ajustas o reemplazas archivos)
┌────────────────────────────────────────────────────────┐
│  FASE 2: EMPAQUETADO Y PUBLICACIÓN A PRODUCCIÓN        │
│  Comando: python tool/publicar_tema.py                 │
│                                                        │
│  • Comprime dlc_src/<id> en dist_dlc/<id>.zip          │
│  • Sube el ZIP y portada a GitHub Releases             │
│  • Obtiene la URL pública directa de descarga          │
│  • Publica la metadata en Firebase Realtime Database   │
│  • ¡El tema aparece inmediatamente en la app!          │
└────────────────────────────────────────────────────────┘
```

---

## 🛠️ Requisitos Previos

Las herramientas utilizan utilidades del sistema ya configuradas en tu máquina:
1. **Python 3.10+** (o el entorno virtual en `C:\Users\herme\Documents\Agentes\ImagenFX\.venv\Scripts\python.exe`).
2. **GitHub CLI (`gh`)**: Autenticado con `gh auth login` en la cuenta `hermeslandia`.
3. **Firebase CLI (`firebase`)**: Autenticado con `firebase login` vinculado al proyecto `basta-f1e25`.

---

## 📋 Fase 1: Generar Recursos del Tema (`generar_tema.py`)

Crea toda la estructura del tema y genera automáticamente las ilustraciones usando la IA local conectada a **Vertex AI** (sin consumir créditos del IDE).

### Sintaxis Básica
```powershell
python tool/generar_tema.py --id <id_tema> --nombre "<Nombre Visible>" --descripcion "<Descripción>" --estilo "<Estilo Visual>" [opciones]
```

### Parámetros Disponibles:
| Parámetro | Requerido | Descripción | Ejemplo |
| :--- | :---: | :--- | :--- |
| `--id` | **Sí** | Identificador técnico único (letras minúsculas y guiones bajos). | `navidad`, `espacio`, `piratas` |
| `--nombre` | **Sí** | Nombre visible que aparecerá en el carrusel de la app. | `"Navidad Festiva"`, `"Odisea Espacial"` |
| `--estilo` | **Sí** | Prompt descriptor para guiar a la IA en el arte 3D. | `"Navidad acogedora, nieve suave, árboles iluminados estilo 3D Pixar"` |
| `--descripcion` | No | Breve descripción que se guarda en el `theme.json`. | `"Ofrendas, villancicos y regalos."` |
| `--color-primario` | No | Color hex para contenedores y cajas oscuras de UI. | `0xFFB71C1C` (Rojo navideño) |
| `--color-titulo` | No | Color hex para títulos y acentos principales. | `0xFFFFD700` (Dorado) |
| `--color-texto` | No | Color hex para el texto principal. | `0xFFFFFFFF` (Blanco) |
| `--color-borde` | No | Color hex para bordes de botones y tarjetas. | `0xFF2E7D32` (Verde pino) |
| `--audio-base` | No | Tema desde donde clonar audios base (por defecto: `dia_muertos`). | `dia_muertos`, `party` |
| `--solo-estructura` | No | Solo crea carpetas y `theme.json` sin llamar a la IA. | *(Flag opcional)* |
| `--omitir-avatares` | No | Genera fondos y ruleta, pero no los 20 avatares. | *(Flag opcional)* |

---

### 💡 Ejemplos de Generación

#### Ejemplo A: Tema de Navidad
```powershell
python tool/generar_tema.py `
  --id navidad `
  --nombre "Navidad Festiva" `
  --descripcion "Nieve mágica, regalos, árboles decorados y espíritu navideño." `
  --estilo "Cozy magical Christmas holiday celebration, soft glowing snow, decorated pine trees, warm golden fairy lights, cute Pixar 3D animated style, vibrant rich festive colors, child friendly" `
  --color-primario "0xFF8B0000" `
  --color-titulo "0xFFFFD700" `
  --color-borde "0xFF2E7D32"
```

#### Ejemplo B: Tema Cyberpunk / Futurista
```powershell
python tool/generar_tema.py `
  --id cyberpunk `
  --nombre "Cyberpunk 2099" `
  --descripcion "El futuro neón en tus partidas de BASTA." `
  --estilo "Retro futuristic cyberpunk synthwave arcade theme, glowing cyan and hot magenta neon signs, dark reflective metallic surfaces, holographic 3D effects, child friendly" `
  --color-primario "0xFF0A0A1A" `
  --color-titulo "0xFF00E5FF" `
  --color-borde "0xFFFF007F"
```

#### Ejemplo C: Tema Piratas del Caribe
```powershell
python tool/generar_tema.py `
  --id piratas `
  --nombre "Isla Pirata" `
  --descripcion "Tesoros, mapas antiguos, cañones y galeones legendarios." `
  --estilo "Caribbean tropical pirate adventure, wooden galleons, treasure chests, golden doubloons, turquoise ocean and tropical palm islands, cute Pixar 3D cartoon style" `
  --color-primario "0xFF2E1C0C" `
  --color-titulo "0xFFFFC107" `
  --color-borde "0xFFD7CCC8"
```

---

## 🔍 Revisión y Edición Local

Una vez ejecutado `generar_tema.py`, los archivos quedan listos en:
```
dlc_src/<id_tema>/
├── theme.json                          <-- Colores, nombre, descripción y rutas
├── images/
│   ├── <id>_cover.png                  <-- Portada horizontal 16:9 para el carrusel
│   ├── <id>_bg.png                     <-- Fondo vertical 9:16 para toda la app
│   ├── <id>_roulette_bg.png            <-- Fondo oscuro vertical 9:16 para la ruleta
│   └── <id>_center.png                 <-- Medallón circular 1:1 que gira al centro
├── avatars/
│   ├── avatar_m_doctor.png             <-- 10 Avatares masculinos
│   ├── avatar_f_doctor.png             <-- 10 Avatares femeninos
│   └── ... (20 avatares en total)
└── audio/
    ├── bgm.mp3 / bgm.wav               <-- Música de fondo del tema
    ├── roulette.wav                    <-- Giro de ruleta
    ├── start_bell.wav                  <-- Campana de inicio
    └── ...
```

### ¿Cómo regenerar una sola imagen si quieres mejorarla?
Puedes usar directamente el agente local CLI:
```powershell
C:\Users\herme\Documents\Agentes\ImagenFX\.venv\Scripts\python.exe .\imagenfx_agent\generar_cli.py generar `
  --prompt "Tu prompt detallado aquí" `
  --aspect-ratio "16:9" `
  --nombre "navidad_cover_v2" `
  --destino "dlc_src/navidad/images/navidad_cover.png" `
  --notas "Mejora de portada"
```

---

## 🚀 Fase 2: Publicar a Producción (`publicar_tema.py`)

Cuando estés contento con el resultado visual y sonoro del tema, ejecutas el publicador:

### Sintaxis Básica
```powershell
python tool/publicar_tema.py --id <id_tema>
```

### Parámetros Disponibles:
| Parámetro | Por Defecto | Descripción |
| :--- | :---: | :--- |
| `--id` | **Requerido** | El ID del tema que está en `dlc_src/<id>`. |
| `--tag` | `v1.0.0` | Tag de la release en GitHub donde subir el `.zip`. |
| `--repo` | `hermeslandia/basta-dlc` | Repositorio público de GitHub. |
| `--omitir-firebase` | `False` | Solo empaqueta y sube a GitHub sin registrar en Firebase. |

### Ejemplo:
```powershell
python tool/publicar_tema.py --id navidad
```

### ¿Qué hace en automático?
1. **Comprime:** Empaqueta `dlc_src/navidad` en `dist_dlc/navidad.zip`.
2. **Sube a GitHub:** Sube el `.zip` y la portada a tu release en `hermeslandia/basta-dlc` con GitHub CLI.
3. **URL Directa:** Obtiene la URL pública directa (ej. `https://github.com/hermeslandia/basta-dlc/releases/download/v1.0.0/navidad.zip`).
4. **Actualiza:** Inserta la `downloadUrl` y el enlace de la portada en `dlc_src/navidad/theme.json`.
5. **Firebase Realtime Database:** Escribe la entrada directamente en `/themes_catalog/navidad` del proyecto `basta-f1e25`.

---

## 📱 Validación en la Aplicación Móvil

1. Abre la aplicación **¡BASTA!** en cualquier celular o emulador.
2. Ve a la pantalla de **Perfil** (o Tienda de Temas).
3. Verás la nueva tarjeta del tema en el carrusel con su portada y botón de descarga.
4. Al tocarlo, se descargará el ZIP por streaming con progreso porcentual, se descomprimirá en el almacenamiento del dispositivo y se activará inmediatamente.
5. **Probar de nuevo:** Si mantienes presionado el tema en el carrusel, se desinstala de tu teléfono para que puedas probar la descarga desde cero cuantas veces quieras.
