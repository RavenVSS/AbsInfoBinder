// dllmain.cpp : Defines the entry point for the DLL application.
#include "pch.h"
#include <windows.h>
#include "Shlwapi.h"
#include <string>

typedef std::basic_string<TCHAR> String;

#define DLL_EXPORT extern "C" __declspec(dllexport)

HINSTANCE m_hInstance;
BLENDFUNCTION m_blend;
POINT m_ptZero;
static HWND hwnd;
static SIZE bmpSize;
static POINT position;

static wchar_t szWindowClass[] = L"Overlay";
static wchar_t szTitle[] = L"SAMP Overlay";

void RegisterWindowClass()
{
	WNDCLASS wc = { 0 };
	wc.lpfnWndProc = DefWindowProc;
	wc.hInstance = m_hInstance;
	wc.hCursor = LoadCursor(nullptr, IDC_HAND);
	wc.lpszClassName = szWindowClass;
	RegisterClass(&wc);
}

void UnregisterWindowClass()
{
	UnregisterClass(szWindowClass, m_hInstance);
}

void Init(HINSTANCE hInstance)
{
	hwnd = NULL;
	m_ptZero = { 0 };

	m_hInstance = hInstance;

	m_blend.BlendOp = AC_SRC_OVER;
	m_blend.AlphaFormat = AC_SRC_ALPHA;
	m_blend.SourceConstantAlpha = 0xff;
	m_blend.BlendFlags = NULL;

	CoInitialize(nullptr);
	RegisterWindowClass();
	hwnd = CreateWindowEx(WS_EX_LAYERED, szWindowClass, szTitle, WS_POPUP | WS_VISIBLE, 0, 0, 0, 0, nullptr, nullptr, m_hInstance, nullptr);
}


RECT GetMainMonitorRect()
{
	HMONITOR hmonitor = MonitorFromPoint(m_ptZero, MONITOR_DEFAULTTOPRIMARY);
	MONITORINFO monitorinfo = { 0 };
	monitorinfo.cbSize = sizeof(monitorinfo);
	GetMonitorInfo(hmonitor, &monitorinfo);
	return monitorinfo.rcWork;
}

HBITMAP CreateAlphaTextBitmap(String text, HFONT font, COLORREF color)
{
	int TextLength = text.length();
	if (TextLength <= 0) return NULL;
	HDC hTextDC = CreateCompatibleDC(NULL);
	HFONT hOldFont = (HFONT)SelectObject(hTextDC, font);
	HBITMAP result = NULL;
	RECT text_area = { 0, 0, 0, 0 };
	DrawText(hTextDC, text.c_str(), TextLength, &text_area, DT_CALCRECT);
	if ((text_area.right > text_area.left) && (text_area.bottom > text_area.top))
	{
		BITMAPINFOHEADER bitmapinfoheader;
		memset(&bitmapinfoheader, 0x0, sizeof(BITMAPINFOHEADER));
		void *pvBits = NULL;

		bitmapinfoheader.biSize = sizeof(bitmapinfoheader);
		bitmapinfoheader.biWidth = text_area.right - text_area.left;
		bitmapinfoheader.biHeight = text_area.bottom - text_area.top;
		bitmapinfoheader.biPlanes = 1;
		bitmapinfoheader.biBitCount = 32;
		bitmapinfoheader.biCompression = BI_RGB;

		result = CreateDIBSection(hTextDC, (LPBITMAPINFO)&bitmapinfoheader, 0, (LPVOID*)&pvBits, NULL, 0);
		HBITMAP hOldBMP = (HBITMAP)SelectObject(hTextDC, result);
		if (hOldBMP != NULL)
		{
			SetTextColor(hTextDC, 0x00FFFFFF);
			SetBkColor(hTextDC, 0x00000000);
			SetBkMode(hTextDC, OPAQUE);

			DrawText(hTextDC, text.c_str(), -1, &text_area, DT_WORDBREAK);
			BYTE* data_ptr = (BYTE*)pvBits;
			BYTE fill_r = GetRValue(color);
			BYTE fill_g = GetGValue(color);
			BYTE fill_b = GetBValue(color);
			for (int y = 0; y < bitmapinfoheader.biHeight; y++) {
				for (int x = 0; x < bitmapinfoheader.biWidth; x++) {
					BYTE this_a = *data_ptr;
					*data_ptr++ = (fill_b * this_a) >> 8;
					*data_ptr++ = (fill_g * this_a) >> 8;
					*data_ptr++ = (fill_r * this_a) >> 8;
					*data_ptr++ = this_a; // Set Alpha 
				}
			}

			SelectObject(hTextDC, hOldBMP);
		}
	}

	SelectObject(hTextDC, hOldFont);
	DeleteDC(hTextDC);

	return result;
}

void SetTransparentImageAndShowWindow(HWND hwnd, HBITMAP hbmp)
{
	HDC hdcScreen = GetDC(nullptr);
	HDC hdcMem = CreateCompatibleDC(hdcScreen);
	HBITMAP hbmpOld = HBITMAP(SelectObject(hdcMem, hbmp));
	//----------------------------------Calculate top left position----------------------------------
	BITMAP bm;
	GetObject(hbmp, sizeof(bm), &bm);
	bmpSize = { bm.bmWidth, bm.bmHeight };
	//======= UnComment below if you want to show text at center of desktop==========================
	//RECT rect = GetMainMonitorRect();
	//position.x = rect.left + (rect.right - rect.left - bmpSize.cx) / 2;
	//position.y = rect.top + (rect.bottom - rect.top - bmpSize.cy) / 2;
	//----------------------------------Update window transparency-----------------------------------		
	UpdateLayeredWindow(hwnd, hdcScreen, &position, &bmpSize, hdcMem, &m_ptZero, NULL, &m_blend, ULW_ALPHA);
	SetWindowPos(hwnd, HWND_TOPMOST, position.x, position.y, bmpSize.cx, bmpSize.cy, SWP_SHOWWINDOW);
	//----------------------------------delete temporary objects----------------------------------
	SelectObject(hdcMem, hbmpOld);
	DeleteDC(hdcMem);
	ReleaseDC(nullptr, hdcScreen);
}

void Show(String text, HFONT font, COLORREF color)
{
	HBITMAP MyBMP = CreateAlphaTextBitmap(text, font, color);
	if (MyBMP != nullptr)
	{
		SetTransparentImageAndShowWindow(hwnd, MyBMP);
	}
}

void Hide()
{
	SetWindowPos(hwnd, HWND_NOTOPMOST, position.x, position.y, bmpSize.cx, bmpSize.cy, SWP_HIDEWINDOW | SWP_NOACTIVATE);
}

BOOL APIENTRY DllMain( HMODULE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
                     )
{
	if (ul_reason_for_call == DLL_PROCESS_ATTACH)
	{
		m_hInstance = hModule;
		Init(m_hInstance);
	}
	else if (ul_reason_for_call == DLL_PROCESS_DETACH)
	{
		UnregisterWindowClass();
	}
	return TRUE;
}

DLL_EXPORT int __stdcall ShowText(const wchar_t* text, const wchar_t* fontName, int fontSize, int x, int y, int r, int g, int b)
{
	position.x = x;
	position.y = y;

	HFONT font = CreateFont(
		fontSize, 0, 0, 0, 0,
		0, 0, 0,
		DEFAULT_CHARSET,
		0, 0, 0, 0,
		fontName
	);

	Show(text, font, RGB(r, g, b));

	return 0;
}

DLL_EXPORT int __stdcall HideText()
{
	Hide();

	return 0;
}