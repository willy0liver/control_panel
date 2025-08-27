#Requires AutoHotkey v2.0

; ============================================
; TasksUI.ahk  (AHK v2)
; Ventana de Tareas (Pendientes/Completadas)
; - API:
;   Tasks_Show()
;   (Hotkey) Alt+T
; Requiere:
   #Include ../../Assets\Json.ahk
   #Include ../../Assets\Tasks\TasksStore.ahk
   #Include ../../Assets\Tasks\TasksScheduler.ahk
; ============================================


global gTasksGui := 0
global gLV_Pend := 0
global gLV_Done := 0
global gPanelComp := 0
global gHistGui := 0
; --- Guard para controlar AlwaysOnTop mientras Tareas está abierta ---
global _Tasks_WasTopMost := false

; -------- Hotkey ----------
!t::Tasks_Show()

Tasks_Show() {
    global gTasksGui, gGui
    _Tasks_TopMostOff()   ; baja temporalmente el Panel

    if !IsSet(gTasksGui) || !gTasksGui {
        _BuildGui()
        try gTasksGui.Opt("+Owner" gGui.Hwnd)
        gTasksGui.OnEvent("Close",  (*) => (_Tasks_TopMostRestore(), _ErrWatch_Stop()))
        gTasksGui.OnEvent("Escape", (*) => (_Tasks_TopMostRestore(), _ErrWatch_Stop()))
    }

    _ErrWatch_Start()     ; <<< vigila errores mientras Tareas esté abierta
    gTasksGui.Show()
}


_BuildGui() {
    global gTasksGui, gLV_Pend, gPanelComp
    gTasksGui := Gui("+AlwaysOnTop", "Tareas")
    tabs := gTasksGui.Add("Tab3", "x10 y10 w780 h480", ["Pendientes", "Completadas"])

    ; -------- Pestaña: Pendientes --------
    tabs.UseTab("Pendientes")
    ;gLV_Pend := gTasksGui.Add("ListView", "x20 y50 w750 h370 Grid", "Título|Trigger|Acción|Proc.|Creada")
    gLV_Pend := gTasksGui.Add(
        "ListView"
    , "x20 y50 w750 h370 Grid"
    , ["Título","Trigger","Acción","Proc.","Creada"]
    )
    ; (opcional) ajustar anchos
    gLV_Pend.ModifyCol(1, 250)
    gLV_Pend.ModifyCol(2, 140)
    gLV_Pend.ModifyCol(3, 140)
    gLV_Pend.ModifyCol(4, 60)     ; Proc.
    gLV_Pend.ModifyCol(5, 160)    ; Creada

    btnAdd   := gTasksGui.Add("Button", "x20  y430 w100", "Nueva")
    btnEdit  := gTasksGui.Add("Button", "x130 y430 w100", "Editar")
    btnDel   := gTasksGui.Add("Button", "x240 y430 w100", "Eliminar")
    btnComp  := gTasksGui.Add("Button", "x350 y430 w120", "Completar")
    btnProg  := gTasksGui.Add("Button", "x480 y430 w140", "En Proceso ON/OFF")
    btnTrig  := gTasksGui.Add("Button", "x630 y430 w140", "Activar/Desactivar Trigger")

    btnAdd.OnEvent("Click", (*) => _NewTaskDialog())
    btnEdit.OnEvent("Click", (*) => _EditSelected())
    btnDel.OnEvent("Click", (*) => _DeleteSelected())
    btnComp.OnEvent("Click", (*) => _CompleteSelected())
    btnProg.OnEvent("Click", (*) => _ToggleInProgressSelected())
    btnTrig.OnEvent("Click", (*) => _ToggleTriggerSelected())

    ; -------- Pestaña: Completadas --------
    tabs.UseTab("Completadas")
    gLV_Done := gTasksGui.Add(
        "ListView"
    , "x20 y50 w750 h370 Grid"
    , ["Fecha","Hora","Título"]
    )
    ; (opcional) ajustar anchos
    gLV_Done.ModifyCol(1, 120)   ; Fecha
    gLV_Done.ModifyCol(2, 80)    ; Hora
    gLV_Done.ModifyCol(3, 520)   ; Título (ajusta a tu gusto)
    gPanelComp := gTasksGui.Add("Text", "x20 y50 w750 h360", "")  ; contenedor “dummy”; reconstruiremos bloques encima
    btnHist := gTasksGui.Add("Button", "x20 y430 w160", "Historial de Tareas")
    btnHist.OnEvent("Click", (*) => _ShowHistory())

    tabs.UseTab()  ; salir del control Tab
}

_RefreshAll() {
    _RefreshPending()
    _RefreshCompleted()
}

; ---------------- Pendientes ----------------
_RefreshPending() {
    global gLV_Pend
    gLV_Pend.Delete()  ; limpiar filas

    for t in TasksStore_All() {
        if t.completed
            continue
        gLV_Pend.Add("", t.title, _TriggerText(t), _ActionText(t), (t.inProgress ? "Sí" : "No"), t.createdAt)
        ; Guardar el id en el último item
        row := gLV_Pend.GetCount()
        gLV_Pend.SetText(row, t.id)  ; truco: guardarlo fuera de columnas visibles
    }
}

_GetSelectedId() {
    global gLV_Pend
    row := gLV_Pend.GetNext(0, "F")
    if !row
        return ""
    ; el texto “invisible” lo guardamos con SetText(row, id) -> lo leemos con GetText(row)
    id := gLV_Pend.GetText(row)   ; devuelve el "item text" del row (col 0)
    return id
}

_NewTaskDialog(editId := "") {
    isEdit := (editId != "")
    t := isEdit ? _CloneTask(_Find(editId)) : { title:"", trigger:{type:"off"}, action:{type:"openUrl",value:""}, inProgress:false, completed:false, completedAt:"" }

    gui := Gui("+Owner", isEdit ? "Editar Tarea" : "Nueva Tarea")
    gui.Add("Text",, "Título:")
    edTitle := gui.Add("Edit", "w320", t.title)

    gui.Add("Text",, "Trigger:")
    ddTrig := gui.Add("DropDownList", "w180", ["off","at","interval"])
    ddTrig.Choose( (t.trigger.type="at")?2 : (t.trigger.type="interval")?3 : 1 )

    txA := gui.Add("Text", "xm", "Hora (hh:mm am/pm) para 'at'  |  Minutos para 'interval':")
    edT := gui.Add("Edit", "w180", (t.trigger.type="at")? (ObjHasOwnProp(t.trigger,"time")?t.trigger.time:"") : (ObjHasOwnProp(t.trigger,"minutes")?t.trigger.minutes:""))

    gui.Add("Text", "xm", "Acción:")
    ddAct := gui.Add("DropDownList", "w180", ["openUrl","run","sendText","ahk"])
    ddAct.Choose( (t.action.type="run")?2 : (t.action.type="sendText")?3 : (t.action.type="ahk")?4 : 1 )

    gui.Add("Text", "xm", "Valor de acción (URL, ruta, texto o nombre de función):")
    edVal := gui.Add("Edit", "w380", t.action.value)

    cbInProg := gui.Add("CheckBox", "xm", "En Proceso")
    cbInProg.Value := t.inProgress

    btnOK := gui.Add("Button", "xm w120", "Guardar")
    btnCancel := gui.Add("Button", "x+m w120", "Cancelar")

    btnOK.OnEvent("Click", (*) => (
        _SaveTaskDialog(gui, edTitle, ddTrig, edT, ddAct, edVal, cbInProg, isEdit, editId)
    ))
    btnCancel.OnEvent("Click", (*) => gui.Destroy())

    gui.Show()
}

_SaveTaskDialog(gui, edTitle, ddTrig, edT, ddAct, edVal, cbInProg, isEdit, editId) {
    title := Trim(edTitle.Text)
    if (title = "") {
        MsgBox("El título es obligatorio.")
        return
    }
    trig := { type: ddTrig.Text }
    if (trig.type = "at") {
        tim := Trim(edT.Text)
        if (_NormalizeTimeToHHmm(tim) = "") {
            MsgBox("Hora inválida. Usa hh:mm (am/pm opcional).")
            return
        }
        trig.time := tim
    } else if (trig.type = "interval") {
        mins := Integer(Trim(edT.Text))
        if (mins < 1) {
            MsgBox("Minutos inválidos (>=1).")
            return
        }
        trig.minutes := mins
    }

    act := { type: ddAct.Text, value: edVal.Text }
    inProg := (cbInProg.Value = 1)

    if isEdit {
        ok := TasksStore_UpdateById(editId, { title:title, trigger:trig, action:act, inProgress:inProg })
        if !ok {
            MsgBox("No se pudo actualizar la tarea.")
        }
    } else {
        TasksStore_Add({ title:title, trigger:trig, action:act, inProgress:inProg, completed:false })
    }
    gui.Destroy()
    _RefreshAll()
}

_EditSelected() {
    id := _GetSelectedId()
    if (id = "") {
        MsgBox("Selecciona una tarea.")
        return
    }
    _NewTaskDialog(id)
}

_DeleteSelected() {
    id := _GetSelectedId()
    if (id = "") {
        MsgBox("Selecciona una tarea.")
        return
    }
    if (MsgBox("¿Eliminar la tarea seleccionada?", "Confirmar", "YesNo Icon!") = "Yes") {
        TasksStore_Delete(id)
        _RefreshAll()
    }
}

_CompleteSelected() {
    id := _GetSelectedId()
    if (id = "") {
        MsgBox("Selecciona una tarea.")
        return
    }
    TasksStore_SetCompleted(id, true)
    _RefreshAll()
}

_ToggleInProgressSelected() {
    id := _GetSelectedId()
    if (id = "") {
        MsgBox("Selecciona una tarea.")
        return
    }
    t := _Find(id)
    if !t {
        MsgBox("No se encontró la tarea.")
        return
    }
    TasksStore_UpdateById(id, { inProgress: !t.inProgress })
    _RefreshAll()
}

_ToggleTriggerSelected() {
    id := _GetSelectedId()
    if (id = "") {
        MsgBox("Selecciona una tarea.")
        return
    }
    t := _Find(id)
    if !t {
        MsgBox("No se encontró la tarea.")
        return
    }
    if (t.trigger.type = "off") {
        MsgBox("Esta tarea ya está desactivada. Edita la tarea para configurar el trigger.")
        return
    }
    ; pausa / reanuda → si estaba activo, la pasamos temporalmente a off; si estaba offTemp, restaurar
    if !ObjHasOwnProp(t, "triggerPaused") || !t.triggerPaused {
        ; pausar
        TasksStore_UpdateById(id, { triggerPaused: true, triggerBackup: t.trigger, trigger: {type:"off"} })
    } else {
        ; reanudar
        trg := ObjHasOwnProp(t, "triggerBackup") ? t.triggerBackup : {type:"off"}
        TasksStore_UpdateById(id, { triggerPaused: false, trigger: trg })
    }
    _RefreshAll()
}

_TriggerText(t) {
    if t.trigger.type = "off"
        return "off"
    if t.trigger.type = "at" {
        return "diario " t.trigger.time
    }
    if t.trigger.type = "interval" {
        mins := t.trigger.minutes
        return "cada " mins " min"
    }
    return t.trigger.type
}

_ActionText(t) {
    a := t.action
    if a.type = "openUrl"
        return "openUrl"
    if a.type = "run"
        return "run"
    if a.type = "sendText"
        return "sendText"
    if a.type = "ahk"
        return "ahk"
    return a.type
}

_Find(id) {
    for t in TasksStore_All()
        if t.id = id
            return t
    return 0
}

_CloneTask(t) {
    if !t
        return 0
    ; copia superficial suficiente para editar
    z := {}
    for k,v in t
        z.%k% := v
    return z
}

; ---------------- Completadas ----------------
_RefreshCompleted() {
    global gTasksGui, gPanelComp
    ; borrar elementos previos “dibujados” en esta pestaña
    ; estrategia: eliminar todo control que esté en la misma área
    for ctrl in gTasksGui {
        ctrl.GetPos(&x,&y,&w,&h)
        if (y>=50 && y<=420) && (x>=20 && x<=770) {
            ; preservar el botón "Historial de Tareas" (está a y~430)
            if (ctrl.Type != "Button")
                try ctrl.Destroy()
        }
    }

    dates := TasksStore_Last3CompletedDates()
    y := 50
    for d in dates {
        gTasksGui.Add("Text", "x20 y" y " w740 +0x200", "Fecha: " d) ; +0x200 = SS_CENTERIMAGE
        y += 22
        lv := gTasksGui.Add("ListView", "x20 y" y " w750 h100 Grid", "Hora|Título")
        lv.ModifyCol(1, 120), lv.ModifyCol(2, 600)

        ; rellenar esa fecha
        for t in TasksStore_All() {
            if t.completed && SubStr(t.completedAt,1,10) = d {
                hour := SubStr(t.completedAt, 12)   ; "hh:mm tt"
                lv.Add("", hour, t.title)
            }
        }
        y += 110
        if (y > 360)
            break
    }
}

_ShowHistory() {
    global gHistGui
    if gHistGui {
        gHistGui.Show()
        return
    }
    gHistGui := Gui("+Owner", "Historial de Tareas")
    lv := gHistGui.Add("ListView", "x10 y10 w560 h300 Grid", "Fecha|Título|Acción")
    lv.ModifyCol(1, 160), lv.ModifyCol(2, 240), lv.ModifyCol(3, 140)

    ; últimas 50 por completedAt desc (o updatedAt si no completada)
    arr := []
    for t in TasksStore_All() {
        k := (t.completedAt != "") ? t.completedAt : t.updatedAt
        arr.Push({ k:k, t:t })
    }
    arr.Sort((a,b) => (a.k < b.k) ? 1 : (a.k > b.k) ? -1 : 0)
    i := 0
    for it in arr {
        t := it.t
        ++i
        if (i>50)
            break
        lv.Add("", (t.completedAt!="")?t.completedAt:t.updatedAt, t.title, _ActionText(t))
    }

    btnOpen := gHistGui.Add("Button", "x10 y320 w180", "Abrir carpeta de tareas")
    btnOpen.OnEvent("Click", (*) => Run(A_ScriptDir "\tareas"))

    btnClose := gHistGui.Add("Button", "x+10 w120", "Cerrar")
    btnClose.OnEvent("Click", (*) => gHistGui.Hide())

    gHistGui.Show()
}

; Mostrar / ocultar AlwaysOnTop mientras Tareas está abierta
_Tasks_TopMostOff() {
    global gGui, gTasksGui, _Tasks_WasTopMost
    if IsSet(gGui) && gGui {
        if _IsTopMost(gGui.Hwnd) {
            _Tasks_WasTopMost := true
            gGui.Opt("-AlwaysOnTop")
        } else {
            _Tasks_WasTopMost := false
        }
    }
    ; por si en algún momento marcas Tareas como topmost, también lo bajamos
    if IsSet(gTasksGui) && gTasksGui && _IsTopMost(gTasksGui.Hwnd)
        gTasksGui.Opt("-AlwaysOnTop")
}

_Tasks_TopMostRestore(*) {
    global gGui, _Tasks_WasTopMost
    if _Tasks_WasTopMost && IsSet(gGui) && gGui
        gGui.Opt("+AlwaysOnTop")
    _Tasks_WasTopMost := false
}

_IsTopMost(hwnd) {
    ex := DllCall("user32\GetWindowLongPtr", "ptr", hwnd, "int", -20, "ptr")
    WS_EX_TOPMOST := 0x00000008
    return (ex & WS_EX_TOPMOST) != 0
}

; --- Error dialog watcher ---
global _ErrWatchOn := false

_ErrWatch_Start() {
    global _ErrWatchOn
    if _ErrWatchOn
        return
    _ErrWatchOn := true
    SetTimer _ErrWatch_Tick, 250
}

_ErrWatch_Stop(*) {
    global _ErrWatchOn
    _ErrWatchOn := false
    SetTimer _ErrWatch_Tick, 0
}

_ErrWatch_Tick() {
    ; Los errores de AHK son diálogos (#32770) cuyo texto contiene "Error:"
    for hwnd in WinGetList("ahk_class #32770") {
        text := ""
        try text := WinGetText("ahk_id " hwnd)
        if InStr(text, "Error:") {
            ; Sube el diálogo y garantiza visibilidad
            WinActivate "ahk_id " hwnd
            try {
                WinSetAlwaysOnTop true,  "ahk_id " hwnd
                Sleep 30
                WinSetAlwaysOnTop false, "ahk_id " hwnd
            }
            return
        }
    }
}
