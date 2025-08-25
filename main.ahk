#Requires AutoHotkey v2.0
#Include Assets\Menu.ahk
#Include Assets\Json.ahk 
#Include Assets\MenuTips.ahk
#Include Assets\Utiles.ahk
#Include Assets\ButtonsUI.ahk 
#Include Assets\ButtonColors.ahk   ; <<< NUEVO
#Include Assets\Theme.ahk          ; <<< Opcional (si lo usas)

CoordMode("Menu", "Screen")
;===========================================================
; Panel de botones dinámicos desde JSON - AutoHotkey v2
; Alt+P abre la ventana
; Varias filas: /botones/filaXX con general.json y boton*.json
;===========================================================

;----------------------
; Configuración
;----------------------
dataDir := A_ScriptDir "\botones"
pattern := "boton*.json"
startX := 10
stepX  := 170
yPos   := 20
btnW   := 150
btnH   := 30
maxRowWidth := 800
gapY        := 10

;----------------------
; Estado global
;----------------------
global gGui := 0
global gBtnMenus := Map()   ; Hwnd botón -> Menu
global gBtnTips  := Map()   ; Hwnd botón -> Array de tooltips (por ítem)
global gBuilt := false

;----------------------
; Hotkey: Alt + P
;----------------------
!p:: {
    global gGui, gBuilt
    if !gBuilt {
        gGui := Gui("+AlwaysOnTop", "Panel dinámico")
        BuildMenuBar()
        MenuTips_Init()      ; Tooltips en ítems de menú
        BtnColor_Init()      ; <<< NUEVO: activa coloración de botones
        BuildUI()            ; Construye filas/títulos/botones/menús
        gBuilt := true
    }
    gGui.Show()
}

; Hotkey: Alt + R -> reconstruir
!r:: {
    global gGui, gBuilt
    if !gBuilt
        return
    try gGui.Destroy()
    gBuilt := false
    gGui := Gui("+AlwaysOnTop", "Panel dinámico")
    BuildMenuBar()
    MenuTips_Init()
    BuildUI()
    gBuilt := true
    gGui.Show()
}

;----------------------
; Barra de menú superior (usa tu Assets\Menu.ahk)
;----------------------
BuildMenuBar() {
    global gGui
    mb := fn_get_menu()
    gGui.MenuBar := mb
}
