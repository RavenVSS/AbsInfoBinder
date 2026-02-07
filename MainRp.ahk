#Requires AutoHotkey v1.1
#Persistent
#SingleInstance, force
SetBatchLines, -1

;=== Init ===
;@Ahk2Exe-SetName AbsInfoBot
;@Ahk2Exe-SetProductVersion v0.1
;@Ahk2Exe-SetMainIcon icon.ico
;@Ahk2Exe-ExeName AbsInfoBotRp.exe

global version = "v0.1"
global url = "https://game-proxy-2jm4.onrender.com/external/find-number"
global sendDuration = 2000 ; Задержка отправки номеров в чат
global httpRequestTimeout = 2000 ; Таймаут запроса
global maxNumbers = 3 ; К-во номеров для вывода в чат

#include, %A_ScriptDir%\Utils.ahk
#include, %A_ScriptDir%\GUI.ahk
#include, %A_ScriptDir%\JSON.ahk ;https://github.com/cocobelgica/AutoHotkey-JSON

ComObjError(false)
CheckService()

setTimer, CheckService, 30000

;=== End Init ===
;=== Main ===

GetNumbers(search) {
    Log("Запрос номера: " . search)
    search := UrlEncodeUtf8(search)
    requestUrl := url . "?s=" . search
    Log("Запрос: " . requestUrl)
    try {
        response := HttpRequest(requestUrl)
    } catch e {
        Log("Ошибка HTTP запроса: " . e.Message)
        return []
    }
    
    status := response.Status
    body := response.ResponseBody
    text := Utf8ToString(body)

    if (status != 200) {
        Log("Ошибка запроса. Статус: " . status . " Ответ: " . text)
        return []
    }

    Log("Ответ: " . text)

    jsonNumbers := JSON.Load(text)

    textRows := BuildTextList(jsonNumbers)

    return textRows
}

BuildTextList(jsonNumbers) {
    rows := []

    count := 0
    for each, num in jsonNumbers {
        rows.Push(num.nickname . " " . num.number)
        count++
        if (count >= maxNumbers)
            break
    }

    return rows
}

;=== End Main ===
;=== Timers ===

CheckService() {
    try {
        response := HttpRequest(url, method := "OPTIONS")
    } catch e {
        Log("HTTP ошибка: " . e.Message)
        return
    }
    if (response.Status == 200) {
        GUISetServiceStatus(True)
        ;Log("Сервис работает")
    } else {
        GUISetServiceStatus(False)
        ;Log("Сервис недоступен")
    }
}

;=== End Timers ===
;=== Hotkeys ===

:?b0:/ном::
:?b0:.ном::
:?b0:/num::
:?b0:.num::
input, search, L30 V, {enter}
SwitchToRussianKeyboard()
sendinput, ^a{backspace}{esc}
sleep 100
SendInput, {f6}
SendInput, /я заглянул в записную книжку{enter}
time := A_TickCount
textRows := GetNumbers(search)
if (time + 3000 < A_TickCount) {
    Log("Сработал таймаут скрипта 3 секунды!")
    SendInput, {f6}
    SendInput, /де На странице нет записей{enter}
    return
}
sleep sendDuration
if (textRows.Length() == 0) {
    SendInput, {f6}
    SendInput, /де На странице нет записей{enter}
    return
}
for each, element in textRows {
    SendInput, {f6}
    vInput := "/де " . element
    SendInput, %vInput%{enter}
    sleep sendDuration
}
return

;=== End Hotkeys ===
;=== Workaround ===

GuiClose:
    GUIClose()
return
