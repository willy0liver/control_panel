#Requires AutoHotkey v2.0
#Include ../Assets/_JXON.ahk
#Include ../Assets/utiles.ahk


fn_get_menu_0(){
    ; 🔸 Opciones de Menu
    OptionsMenu := Menu()
    OptionsMenu.Add("Reload", (*) => Reload())
    OptionsMenu.SetIcon("Reload", "C:\Windows\System32\shell32.dll", 239) 
    
    MyMenuBar := MenuBar()
    MyMenuBar.Add("&Options", OptionsMenu)

    cont := 1
    Menus := Map()  ; Crear un objeto para almacenar menús dinámicos
    ; 🔸 Ruta del directorio donde están los JSON
    directorio := A_ScriptDir "\menu"
    ; 🔍 Obtener todos los archivos .json dentro del directorio
    loop files directorio "\*.json"
    {
        archivo := A_LoopFileFullPath
        nombreArchivo := A_LoopFileName    
        try {
            ; 📄 Leer contenido del archivo
            contenido := FileRead(archivo)    
            ; 🔄 Convertir JSON en objeto
            datos := JXON_Load(&contenido)    
            ;MsgBox "📂 Leyendo: " nombreArchivo    
            ; 🔥 Recorrer claves y valores
            for clave, valor in datos {
                if IsObject(valor) {
                    if valor is Array {
                        MsgBox "🔹 " clave " (Array)"
                        for idx, item in valor {
                            MsgBox "   ➤ [" idx "] " item
                        }
                    } else { ; Es un objeto (mapa)
                        MsgBox "🔸 " clave " (Objeto)"
                        for subclave, subvalor in valor {
                            MsgBox "   ➤ " subclave ": " subvalor
                        }
                    }
                } else {
                    MsgBox "✔️ " clave ": " valor
                }
            }
            cont := cont + 1
        } catch Error as e {
            MsgBox "❌ Error procesando " nombreArchivo ": " e.Message
        }
    }


    MenuHandler(*) {
        ; For this example, the menu items don't do anything.
        MsgBox("Menu item clicked")
    }

    return MyMenuBar
}

fn_get_menu(){
    cont := 1
    Menus := Map()  ; Crear un objeto para almacenar menús dinámicos
    MyMenuBar := MenuBar()  ; Crear un objeto MenuBar para la ventana

    ; Crear un menú dinámico con el nombre basado en `cont`
    nombreMenu := "Options"
    Menus[nombreMenu] := Menu()  ; Crear un nuevo menú y almacenarlo en el objeto `Menus`

    Menus[nombreMenu].Add("Reload", (*) => Reload())
    Menus[nombreMenu].SetIcon("Reload", "C:\Windows\System32\shell32.dll", 239) 
        
    Menus[nombreMenu].Add("Ver Iconos", (*) => abrir_imagen())
    Menus[nombreMenu].SetIcon("Ver Iconos", "C:\Windows\System32\shell32.dll", 329) 
    
    Menus[nombreMenu].Add("Ver Proyecto", (*) => Run(A_ScriptDir))
    Menus[nombreMenu].SetIcon("Ver Proyecto", "C:\Windows\System32\shell32.dll", 4) 
    
    Menus[nombreMenu].Add("Ver Log", (*) => ver_log())
    Menus[nombreMenu].SetIcon("Ver Log", "C:\Windows\System32\shell32.dll", 328) 
    
    ; Agregar el menú dinámico al MenuBar
    MyMenuBar.Add("&" nombreMenu, Menus[nombreMenu])

    ; 🔸 Ruta del directorio donde están los JSON
    directorio := A_ScriptDir "\menu"
    ; 🔍 Obtener todos los archivos .json dentro del directorio
    loop files directorio "\*.json" {
        archivo := A_LoopFileFullPath
        nombreArchivo := A_LoopFileName    
        try {
            ; 📄 Leer contenido del archivo
            contenido := FileRead(archivo, "UTF-8")    
            ; 🔄 Convertir JSON en objeto
            datos := JXON_Load(&contenido)    
            ;MsgBox "📂 Leyendo: " nombreArchivo   
            
            ; Recorrer claves y valores del objeto
            for clave, valor in datos {
                if IsObject(valor) {
                    if valor is Array {
                        ;MsgBox "🔹 " clave " (Array)"
                        for idx, item in valor {       
                            if (clave = "paginas") {
                                miPag := Trim(item["pagina"])
                                Menus[nombreMenu].Add(item["name"], (*) => open_pagina(miPag))
                                Menus[nombreMenu].SetIcon(item["name"], "C:\Windows\System32\shell32.dll", item["icono"])  ; Usar el índice dinámico
                                try {
                                    if (StrUpper(item["separador"]) == 'S') {
                                        Menus[nombreMenu].Add("") ; Agregar un separador
                                    }
                                } catch {
                                    
                                }                                
                            }
                        }
                    } else { ; Es un objeto (mapa)
                        MsgBox "🔸 " clave " (Objeto)"
                        for subclave, subvalor in valor {
                            MsgBox "   ➤ " subclave ": " subvalor
                        }
                    }
                } else {
                    ;MsgBox "✔️ " clave ": " valor
                    if (clave = "nombre") {
                        ; Crear un menú dinámico con el nombre basado en `cont`
                        nombreMenu := valor
                        Menus[nombreMenu] := Menu()  ; Crear un nuevo menú y almacenarlo en el objeto `Menus`
                    }   
                }
            }

            ; 🔥 Recorrer claves y valores del JSON - Asignar Nombre
            for clave, valor in datos {
                             
            }

            ; 🔥 Recorrer claves y valores del JSON
            for clave, valor in datos {
                ;Menus[nombreMenu].Add(clave, (*) => MsgBox("Opción seleccionada: " clave))
            }

            ; Agregar el menú dinámico al MenuBar
            MyMenuBar.Add("&" nombreMenu, Menus[nombreMenu])

            cont := cont + 1
        } catch Error as e {
            MsgBox "❌ Error procesando " nombreArchivo ": " e.Message
        }
    }

    

    return MyMenuBar  ; Retornar el objeto MenuBar
}

open_pagina(pag){
    Run pag
}

abrir_imagen(){
    rutaImagen := A_ScriptDir "\Assets\Iconos_shell32.png"
    Run rutaImagen
}