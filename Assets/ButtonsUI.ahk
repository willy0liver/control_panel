#Requires AutoHotkey v2.0
#Include ..\Assets\Json.ahk 
#Include ..\Assets\utiles.ahk
#Include ..\Assets\MenuTips.ahk
; Assets\ButtonsUI.ahk
; Construcción de filas/títulos/botones/menús y lógica asociada

BuildUI() {
    global gGui, gBtnMenus, gBtnTips
    global dataDir, pattern, startX, stepX, yPos, btnW, btnH, maxRowWidth, gapY

    rowDirs := ListRowDirs(dataDir)
    if rowDirs.Length = 0 {
        MsgBox("No se encontraron carpetas de fila (fila01, fila02, ...) en:`n" dataDir, "Sin datos", "Icon!")
        return
    }

    curY := yPos
    maxX := 0
    pageBottom := 0

    for rowDir in rowDirs {
        ; ---- Título (general.json) ----
        title := GetGeneralTitle(rowDir)
        curX := startX
        if (title != "") {
            tCtrl := gGui.Add("Text", "x" startX " y" curY, title)
            tCtrl.GetPos(, , , &th)
            curY := curY + th + 10
        }

        ; ---- Botones de la fila ----
        files := ListFiles(rowDir, pattern)  ; orden natural
        for filePath in files {
            if (curX > startX && (curX - startX + btnW) > maxRowWidth) {
                curX := startX
                curY += btnH + gapY
            }

            ; Cargar JSON del botón
            jsonText := ""
            try jsonText := FileRead(filePath, "UTF-8")
            catch as e {
                MsgBox("No se pudo leer:`n" filePath "`n`n" e.Message, "Error de lectura", "Iconx")
                continue
            }
            data := 0
            try {
                jsonText := RegExReplace(jsonText, "^\xEF\xBB\xBF")
                jsonVar  := Trim(jsonText, "`r`n`t ")
                data := Jxon_Load2(&jsonVar)
            } catch as e {
                MsgBox("JSON inválido en:`n" filePath "`n`n" e.Message, "Error de JSON", "Iconx")
                continue
            }

            btnText  := GetJsonNameOrFile(data, filePath)
            btnColor  := GetJsonColorOrFile(data, filePath)            
            opciones := GetJsonOpciones(data)

            btn := gGui.Add("Button", "x" curX " y" curY " w" btnW " h" btnH, btnText)
            if (btnColor != "")
                BtnColors_Apply(btn, btnColor)   ; <<< NUEVO: aplicar color al botón
            
            ; Formar de poner color al botón
            ;BtnColors_Apply(btn, "red-50")   ; o "primary", "success", etc.
            ;BtnColors_ApplyCustom(btn, { bg:0x222222, fg:0xFFFFFF, border:0x666666, hotBg:0x333333, downBg:0x111111 })
            ; o
            ;BtnColors_ApplyRGB(btn, 0xF97316)                ; sólo fondo; el resto se calcula
            ;BtnColors_ApplyRGB(btn, 0xF97316, 0x000000)      ; fondo + color de texto

            ; Menú y tooltips por ítem
            m := Menu()
            tips := []
            hasItems := false

            for _, op in opciones {
                optName := SafeTrim(GetKey(op, "opcion", "opción"))
                optUrl  := SafeTrim(GetKey(op, "url", "valor"))
                if (optName = "" || optUrl = "")
                    continue
                hasItems := true

                isPage := SafeTrim(GetKey(op, "isPage"))
                atajo  := SafeTrim(GetKey(op, "atajo"))

                ; Hotstrings si hay atajo
                if (atajo != "") {
                    Hotstring(":*:" atajo, optUrl)           ; reemplazo de texto
                    if (isPage = "S")
                        Hotstring(":*:oo" atajo, MakeUrlHandler(optUrl)) ; abrir URL con "oo" + atajo
                    tips.Push(atajo " --> " optUrl)
                } else {
                    tips.Push(" --> " optUrl)
                }

                m.Add(optName, MakeUrlHandler(optUrl))
            }

            if !hasItems {
                m.Add("(sin opciones)", (*) => 0)
                m.Disable("(sin opciones)")
                tips.Push("")
            }

            gBtnMenus[btn.Hwnd] := m
            gBtnTips[btn.Hwnd]  := tips
            btn.OnEvent("Click", ShowBtnMenu)

            curX += stepX
            if (curX - stepX + btnW > maxX)
                maxX := curX - stepX + btnW
        }

        rowBottom := (files.Length > 0) ? (curY + btnH) : curY
        if (rowBottom > pageBottom)
            pageBottom := rowBottom

        curY := rowBottom + gapY
    }

    finalW := Max(startX + maxRowWidth, startX + maxX - startX) + 20
    finalH := pageBottom + 30
    gGui.Move(, , finalW, finalH)
}

; Muestra el menú del botón y activa tooltips para sus ítems
ShowBtnMenu(ctrl, info) {
    global gGui, gBtnMenus, gBtnTips
    m := gBtnMenus.Get(ctrl.Hwnd, 0)
    if !m
        return

    ctrl.GetPos(&bx, &by, &bw, &bh)
    gGui.GetPos(&gx, &gy)

    x := gx + bx + (bw // 2)
    y := gy + by + bh

    sw := A_ScreenWidth, sh := A_ScreenHeight
    x := Max(0, Min(x, sw - 1))
    y := Max(0, Min(y, sh - 1))

    ; Activar tooltips para este menú
    MenuTips_BeforeShow(gBtnTips.Get(ctrl.Hwnd, []))
    m.Show(x, y)
}

; ---------- Helpers de datos/archivos (orden natural) ----------
; Lee general.json y devuelve el título (nombreFila) o "" si no existe / falla.
GetGeneralTitle(dir) {
    path := dir "\general.json"
    if !FileExist(path)
        return ""
    txt := ""
    try {
        txt := FileRead(path, "UTF-8")
    } catch {
        return ""
    }
    try {
        txt := RegExReplace(txt, "^\xEF\xBB\xBF") ; quitar BOM si existe
        v   := Trim(txt, "`r`n`t ")
        data := Jxon_Load2(&v)
    } catch {
        return ""
    }
    return SafeTrim(GetKey(data, "nombreFila"))
}

; Carpetas filaXX orden natural
ListRowDirs(baseDir) {
    rows := ""
    Loop Files baseDir "\fila*", "D" {
        path := A_LoopFileFullPath
        SplitPath(path, &name)
        if RegExMatch(name, "\d+", &m)
            key := Format("{:012}", Integer(m[0]))
        else
            key := "ZZZ" . name
        rows .= key "|" path "`n"
    }
    if (rows = "")
        return []
    sorted := Sort(rows, "D| P1")
    res := []
    Loop Parse sorted, "`n", "`r" {
        if A_LoopField = ""
            continue
        parts := StrSplit(A_LoopField, "|")
        if (parts.Length >= 2)
            res.Push(parts[2])
    }
    return res
}

; Archivos boton*.json orden natural
ListFiles(dir, pattern) {
    rows := ""
    Loop Files dir "\" pattern, "F" {
        path := A_LoopFileFullPath
        SplitPath(path, &name)
        if RegExMatch(name, "\d+", &m)
            key := Format("{:012}", Integer(m[0]))
        else
            key := "ZZZ" . name
        rows .= key "|" path "`n"
    }
    if (rows = "")
        return []
    sorted := Sort(rows, "D| P1")
    res := []
    Loop Parse sorted, "`n", "`r" {
        if A_LoopField = ""
            continue
        parts := StrSplit(A_LoopField, "|")
        if (parts.Length >= 2)
            res.Push(parts[2])
    }
    return res
}
