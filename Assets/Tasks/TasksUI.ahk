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

; Lector seguro para Map() y Object {}
_KV(obj, key, def:="") {
    if !IsObject(obj)
        return def
    if (obj is Map)
        return obj.Has(key) ? obj[key] : def
    try {
        if ObjHasOwnProp(obj, key)
            return obj.%key%
    }
    return def
}

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
        if _KV(t, "completed", false)
            continue
        gLV_Pend.Add(
            ""
        , _KV(t, "title", "")
        , _TriggerText(t)
        , _ActionText(t)
        , (_KV(t, "inProgress", false) ? "Sí" : "No")
        , _KV(t, "createdAt", "")
        , _KV(t, "id", "")      ; <-- columna 6 (oculta)
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
        : Map(
            "title", "",
            "trigger", Map("type", "off"),
            "action",  Map("type", "openUrl", "value", ""),
            "inProgress", false,
            "completed",  false,
            "completedAt", ""
        )

    title := isEdit ? "Editar Tarea" : "Nueva Tarea"
    dlg := Gui("+Owner" gTasksGui.Hwnd, title)
    dlg.OnEvent("Close", (*)  => dlg.Destroy())
    dlg.OnEvent("Escape", (*) => dlg.Destroy())

    ; ---- Título ---------------------------------------------------------
    dlg.Add("Text",, "Título:")
    edTitle := dlg.Add("Edit", "w360", _KV(t, "title", ""))

    ; ---- Trigger (valores iniciales seguros) ----
    trig      := _KV(t, "trigger", Map())
    tTrigType := _KV(trig, "type", "off")
    tAtTime   := _KV(trig, "time", "")
    tMins     := _KV(trig, "minutes", "")

    dlg.Add("GroupBox", "xm w360 h95", "Trigger")
    ddTrig := dlg.Add("DropDownList", "xp+10 yp+20 w120", ["off","at","interval"])
    edTime := dlg.Add("Edit", "x+10 w90",  (tTrigType="at") ? tAtTime : "")
    edMins := dlg.Add("Edit", "x+10 w70 Number", (tTrigType="interval") ? tMins : "")
    ddTrig.Choose( (tTrigType="interval") ? 3 : (tTrigType="at") ? 2 : 1 )
    

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

    ; ---- Acción (valores iniciales seguros) ----
    dlg.Add("GroupBox", "xm w360 h95", "Acción")
    ddAct := dlg.Add("DropDownList", "xp+10 yp+20 w120", ["openUrl","run","sendText","ahk"])

    act   := _KV(t, "action", Map())
    aType := _KV(act, "type",  "openUrl")
    aVal  := _KV(act, "value", "")

    edVal := dlg.Add("Edit", "x+10 w220", aVal)
    ddAct.Choose( (aType="run") ? 2 : (aType="sendText") ? 3 : (aType="ahk") ? 4 : 1 )

    ; ---- Estado ---------------------------------------------------------
    chkInProgress := dlg.Add("CheckBox", "xm w200", "En proceso")
    chkInProgress.Value := _KV(t, "inProgress", false) ? 1 : 0

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
            return Map("type", "off")
        if (typ = "at")
            return Map("type", "at", "time", Trim(edTime.Value))
        if (typ = "interval")
            return Map("type", "interval", "minutes", Integer(Trim(edMins.Value)))
        ; fallback
        return Map("type", "off")
    }

    _UiReadAction() {
        aType := ddAct.Text
        val   := Trim(edVal.Value)
        return Map("type", aType, "value", val)
    }

    SaveAndClose(*) {
        t := Map(
            "id",         (isEdit ? editId : ""),
            "title",      Trim(edTitle.Value),
            "trigger",    _UiReadTrigger(),   ; <-- devuelve Map()
            "action",     _UiReadAction(),    ; <-- devuelve Map()
            "inProgress", chkInProgress.Value = 1,
            "completed",  false,
            "completedAt",""
            )

        if (Trim(edTitle.Value) = "") {
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
    TasksStore_UpdateById(id, { inProgress: !_KV(t, "inProgress", false) })
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
    if (_KV(_KV(t,"trigger",Map()), "type", "off") = "off") {
        MsgBox("Esta tarea ya está desactivada. Edita la tarea para configurar el trigger.")
        return
    }
    ; pausa / reanuda → si estaba activo, la pasamos temporalmente a off; si estaba offTemp, restaurar
    if !_KV(t, "triggerPaused", false) {
        ; pausar
        TasksStore_UpdateById(id, { triggerPaused: true, triggerBackup: _KV(t,"trigger",Map()), trigger: {type:"off"} })
    } else {
        ; reanudar
        trg := _KV(t, "triggerBackup", {type:"off"})
        TasksStore_UpdateById(id, { triggerPaused: false, trigger: trg })
    }
    _RefreshAll()
}

_TriggerText(t) {
    trig := _KV(t,"trigger",Map())
    typ  := _KV(trig,"type","off")
    if typ = "off"
        return "off"
    if typ = "at" {
        return "diario " _KV(trig,"time","")
    }
    if typ = "interval" {
        mins := _KV(trig,"minutes","")
        return "cada " mins " min"
    }
    return typ
}

_ActionText(t) {
    a := _KV(t,"action",Map())
    typ := _KV(a,"type","openUrl")
    if typ = "openUrl"
        return "openUrl"
    if typ = "run"
        return "run"
    if typ = "sendText"
        return "sendText"
    if typ = "ahk"
        return "ahk"
    return typ
}

_Find(id) {
    for t in TasksStore_All()
        if _KV(t, "id", "") = id
            return t
    return 0
}

_CloneTask(t) {
    if !t
        return 0
    return _DeepToMap(t)
}

; Convierte cualquier estructura (Object / Array / Map) a Map/Array (JSON-friendly)
_DeepToMap(x) {
    if !IsObject(x)
        return x
    if (x is Array) {
        out := []
        for , v in x
            out.Push(_DeepToMap(v))
        return out
    }
    ; Map u Object genérico -> Map
    out := Map()
    for k, v in x
        out[k] := _DeepToMap(v)
    return out
}


; ---------------- Completadas ----------------
_RefreshCompleted() {
    global gTasksGui, gPanelComp
    ; borrar elementos previos dibujados en el área de la pestaña "Completadas"
    for ctrl in gTasksGui {
        ctrl.GetPos(&x,&y,&w,&h)
        if (y>=50 && y<=420) && (x>=20 && x<=770) {
            ; preserva el botón "Historial de Tareas" (está aprox. en y~430)
            if (ctrl.Type != "Button")
                try ctrl.Destroy()
        }
    }

    dates := TasksStore_Last3CompletedDates()
    y := 50
    for d in dates {
        gTasksGui.Add("Text", "x20 y" y " w740 +0x200", "Fecha: " d) ; +0x200 = SS_CENTERIMAGE
        y += 22
        lv := gTasksGui.Add("ListView", "x20 y" y " w750 h100 Grid", ["Hora","Título"])
        lv.ModifyCol(1, 120), lv.ModifyCol(2, 600)

        ; rellenar esa fecha (uso de _KV para robustez)
        for t in TasksStore_All() {
            if _KV(t,"completed",false) {
                ts := _KV(t,"completedAt","")
                if (SubStr(ts,1,10) = d) {
                    hour := (StrLen(ts) >= 12) ? SubStr(ts, 12) : ""
                    lv.Add("", hour, _KV(t,"title",""))
                }
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
        compAt := _KV(t,"completedAt","")
        updAt  := _KV(t,"updatedAt","")
        k := (compAt != "") ? compAt : updAt
        arr.Push({ k:k, t:t })
    }
    arr.Sort((a,b) => (a.k < b.k) ? 1 : (a.k > b.k) ? -1 : 0)
    i := 0
    for it in arr {
        t := it.t
        ++i
        if (i>50)
            break
        compAt := _KV(t,"completedAt","")
        updAt  := _KV(t,"updatedAt","")
        lv.Add("", (compAt!="")?compAt:updAt, _KV(t,"title",""), _ActionText(t))
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
