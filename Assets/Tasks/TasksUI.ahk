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
    ;global gTasksGui, gGui
    _Tasks_TopMostOff()   ; baja temporalmente el Panel    
    static inited := false
    if !inited {
        TasksStore_Init()
        inited := true
    }
    _BuildGui()
    _RefreshAll()
    _ErrWatch_Start()     ; <<< vigila errores mientras Tareas esté abierta
    gTasksGui.Show()
}


_BuildGui() {
    global gTasksGui, gLV_Pend, gPanelComp
    gTasksGui := Gui("+AlwaysOnTop", "Tareas")
    tabs := gTasksGui.Add("Tab3", "x10 y10 w780 h480", ["Pendientes", "Completadas"])

    ; -------- Pestaña: Pendientes --------
    tabs.UseTab("Pendientes")
    gLV_Pend := gTasksGui.Add(
        "ListView"
    , "x20 y50 w750 h370 Grid"
    , ["Título","Trigger","Acción","Proc.","Creada","__id__"]  ; <-- col 6 oculta
    )
    gLV_Pend.ModifyCol(1, 250)
    gLV_Pend.ModifyCol(2, 140)
    gLV_Pend.ModifyCol(3, 140)
    gLV_Pend.ModifyCol(4, 60)
    gLV_Pend.ModifyCol(5, 160)
    gLV_Pend.ModifyCol(6, 0)  ; <-- oculta id


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
        gLV_Pend.Add(
            ""
        , t.title
        , _TriggerText(t)
        , _ActionText(t)
        , (t.inProgress ? "Sí" : "No")
        , t.createdAt
        , t.id                 ; <-- columna 6 (oculta)
        )
    }
}

_GetSelectedId() {
    global gLV_Pend
    row := gLV_Pend.GetNext(0, "F")
    return row ? gLV_Pend.GetText(row, 6) : ""   ; <-- lee col 6
}

_NewTaskDialog(editId := "") {
    global gTasksGui

    isEdit := (editId != "")
    t := isEdit
        ? _CloneTask(_Find(editId))
        : { title:"", trigger:{type:"off"}, action:{type:"openUrl",value:""}, inProgress:false, completed:false, completedAt:"" }

    title := isEdit ? "Editar Tarea" : "Nueva Tarea"
    dlg := Gui("+Owner" gTasksGui.Hwnd, title)
    dlg.OnEvent("Close", (*)  => dlg.Destroy())
    dlg.OnEvent("Escape", (*) => dlg.Destroy())

    ; ---- Título ---------------------------------------------------------
    dlg.Add("Text",, "Título:")
    edTitle := dlg.Add("Edit", "w360", t.title)

    ; ---- Trigger --------------------------------------------------------
    dlg.Add("GroupBox", "xm w360 h95", "Trigger")
    ddTrig := dlg.Add("DropDownList", "xp+10 yp+20 w120", ["off","at","interval"])
    edTime := dlg.Add("Edit", "x+10 w90"
    , (t.trigger.type = "at")
        ? (ObjHasOwnProp(t.trigger, "time") ? t.trigger.time : "")
        : ""
    )
    edMins := dlg.Add("Edit", "x+10 w70 Number"
    , (t.trigger.type = "interval")
        ? (ObjHasOwnProp(t.trigger, "minutes") ? t.trigger.minutes : "")
        : ""
    )

    ; elegir trigger inicial
    ddTrig.Choose( (t.trigger.type="interval") ? 3 : (t.trigger.type="at") ? 2 : 1 )

    ToggleTrigFields(*) {
        if (ddTrig.Text = "at") {
            edTime.Visible := true
            edMins.Visible := false
        } else if (ddTrig.Text = "interval") {
            edTime.Visible := false
            edMins.Visible := true
        } else {
            edTime.Visible := false
            edMins.Visible := false
        }
    }
    ddTrig.OnEvent("Change", ToggleTrigFields)
    ToggleTrigFields()

    ; ---- Acción ---------------------------------------------------------
    dlg.Add("GroupBox", "xm w360 h95", "Acción")
    ddAct := dlg.Add("DropDownList", "xp+10 yp+20 w120", ["openUrl","run","sendText","ahk"])
    edVal := dlg.Add("Edit", "x+10 w220", ObjHasOwnProp(t.action, "value") ? t.action.value : "")

    
    actIdx := 1
    aType := ObjHasOwnProp(t.action, "type") ? t.action.type : "openUrl"
    if (aType="run")
        actIdx := 2
    else
        if (aType="sendText")
            actIdx := 3
        else
            if (aType="ahk")
                actIdx := 4
    ddAct.Choose(actIdx)

    ; ---- Estado ---------------------------------------------------------
    chkInProgress := dlg.Add("CheckBox", "xm w200", "En proceso")
    chkInProgress.Value := t.inProgress ? 1 : 0

    ; ---- Botones --------------------------------------------------------
    btnSave := dlg.Add("Button", "xm w100", "Guardar")
    btnSave.OnEvent("Click", SaveAndClose)
    btnCancel := dlg.Add("Button", "x+m w100", "Cancelar")
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())

    dlg.Show()

    ; ---- Helpers locales (cierran sobre los controles) ------------------
    _UiReadTrigger() {
        typ := ddTrig.Text
        if (typ = "off")
            return { type:"off" }
        if (typ = "at")
            return { type:"at", time: Trim(edTime.Value) }
        ; interval
        mins := Integer(Trim(edMins.Value))
        if (mins < 1)
            mins := 1
        return { type:"interval", minutes: mins }
    }

    _UiReadAction() {
        return { type: ddAct.Text, value: Trim(edVal.Value) }
    }

    SaveAndClose(*) {
        t := {
            id: (isEdit ? editId : "")
          , title: Trim(edTitle.Value)
          , trigger: _UiReadTrigger()
          , action: _UiReadAction()
          , inProgress: chkInProgress.Value = 1
          , completed: false
          , completedAt: ""
        }

        if (t.title = "") {
            MsgBox("El título no puede estar vacío.", "Validación", "Icon!")
            return
        }

        if (isEdit)
            TasksStore_Update(editId, t)
        else
            TasksStore_Add(t)

        _RefreshAll()
        dlg.Destroy()
    }
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
        ;lv := gTasksGui.Add("ListView", "x20 y" y " w750 h100 Grid", "Hora|Título")
        lv := gTasksGui.Add("ListView", "x20 y" y " w750 h100 Grid", ["Hora","Título"])

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

; --- Error dialog watcher (reemplazo) --------------------
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
    static curr := 0  ; HWND del último diálogo de error manejado

    ; Si ya estamos gestionando uno y sigue abierto, no hagas nada.
    if (curr && WinExist("ahk_id " curr))
        return
    ; Si ya no existe, limpiamos y seguimos buscando.
    curr := 0

    ; Busca cualquier diálogo de error del intérprete AHK (#32770 + texto "Error:")
    for hwnd in WinGetList("ahk_class #32770") {
        text := ""
        try text := WinGetText("ahk_id " hwnd)
        if !InStr(text, "Error:")
            continue

        ; Traerlo al frente UNA sola vez y dejarlo AlwaysOnTop mientras exista.
        curr := hwnd
        try {
            WinActivate "ahk_id " hwnd
            WinSetAlwaysOnTop true, "ahk_id " hwnd   ; no lo “despulsemos” en bucle
        }
        return
    }
}
