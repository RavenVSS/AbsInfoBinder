global LogText := ""

Gui, -MaximizeBox
Gui, Add, Text,, Связь через /report бота
Gui, Add, Link, yp x+5 w100, <a href="https://t.me/AbsInfoBot">https://t.me/AbsInfoBot</a>
Gui, Add, Text, yp x+5 w230 Right c660000 vServiceStatus, Подключение...
Gui, Add, Text, xm, В чате ввести: /ном ник или /num nick. Можно ввести часть ника
Gui, Add, Text,, Логи
Gui, Add, Button, gGUIClearLog, Очистить
Gui, Add, Edit, r20 w500 vLogViewGui ReadOnly +VScroll
Gui, Show,, @AbsInfoBot %version%


GUILog(text) {
    LogText .= A_Hour ":" A_Min ":" A_Sec " - " . text . "`n"
    GuiControl,, LogViewGui, %LogText%
    SendMessage, 0x115, 7, 0, Edit1, Log Window
}

GUISetServiceStatus(available) {
    if (available) {
        GuiControl, +c006600, ServiceStatus
        GuiControl,, ServiceStatus, Сервис работает
    } else {
        GuiControl, +c660000, ServiceStatus
        GuiControl,, ServiceStatus, Подключение...
    }
    
}

GUIClearLog() {
    global LogText
    LogText := ""
    GuiControl,, LogViewGui,
}

GUIClose() {
    ExitApp
}
