# 🎬 GDD: ¡BASTA! El Show de TV (Roblox Game Design Document)

**Proyecto:** ¡BASTA! El Show de TV  
**Plataforma:** Roblox (PC, Móvil, Consolas, VR)  
**Género:** Trivia / Minijuego de Fiesta / Show de TV Interactivo  
**Público Objetivo:** Todas las edades (7+), enfocado en multijugador social y streamers.

---

## 1. Visión y Resumen Ejecutivo (High Concept)

**¡BASTA! El Show de TV** traslada el tradicional juego de mesa de palabras ("Basta", "Tutti Frutti" o "Stop") a un **estudio de televisión 3D en vivo dentro de Roblox**. 

A diferencia de los juegos tradicionales donde los espectadores simplemente miran aburridos, en este show **el público sentado en las gradas es un participante activo clave**: pueden comprar y arrojar tomates o pasteles al presentador, vitorear a sus amigos con pancartas o activar efectos de sonido que retumban en todo el estudio, creando momentos virales dignos de streaming.

---

## 2. Los 3 Pilares de Jugabilidad

```
┌────────────────────────────────────────────────────────────────────────┐
│                        BUCLE PRINCIPAL DEL SHOW                        │
│                                                                        │
│   1. LOBBY & PRESENTACIÓN ➔ El Conductor introduce a los Concursantes  │
│   2. GIRO DE RULETA       ➔ Ruleta gigante 3D elige la letra           │
│   3. FASE DE ESCRITURA    ➔ Concursantes teclean categorías contra reloj│
│   4. ¡GOLPE AL BOTÓN!     ➔ Primer jugador corre al botón rojo central │
│   5. VOTACIÓN PÚBLICA     ➔ Pantalla LED gigante muestra respuestas    │
│   6. PREMIACIÓN & PODIO   ➔ Coronación de ganadores con confeti        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Roles y Dinámica de Jugadores

### A. Los Concursantes (En Escenario - 4 a 8 Jugadores)
- **Ubicación:** Sentados en podios circulares alrededor de la mesa principal.
- **Acciones:**
  - Aparece la interfaz `ScreenGui` con las casillas de categorías:
    *Nombre | Apellido | País/Ciudad | Animal | Fruta/Flor | Cosa*
  - Deben escribir palabras válidas que inicien con la letra sorteada.
  - Al completar sus palabras, su avatar debe pulsar el **Botón Rojo Físico de BASTA** en medio de la mesa.
  - Al presionarlo, se activan sirenas rojas en todo el set y comienza una cuenta regresiva de 10 segundos para los rivales.

### B. El Conductor del Show (NPC / Bot Animado)
- **Nombre:** *Don Basta / Showmaster*.
- **Función:** Guía cada momento de la partida con animaciones (apunta con el micrófono, gesticula con las manos, baila).
- **Diálogos Dinámicos:** Globos de texto cómicos y efectos de voz estilo cartoon según lo que pase en el juego:
  - *"¡Damas y caballeros, la letra de hoy es... la R de RRRÁPIDO!"*
  - *"¡Cuidado! ¡Alguien me acaba de lanzar un pastel en la cara!"*
  - *"¡Esa palabra parece inventada, que decida el público!"*

### C. El Público Interactivo (Gradas - Jugadores en Espera)
Los jugadores que no alcanzaron puesto en la mesa o fueron eliminados se sientan en las gradas con una cámara dinámica y una bandeja de herramientas interactiva:
- 🍅 **Tomates Podridos:** Al arrojarlos al presentador o a un concursante, dejan una mancha cómica "splat!" en su pantalla.
- 🎂 **Pastelazo de Crema:** Lanza un pastel volador que empapa al objetivo.
- 🎉 **Cañones de Confeti & Fuegos Artificiales:** Para celebrar a su concursante preferido.
- 📣 **Efectos de Sonido del Estudio:** Botones para disparar risas grabadas (*Canned Laughter*), trompeta de derrota (*Sad Trombone*) o aplausos estruendosos.
- 🪧 **Pancartas de Apoyo:** Carteles en alto con el nombre del concursante apoyado.

---

## 4. Fase de Votación en Pantalla Gigante

Al terminar la ronda, el juego cambia a modo **Tribunal del Show**:
1. La cámara enfoca una **pantalla LED gigante de 20 metros** en el escenario.
2. Cada concursante muestra su respuesta para una categoría.
3. El público y los rivales votan en tiempo real:
   - 🟢 **Válida (+100 pts / +50 si repetida)**
   - 🔴 **Inválida / Falsa (0 pts)**
4. ¡Si un concursante intenta hacer trampa o inventar una palabra graciosa, el público le llueve a tomatazos!

---

## 5. Economía y Monetización (Robux & Monedas)

| Categoría | Elementos | Monetización |
| :--- | :--- | :--- |
| **Herramientas del Público** | Tomates infinitos, pasteles dorados, globos de agua, pistolas de confeti. | Monedas ganadas jugando o Robux (Microtransacciones). |
| **Skins de Ruleta** | Ruleta de Fuego, Ruleta Neón Cyberpunk, Ruleta Ofrenda de Cempasúchil. | Tienda de cosméticos (Robux). |
| **Efectos al pulsar BASTA** | Explosión nuclear de confeti, rayo celestial, sonido de sirena dorada. | Tienda de efectos (Robux). |
| **Pases de Juego (Gamepasses)** | **Pase VIP:** Asiento en palco de honor, micrófono dorado para hablarle al público, título *"Productor Ejecutivo"*. | Gamepass permanente (150 - 300 Robux). |

---

## 6. Programas Requeridos para Desarrollar

Para continuar con el desarrollo en Roblox necesitas instalar:

1. **Roblox Studio** *(Obligatorio y Gratuito):*
   - Descarga oficial: [https://www.roblox.com/create](https://www.roblox.com/create)
   - Es el motor completo donde se modela el estudio 3D, se colocan las luces, los asientos y se prueban los scripts.
2. **Rojo (Extensión de VS Code / Antigravity)** *(Recomendado para programación profesional):*
   - Permite que escribamos todo el código Luau en el editor de código y se sincronice en tiempo real con Roblox Studio con un solo clic.
3. **Extensión Luau / Roblox LSP en VS Code:**
   - Autocompletado, resaltado de sintaxis y detección de errores para Roblox.
