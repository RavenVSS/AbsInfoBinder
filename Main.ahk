#Requires AutoHotkey v1.1
#Persistent
#SingleInstance, force
SetBatchLines, -1

;=== Init ===
;@Ahk2Exe-SetName AbsInfoBinder
;@Ahk2Exe-SetProductVersion v0.3
;@Ahk2Exe-SetMainIcon icon.ico
;@Ahk2Exe-ExeName AbsInfoBinder.exe

global version := "v0.3"
global configPath := "config.json"
global urlTxtAddress := "https://raw.githubusercontent.com/RavenVSS/AbsInfoBinder/main/url.txt"
global url
global httpRequestTimeout := 2000 ; Таймаут запроса
global overlayOnDisplay := false ; Флаг - оверлей выведен на экран
global overlayAutoHide := false ; Флаг - оверлей скрыт автоматически
global overlayText := 0 ; Текст, который выведен на оверлей

global chatlogMonitoringEnabled := false ; Мониторинг чатлога включён
global chatlogPath := UserProfile . "\Documents\GTA San Andreas User Files\SAMP\chatlog.txt"
global chatlogFile := 0
global chatlogOldFileSize := 0

global currentNickname := 0 ; Текуший ник на сервере Platinum
global currentNicknamePattern := 0


#include, %A_ScriptDir%\Utils.ahk
#include, %A_ScriptDir%\Overlay.ahk
#include, %A_ScriptDir%\GUI.ahk
#include, %A_ScriptDir%\JSON.ahk ;https://github.com/cocobelgica/AutoHotkey-JSON

global config := { "overlayPositionX": 10
    , "overlayPositionY": 400
    , "overlayFontSize": 20
    , "maxNumbers": 8
    , "createLogFile": false
    , "chatlogMonitoring": false}

Init()
OLHide()
ComObjError(false)
CheckService()

setTimer, CheckService, 30000
setTimer, CheckOverlay, 1000

;=== End Init ===
;=== Main ===

Init() {
    url := LoadActualUrl()
    currentNickname := GetCurrentNickname()
    currentNicknamePattern := StrReplace(currentNickname, "_", " ")
    currentNicknamePattern := StrReplace(currentNicknamePattern, " ", "[_ ]")
    currentNicknamePattern := "^\[.+\] (.*" . currentNicknamePattern . ".*)$"

    if (FileExist(configPath)) {
        file := FileOpen(configPath, "r")
        configFileText := file.Read()
        file.Close()

        config := JSON.Load(configFileText)
        
        ; === Config Migration ===
        if (!config.HasKey("chatlogMonitoring")) {
            config.chatlogMonitoring := false
        }
        ; === End Config Migration ===
    }

    UpdateConfig()

    newVersion := GetNewVersion()
    if (newVersion) {
        GUISetUpdateStatus(newVersion)
    }

    GUISetChatlogMonitoring(config.chatlogMonitoring)
}

UpdateConfig() {
    configFileText := JSON.Dump(config)
    file := FileOpen(configPath, "w")
    file.Write(configFileText)
    file.Close()

    if (config.chatlogMonitoring) {
        SetTimer, CheckChatlog, 1000
        chatlogFile := 0
        chatlogOldFileSize := 0
    } else {
        SetTimer, CheckChatlog, off
    }
}

GetNumbers(search) {
    Log("Запрос номера: " . search)
    search := UrlEncodeUtf8(search)
    
    if (!search)
        return "Поисковая строка пуста"

    requestUrl := url . "?s=" . search
    Log("Запрос: " . requestUrl)
    try {
        response := HttpRequest(requestUrl)
    } catch e {
        Log("Ошибка HTTP запроса: " . e.Message)
        return "Ошибка запроса"
    }

    status := response.Status
    body := response.ResponseBody
    text := Utf8ToString(body)

    if (status != 200) {
        Log("Ошибка запроса. Статус: " . status . " Ответ: " . text)
        return "Ошибка запроса"
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

GetNicknameHistory(search) {
    Log("Запрос истории никнеймов: " . search)
    search := UrlEncodeUtf8(search)
    if (!search)
        return "Поисковая строка пуста"

    requestUrl := "https://sa-mp.ru/server-platinum?NickAccid=" . search
    Log("Запрос: " . requestUrl)
    try {
        response := HttpRequest(requestUrl)
    } catch e {
        Log("Ошибка HTTP запроса: " . e.Message)
        return "Ошибка запроса"
    }

    status := response.Status
    body := response.ResponseBody
    html := Utf8ToString(body)

    if (status != 200) {
        Log("Ошибка запроса. Статус: " . status)
        return "Ошибка запроса"
    }

    RegExMatch(html, "Информация об аккаунте\s+(\S+)\s+номер\s+(\d+)", match)
    nickname := match1
    accountId := match2

    if (!nickname)
        return "Не найдено`nНик должен полностью совпадать,`nв том числе большие буквы!"

    result := "Ник: " . nickname . " Аккаунт: " . accountId
    pos := 1

    maxDateLen := 0
    nickHistory := []
    While, pos := RegExMatch(html, "<td>([^<]*\d{4}[^<]*)</td>\s*<td>\s*([^<]+?)\s*</td>", match, pos)
    {
        date := match1
        nick := match2

        len := StrLen(date)
        if (len > maxDateLen)
            maxDateLen := len

        nickHistory.Push({date: date, nick: nick})
        
        pos += StrLen(match)
    }

    length := nickHistory.Length()
    for index, element in nickHistory {
        if (index == 17) {
            result := result . "`n..."
            continue
        }

        if (index > 17 && index != length)
            continue

        datePadRight := PadRight(element.date, maxDateLen)

        result := result . "`n" . datePadRight . " " . element.nick
    }

    return result
}

ProcessChatLogLine(chatlogLine) {
    if (!currentNickname)
        return

    if RegExMatch(chatlogLine, "i)" . currentNicknamePattern, match) {
        TrayTip, Вас упомянули, %match1%, 5, 1
    }
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

CheckOverlay() {
    if (!overlayOnDisplay) 
        return

    gameActive := CheckActiveWindowGta()
    if (gameActive) {
        if (overlayAutoHide) {
            Sleep, 1000
            OLShow(overlayText
            , config.overlayFontSize
            , config.overlayPositionX
            , config.overlayPositionY)
            overlayAutoHide := false
        }
    } else {
        if (!overlayAutoHide) {
            OLHide()
            overlayAutoHide := true
        }
    }
}

CheckChatlog() {
    if (!config.chatlogMonitoring) {
        return
    }

    ; Если игра развёрнута и мониторинг включен
    if (CheckActiveWindowGta() && chatlogMonitoringEnabled) {
        chatlogMonitoringEnabled := false
    }

    ; Если игра свёрнута и мониторинг выключен
    if (!CheckActiveWindowGta() && !chatlogMonitoringEnabled) {
        chatlogMonitoringEnabled := true
        if (chatlogFile)
            chatlogFile.Seek(0, 2)
            chatlogOldFileSize := 0
    }

    if (!chatlogMonitoringEnabled)
        return

    if (!chatlogFile) {
        if (!FileExist(chatlogPath))
        {
            Log("Файл логов SAMP не найден!")
            config.chatlogMonitoring := false
        } else {
            chatlogFile := FileOpen(chatlogPath, "r", "CP1251")
            chatlogFile.Seek(0, 2)
            chatlogOldFileSize := 0
        }
    }

    logFileSize := chatlogFile.Length()
    if (logFileSize > chatlogOldFileSize)
    {
        Loop
        {
            if (chatlogFile.AtEOF())
                break
            textLine := chatlogFile.Readline()
            if (!textLine) 
                Break

            ProcessChatLogLine(textLine)
        }
        chatlogOldFileSize := logFileSize
    }
}

;=== End Timers ===
;=== Hotkeys ===
#If overlayOnDisplay && !overlayAutoHide
    Esc::
    overlayOnDisplay := false
    OLHide()
return
#If

:?b0:/ном::
:?b0:.ном::
:?b0:/num::
:?b0:.num::
    if (!CheckActiveWindowGta())
        return
    input, search, L30 V, {enter}
    SwitchToRussianKeyboard()
    sendinput, ^a{backspace}{esc}
    sleep 100

    if (!search) 
        search := Clipboard

    if (StrLen(search) > 50) {
        finalText := "Ник более 50 символов"
    } else {
        finalText := GetNumbers(search)
    }
    
    finalText := finalText . "`nESC - закрыть"
    overlayText := finalText
    OLShow(finalText
    , config.overlayFontSize
    , config.overlayPositionX
    , config.overlayPositionY)
    overlayOnDisplay := true
return

:?b0:/ник::
:?b0:.ник::
:?b0:/nick::
:?b0:.nick::
    if (!CheckActiveWindowGta())
        return
    input, search, L30 V, {enter}
    SwitchToRussianKeyboard()
    sendinput, ^a{backspace}{esc}
    sleep 100

    if (!search) 
        search := Clipboard

    if (StrLen(search) > 50) {
        finalText := "Ник более 50 символов"
    } else {
        finalText := GetNicknameHistory(search)
    }
    
    finalText := finalText . "`nESC - закрыть"
    overlayText := finalText
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
