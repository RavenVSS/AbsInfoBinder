#include <windows.h>
#include <iostream>

typedef int(__stdcall* ShowTextFunc)(const wchar_t*, const wchar_t*, int, int, int, int, int, int);

int main()
{
    HMODULE hDll = LoadLibrary(L"WinOverlay.dll");
    if (!hDll) {
        std::cout << "Cannot load DLL\n";
        system("pause");
        return 1;
    }

    ShowTextFunc ShowText = (ShowTextFunc)GetProcAddress(hDll, "_ShowText@32");
    if (!ShowText) {
        std::cout << "Cannot find ShowText function\n";
        system("pause");
        return 1;
    }

    // тестируем функцию
    ShowText(L"Hello World", L"Arial", 48, 200, 300, 255, 0, 0);

    // ждём чтобы увидеть результат
    Sleep(3000);

    FreeLibrary(hDll);

    std::cout << "Finish\n";
    system("pause");
    return 0;
}
