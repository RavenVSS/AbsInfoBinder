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

CheckActiveWindowGta() {
    WinGet, process, ProcessName, A
    if (process == "gta_sa.exe") 
        return True
    return False
}

GetCurrentNickname() {
    configAbsPath := A_AppData "\SAMPLauncher\AbsLauncherServerNicks.ini"

    nickname := 0
    FileRead, configAbsFileText, %configAbsPath%
    if not ErrorLevel
    {
        if RegExMatch(configAbsFileText, "185\.71\.66\.21%3A7771=(\S+)", match)
        {
            nickname := ConvertNickname(match1)
            Log("Текущий никнейм: " . nickname)
            return nickname
        }
    }
    Log("Не удалось получить никнейм")
    return nickname
}

ConvertNickname(text) {
    result := RegExReplace(text, "\\x([0-9A-Fa-f]{1,4})", "$hexChar")
    result := text
    pos := 1
    While, pos := RegExMatch(result, "\\x([0-9A-Fa-f]{1,4})", match, pos)
    {
        code := "0x" . match1
        char := Chr(code)
        result := StrReplace(result, match, char)
    }

    return result
}

GetNewVersion() {
    try {
        response := HttpRequest("https://api.github.com/repos/RavenVSS/AbsInfoBinder/releases/latest")
    } catch e {
        Log("Ошибка HTTP запроса при получении версии: " . e.Message)
        return
    }

    status := response.Status
    body := response.ResponseBody
    text := Utf8ToString(body)

    if (status != 200) {
        Log("Ошибка запроса при получении версии. Статус: " . status)
        return
    }

    repo := JSON.Load(text)

    if (repo.tag_name != version)
        return repo.tag_name

    return
}