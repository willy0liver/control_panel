#Requires AutoHotkey v2.0

; Assets\MenuTips.ahk
; Tooltips al pasar el mouse por ítems de menú (popup menus)
global __MenuTips_Enabled   := false
global __MenuTips_ActiveTips := []
global __MenuTips_ActiveMenu := 0

MenuTips_Init() {
    OnMessage(0x117, MenuTips_WM_INITMENUPOPUP) ; wParam = HMENU (correcto)
    OnMessage(0x11F, MenuTips_WM_MENUSELECT)
}

; Llamar ANTES de mostrar el popup: activa tooltips para esa lista
MenuTips_BeforeShow(tipsArray) {
    global __MenuTips_Enabled, __MenuTips_ActiveTips, __MenuTips_ActiveMenu
    __MenuTips_ActiveTips := tipsArray
    __MenuTips_ActiveMenu := 0
    __MenuTips_Enabled := true
}

MenuTips_WM_INITMENUPOPUP(wParam, lParam, msg, hwnd) {
    global __MenuTips_Enabled, __MenuTips_ActiveMenu
    if !__MenuTips_Enabled
        return
    __MenuTips_ActiveMenu := wParam ; HMENU del popup abierto
}

MenuTips_WM_MENUSELECT(wParam, lParam, msg, hwnd) {
    global __MenuTips_Enabled, __MenuTips_ActiveTips, __MenuTips_ActiveMenu
    if !__MenuTips_Enabled
        return

    flags := (wParam >> 16) & 0xFFFF
    id    :=  wParam        & 0xFFFF
    hMenu :=  lParam

    if (flags = 0xFFFF) { ; menú cerrado
        ToolTip()
        __MenuTips_Enabled := false
        __MenuTips_ActiveMenu := 0
        return
    }

    if (hMenu != __MenuTips_ActiveMenu)
        return

    MF_POPUP := 0x0010, MF_SEPARATOR := 0x0800
    if (flags & (MF_POPUP | MF_SEPARATOR)) {
        ToolTip()
        return
    }

    pos := MenuTips_IdToPos(hMenu, id)
    if (pos < 0) {
        ToolTip()
        return
    }

    tip := (pos+1 <= __MenuTips_ActiveTips.Length) ? __MenuTips_ActiveTips[pos+1] : ""
    if (tip = "") {
        ToolTip()
        return
    }

    MouseGetPos &mx, &my
    ToolTip(tip, mx + 16, my + 16)
}

MenuTips_IdToPos(hMenu, id) {
    count := DllCall("user32\GetMenuItemCount", "ptr", hMenu, "int")
    loop count {
        idx := A_Index - 1
        thisId := DllCall("user32\GetMenuItemID", "ptr", hMenu, "int", idx, "int")
        if (thisId = id)
            return idx
    }
    return -1
}
