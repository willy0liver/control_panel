; ============================================
; TasksStore.ahk  (AHK v2)
; Persistencia y utilitarios de tareas
; - API:
;   TasksStore_Init()
;   TasksStore_All()                   -> Array de tareas (en memoria)
;   TasksStore_Add(taskObj)            -> id
;   TasksStore_UpdateById(id, patch)
;   TasksStore_Delete(id)
;   TasksStore_SetCompleted(id, completed := true)
;   TasksStore_SaveNow()
;   TasksStore_Path()
;   TasksStore_Last3CompletedDates()   -> Array fechas (YYYY-MM-DD) desc
; ============================================

#Include ../../Assets/Json.ahk

global gTasksData := { tasks: [] }
global gTasksLoaded := false

TasksStore_Init() {
    global gTasksLoaded
    if gTasksLoaded
        return
    _LoadFromDisk()
    gTasksLoaded := true
}

TasksStore_Path() {
    base := A_ScriptDir "\tareas"
    if !DirExist(base)
        DirCreate(base)
    return base "\tasks.json"
}

TasksStore_All() {
    global gTasksData
    return gTasksData.tasks
}

TasksStore_Add(task) {
    _EnsureTaskDefaults(task)
    task.id := _NewId()
    task.createdAt := _NowString()
    task.updatedAt := task.createdAt
    TasksStore_All().Push(task)
    TasksStore_SaveNow()
    return task.id
}

TasksStore_UpdateById(id, patch) {
    t := _FindById(id)
    if !t
        return false
    for k,v in patch
        t.%k% := v
    t.updatedAt := _NowString()
    TasksStore_SaveNow()
    return true
}

TasksStore_Delete(id) {
    arr := TasksStore_All()
    loop arr.Length {
        if arr[A_Index].id = id {
            arr.RemoveAt(A_Index)
            TasksStore_SaveNow()
            return true
        }
    }
    return false
}

TasksStore_SetCompleted(id, completed := true) {
    t := _FindById(id)
    if !t
        return false
    t.completed := completed
    if completed
        t.completedAt := _NowString()
    else
        t.completedAt := ""
    t.updatedAt := _NowString()
    TasksStore_SaveNow()
    return true
}

TasksStore_Last3CompletedDates() {
    ; devuelve últimas 3 fechas (YYYY-MM-DD) con tareas completadas
    seen := Map()
    dates := []
    for t in TasksStore_All() {
        if t.completed && t.completedAt != "" {
            d := SubStr(t.completedAt, 1, 10)  ; YYYY-MM-DD
            if !seen.Has(d) {
                seen[d] := true
                dates.Push(d)
            }
        }
    }
    ; ordenar desc
    ; NEW (compatible y simple)
    dates := _Tasks_SortDatesDesc(dates)
    if (dates.Length > 3)
        dates.Length := 3
    return dates
}

; Ordena un array de fechas YYYY-MM-DD en orden descendente (compat v2 sin Array.Sort)
_Tasks_SortDatesDesc(arr) {
    if !(arr is Array) || arr.Length <= 1
        return arr
    s := ""
    for d in arr
        s .= d "`n"
    s := RTrim(s, "`n")
    s := Sort(s, "R")                 ; "R" = reverse (desc); lexicográfico sirve para YYYY-MM-DD
    return StrSplit(s, "`n")
}


; ---------- Internos ----------

_LoadFromDisk() {
    global gTasksData
    path := TasksStore_Path()
    if !FileExist(path) {
        gTasksData := { tasks: [] }
        return
    }
    txt := ""
    try txt := FileRead(path, "UTF-8")
    catch {
        gTasksData := { tasks: [] }
        return
    }
    txt := RegExReplace(txt, "^\xEF\xBB\xBF")
    v := Trim(txt, "`r`n`t ")
    data := 0
    ;try data := Jxon_Load(&v)      ; usa tu Assets\Json.ahk
    try data := Jxon_Load2(&v)      ; usa tu Assets\Json.ahk    
    catch {
        data := 0
    }
    if !IsObject(data) || !ObjHasOwnProp(data, "tasks") || !(data.tasks is Array)
        data := { tasks: [] }
    ; normalizar
    for t in data.tasks
        _EnsureTaskDefaults(t)
    gTasksData := data
}

TasksStore_SaveNow() {
    global gTasksData
    path := TasksStore_Path()
    json := _DumpJson(gTasksData)
    f := FileOpen(path, "w", "UTF-8")
    f.Write(json)
    f.Close()
}

_FindById(id) {
    for t in TasksStore_All()
        if t.id = id
            return t
    return 0
}


_EnsureTaskDefaults(t) {
    if !ObjHasOwnProp(t, "id"){
        t.id := ""
    }
    if !ObjHasOwnProp(t, "title"){
        t.title := ""
    }
    if !ObjHasOwnProp(t, "trigger"){
        t.trigger := { type:"off" }  ; off|at|interval
    }
    if !ObjHasOwnProp(t, "action"){
        t.action := { type:"openUrl", value:"" }
    }
    if !ObjHasOwnProp(t, "inProgress"){
        t.inProgress := false
    }
    if !ObjHasOwnProp(t, "completed"){
        t.completed := false
    }
    if !ObjHasOwnProp(t, "completedAt"){
        t.completedAt := ""
    }
    if !ObjHasOwnProp(t, "createdAt"){
        t.createdAt := _NowString()
    }
    if !ObjHasOwnProp(t, "updatedAt"){
        t.updatedAt := t.createdAt
    }
    ; scheduler helpers
    if !ObjHasOwnProp(t, "lastDateRun"){
        t.lastDateRun := ""   ; para type=at (YYYY-MM-DD ya ejecutó)
    }
    if !ObjHasOwnProp(t, "nextRunAt"){
        t.nextRunAt := ""     ; para type=interval (YYYY-MM-DD HH:mm tt)
    }
}

_NewId() {
    buf := Buffer(16)
    DllCall("ole32\CoCreateGuid", "ptr", buf)
    p := BufToHex(buf)
    return SubStr(p,1,8) "-" SubStr(p,9,4) "-" SubStr(p,13,4) "-" SubStr(p,17,4) "-" SubStr(p,21,12)
}

BufToHex(buf) {
    s := ""
    loop buf.Size {
        b := NumGet(buf, A_Index-1, "UChar")
        s .= Format("{:02X}", b)
    }
    return s
}

_NowString() {
    f := FormatTime(, "yyyy-MM-dd hh:mm tt")
    return f
}

; -------- Pequeño dumper JSON (suficiente para nuestro esquema) --------
_DumpJson(v) {
    t := Type(v)
    if (t = "String") {
        return _Jstr(v)
    } else if (t = "Integer" || t = "Float") {
        return v ""
    } else if (t = "Array") {
        parts := []
        for itm in v
            parts.Push(_DumpJson(itm))
        return "[" . StrJoin(parts, ",") . "]"
    } else if (t = "Map" || t = "Object") {
        parts := []
        for k,val in v
            parts.Push(_Jstr(k) ":" _DumpJson(val))
        return "{" . StrJoin(parts, ",") . "}"
    } else if (t = "Boolean") {
        return v ? "true" : "false"
    } else if (v = "" || v = 0) {
        ; usar "" para null-like del proyecto
        return _Jstr("")
    }
    return _Jstr(v "")
}

_Jstr(s) {
    s := StrReplace(s, "\", "\\")
    s := StrReplace(s, "`t", "\t")
    s := StrReplace(s, "`r", "\r")
    s := StrReplace(s, "`n", "\n")
    s := StrReplace(s, "''", "\''")
    return "''" s "''"
}

StrJoin(arr, sep:=",") {
    out := ""
    for i,v in arr
        out .= (i>1 ? sep : "") v
    return out
}

