# Control Panel (AutoHotkey v2)

Panel dinámico de botones alimentados por JSON, con soporte para múltiples **filas** (secciones), **barra de menú** superior, **tooltips en las opciones** y **hotstrings** (atajos de texto) para abrir páginas.

> Requiere **AutoHotkey v2** en Windows.

---

## ✨ Características

- **Alt+P** abre la ventana principal.
- **Múltiples filas**: cada carpeta `filaNN` define un **título** (desde `general.json`) y sus **botones** debajo.
- **Botones dinámicos** desde archivos `boton*.json` (orden **natural**: `boton1`, `boton2`, …, `boton10`).
- **Menú por botón**:
  - Click en el botón → se muestra un menú con sus **opciones**.
  - Hover sobre cada opción → **tooltip** con `atajo --> url` o `--> url`.
  - Click en una opción → abre la **URL** en el navegador predeterminado.
- **Hotstrings**:
  - Escribe `atajo` → se expande como **texto** de la URL.
  - Si `isPage = "S"`, escribe `ooatajo` → **abre** la URL (sin expandir texto).
- **Barra de menú** (definida en `Assets/Menu.ahk`):
  - **Options**: `Reload` (reconstruye la interfaz) y `Ver Iconos` (abre una carpeta).
  - **Menu 01**: accesos directos a Google y YouTube (editable/expandible).
- **Distribución con wrap**: los botones hacen salto de línea al alcanzar el ancho lógico de la fila.

---

## ✅ Requisitos

- Windows.
- [AutoHotkey v2](https://www.autohotkey.com/).

---

## 📁 Estructura de carpetas

```text
control_panel/
├─ main.ahk
├─ Assets/
│  ├─ Menu.ahk                # crea y devuelve la barra de menú (fn_get_menu)
│  └─ (otros módulos opcionales futuros)
└─ botones/
   ├─ fila01/
   │  ├─ general.json         # { "nombreFila": "Título de la fila" }
   │  ├─ boton01.json
   │  ├─ boton02.json
   │  └─ boton03.json
   ├─ fila02/
   │  ├─ general.json
   │  ├─ boton01.json
   │  └─ ...
   └─ filaNN/
      └─ ...
```

---

## 🚀 Inicio rápido

1. Instala AutoHotkey v2.
2. Clona este repositorio.
3. Ejecuta `main.ahk`.
4. Pulsa **Alt+P** para abrir el panel (o **Alt+R** para reconstruir la interfaz si cambiaste archivos).

**Cómo se dibuja la ventana:**

- Se recorren las carpetas `botones\filaNN` en orden **natural** por número.
- Por cada fila:
  - Se lee `general.json` y se muestra `nombreFila` como **título**.
  - Se cargan `boton*.json` (orden natural) y se agregan como **botones** debajo del título.
  - Los botones hacen *wrap* cuando no caben en el ancho configurado.
- La siguiente fila se dibuja **debajo** de la anterior (no se superponen).

Diagrama:

```
[TÍTULO DE FILA]
[Botón 1]    [Botón 2]    [Botón 3]   ... (wrap) ...
[Botón n+1]  [Botón n+2]  ...

[TÍTULO DE SIGUIENTE FILA]
[Botón 1]    [Botón 2]    ...
```

---

## 🧾 Formato de los JSON

### `general.json` (por fila)

```json
{
  "nombreFila": "Mi Primera Fila xD"
}
```

### `boton*.json` (por botón)

```json
{
  "name": "Mi botón",
  "opciones": [
    { "opcion": "Opción 1", "url": "https://ejemplo1.com", "isPage": "S", "atajo": "atj1" },
    { "opcion": "Opción 2", "url": "https://ejemplo2.com" },
    { "opcion": "Opción 3", "valor": "https://alias-de-url.com" }
  ]
}
```

- `name` → texto del **botón**.
- `opciones` → ítems del **menú** al hacer click en el botón.
  - `opcion` → texto visible del ítem del menú.
  - `url` (o `valor`) → enlace que abrirá/expandirá.
  - `isPage` = `"S"` → habilita hotstring para **abrir** la URL con `oo` + `atajo`.
  - `atajo` → hotstring de **texto** (ver siguiente sección).

---

## ⌨️ Hotstrings (atajos de texto)

Para cada opción que tenga `atajo`:

- **`atajo`** → se expande como **texto** a la URL.
  - Ej.: escribes `atj1` y se reemplaza por `https://ejemplo1.com`.
- Si además `isPage = "S"`:
  - **`ooatajo`** → **abre** la URL en el navegador (no inserta texto).
  - Ej.: `ooatj1` abre `https://ejemplo1.com`.

> Internamente se utiliza una **factory** para “congelar” la URL por ítem (`MakeUrlHandler(url)`) y evitar que todas las acciones apunten al último elemento.

---

## 🏷️ Tooltips (hover en opciones)

- Al abrir el menú de un botón y **pasar el mouse** por cada ítem:
  - Verás un tooltip cerca del cursor con:
    - `atajo --> url` si la opción tiene `atajo`.
    - `--> url` si no tiene `atajo`.
- Se generan automáticamente a partir de `opciones`.  
- No requieren configuración adicional.

---

## 🧰 Barra de menú superior

Definida en `Assets/Menu.ahk` mediante `fn_get_menu()` y asignada desde `main.ahk`:

```ahk
BuildMenuBar() {
    global gGui
    mb := fn_get_menu()
    gGui.MenuBar := mb
}
```

**Menú por defecto** (editable en `Assets/Menu.ahk`):

- **Options**
  - **Reload**: reconstruye la interfaz (equivalente a **Alt+R**).
  - **Ver Iconos**: abre una carpeta (edita la ruta en tu implementación).
- **Menu 01**
  - **Google**: abre google.com.
  - **YouTube**: abre youtube.com.

> Para añadir/quitar elementos, edita **solo** `Assets/Menu.ahk`.

---

## 🔢 Ordenado “natural”

- **Filas** (`fila01`, `fila02`, …) y **botones** (`boton01`, `boton02`, …) se ordenan por **número**, de menor a mayor.
- Nombres **sin número** van después, ordenados alfabéticamente.
- Así evitas que `boton10` aparezca antes que `boton2`.

---

## ⚙️ Personalización rápida

En `main.ahk`:

```ahk
startX := 10        ; X inicial de la fila
stepX  := 200       ; salto horizontal entre botones
yPos   := 20        ; margen superior inicial
btnW   := 180       ; ancho botón
btnH   := 60        ; alto botón
maxRowWidth := 800  ; ancho lógico para wrap
gapY        := 20   ; separación vertical entre líneas y filas
```

- **`maxRowWidth`** controla el salto a nueva línea en una misma fila.
- **`stepX`/`btnW`** ajustan densidad horizontal.
- **`gapY`** controla el espaciado vertical.

---

## 🛠️ Problemas comunes

- **No aparecen filas/botones**  
  Verifica la estructura `botones\filaNN`, y que existan `general.json` y `boton*.json` válidos.
- **“Error de JSON”**  
  Asegúrate de que los JSON estén bien formados y en **UTF-8** (idealmente sin BOM).
- **Todas las opciones abrían la misma URL**  
  Corregido con `MakeUrlHandler(url)` (cada ítem mantiene su propia URL).
- **Tooltips no se ven**  
  Los tooltips son para el **menú contextual del botón**. Mantén activos los hooks de mensaje (`OnMessage(0x117, ...)` y `OnMessage(0x11F, ...)`) tal como están en `main.ahk`.

---

## 🤝 Contribuir

- Issues y PRs son bienvenidos.
- Mantén el estilo y organización (lógica de interfaz en `main.ahk`, barra de menú en `Assets/Menu.ahk`, datos en `botones/...`).

---

## 📄 Licencia

MIT (o la que definas en el repositorio).
