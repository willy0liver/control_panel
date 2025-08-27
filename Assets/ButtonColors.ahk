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
        "success", { bg:0x10B981, fg:0x0B0B0B, border:0x0E9F6E, hotBg:0x34D399, downBg:0x059669 },
        "danger", { bg:0xDC2626, fg:0xFFFFFF, border:0x991B1B, hotBg:0xEF4444, downBg:0xB91C1C },
        "warning", { bg:0xF59E0B, fg:0x111111, border:0xB45309, hotBg:0xFBBF24, downBg:0xD97706 },
        "info", { bg:0x3B82F6, fg:0xFFFFFF, border:0x1E40AF, hotBg:0x60A5FA, downBg:0x2563EB },
        "light", { bg:0xF9FAFB, fg:0x111111, border:0xE5E7EB, hotBg:0xFFFFFF, downBg:0xD1D5DB },
        "dark", { bg:0x1F2937, fg:0xFFFFFF, border:0x111827, hotBg:0x374151, downBg:0x1E293B },
        ; Escalas de grises
        "gray-50", { bg:0xFAFAFA, fg:0x111111, border:0xE5E5E5, hotBg:0xFFFFFF, downBg:0xF5F5F5 },
        "gray-100", { bg:0xF3F4F6, fg:0x111111, border:0xE5E7EB, hotBg:0xFFFFFF, downBg:0xD1D5DB },
        "gray-200", { bg:0xE5E7EB, fg:0x111111, border:0xD1D5DB, hotBg:0xF3F4F6, downBg:0x9CA3AF },
        "gray-300", { bg:0xD1D5DB, fg:0x111111, border:0x9CA3AF, hotBg:0xE5E7EB, downBg:0x6B7280 },
        "gray-400", { bg:0x9CA3AF, fg:0xFFFFFF, border:0x6B7280, hotBg:0xD1D5DB, downBg:0x4B5563 },
        "gray-500", { bg:0x6B7280, fg:0xFFFFFF, border:0x4B5563, hotBg:0x9CA3AF, downBg:0x374151 },
        "gray-600", { bg:0x4B5563, fg:0xFFFFFF, border:0x374151, hotBg:0x6B7280, downBg:0x1F2937 },
        "gray-700", { bg:0x374151, fg:0xFFFFFF, border:0x1F2937, hotBg:0x4B5563, downBg:0x111827 },
        "gray-800", { bg:0x1F2937, fg:0xFFFFFF, border:0x111827, hotBg:0x374151, downBg:0x0F172A },
        "gray-900", { bg:0x111827, fg:0xFFFFFF, border:0x0F172A, hotBg:0x1F2937, downBg:0x000000 },

        ; Escalas de rojos
        "red-50", { bg:0xFEF2F2, fg:0x111111, border:0xFEE2E2, hotBg:0xFECACA, downBg:0xF87171 },
        "red-100", { bg:0xFEE2E2, fg:0x111111, border:0xFCA5A5, hotBg:0xFECACA, downBg:0xF87171 },
        "red-200", { bg:0xFCA5A5, fg:0x111111, border:0xF87171, hotBg:0xFEE2E2, downBg:0xEF4444 },
        "red-300", { bg:0xF87171, fg:0xFFFFFF, border:0xEF4444, hotBg:0xFCA5A5, downBg:0xDC2626 },
        "red-400", { bg:0xEF4444, fg:0xFFFFFF, border:0xDC2626, hotBg:0xF87171, downBg:0xB91C1C },
        "red-500", { bg:0xDC2626, fg:0xFFFFFF, border:0xB91C1C, hotBg:0xEF4444, downBg:0x991B1B },
        "red-600", { bg:0xB91C1C, fg:0xFFFFFF, border:0x991B1B, hotBg:0xDC2626, downBg:0x7F1D1D },
        "red-700", { bg:0x991B1B, fg:0xFFFFFF, border:0x7F1D1D, hotBg:0xB91C1C, downBg:0x601212 },
        "red-800", { bg:0x7F1D1D, fg:0xFFFFFF, border:0x601212, hotBg:0x991B1B, downBg:0x4C0D0D },
        "red-900", { bg:0x601212, fg:0xFFFFFF, border:0x4C0D0D, hotBg:0x7F1D1D, downBg:0x3B0A0A },

        ; Escalas de azules
        "blue-50", { bg:0xEFF6FF, fg:0x111111, border:0xDBEAFE, hotBg:0xBFDBFE, downBg:0x93C5FD },
        "blue-100", { bg:0xDBEAFE, fg:0x111111, border:0xBFDBFE, hotBg:0xE0F2FE, downBg:0x93C5FD },
        "blue-200", { bg:0xBFDBFE, fg:0x111111, border:0x93C5FD, hotBg:0xDBEAFE, downBg:0x60A5FA },
        "blue-300", { bg:0x93C5FD, fg:0x111111, border:0x60A5FA, hotBg:0xBFDBFE, downBg:0x3B82F6 },
        "blue-400", { bg:0x60A5FA, fg:0xFFFFFF, border:0x3B82F6, hotBg:0x93C5FD, downBg:0x2563EB },
        "blue-500", { bg:0x3B82F6, fg:0xFFFFFF, border:0x2563EB, hotBg:0x60A5FA, downBg:0x1D4ED8 },
        "blue-600", { bg:0x2563EB, fg:0xFFFFFF, border:0x1D4ED8, hotBg:0x3B82F6, downBg:0x1E40AF },
        "blue-700", { bg:0x1D4ED8, fg:0xFFFFFF, border:0x1E40AF, hotBg:0x2563EB, downBg:0x1E3A8A },
        "blue-800", { bg:0x1E40AF, fg:0xFFFFFF, border:0x1E3A8A, hotBg:0x1D4ED8, downBg:0x1E3A8A },
        "blue-900", { bg:0x1E3A8A, fg:0xFFFFFF, border:0x1E3A8A, hotBg:0x1E40AF, downBg:0x1E3A8A },

        ; Escalas de verdes
        "green-50", { bg:0xF0FDF4, fg:0x111111, border:0xDCFCE7, hotBg:0xBBF7D0, downBg:0x86EFAC },
        "green-100", { bg:0xDCFCE7, fg:0x111111, border:0xBBF7D0, hotBg:0xD1FAE5, downBg:0x86EFAC },
        "green-200", { bg:0xBBF7D0, fg:0x111111, border:0x86EFAC, hotBg:0xDCFCE7, downBg:0x4ADE80 },
        "green-300", { bg:0x86EFAC, fg:0x111111, border:0x4ADE80, hotBg:0xBBF7D0, downBg:0x22C55E },
        "green-400", { bg:0x4ADE80, fg:0xFFFFFF, border:0x22C55E, hotBg:0x86EFAC, downBg:0x16A34A },
        "green-500", { bg:0x22C55E, fg:0xFFFFFF, border:0x16A34A, hotBg:0x4ADE80, downBg:0x15803D },
        "green-600", { bg:0x16A34A, fg:0xFFFFFF, border:0x15803D, hotBg:0x22C55E, downBg:0x166534 },
        "green-700", { bg:0x15803D, fg:0xFFFFFF, border:0x166534, hotBg:0x16A34A, downBg:0x14532D },
        "green-800", { bg:0x166534, fg:0xFFFFFF, border:0x14532D, hotBg:0x15803D, downBg:0x134E2A },
        "green-900", { bg:0x14532D, fg:0xFFFFFF, border:0x134E2A, hotBg:0x166534, downBg:0x123524 },

        ; Escalas de púrpura
        "purple-50", { bg:0xF5F3FF, fg:0x111111, border:0xEDE9FE, hotBg:0xDDD6FE, downBg:0xC4B5FD },
        "purple-100", { bg:0xEDE9FE, fg:0x111111, border:0xDDD6FE, hotBg:0xC4B5FD, downBg:0xA78BFA },
        "purple-200", { bg:0xDDD6FE, fg:0x111111, border:0xC4B5FD, hotBg:0xA78BFA, downBg:0x8B5CF6 },
        "purple-300", { bg:0xC4B5FD, fg:0xFFFFFF, border:0xA78BFA, hotBg:0x8B5CF6, downBg:0x7C3AED },
        "purple-400", { bg:0xA78BFA, fg:0xFFFFFF, border:0x8B5CF6, hotBg:0x7C3AED, downBg:0x6D28D9 },
        "purple-500", { bg:0x8B5CF6, fg:0xFFFFFF, border:0x7C3AED, hotBg:0xA78BFA, downBg:0x6D28D9 },
        "purple-600", { bg:0x7C3AED, fg:0xFFFFFF, border:0x6D28D9, hotBg:0x8B5CF6, downBg:0x5B21B6 },
        "purple-700", { bg:0x6D28D9, fg:0xFFFFFF, border:0x5B21B6, hotBg:0x7C3AED, downBg:0x4C1D95 },
        "purple-800", { bg:0x5B21B6, fg:0xFFFFFF, border:0x4C1D95, hotBg:0x6D28D9, downBg:0x3F0E7A },
        "purple-900", { bg:0x4C1D95, fg:0xFFFFFF, border:0x3F0E7A, hotBg:0x5B21B6, downBg:0x2E1065 },

        ; Escalas de amarillo
        "yellow-50", { bg:0xFFFBEB, fg:0x111111, border:0xFEF3C7, hotBg:0xFDE68A, downBg:0xFCD34D },
        "yellow-100", { bg:0xFEF3C7, fg:0x111111, border:0xFDE68A, hotBg:0xFCD34D, downBg:0xFBBF24 },
        "yellow-200", { bg:0xFDE68A, fg:0x111111, border:0xFCD34D, hotBg:0xFBBF24, downBg:0xF59E0B },
        "yellow-300", { bg:0xFCD34D, fg:0x111111, border:0xFBBF24, hotBg:0xF59E0B, downBg:0xD97706 },
        "yellow-400", { bg:0xFBBF24, fg:0x111111, border:0xF59E0B, hotBg:0xD97706, downBg:0xB45309 },
        "yellow-500", { bg:0xF59E0B, fg:0x111111, border:0xD97706, hotBg:0xFBBF24, downBg:0xB45309 },
        "yellow-600", { bg:0xD97706, fg:0xFFFFFF, border:0xB45309, hotBg:0xF59E0B, downBg:0x92400E },
        "yellow-700", { bg:0xB45309, fg:0xFFFFFF, border:0x92400E, hotBg:0xD97706, downBg:0x78350F },
        "yellow-800", { bg:0x92400E, fg:0xFFFFFF, border:0x78350F, hotBg:0xB45309, downBg:0x652B0E },
        "yellow-900", { bg:0x78350F, fg:0xFFFFFF, border:0x652B0E, hotBg:0x92400E, downBg:0x4D210C },

        ; Escalas de cian
        "cyan-50", { bg:0xECFEFF, fg:0x111111, border:0xCFFAFE, hotBg:0xA5F3FC, downBg:0x67E8F9 },
        "cyan-100", { bg:0xCFFAFE, fg:0x111111, border:0xA5F3FC, hotBg:0x67E8F9, downBg:0x22D3EE },
        "cyan-200", { bg:0xA5F3FC, fg:0x111111, border:0x67E8F9, hotBg:0x22D3EE, downBg:0x06B6D4 },
        "cyan-300", { bg:0x67E8F9, fg:0x111111, border:0x22D3EE, hotBg:0x06B6D4, downBg:0x0891B2 },
        "cyan-400", { bg:0x22D3EE, fg:0xFFFFFF, border:0x06B6D4, hotBg:0x0891B2, downBg:0x0E7490 },
        "cyan-500", { bg:0x06B6D4, fg:0xFFFFFF, border:0x0891B2, hotBg:0x22D3EE, downBg:0x0E7490 },
        "cyan-600", { bg:0x0891B2, fg:0xFFFFFF, border:0x0E7490, hotBg:0x06B6D4, downBg:0x155E75 },
        "cyan-700", { bg:0x0E7490, fg:0xFFFFFF, border:0x155E75, hotBg:0x0891B2, downBg:0x164E63 },
        "cyan-800", { bg:0x155E75, fg:0xFFFFFF, border:0x164E63, hotBg:0x0E7490, downBg:0x083344 },
        "cyan-900", { bg:0x164E63, fg:0xFFFFFF, border:0x083344, hotBg:0x155E75, downBg:0x062C3A },

        ; Escalas de rosa
        "pink-50", { bg:0xFDF2F8, fg:0x111111, border:0xFCE7F3, hotBg:0xFBCFE8, downBg:0xF9A8D4 },
        "pink-100", { bg:0xFCE7F3, fg:0x111111, border:0xFBCFE8, hotBg:0xF9A8D4, downBg:0xF472B6 },
        "pink-200", { bg:0xFBCFE8, fg:0x111111, border:0xF9A8D4, hotBg:0xF472B6, downBg:0xEC4899 },
        "pink-300", { bg:0xF9A8D4, fg:0xFFFFFF, border:0xF472B6, hotBg:0xEC4899, downBg:0xDB2777 },
        "pink-400", { bg:0xF472B6, fg:0xFFFFFF, border:0xEC4899, hotBg:0xDB2777, downBg:0xBE185D },
        "pink-500", { bg:0xEC4899, fg:0xFFFFFF, border:0xDB2777, hotBg:0xF472B6, downBg:0xBE185D },
        "pink-600", { bg:0xDB2777, fg:0xFFFFFF, border:0xBE185D, hotBg:0xEC4899, downBg:0x9D174D },
        "pink-700", { bg:0xBE185D, fg:0xFFFFFF, border:0x9D174D, hotBg:0xDB2777, downBg:0x831843 },
        "pink-800", { bg:0x9D174D, fg:0xFFFFFF, border:0x831843, hotBg:0xBE185D, downBg:0x701A3E },
        "pink-900", { bg:0x831843, fg:0xFFFFFF, border:0x701A3E, hotBg:0x9D174D, downBg:0x5F1239 }
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
