#Requires AutoHotkey v1.1
#Persistent
#SingleInstance, force
SetBatchLines, -1

;=== Init ===
;@Ahk2Exe-SetName AbsInfoBot
;@Ahk2Exe-SetProductVersion v0.1
;@Ahk2Exe-SetMainIcon icon.ico
;@Ahk2Exe-ExeName AbsInfoBotOL.exe

global version := "v0.1"
global configPath := "config.json"
global urlTxtAddress := "https://raw.githubusercontent.com/RavenVSS/AbsInfoBinder/main/url.txt"
global url
global httpRequestTimeout := 2000 ; Таймаут запроса
global overlayOnDisplay := false ; Флаг - оверлей выведен на экран

#include, %A_ScriptDir%\Utils.ahk
#include, %A_ScriptDir%\Overlay.ahk
#include, %A_ScriptDir%\GUI.ahk
#include, %A_ScriptDir%\JSON.ahk ;https://github.com/cocobelgica/AutoHotkey-JSON

url := LoadActualUrl()

global config := { "overlayPositionX": 10
    , "overlayPositionY": 400
    , "overlayFontSize": 20
    , "maxNumbers": 8
    , "createLogFile": false}

FileRead, configFileText, %configPath%
if not ErrorLevel
{
    config := JSON.Load(configFileText)
} else {
    configFileText := JSON.Dump(config)
    FileAppend, %configFileText%, %configPath%
}

OLHide()
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
    if (jsonNumbers.Length() == 0) {
        return "Ничего не найдено"
    } 

    maxNickLen := 0
    maxNumLen := 0

    for each, num in jsonNumbers {
        len := StrLen(num.number)
        if (len > maxNumLen)
            maxNumLen := len
        len := StrLen(num.nickname)
        if (len > maxNickLen)
            maxNickLen := len
    }

    text := PadRight("Ник", maxNickLen) . " " . PadRight("Устарел", 8) . " " . PadRight("Номер", maxNumLen)

    count := 0
    for each, num in jsonNumbers {
        nickname := PadRight(num.nickname, maxNickLen)
        number := PadRight(num.number, maxNumLen)
        outdated := PadRight(num.outdated, 8)
        text := text . "`n" . nickname . " " . outdated . " " . number
        count++
        if (count >= config.maxNumbers)
            break
    }

    return text
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
        return True
    } else {
        GUISetServiceStatus(False)
        return False
    }
}

;=== End Timers ===
;=== Hotkeys ===
#If overlayOnDisplay
    Esc::
    overlayOnDisplay := false
    OLHide()
return
#If

:?b0:/ном::
:?b0:.ном::
:?b0:/num::
:?b0:.num::
    input, search, L30 V, {enter}
    SwitchToRussianKeyboard()
    sendinput, ^a{backspace}{esc}
    sleep 100
    finalText := GetNumbers(search)
    finalText := finalText . "`nESC - закрыть"
    OLShow(finalText
    , config.overlayFontSize
    , config.overlayPositionX
    , config.overlayPositionY)
    overlayOnDisplay := true
return

; f1::
; finalText := GetNumbers("ник")
;     finalText := finalText . "`nESC - закрыть"
;     OLShow(finalText
;     , config.overlayFontSize
;     , config.overlayPositionX
;     , config.overlayPositionY)
;     overlayOnDisplay := true
; return

;=== End Hotkeys ===
;=== Workaround ===

GuiClose:
    GUIClose()
return
