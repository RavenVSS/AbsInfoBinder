global pathObverlay := "WinOverlay.dll"

if (!FileExist(pathObverlay))
{
    MsgBox  WinOverlay.dll файл не найден
    ExitApp
}

global hOverlay := DllCall("LoadLibrary", "Str", pathObverlay)

if (hOverlay == 0) {

    MsgBox Не удалось загрузить WinOverlay.dll
    ExitApp
}

;ShowText(const wchar_t* text, const wchar_t* fontName, int fontSize, int x, int y, int r, int g, int b)
; Названия функций dumpbin.exe /exports WinOverlay.dll
global funShowText := DllCall("GetProcAddress", "Ptr", hOverlay, "AStr", "_ShowText@32", "Ptr")
global funHideText := DllCall("GetProcAddress", "Ptr", hOverlay, "AStr", "_HideText@0", "Ptr")

OLShow(text, fontSize, x, y) {
    DllCall(funShowText
    , "WStr", text
    , "WStr", "Courier New"
    , "Int", fontSize
    , "Int", x
    , "Int", y
    , "Int", 255
    , "Int", 255
    , "Int", 255)
}

OLHide() {
    DllCall(funHideText)
}