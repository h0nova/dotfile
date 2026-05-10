# Hyprland + ActivSpot Dynamic Island — Setup Guide

> Конфіг Hyprland з Dynamic Island (ActivSpot), Waybar, погодою, музикою, повідомленнями та clipboard.

---

## Що входить

- **Dynamic Island** — острів у стилі Apple (музика, повідомлення, погода, pet, лаунчер)
- **Waybar** — топ-бар
- **Quickshell** — рендер острова (QML)
- **Автозапуск** усіх демонів при старті Hyprland

---

## 1. Встановити залежності

```bash
# Офіційні пакети (pacman)
sudo pacman -S hyprland waybar playerctl cliphist wl-clipboard \
               inotify-tools pamixer imagemagick bc cava \
               ttf-jetbrains-mono ttf-iosevka-nerd \
               python3 jq curl pipewire wireplumber

# AUR-пакети (через yay або paru)
yay -S quickshell-git matugen awww
```

> **Опціонально:** `easyeffects` — для еквалайзера в музичному плеєрі острова.

---

## 2. Скопіювати файли

Розпакуй архів і скопіюй вміст у потрібні місця:

```bash
# Конфіг Hyprland
cp -r hyprland-config/hyprland.conf     ~/.config/hypr/
cp -r hyprland-config/settings.json     ~/.config/hypr/
cp -r hyprland-config/scripts/          ~/.config/hypr/

# Конфіг Waybar
mkdir -p ~/.config/waybar
cp -r hyprland-config/waybar/           ~/.config/waybar/
```

---

## 3. Зробити скрипти виконуваними

```bash
find ~/.config/hypr/scripts -name "*.sh" -exec chmod +x {} \;
```

---

## 4. Налаштувати погоду

Відкрий файл `~/.config/hypr/scripts/quickshell/calendar/.env`:

```bash
nano ~/.config/hypr/scripts/quickshell/calendar/.env
```

Вміст файлу:

```env
OPENWEATHER_KEY=твій_ключ_тут
OPENWEATHER_CITY_ID=ід_твого_міста
OPENWEATHER_UNIT=metric
```

**Як отримати ключ і ID:**
1. Зареєструйся на [openweathermap.org](https://openweathermap.org/api) (безкоштовно)
2. Скопіюй API Key з розділу "API keys"
3. Знайди ID свого міста: [openweathermap.org/find](https://openweathermap.org/find)
   - Наприклад: Київ = `703448`, Харків = `706483`, Запоріжжя = `689558`

> Без ключа погода показуватиме "No API Key" — острів все одно працює.

---

## 5. Налаштувати шпалери

Відкрий `~/.config/hypr/settings.json` і вкажи свою папку зі шпалерами:

```json
{
  "wallpaperDir": "/home/твій_юзер/Pictures/Wallpapers/"
}
```

Створи папку і поклади туди будь-яке `.jpg` або `.png`:

```bash
mkdir -p ~/Pictures/Wallpapers
```

---

## 6. Вимкнути dunst (конфліктує з островом)

Quickshell сам обробляє повідомлення. Dunst потрібно зупинити, щоб не було конфлікту:

```bash
# Зупинити зараз
systemctl --user stop dunst

# Заблокувати автозапуск (опціонально, але рекомендовано)
systemctl --user mask dunst
```

> Якщо не замаскувати — dunst перезапуститься після перезавантаження, але `exec-once = systemctl --user stop dunst` у `hyprland.conf` зупинить його автоматично.

---

## 7. Перезапустити Hyprland

```bash
hyprctl reload
```

Або повністю вийти і зайти знову — всі демони запустяться автоматично через `exec-once` у `hyprland.conf`.

---

## Клавіші

| Комбінація | Дія |
|---|---|
| `Super + Space` | App Launcher |
| `Super + C` | Clipboard Viewer |
| `Super + Shift + S` | Screenshot |
| `Super + T` | Термінал (kitty) |
| `Super + B` | Браузер (firefox) |
| `Super + E` | Файловий менеджер (dolphin) |
| `Super + Q` | Закрити вікно |
| `Super + R` | Wofi launcher |

---

## Структура файлів

```
~/.config/hypr/
├── hyprland.conf               # Головний конфіг
├── settings.json               # Налаштування острова (мова, шпалери, масштаб)
└── scripts/
    ├── qs_manager.sh           # Запуск/перезапуск Quickshell компонентів
    ├── init.sh                 # Ініціалізація шпалери при старті
    ├── settings_watcher.sh     # Слідкує за settings.json
    ├── volume_listener.sh      # OSD гучності
    ├── update_notifier.sh      # Перевірка оновлень
    ├── screenshot.sh           # Скріншот
    └── quickshell/
        ├── Main.qml            # Головне вікно (NotificationServer)
        ├── DynamicIsland.qml   # Острів
        ├── AppLauncher.qml     # Лаунчер
        ├── ClipboardViewer.qml # Clipboard
        ├── calendar/
        │   ├── .env            # API ключ погоди ← ЗМІНИТИ
        │   └── weather.sh
        └── music/
            └── music_info.sh   # Читає playerctl (музика/YouTube)

~/.config/waybar/
├── config.jsonc
└── style.css
```

---

## Вирішення проблем

**Острів не з'являється:**
```bash
bash ~/.config/hypr/scripts/qs_manager.sh
```

**Музика/YouTube не відображається:**
```bash
playerctl status   # Перевір чи бачить плеєр
bash ~/.config/hypr/scripts/quickshell/music/music_info.sh  # Тест
```

**Погода не працює:**
```bash
bash ~/.config/hypr/scripts/quickshell/calendar/weather.sh --json | jq '.forecast[0].desc'
```

**Повідомлення не приходять:**
```bash
systemctl --user stop dunst
notify-send "Тест" "Повідомлення"
```

**Перезапустити все:**
```bash
pkill -f quickshell; systemctl --user stop dunst; bash ~/.config/hypr/scripts/qs_manager.sh
```
