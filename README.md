# AbsInfoBot биндер для SAMP
Приложение позволяет выводить на экран номера телефонов игроков сервера Absolute RP Platinum и не только.  
✅ Совместимо с античитом, приложение работает поверх игры, без внедрения в работу SAMP.  
По всем вопросам писать в телеграмм бота [https://t.me/AbsInfoBot](https://t.me/AbsInfoBot) команда `/report`  
![Пример](images/example.png)
## Команды и возможности
#### Поиск номеров
Пример команды для вывода номеров игроков, у которых в нике есть слово `ronny`
```
/ном ronny
.ном ronny
/num ronny
.num ronny
```
Также можно искать по номеру телефона ник игрока
```
/ном 123456
```
#### История ников
Пример команды для вывода истории никнеймов  
⚠️Важно чтобы ник полностью совпадал!
```
/ник Ronny Madison
.ник Ronny Madison
/nick Ronny Madison
.nick Ronny Madison
```
Если ников будет слишком много, часть ников заменится на `...`
#### Мониторинг чата
⚠️Работает только с оригинальным лаунчером Absolute!  
Приложение мониторит чат когда игра свёрнута, если ваш никнейм появится в чате - появится уведомление Windows.  
Мониторинг можно отключить, убрав галочку "Мониторинг чата".  
![Мониторинг чата](images/chat_monitoring.png)

## Как установить

 1. Скачать из [Releases](https://github.com/RavenVSS/AbsInfoBinder/releases) AbsInfoBinder.exe, WinOverlay.dll и поместить в одну папку
 2. Запустить AbsInfoBinder.exe
 3. (если ошибка с dll) Установить [Visual C++ v14 x86](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170#latest-supported-redistributable-version)


## Настройки config.json
```json
{ 
	"overlayPositionX": 10, // Позиция X от левого верхнего угла в пикселях
	"overlayPositionY": 400, // Позиция Y от левого верхнего угла в пикселях
	"overlayFontSize": 20, // Размер шрифта
	"maxNumbers": 8, // Максимальное количество номеров для вывода
	"createLogFile": false, // Вывод логов в файл
	"chatlogMonitoring": false // Мониторинг чата
}
```

## Source
- https://github.com/cocobelgica/AutoHotkey-JSON

- https://gist.github.com/rasoulcpu/50030f6fbbac44e24f1d62875dd7d66d
