#Requires AutoHotkey v2.0
;===========================================================
; JSON Parser (JXON v2 adaptado a AHK v2) - Solo carga
;===========================================================
Jxon_Load2(& src) {
    static q := Chr(34)
    pos := 1
    return _Value()

    _SkipSpaces() {
        while pos <= StrLen(src) {
            ch := SubStr(src, pos, 1)
            if (ch != " " && ch != "`t" && ch != "`r" && ch != "`n")
                break
            pos++
        }
    }

    _Expect(char) {
        _SkipSpaces()
        if SubStr(src, pos, 1) != char
            throw Error("Se esperaba '" char "' en pos " pos)
        pos++
    }

    _Value() {
        _SkipSpaces()
        if (pos > StrLen(src))
            throw Error("JSON truncado")
        ch := SubStr(src, pos, 1)
        if (ch = q)
            return _String()
        if (ch = "{")
            return _Object()
        if (ch = "[")
            return _Array()

        if RegExMatch(SubStr(src, pos), "^-?\d+(\.\d+)?([eE][\+\-]?\d+)?", &m)
            return _Number(m[0])
        ; true / false / null
        if SubStr(src, pos, 4) = "true" {
            pos += 4
            return true
        }
        if SubStr(src, pos, 5) = "false" {
            pos += 5
            return false
        }
        if SubStr(src, pos, 4) = "null" {
            pos += 4
            return ""  ; tratar null como cadena vacía
        }

        throw Error("Valor JSON inválido en pos " pos)
    }

    _String() {
        _Expect(q)
        out := ""
        while pos <= StrLen(src) {
            ch := SubStr(src, pos, 1), pos++
            if ch = q
                return out
            if ch = "\" {
                esc := SubStr(src, pos, 1), pos++
                if (esc = q || esc = "\" || esc = "/")
                    out .= esc
                else if esc = "b"
                    out .= Chr(8)
                else if esc = "f"
                    out .= Chr(12)
                else if esc = "n"
                    out .= "`n"
                else if esc = "r"
                    out .= "`r"
                else if esc = "t"
                    out .= "`t"
                else if esc = "u" {
                    hex := SubStr(src, pos, 4), pos += 4
                    out .= Chr(("0x" hex)+0)
                } else
                    throw Error("Secuencia de escape inválida en string")
            } else out .= ch
        }
        throw Error("String no cerrado")
    }

    _Array() {
        arr := []
        _Expect("[")
        _SkipSpaces()
        if SubStr(src, pos, 1) = "]" {
            pos++
            return arr
        }
        loop {
            arr.Push(_Value())
            _SkipSpaces()
            ch := SubStr(src, pos, 1)
            if ch = "]" {
                pos++
                break
            }
            _Expect(",")
        }
        return arr
    }

    _Object() {
        obj := Map()
        _Expect("{")
        _SkipSpaces()
        if SubStr(src, pos, 1) = "}" {
            pos++
            return obj
        }
        loop {
            key := _String()
            _Expect(":")
            val := _Value()
            obj[key] := val
            _SkipSpaces()
            ch := SubStr(src, pos, 1)
            if ch = "}" {
                pos++
                break
            }
            _Expect(",")
        }
        return obj
    }

    _Number(txt) {
        pos += StrLen(txt)
        if (InStr(txt, ".") || RegExMatch(txt, "[eE]"))
            return txt + 0.0
        return txt + 0
    }
}