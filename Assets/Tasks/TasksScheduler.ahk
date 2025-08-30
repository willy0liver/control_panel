#Requires AutoHotkey v2.0

; ============================================
; TasksScheduler.ahk (AHK v2)
; Motor simple de disparo de triggers
; - API:
;   Tasks_Init()            ; llama Store y arranca timer
;   TasksScheduler_Start()
;   TasksScheduler_Stop()
; ============================================

#Include ../../Assets/Tasks/TasksStore.ahk

global gTasksSchedulerOn := false

Tasks_Init() {
    TasksStore_Init()
    TasksScheduler_Start()
}

TasksScheduler_Start() {
    global gTasksSchedulerOn
    if gTasksSchedulerOn
        return
    gTasksSchedulerOn := true
    SetTimer(TasksScheduler_Tick, 30000) ; cada 30s
}

TasksScheduler_Stop() {
    global gTasksSchedulerOn
    if !gTasksSchedulerOn
        return
    gTasksSchedulerOn := false
    SetTimer(TasksScheduler_Tick, 0)
}

TasksScheduler_Tick(*) {
    now    := _NowString()
    today  := SubStr(now, 1, 10)
    nowHHm := FormatTime(, "HHmm")  ; 24h para comparar triggers "at"

    for t in TasksStore_All() {
        ; Normaliza por si vino como Object {} en vez de Map()
        t := _AsMap(t)

        ; Saltar completadas
        if (t.Has("completed") && t["completed"])
            continue

        trg := _AsMap( t.Has("trigger") ? t["trigger"] : Map() )
        typ := trg.Has("type") ? trg["type"] : "off"
        if (typ = "off")
            continue

        if (typ = "at") {
            hhmm := _NormalizeTimeToHHmm( trg.Has("time") ? trg["time"] : "" )
            if (hhmm = "")
                continue
            last := t.Has("lastDateRun") ? t["lastDateRun"] : ""
            if (last != today && nowHHm >= hhmm) {
                _RunTaskAction(t)
                t["lastDateRun"] := today
                t["updatedAt"]   := _NowString()
                TasksStore_SaveNow()
            }

        } else if (typ = "interval") {
            mins := trg.Has("minutes") ? Integer(trg["minutes"]) : 0
            if (mins < 1)
                continue

            next := t.Has("nextRunAt") ? t["nextRunAt"] : ""
            if (next = "") {
                t["nextRunAt"] := _AddMinutes(_NowString(), mins)
                t["updatedAt"] := _NowString()
                TasksStore_SaveNow()
            } else if (_NowGE(next, now)) {   ; corre si next <= now
                _RunTaskAction(t)
                t["nextRunAt"] := _AddMinutes(_NowString(), mins)
                t["updatedAt"] := _NowString()
                TasksStore_SaveNow()
            }
        }
    }
}


_RunTaskAction(t) {
    act := _KV(t, "action", Map())
    typ := _KV(act, "type", "")
    val := _KV(act, "value", "")
    try {
        if (typ = "openUrl") {
            if (val != "")
                Run(val)
        } else if (typ = "run") {
            if (val != "")
                Run(val)
        } else if (typ = "sendText") {
            if (val != "") {
                ClipSaved := ClipboardAll()
                A_Clipboard := val
                Send("^v")
                Sleep(50)
                A_Clipboard := ClipSaved
            }
        } else if (typ = "ahk") {
            ; ejecutar función por nombre si existe
            if (val != "") {
                fn := ""
                try fn := Func()
                if IsObject(fn)
                    fn.Call()
            }
        }
    } catch as e {
        ; puedes registrar logs si quieres
    }
}

; -------- Helpers de tiempo (compatibles con nuestro formato) ----------
_NormalizeTimeToHHmm(s) {
    ; acepta "08:30", "8:30", "20:05", etc. -> "0830"
    if RegExMatch(s, "^\s*(\d{1,2}):(\d{2})\s*(am|pm)?\s*$", &m) {
        h := Integer(m[1]), mi := Integer(m[2])
        ampm := (m.Count>=3) ? StrLower(Trim(m[3])) : ""
        if (ampm = "pm" && h<12) h += 12
        if (ampm = "am" && h=12) h := 0
        if (h<0 || h>23 || mi<0 || mi>59)
            return ""
        return Format("{:02}{:02}", h, mi)
    }
    return ""
}

_AddMinutes(yyyyMMdd_hhmmtt, mins) {
    ; yyyy-MM-dd hh:mm tt  -> añade minutos -> mismo formato
    ts := StrReplace(yyyyMMdd_hhmmtt, " ", "T")  ; no real ISO, pero sirve
    try {
        t := DateAdd(yyyyMMdd_hhmmtt, mins, "minutes")
        return FormatTime(StrReplace(t,"T"," "), "yyyy-MM-dd hh:mm tt")
    } catch {
        ; fallback: usa A_Now
        return FormatTime(DateAdd(A_Now, mins, "minutes"), "yyyy-MM-dd hh:mm tt")
    }
}

_NowGE(a, bNow) {
    ; a <= now ? (queremos correr si a <= now)
    ; Como lo usamos: _NowGE(nextRunAt, now) -> "ya venció"
    return (a <= bNow)
}
