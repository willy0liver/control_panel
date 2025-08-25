;===========================
; ButtonColors.ahk
; Colorear botones (texto y fondo) de forma sencilla en AHK v2
; Requiere: desactivar tema visual del botón y manejar WM_CTLCOLORBTN
;===========================

#Requires AutoHotkey v2.0

; Mapas globales
global __BtnColor_Map := Map()   ; hwnd -> { fg: COLORREF, bg: COLORREF }
global __BtnColor_Brush := Map() ; COLORREF -> HBRUSH
global __BtnColor_Inited := false

; ---- API pública ----
BtnColor_Init() {
    global __BtnColor_Inited
    if __BtnColor_Inited
        return
    ; Registrar manejador de WM_CTLCOLORBTN
    OnMessage(0x0135, __BtnColor_WM_CTLCOLORBTN)  ; WM_CTLCOLORBTN
    __BtnColor_Inited := true
}

; Aplica color de texto/fondo a un botón
; - btn: control Button
; - textColor/backColor en 0xRRGGBB (RGB)
; - Si THEME_BTN_FLAT es true, agrega estilo BS_FLAT (solo visual)
BtnColor_Apply(btn, textColor, backColor) {
    global __BtnColor_Map
    ; Desactivar tema (UxTheme) para que Windows no sobreescriba colores
    try DllCall("UxTheme\SetWindowTheme", "ptr", btn.Hwnd, "str", "", "str", "")
    catch as ex{
        
    }

    ; Guardar colores (convertidos a COLORREF->BGR)
    __BtnColor_Map[btn.Hwnd] := Map(
        "fg", __BtnColor_RGB_to_COLORREF(textColor),
        "bg", __BtnColor_RGB_to_COLORREF(backColor)
    )

    ; Opcional: aspecto “plano”
    try {
        if (IsSet(THEME_BTN_FLAT) && THEME_BTN_FLAT)
            btn.Opt("+0x8000")   ; BS_FLAT
    }
}

; ---- Internos ----
__BtnColor_WM_CTLCOLORBTN(hDC, hWnd, msg, hGui) {
    global __BtnColor_Map, __BtnColor_Brush
    ; hDC = wParam, hWnd = lParam

    if !__BtnColor_Map.Has(hWnd)
        return

    colors := __BtnColor_Map[hWnd]
    fg := colors["fg"]
    bg := colors["bg"]

    ; Texto
    DllCall("gdi32\SetTextColor", "ptr", hDC, "int", fg)
    ; Fondo del texto transparente para no recuadrar el label
    DllCall("gdi32\SetBkMode", "ptr", hDC, "int", 1) ; TRANSPARENT = 1

    ; Pincel para fondo
    if !__BtnColor_Brush.Has(bg) {
        hBrush := DllCall("gdi32\CreateSolidBrush", "int", bg, "ptr")
        __BtnColor_Brush[bg] := hBrush
    }
    return __BtnColor_Brush[bg]  ; HBRUSH que usará Windows para el fondo
}

__BtnColor_RGB_to_COLORREF(rgb) {
    ; GDI usa BGR (0x00BBGGRR). Convertimos 0xRRGGBB -> 0x00BBGGRR
    r := (rgb >> 16) & 0xFF
    g := (rgb >> 8)  & 0xFF
    b :=  rgb        & 0xFF
    return (b << 16) | (g << 8) | r
}
