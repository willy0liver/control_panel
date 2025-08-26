; ============================================
; ButtonColors.ahk  (AHK v2)
; Botones coloreados con Owner-Draw
; - API:
;     BtnColors_Apply(btnCtrl, theme := "default")
;     BtnColors_ApplyCustom(btnCtrl, colorsObj)
;     BtnColors_ApplyRGB(btnCtrl, bg, fg := "", border := "", hotBg := "", downBg := "")
;     BtnColors_SetTheme(name, colorsObj)
; ============================================

class BtnThemes {
    static map := Map(
        "default", { bg:0xF3F4F6, fg:0x111111, border:0xCBD5E1, hotBg:0xE8F2FF, downBg:0xD1E9FF },
        "primary", { bg:0x2563EB, fg:0xFFFFFF, border:0x1E40AF, hotBg:0x3B82F6, downBg:0x1D4ED8 },
        "success", { bg:0x10B981, fg:0x0B0B0B, border:0x0E9F6E, hotBg:0x34D399, downBg:0x059669 }
    )
}

BtnColors_SetTheme(name, colorsObj) {
    BtnThemes.map[name] := colorsObj
}

; ---------- NUEVO: acepta nombre de tema o guarda directamente el objeto resuelto
BtnColors_Apply(ctrl, theme := "default") {
    static inited := false
    if !inited {
        OnMessage(0x002B, _WM_DRAWITEM)  ; WM_DRAWITEM
        inited := true
    }
    _InitHoverHooks()  ; <<< NUEVO
    colors := BtnThemes.map.Has(theme) ? BtnThemes.map[theme] : BtnThemes.map["default"]
    _BtnStore().Set(ctrl.Hwnd, _EnsureColors(colors))
    _MakeOwnerDraw(ctrl.Hwnd)
    DllCall("user32\InvalidateRect", "ptr", ctrl.Hwnd, "ptr", 0, "int", true)
}

; ---------- NUEVO: colores ad-hoc vía objeto
BtnColors_ApplyCustom(ctrl, colorsObj) {
    static inited := false
    if !inited {
        OnMessage(0x002B, _WM_DRAWITEM)
        inited := true
    }
    _InitHoverHooks()  ; <<< NUEVO
    _BtnStore().Set(ctrl.Hwnd, _EnsureColors(colorsObj))
    _MakeOwnerDraw(ctrl.Hwnd)
    DllCall("user32\InvalidateRect", "ptr", ctrl.Hwnd, "ptr", 0, "int", true)
}

; ---------- NUEVO: helper rápido por parámetros sueltos
BtnColors_ApplyRGB(ctrl, bg, fg := "", border := "", hotBg := "", downBg := "") {
    colors := { bg:bg }
    if (fg      != "") colors.fg      := fg
    if (border  != "") colors.border  := border
    if (hotBg   != "") colors.hotBg   := hotBg
    if (downBg  != "") colors.downBg  := downBg
    BtnColors_ApplyCustom(ctrl, colors)
}

; --- Internos ----------------------------------------------------------
_BtnStore() {
    static m := Map()   ; hwnd -> colorsObj (resuelto)
    return m
}

_MakeOwnerDraw(hwnd) {
    GWL_STYLE := -16
    old := DllCall("user32\GetWindowLongPtr", "ptr", hwnd, "int", GWL_STYLE, "ptr")
    BS_TYPEMASK := 0x000F
    BS_OWNERDRAW := 0x000B
    new := (old & ~BS_TYPEMASK) | BS_OWNERDRAW
    if (new != old)
        DllCall("user32\SetWindowLongPtr", "ptr", hwnd, "int", GWL_STYLE, "ptr", new)
}

; Completa campos faltantes y deriva colores si no se proveen
_EnsureColors(c) {
    ; Clonar sólo las propiedades presentes (sin usar sintaxis ?. inexistente en AHK v2)
    colors := {}
    if IsObject(c) {
        if ObjHasOwnProp(c, "bg")
            colors.bg := c.bg
        if ObjHasOwnProp(c, "fg")
            colors.fg := c.fg
        if ObjHasOwnProp(c, "border")
            colors.border := c.border
        if ObjHasOwnProp(c, "hotBg")
            colors.hotBg := c.hotBg
        if ObjHasOwnProp(c, "downBg")
            colors.downBg := c.downBg
    }

    ; Defaults/derivaciones si faltan valores
    if !ObjHasOwnProp(colors, "bg")
        colors.bg := 0xE5E7EB  ; fondo claro por defecto
    if !ObjHasOwnProp(colors, "fg")
        colors.fg := (_Luma(colors.bg) < 0.55) ? 0xFFFFFF : 0x111111
    if !ObjHasOwnProp(colors, "border")
        colors.border := _Blend(colors.bg, 0x000000, 0.20)   ; 20% más oscuro
    if !ObjHasOwnProp(colors, "hotBg")
        colors.hotBg := _Blend(colors.bg, 0xFFFFFF, 0.10)    ; +10% claro
    if !ObjHasOwnProp(colors, "downBg")
        colors.downBg := _Blend(colors.bg, 0x000000, 0.10)   ; +10% oscuro

    return colors
}

_WM_DRAWITEM(wParam, lParam, *) {
    hwndItem := NumGet(lParam, 24, "ptr")
    hDC      := NumGet(lParam, 32, "ptr")
    rc       := lParam + 40
    state    := NumGet(lParam, 20, "uint")

    colors := _BtnStore().Get(hwndItem, "")
    if (colors = "")
        return 0

    ODS_SELECTED := 0x0001
    ODS_FOCUS    := 0x0010
    ODS_DISABLED := 0x0004
    ; ODS_HOTLIGHT := 0x0040  ; opcional

    ; <<< ÚNICO CAMBIO IMPORTANTE AQUÍ:
    isHot := (_GetHotBtn() = hwndItem)

    bg := colors.bg
    if (state & ODS_SELECTED)
        bg := colors.downBg
    else if (isHot) ; o (state & ODS_HOTLIGHT)
        bg := colors.hotBg
    if (state & ODS_DISABLED)
        bg := _Blend(bg, 0xFFFFFF, 0.50)

    _FillRect(hDC, rc, _BGR(bg))
    _FrameRect(hDC, rc, _BGR(colors.border))
    txt := _GetWindowText(hwndItem)
    _DrawCenteredText(hDC, rc, txt, _BGR(colors.fg))
    if (state & ODS_FOCUS)
        DllCall("user32\DrawFocusRect", "ptr", hDC, "ptr", rc)
    return 1
}



; --- Helpers GDI -------------------------------------------------------
_BGR(rgb) {
    r := (rgb >> 16) & 0xFF, g := (rgb >> 8) & 0xFF, b := rgb & 0xFF
    return (b << 16) | (g << 8) | r
}

_FillRect(hdc, rc, colorBGR) {
    hbr := DllCall("gdi32\CreateSolidBrush", "uint", colorBGR, "ptr")
    DllCall("user32\FillRect", "ptr", hdc, "ptr", rc, "ptr", hbr)
    DllCall("gdi32\DeleteObject", "ptr", hbr)
}

_FrameRect(hdc, rc, colorBGR) {
    hbr := DllCall("gdi32\CreateSolidBrush", "uint", colorBGR, "ptr")
    DllCall("user32\FrameRect", "ptr", hdc, "ptr", rc, "ptr", hbr)
    DllCall("gdi32\DeleteObject", "ptr", hbr)
}

_DrawCenteredText(hdc, rc, text, colorBGR) {
    DllCall("gdi32\SetBkMode", "ptr", hdc, "int", 1)  ; TRANSPARENT
    DllCall("gdi32\SetTextColor", "ptr", hdc, "uint", colorBGR)
    DT_CENTER := 0x0001, DT_VCENTER := 0x0004, DT_SINGLELINE := 0x0020
    DllCall("user32\DrawText", "ptr", hdc, "str", text, "int", -1, "ptr", rc, "uint", DT_CENTER|DT_VCENTER|DT_SINGLELINE)
}

_GetWindowText(hwnd) {
    len := DllCall("user32\GetWindowTextLengthW", "ptr", hwnd, "int")
    buf := Buffer((len+1)*2, 0)
    DllCall("user32\GetWindowTextW", "ptr", hwnd, "ptr", buf, "int", len+1)
    return StrGet(buf, "UTF-16")
}

_Blend(rgb1, rgb2, alpha := 0.5) {
    r1 := (rgb1>>16)&0xFF, g1 := (rgb1>>8)&0xFF, b1 := rgb1&0xFF
    r2 := (rgb2>>16)&0xFF, g2 := (rgb2>>8)&0xFF, b2 := rgb2&0xFF
    r := Round(r1*(1-alpha)+r2*alpha), g := Round(g1*(1-alpha)+g2*alpha), b := Round(b1*(1-alpha)+b2*alpha)
    return (r<<16)|(g<<8)|b
}

_Luma(rgb) {
    r := (rgb>>16)&0xFF, g := (rgb>>8)&0xFF, b := rgb&0xFF
    ; luminancia aproximada 0..1
    return (0.2126*r + 0.7152*g + 0.0722*b) / 255.0
}


; --- Hover tracking -----------------------------------------------------
_InitHoverHooks() {
    static done := false
    if done
        return
    OnMessage(0x0200, _WM_MOUSEMOVE_HOVER)   ; WM_MOUSEMOVE
    OnMessage(0x02A3, _WM_MOUSELEAVE_HOVER) ; WM_MOUSELEAVE
    done := true
}

_HoverState() {
    static s := { hot: 0 }
    return s
}

_GetHotBtn() {
    return _HoverState().hot
}

_SetHotBtn(newHot) {
    s := _HoverState()
    if (s.hot = newHot)
        return
    old := s.hot
    s.hot := newHot

    if (old)
        DllCall("user32\InvalidateRect", "ptr", old, "ptr", 0, "int", true)
    if (newHot) {
        DllCall("user32\InvalidateRect", "ptr", newHot, "ptr", 0, "int", true)
        _TrackMouseLeave(newHot)
    }
}

_HoverStore() {
    static m := Map()  ; hwnd -> true (hot) / ausente (no hot)
    return m
}

_WM_MOUSEMOVE_HOVER(wParam, lParam, msg, hwnd) {
    ; Detectar SIEMPRE el control real bajo el cursor
    MouseGetPos ,, &winHwnd, &ctrlHwnd, 2
    target := ctrlHwnd ? ctrlHwnd : 0

    ; Si no hay control o no es un botón coloreado, no hacemos nada
    if !target || !_BtnStore().Has(target)
        return

    ; Si cambió el hot, actualizar (esto repinta el anterior y el nuevo)
    if (_GetHotBtn() != target) {
        _SetHotBtn(target)
    }
}


_WM_MOUSELEAVE_HOVER(wParam, lParam, msg, hwnd) {
    ; Si el que deja de tener el mouse es el actual hot, lo limpiamos
    if (_GetHotBtn() = hwnd) {
        _SetHotBtn(0)
    }
}

_TrackMouseLeave(hwnd) {
    size := 8 + A_PtrSize + 4
    tme := Buffer(size, 0)
    NumPut("UInt", size,       tme, 0)
    NumPut("UInt", 0x00000002, tme, 4)             ; TME_LEAVE
    NumPut("Ptr",  hwnd,       tme, 8)
    NumPut("UInt", 0,          tme, 8 + A_PtrSize) ; hoverTime
    DllCall("user32\TrackMouseEvent", "ptr", tme)
}
