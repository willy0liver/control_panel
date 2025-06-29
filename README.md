# control_panel

# 🗂️ Documento Funcional Técnico - Control Panel DF
**Versión:** 1.0  
**Fecha:** 28/06/2025  
**Autor:** Willy Oliver  

---

## 📑 Índice
1. [Introducción](#-introducción)  
2. [Descripción General del Proyecto](#-descripción-general-del-proyecto)  
3. [Estructura Funcional](#-estructura-funcional)  
   - 3.1 [Menú Principal](#31-menú-principal)  
   - 3.2 [Cuadrícula de Botones](#32-cuadrícula-de-botones)  
   - 3.3 [Configuración de Menús](#33-configuración-de-menús)  
   - 3.4 [Configuración de Filas](#34-configuración-de-filas)  
   - 3.5 [Configuración de Botones](#35-configuración-de-botones)  
4. [Estructura de Carpetas](#-estructura-de-carpetas)  
5. [Estructura de Archivos JSON](#-estructura-de-archivos-json)  
   - 5.1 [JSON de Menú](#51-json-de-menú)  
   - 5.2 [JSON de Fila](#52-json-de-fila)  
   - 5.3 [JSON de Botón](#53-json-de-botón)  
6. [Flujo de Personalización](#-flujo-de-personalización)  
7. [Consideraciones Técnicas](#-consideraciones-técnicas)  
8. [Escalabilidad y Futuras Implementaciones](#-escalabilidad-y-futuras-implementaciones)  

---

## 🚀 Introducción
Este documento detalla el funcionamiento, la estructura y la lógica del **Control Panel DF**, una herramienta diseñada para ser completamente personalizable por cada usuario. Permite configurar menús, filas y botones de manera intuitiva y dinámica.

---

## 📋 Descripción General del Proyecto
El proyecto permite al usuario crear su propio panel de control donde podrá definir:

- ✅ Múltiples menús  
- ✅ Cuadrículas de botones organizadas en filas  
- ✅ Acciones personalizadas asociadas a cada botón  

Toda la configuración es almacenada en archivos JSON dentro de una estructura de carpetas específica.

---

## 🧠 Estructura Funcional

### 3.1 Menú Principal
- Barra superior con accesos directos a los distintos menús configurados.  
- Cada menú es independiente y almacena su propia cuadrícula de botones.  

### 3.2 Cuadrícula de Botones
- Área central donde se muestran los botones agrupados por filas.  
- Los botones se distribuyen horizontalmente dentro de cada fila.  

### 3.3 Configuración de Menús
- Permite:  
  - Crear nuevos menús.  
  - Editar el nombre de un menú.  
  - Eliminar menús.  

### 3.4 Configuración de Filas
- Permite:  
  - Crear filas dentro de un menú.  
  - Editar el nombre de cada fila.  
  - Eliminar filas.  

### 3.5 Configuración de Botones
- Permite:  
  - Crear botones dentro de una fila.  
  - Configurar atributos del botón (nombre, acción, color, ícono, etc.).  
  - Eliminar botones.  

---

## 🗂️ Estructura de Carpetas

```plaintext
/ControlPanel
|
|-- /menu
|   |-- menu01.json
|   |-- menu02.json
|   |-- ...
|
|-- /filas
|   |-- /fila01
|   |   |-- general.json
|   |   |-- boton01.json
|   |   |-- boton02.json
|   |   |-- ...
|   |-- /fila02
|   |   |-- ...
|   |-- ...
|
|-- /otros (opcional para futuras expansiones)
```

---

## 🗒️ Estructura de Archivos JSON

### 5.1 JSON de Menú

```json
{
  "nombre_menu": "Menú 01",
  "orden": 1
}
```

### 5.2 JSON de Fila

```json
{
  "nombre_fila": "Fila 1",
  "orden": 1
}
```

### 5.3 JSON de Botón

```json
{
  "nombre_boton": "Abrir Excel",
  "orden": 1,
  "accion": "C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE",
  "color": "#0078D7",
  "icono": "excel"
}
```

---

## 🔄 Flujo de Personalización

### 🔧 Configuración General
1. Entrar a la sección de configuración.  
2. **Agregar un menú:**  
   - Se crea un archivo JSON en `/menu`.  

### ➕ Agregar una Fila
1. Seleccionar el menú deseado.  
2. Crear una fila:  
   - Se genera una carpeta `/fila01` dentro de `/filas`.  
   - Se crea `general.json` con los datos de la fila.  

### ➕ Agregar Botones
1. Seleccionar la fila correspondiente.  
2. Crear un botón:  
   - Se genera un archivo `boton01.json` dentro de la carpeta de la fila.  
   - Configurar los atributos del botón.  

---

## ⚙️ Consideraciones Técnicas
- El sistema debe leer todos los archivos JSON al iniciar y construir dinámicamente la interfaz.  
- La modificación de nombres o eliminación de elementos debe actualizar los archivos correspondientes y refrescar la interfaz.  
- El orden de los menús, filas y botones se gestiona mediante el atributo `"orden"` en los JSON.  

---

## 🌱 Escalabilidad y Futuras Implementaciones
- Submenús: posibilidad de que un botón despliegue submenús o subopciones.  
- Agrupación por categorías dentro de una fila.  
- Soporte para scripts (AHK, PowerShell, Bash, etc.).  
- Nube: guardado y sincronización en la nube para portabilidad del panel.  
- Personalización avanzada: fondos, temas oscuros, sonidos al presionar botones, etc.  

---

## ✍️ Notas Finales
Este documento será actualizado con cada nueva funcionalidad incorporada en el **Control Panel DF**.

---
