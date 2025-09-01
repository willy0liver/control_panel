; ============================================
; TasksStore.ahk  (AHK v2)
; Persistencia y utilitarios de tareas
; >>> Modelo de 1 archivo por día: YYYYMMDD.json
;
;  API pública:
;   - TasksStore_Init()
;   - TasksStore_All()                   -> Array de tareas (en memoria; normalmente las de HOY)
;   - TasksStore_Add(taskObj)            -> id
;   - TasksStore_Update(id, taskObj)
;   - TasksStore_UpdateById(id, patch)
;   - TasksStore_Delete(id)
;   - TasksStore_SetCompleted(id, completed := true)
;   - TasksStore_SaveNow()               -> persiste a YYYYMMDD.json de HOY
;   - TasksStore_Last3CompletedDates()   -> Array fechas (YYYY-MM-DD) desc (basado en tareas cargadas)
;   - TasksStore_Dir()
;   - TasksStore_Path()                  -> ruta del archivo de HOY (YYYYMMDD.json)
; ============================================

#Include ../../Assets/Json.ahk

global gTasksData := { tasks: [] }  ; SIEMPRE mantiene en memoria el conjunto actual (normalmente HOY)

; === Config y helpers de fecha/archivos ==================================

TasksStore_Dir() {
    static dir := A_ScriptDir "\tareas"
    return dir
}

_TodayYYYYMMDD() {
    return FormatTime(, "yyyyMMdd")
}

_DailyPath(dateYYYYMMDD) {
    return TasksStore_Dir() "\" dateYYYYMMDD ".json"
}

TasksStore_Path() {
    ; utilidad: devuelve el path del archivo del día actual
    return _DailyPath(_TodayYYYYMMDD())
}

_EnsureDir() {
    dir := TasksStore_Dir()
    if !DirExist(dir) {
        try DirCreate(dir)
        catch as e
            MsgBox("No se pudo crear la carpeta de tareas:`n" dir "`n`n" e.Message, "Error", "Iconx")
    }
}

_ListDailyFiles() {
    arr := []
    Loop Files, TasksStore_Dir() "\*.json", "F" {
        if RegExMatch(A_LoopFileName, "^\d{8}\.json$")
            arr.Push(A_LoopFileFullPath)
    }
    return arr
}

_FindLatestDailyFile() {
    files := _ListDailyFiles()
    if files.Length = 0
        return ""
    names := []
    for f in files {
        SplitPath f, &name
        names.Push(name)
    }
    ; ordenar descendente por nombre (YYYYMMDD.json)
    names := StrSplit(Sort(StrJoin(names, "`n"), "R"), "`n")
    return TasksStore_Dir() "\" names[1]
}

_LoadJsonFile(path) {
    if !FileExist(path)
        return { tasks: [] }
    txt := ""
    try txt := FileRead(path, "UTF-8")
    catch
        return { tasks: [] }

    txt := RegExReplace(txt, "^\xEF\xBB\xBF")
    v := Trim(txt, "`r`n`t ")
    data := 0
    try
        data := Jxon_Load2(&v)
    catch
        data := 0

    if !IsObject(data) || !ObjHasOwnProp(data, "tasks") || !(data.tasks is Array)
        data := { tasks: [] }

    ; normalizar (y reescribir dentro del array)
    for i, t in data.tasks
        data.tasks[i] := _EnsureTaskDefaults(t)

    return data
}

_SaveJsonFile(path, data) {
    ; Serialización robusta (sin depender de JXON al escribir)
    json := _DumpJsonStrict(data)
    f := 0
    try {
        f := FileOpen(path, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as e {
        try f.Close()
        MsgBox("No se pudo guardar:`n" path "`n`n" e.Message, "Error", "Iconx")
    }
}

; ===== Dumper JSON simple y robusto (usa comillas dobles) =================

_DumpJson(v) {
    t := Type(v)
    if (t = "String") {
        return _JQ(v)
    } else if (t = "Integer" || t = "Float") {
        return v ""   ; números tal cual (booleans en AHK son enteros 0/1 y funcionan)
    } else if (t = "Array") {
        parts := []
        for itm in v
            parts.Push(_DumpJson(itm))
        return "[" . StrJoin(parts, ",") . "]"
    } else if (t = "Map" || t = "Object") {
        parts := []
        ; Intento de enumeración directa
        ok := true
        try {
            for k, val in v
                parts.Push(_JQ(k) ":" _DumpJson(val))
        } catch {
            ok := false
        }
        if !ok {
            ; Fallback: recorrer solo propiedades propias (si el objeto no es enumerable)
            try {
                for k in _OwnPropNames(v) {
                    val := ""
                    try val := v.%k%
                    parts.Push(_JQ(k) ":" _DumpJson(val))
                }
            }
        }
        return "{" . StrJoin(parts, ",") . "}"
    } else if (v = "" || v = 0) {
        ; Para “null-like” del proyecto puedes devolver "" (string vacío)
        ; Si prefieres null JSON estándar, usa: return "null"
        return _JQ("")
    }
    ; Cualquier otro tipo raro -> a string
    return _JQ(v "")
}

_JQ_v0(s) {
    ; Escapes básicos JSON
    s := StrReplace(s, "\", "\\")
    s := StrReplace(s, '""', '\""')
    s := StrReplace(s, '`r', "\r")
    s := StrReplace(s, "`n", "\n")
    s := StrReplace(s, "`t", "\t")
    return '""' s '""'
}

_JQ(s) {
    ; Escapes básicos JSON
    s := StrReplace(s, "\", "\\")
    s := StrReplace(s, '"', '\"')
    s := StrReplace(s, '`r', "\r")
    s := StrReplace(s, "`n", "\n")
    s := StrReplace(s, "`t", "\t")
    return '"' s '"'
}

_OwnPropNames(obj) {
    ; Devuelve nombres de propiedades “propias” cuando el objeto no es enumerable
    ; No todos los objetos necesitan esto; es un fallback seguro.
    names := []
    ; Si ObjOwnProps no existe, esto seguirá protegiendo con try/catch
    try {
        ; En muchos builds de AHK v2 no hay API directa para listar,
        ; así que aquí no hacemos nada especial: devolvemos vacío.
        ; (si tu build aporta algo, puedes rellenarlo aquí)
    }
    return names
}



; === Inicialización: cargar HOY o migrar pendientes desde el último ======

TasksStore_Init() {
    _EnsureDir()
    _LoadTodayOrMigrate()
}

_LoadTodayOrMigrate() {
    global gTasksData
    _EnsureDir()

    today := _TodayYYYYMMDD()
    pathToday := _DailyPath(today)

    ; Si existe hoy → cargarlo y listo
    if FileExist(pathToday) {
        gTasksData := _LoadJsonFile(pathToday)
        return
    }

    ; No existe hoy → buscar último archivo
    latest := _FindLatestDailyFile()
    if (latest = "") {
        ; no hay nada previo → crear el de hoy vacío
        gTasksData := { tasks: [] }
        _SaveJsonFile(pathToday, gTasksData)
        return
    }

    ; Migración: trae PENDIENTES del último archivo hacia HOY
    prev := _LoadJsonFile(latest)
    pend := []
    done := []

    for t in prev.tasks {
        tt := _EnsureTaskDefaults(t)
        if (tt["completed"])
            done.Push(tt)
        else
            pend.Push(tt)
    }

    ; HOY = pendientes (si hay)
    gTasksData := { tasks: pend }
    _SaveJsonFile(pathToday, gTasksData)

    ; El anterior queda solo con completadas
    if (pend.Length > 0) {
        _SaveJsonFile(latest, { tasks: done })
    }
}

; === Lectura en memoria ===================================================

TasksStore_All() {
    global gTasksData
    return gTasksData.tasks
}

; === API principal (escrituras SIEMPRE contra el archivo de HOY) =========

TasksStore_Add(task) {
    task := _AsMap(task)
    if (!task.Has("id") || _IsBlank(task["id"]))
        task["id"] := _TasksStore_NewId()
    _EnsureTaskDefaults(task)

    _TasksStore_AddToMemory(task)
    TasksStore_SaveNow()
    return task["id"]
}

TasksStore_Update(id, task) {
    task := _AsMap(task)
    task["id"] := id
    _EnsureTaskDefaults(task)

    _TasksStore_UpdateInMemory(id, task)
    TasksStore_SaveNow()
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

TasksStore_SaveNow() {
    global gTasksData
    _EnsureDir()
    path := _DailyPath(_TodayYYYYMMDD())
    _SaveJsonFile(path, gTasksData)
}

; === Consultas auxiliares (basadas en las tareas cargadas actualmente) ===

TasksStore_Last3CompletedDates() {
    ; Fechas (YYYY-MM-DD) con alguna tarea completada en el conjunto cargado (normalmente HOY)
    seen := Map()
    dates := []
    for t in TasksStore_All() {
        t := _AsMap(t)
        comp := t.Has("completed") ? t["completed"] : false
        compAt := t.Has("completedAt") ? t["completedAt"] : ""
        if comp && compAt != "" {
            d := SubStr(compAt, 1, 10)  ; YYYY-MM-DD
            if !seen.Has(d) {
                seen[d] := true
                dates.Push(d)
            }
        }
    }
    dates := _Tasks_SortDatesDesc(dates)
    if (dates.Length > 3)
        dates.Length := 3
    return dates
}

_Tasks_SortDatesDesc(arr) {
    if !(arr is Array) || arr.Length <= 1
        return arr
    s := ""
    for d in arr
        s .= d "`n"
    s := RTrim(s, "`n")
    s := Sort(s, "R")   ; lexicográfico sirve para YYYY-MM-DD
    return StrSplit(s, "`n")
}

; === Internos =============================================================

_TasksStore_NewId() {
    ; timestamp + tickcount para que sea único y ordenable
    ts := FormatTime("yyyyMMddHHmmss")
    return ts "_" A_TickCount
}

; Convierte recursivamente cualquier estructura (Object/Array/Map)
; a algo serializable: se deja para compat con otras funciones de lectura.
_TasksStore_ToJsonReady(x) {
    if !IsObject(x)
        return x

    ; Arrays -> []
    if (x is Array) {
        out := []
        for , v in x
            out.Push(_TasksStore_ToJsonReady(v))
        return out
    }

    ; Map() u Object() -> {} (plain object)
    out := {}
    ok := true
    try {
        ; Enumeración directa (rápida)
        for k, v in x
            out.%k% := _TasksStore_ToJsonReady(v)
    } catch {
        ok := false
    }
    if !ok {
        ; Fallback: enumerar solo props propias por nombre
        try {
            for k in ObjOwnProps(x) {
                val := ""
                try val := x.%k%
                out.%k% := _TasksStore_ToJsonReady(val)
            }
        }
    }
    return out
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
    ; helpers scheduler
    if !t.Has("lastDateRun") t["lastDateRun"] := ""   ; YYYY-MM-DD
    if !t.Has("nextRunAt")   t["nextRunAt"] := ""     ; YYYY-MM-DD HH:mm tt
    return t
}

; --- Normalizadores/ayudas ----------------------------------------------

_AsMap(x) {
    if (x is Map)
        return x
    if !IsObject(x)
        return x
    if (x is Array) {
        outA := []
        for , v in x
            outA.Push(_AsMap(v))
        return outA
    }
    out := Map()
    for k, v in x
        out[k] := _AsMap(v)
    return out
}

_IsBlank(v) {
    return (!IsObject(v) && Trim(v "") = "")
}

_NewId() {  ; opcional, no usado
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
    return FormatTime(, "yyyy-MM-dd hh:mm tt")
}

; -------- Utilidad simple de join para strings ---------------------------

StrJoin(arr, sep:=",") {
    out := ""
    for i,v in arr
        out .= (i>1 ? sep : "") v
    return out
}

; ========== SERIALIZADOR JSON ROBUSTO (doble comilla) ==========
_DumpJsonStrict(v) {
    t := Type(v)
    if (t = "String") {
        return _dq(_esc(v))
    } else if (t = "Integer" || t = "Float") {
        return v ""
    } else if (t = "Array") {
        parts := []
        for itm in v
            parts.Push(_DumpJsonStrict(itm))
        return "[" . StrJoin(parts, ",") . "]"
    } else if (t = "Map" || t = "Object") {
        parts := []
        ; Intentar enumeración directa
        ok := true
        try {
            for k,val in v
                parts.Push(_dq(_esc(k "")) ":" _DumpJsonStrict(val))
        } catch {
            ok := false
        }
        if !ok {
            ; Fallback: solo props propias
            try {
                for k in ObjOwnProps(v) {
                    temp := ""
                    try temp := v.%k%
                    parts.Push(_dq(_esc(k "")) ":" _DumpJsonStrict(temp))
                }
            }
        }
        return "{" . StrJoin(parts, ",") . "}"
    } else if (t = "Boolean") {
        return v ? "true" : "false"
    } else if (v = "" || v = 0) {
        ; usa null para vacíos genéricos
        return "null"
    }
    ; fallback: string
    return _dq(_esc(v ""))
}

_esc(s) {
    s := StrReplace(s, "\", "\\")
    s := StrReplace(s, '""', '\""')
    s := StrReplace(s, "`t", "\t")
    s := StrReplace(s, "`r", "\r")
    s := StrReplace(s, "`n", "\n")
    return s
}
_dq(s) {
    return '""' s '""'
}