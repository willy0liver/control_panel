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

; === Config y estado =====================================================
TasksStore_Dir() {
    static dir := A_ScriptDir "\tareas"   ; cambia si prefieres otra carpeta
    return dir
}

; Llama una sola vez al iniciar Tareas_Show()
TasksStore_Init() {
    dir := TasksStore_Dir()
    if !DirExist(dir) {
        try DirCreate(dir)
        catch as e
            MsgBox("No se pudo crear la carpeta de tareas:`n" dir "`n`n" e.Message, "Error", "Iconx")
    }
    ; Si cargas tareas desde disco, déjalo como lo tenías aquí.
    _LoadDirTasks()
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

; === API principal =======================================================

TasksStore_Add(task) {
    task := _AsMap(task)                        ; normaliza a Map()
    if (!task.Has("id") || _IsBlank(task["id"]))
        task["id"] := _TasksStore_NewId()       ; id nuevo si falta
    _EnsureTaskDefaults(task)
    _TasksStore_Persist(task)                   ; escribe a disco
    _TasksStore_AddToMemory(task)               ; y a memoria
}

TasksStore_Update(id, task) {
    task := _AsMap(task)
    task["id"] := id
    _EnsureTaskDefaults(task)
    _TasksStore_Persist(task)
    _TasksStore_UpdateInMemory(id, task)
}

_TasksStore_UpdateInMemory(id, task) {
    arr := TasksStore_All()
    for i, t in arr {
        if _AsMap(t)["id"] = id {
            arr[i] := task
            return true
        }
    }
    return false
}

_TasksStore_AddToMemory(task) {
    global gTasksData
    gTasksData.tasks.Push(task)
}

TasksStore_UpdateById(id, patch) {
    t := _FindById(id)
    if !t
        return false
    t := _AsMap(t)
    for k,v in patch
        t[k] := v
    t["updatedAt"] := _NowString()
    TasksStore_SaveNow()
    return true
}

TasksStore_Delete(id) {
    arr := TasksStore_All()
    loop arr.Length {
        if _AsMap(arr[A_Index])["id"] = id {
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
    t := _AsMap(t)
    t["completed"] := completed
    if completed
        t["completedAt"] := _NowString()
    else
        t["completedAt"] := ""
    t["updatedAt"] := _NowString()
    TasksStore_SaveNow()
    return true
}

TasksStore_Last3CompletedDates() {
    ; devuelve últimas 3 fechas (YYYY-MM-DD) con tareas completadas
    seen := Map()
    dates := []
    for t in TasksStore_All() {
        ; Si por algún motivo hay un elemento no-objeto, lo ignoramos
        if !IsObject(t)
            continue
        t := _AsMap(t)
        if !(t is Map)
            continue
        comp   := t.Has("completed")   ? t["completed"]   : false
        compAt := t.Has("completedAt") ? t["completedAt"] : ""
        if comp && compAt != "" {
            d := SubStr(compAt, 1, 10)  ; YYYY-MM-DD
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

; === Utilidades internas =================================================

_TasksStore_NewId() {
    ; timestamp + tickcount (sin caracteres inválidos)
    ; OJO: en AHK v2 el formato va en el 2º parámetro
    ts := FormatTime(, "yyyyMMddHHmmss")
    return ts "_" A_TickCount
}

; Convierte recursivamente cualquier estructura (Object/Array/Map)
; a algo serializable por JXON (Map y Array).
_TasksStore_ToJsonReady(x) {
    if !IsObject(x)
        return x
    if (x is Array) {
        out := []
        for , v in x
            out.Push(_TasksStore_ToJsonReady(v))
        return out
    }
    ; Map o Object genérico -> siempre lo convertimos a Map
    out := Map()
    for k, v in x
        out[k] := _TasksStore_ToJsonReady(v)
    return out
}

_TasksStore_Persist(task) {
    task := _AsMap(task)
    dir := TasksStore_Dir()
    if !DirExist(dir) {
        try DirCreate(dir)
        catch as e {
            MsgBox("No se pudo crear la carpeta de tareas:`n" dir "`n`n" e.Message, "Error", "Iconx")
            return false
        }
    }
    id := task.Has("id") ? task["id"] : ""
    if _IsBlank(id)
        id := _TasksStore_NewId(), task["id"] := id
    ; Blindaje extra: por si viniera con algún caracter inválido
    id := RegExReplace(id, '[:\\/\\*\?"<>|]', "-")
    path := dir "\" id ".json"

    json := Jxon_Dump(_TasksStore_ToJsonReady(task))
    try {
        f := FileOpen(path, "w", "UTF-8")
        f.Write(json), f.Close()
    } catch as e {
        try f.Close()
        MsgBox("No se pudo guardar la tarea:`n" path "`n`n" e.Message, "Error", "Iconx")
        return false
    }
    return true
}

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
    ; 1) persistir cada tarea a su propio archivo (mantiene estado actualizado)
    for t in TasksStore_All()
        _TasksStore_Persist(t)
    ; 2) (opcional) snapshot agregado tasks.json como respaldo
    global gTasksData
    path := TasksStore_Path()
    json := _DumpJson(gTasksData)
    f := FileOpen(path, "w", "UTF-8")
    f.Write(json), f.Close()
}

_FindById(id) {
    for t in TasksStore_All()
        if _AsMap(t)["id"] = id
            return t
    return 0
}


_EnsureTaskDefaults(t) {
    t := _AsMap(t)
    if !t.Has("id")          t["id"] := ""
    if !t.Has("title")       t["title"] := ""
    if !t.Has("trigger")     t["trigger"] := Map("type","off") ; off|at|interval
    if !t.Has("action")      t["action"] := Map("type","openUrl","value","")
    if !t.Has("inProgress")  t["inProgress"] := false
    if !t.Has("completed")   t["completed"] := false
    if !t.Has("completedAt") t["completedAt"] := ""
    if !t.Has("createdAt")   t["createdAt"] := _NowString()
    if !t.Has("updatedAt")   t["updatedAt"] := t["createdAt"]
    ; scheduler helpers
    if !t.Has("lastDateRun") t["lastDateRun"] := ""   ; YYYY-MM-DD
    if !t.Has("nextRunAt")   t["nextRunAt"] := ""     ; YYYY-MM-DD HH:mm tt
    return t
}

; --- Normalizadores/ayudas ----------------------------------------------
_AsMap(x) {
    if (x is Map)
        return x
    if !IsObject(x)       ; primitivos
        return x
    ; Object {} -> Map() recursivo
    out := Map()
    for k, v in x
        out[k] := _AsMap(v)
    return out
}

_IsBlank(v) {
    return (!IsObject(v) && Trim(v "") = "")
}

; ---------- NUEVO: cargar todas las tareas desde /tareas/*.json ----------
_LoadDirTasks() {
    global gTasksData
    arr := []
    dir := TasksStore_Dir()
    Loop Files, dir "\*.json" {
        txt := ""
        try {
            txt := FileRead(A_LoopFileFullPath, "UTF-8")
        } catch {
            continue
        }
        ; quitar BOM si lo hay
        txt := RegExReplace(txt, "^\xEF\xBB\xBF")
        v := 0
        ; primero intentamos el loader de comillas simples (Jxon_Dump)
        try v := Jxon_Load2(&txt)
        catch {
            ; si el archivo tiene JSON estándar (comillas dobles)
            try v := Jxon_Load(&txt)
            catch {
                v := 0
            }
        }
        if !IsObject(v)
            continue

        t := _AsMap(v)
        ; si no trae id, usamos el nombre del archivo
        id := t.Has("id") ? t["id"] : ""
        if _IsBlank(id) {
            SplitPath(A_LoopFileFullPath, &name)
            t["id"] := name
        }
        ; completar defaults (crea createdAt si está vacío)
        _EnsureTaskDefaults(t)
        ; fallback extra: si sigue sin createdAt, usar hora del archivo
        if _IsBlank(t["createdAt"]) {
            try {
                ts := FileGetTime(A_LoopFileFullPath, "M")
                t["createdAt"] := FormatTime(ts, "yyyy-MM-dd hh:mm tt")
            }
        }
        arr.Push(t)
    }
    gTasksData := { tasks: arr }
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

