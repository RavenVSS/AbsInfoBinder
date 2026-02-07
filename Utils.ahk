;=== Utils ===

HttpRequest(url, method := "GET")
{
    HTTP := ComObjCreate("WinHTTP.WinHTTPRequest.5.1")
    ; DNS resolve, Connect, Send, Receive Таймауты в ms
    HTTP.SetTimeouts(httpRequestTimeout, httpRequestTimeout, httpRequestTimeout, httpRequestTimeout) 
    HTTP.Open(method, url, false)
    HTTP.SetRequestHeader("User-Agent", "AbsInfoBot/" . version)
    HTTP.Send()
    HTTP.WaitForResponse()
    return HTTP
}

Log(text) {
    GUILog(text)
    if (config.createLogFile) {
        FormatTime, time,, yyyy-MM-dd HH:mm:ss
        FileAppend, [%time%] %text%`n, AbsInfoBot.log
    }
}

UrlEncodeUtf8(str) {
    VarSetCapacity(buf, StrPut(str, "UTF-8"), 0)
    len := StrPut(str, &buf, "UTF-8") - 1

    out := ""
    Loop, % len {
        b := NumGet(buf, A_Index-1, "UChar")
        if ((b >= 0x30 && b <= 0x39) || (b >= 0x41 && b <= 0x5A) || (b >= 0x61 && b <= 0x7A)
        || b = 0x2D || b = 0x5F || b = 0x2E || b = 0x7E) {
            out .= Chr(b)
        } else {
            out .= "%" . Format("{:02X}", b)
        }
    }
    return out
}

Utf8ToString(body)
{
    size := body.MaxIndex() + 1
    VarSetCapacity(buf, size)
    Loop % size
        NumPut(body[A_Index-1], buf, A_Index-1, "UChar")

    return StrGet(&buf, size, "UTF-8")
}

SwitchToRussianKeyboard() {
    ThreadID := DllCall("GetWindowThreadProcessId", "UInt", WinExist("A"), "UInt", 0)
    KeyboardLayout := DllCall("GetKeyboardLayout", "UInt", ThreadID, "UInt")

    LanguageID := KeyboardLayout & 0xFFFF

    if (LanguageID != 0x0419) { ; Код русского языка
        PostMessage, 0x50, 0, 0x04190419,, A ; Переключение на Русский
    }
}

PadRight(str, totalLen)
{
    while (StrLen(str) < totalLen)
        str .= " "
    return str
}

LoadActualUrl() {
    try {
        response := HttpRequest(urlTxtAddress)
    } catch e {
        Log("Ошибка HTTP запроса: " . e.Message)
        MsgBox Ошибка запроса при получении URL сервиса
        ExitApp
    }

    status := response.Status
    body := response.ResponseBody
    text := Utf8ToString(body)

    if (!text || status != 200) {
        MsgBox Не удалось получить актуальный URL сервиса
        ExitApp
    }

    return text
}