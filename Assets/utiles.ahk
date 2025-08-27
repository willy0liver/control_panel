#Requires AutoHotkey v2.0

util_obtener_padre(){
    directorio := A_ScriptDir  ; Ruta actual del script
    partes := StrSplit(directorio, "\")  ; Dividir la ruta en partes
    partes.Pop()  ; Eliminar el último elemento (nombre del directorio actual)
    directorioPadre := ""  ; Inicializar la variable para el directorio padre

    ; Reconstruir la ruta del directorio padre
    for parte in partes {
        directorioPadre .= (directorioPadre ? "\" : "") parte
    }
    return directorioPadre
}


Clear_Log() {
    FileDelete(A_ScriptDir "\debug.log")
    FileAppend("", A_ScriptDir "\debug.log", "UTF-8")
}


Log(msg) {
    FileAppend(msg "`n", A_ScriptDir "\debug.log", "UTF-8")
}

ver_log() {
    logPath := A_ScriptDir "\debug.log"
    if FileExist(logPath){
        notepadpp := "C:\Program Files\Notepad++\notepad++.exe"
        if FileExist(notepadpp){
            Run('"' notepadpp '" "' logPath '"')
        }            
        else{
            Run(logPath)
        }
    }
    else {
        MsgBox "No existe Log"
    }
        
}

; Assets\Utils.ahk
; Utilidades genéricas

; Abre URL con el navegador predeterminado (acepta args extra)
OpenUrl(url, *) {
    try Run(url)
    catch as e
        MsgBox("No se pudo abrir la URL:`n" url "`n`n" e.Message, "Error", "Iconx")
}

; Handler factory: congela la URL en una lambda
MakeUrlHandler(url) {
    return (*) => OpenUrl(url)
}

; Abrir carpeta en el explorador
OpenFolder(path) {
    try Run(path)
    catch as e
        MsgBox("No se pudo abrir la carpeta:`n" path "`n`n" e.Message, "Error", "Iconx")
}

; Helpers JSON/strings
SafeTrim(val) {
    try return Trim(val)
    catch 
        return ""
}

GetKey(obj, key, alias := "") {
    try {
        if (obj is Map) {
            if obj.Has(key)
                return obj[key]
            if (alias != "" && obj.Has(alias))
                return obj[alias]
        } else if IsObject(obj) {
            try {
                if ObjHasOwnProp(obj, key)
                    return obj.%key%
            }
            try {
                if (alias != "" && ObjHasOwnProp(obj, alias))
                    return obj.%alias%
            }
            try return obj[key]
        }
    }
    return ""
}

GetJsonColorOrFile(data, filePath) {
    color := SafeTrim(GetKey(data, "color"))
    if (color != "")
        return color
    SplitPath(filePath, &fn)
    return RegExReplace(fn, "\.json$", "")
}

GetJsonNameOrFile(data, filePath) {
    name := SafeTrim(GetKey(data, "name"))
    if (name != "")
        return name
    SplitPath(filePath, &fn)
    return RegExReplace(fn, "\.json$", "")
}

GetJsonOpciones(data) {
    opt := GetKey(data, "opciones")
    if (opt is Array)
        return opt
    return []
}
