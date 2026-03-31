# CLAUDE.md — Antistress (Fidget App)

## Що це
iOS антистрес-застосунок для людей з СДУГ та тривожністю. 5 інтерактивних табів з тактильним зворотнім зв'язком, звуком та плавними анімаціями.

## Стек
- SwiftUI, iOS 17+
- AudioToolbox / AudioServicesPlaySystemSound для звуків
- UIImpactFeedbackGenerator для haptics
- UNUserNotificationCenter для локальних нотифікацій
- UserDefaults для збереження (FocusStore)
- CoreMotion (планується для Physics)
- SpriteKit (планується для Physics)

## Структура проєкту
```
Antistress/
├── AntistressApp.swift          # Entry point
├── ContentView.swift            # TabView + глобальна шапка (diamond, person icons)
├── SharedViews.swift            # AppColors, AppBackground, GlassCard
├── Info.plist
├── Assets.xcassets
└── Views/
    ├── PopView.swift            # Бульбашкова плівка з силуетами
    ├── SoundView.swift          # Генератор шуму (заглушка)
    ├── FocusView.swift          # Помодоро таймер
    ├── CubeView.swift           # Infinity Cube 4x4
    └── PhysicsView.swift        # Фізичний об'єкт (заглушка)
```

## Таби та акцентні кольори
| # | Таб     | Колір                                      | SF Symbol                  |
|---|---------|--------------------------------------------|-----------------------------|
| 0 | Pop     | Рожевий (AppColors.pop)                    | circle.hexagongrid.fill     |
| 1 | Sound   | Бірюзовий (AppColors.sound)                | waveform                    |
| 2 | Focus   | Червоний — Color(red: 0.9, green: 0.2, blue: 0.2) | timer              |
| 3 | Cube    | Фіолетовий (AppColors.cube)                | cube.fill                   |
| 4 | Physics | Оранжевий (AppColors.physics)              | gyroscope                   |

Базовий фон: `#0A0A0F`

## Архітектура ContentView
- `TabView` з 5 табами
- Глобальна шапка (ZStack overlay): diamond (преміум) зліва, person (акаунт) справа
- Центр шапки: назва табу + іконка (для Pop — назва силуету)
- `@StateObject var focusTimer = FocusTimer()` створюється тут, передається в FocusView як `@ObservedObject`

## Pop таб — деталі
- Сітка 11×13 пікселів (pixel art силуети)
- Матриці з кольоровими зонами: 0=порожньо, 1=accent, 2=shadow, 3=highlight
- 3 силуети: Heart, Cactus, Cloud
- Свайп для навігації між силуетами (elastic drag + spring animation)
- Системний звук при лопанні пупирки
- Dots-індикатор силуету внизу

## Cube таб — деталі
- 4×4 сітка тайлів = грань куба
- 6 унікальних кольорів граней (включаючи синій #4DA6FF)
- `SwipeDirection` enum для напрямку обертання
- `makeUniqueFaces()` генерує 6 граней
- Flip звук: `AudioServicesPlaySystemSound(1104)`

## Focus таб — деталі
- Два режими: Standard (25+5 хв), ADHD (15+5 хв)
- `FocusTimer.swift` — timestamp-based countdown (НЕ Timer.publish, бо дрифтить у фоні)
- `FocusStore.swift` — UserDefaults: daily counts, streaks, focus minutes, auto-reset
- Circular progress ring (зелений під час Break)
- Stats bar + 3 кнопки управління
- Локальні нотифікації при завершенні фази у фоні

## Ellipsis (налаштування) — патерн
Кожен таб має свою ellipsis кнопку зверху справа:
- Розмір: 36×36
- Фон: `.white.opacity(0.07)` 
- Відступ: `.padding(.trailing, 64)` — щоб не перекривати глобальну шапку
- Відкриває glassmorphism панель з toggle'ами (Sound, Haptics)
- Focus має додатково: Auto-start toggle, Work/Break duration steppers

## Правила розробки

### ОБОВ'ЯЗКОВО
- **Повні заміни файлів** — ніколи не давай часткові diff'и чи фрагменти з "// ... existing code". Завжди повний файл.
- **Timestamp-based таймери** — замість `Timer.publish` countdown, для коректної роботи у фоні.
- **Pixel матриці для силуетів** — не використовувати математичні формули для hit-testing форм.
- **6 кольорів для 6 граней куба** — менше = дублікати.
- **Розбивати складні body** на іменовані під-в'юхи — інакше Swift type-checker timeout.
- **MARK коментарі** для структури файлу.

### НЕ РОБИТИ
- Не додавати кастомну навігаційну шапку у Views — глобальна вже є в ContentView
- Не використовувати модальні вікна / попапи / alerts
- Не додавати зайвий текст в UI — мінімалізм
- Не використовувати агресивні кольори — все м'яке і заспокійливе
- Не ламати паралельну роботу табів (звук з Sound має грати поки юзер на іншому табі)

## Git
- Repo: github.com/mikeperish/Softly
- Branch: main
- Коміти: описові, українською або англійською

## Мова спілкування
Розробник спілкується **українською**. Відповідай українською.
Давай повні файли, не фрагменти. Крок за кроком.
