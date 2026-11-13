# Kalinka Brand Asset Manifest & Branding Audit

> **Документ:** Спецификация и аудит брендовых ассетов проекта «Калинка» (Kalinka).
> **Основа:** Архитектурный аудит форка `calcom/cal.diy` (commit `ef7954d16ab50882ca2f263c551537115b8a8bb1`).
> **Утверждённая визуальная концепция:** **Folk-tech** (Концепт 1) — современный минималистичный планировщик встреч со славянскими корнями, аутентичной геометрической вышивкой и гроздью калины.

---

## 1. Сводная матрица ассетов

| Ассет / Назначение | Расположение в коде | Формат и размеры | Светлая / Тёмная тема | Использование (компонент / константа) | Приоритет MVP |
|---|---|---|---|---|---|
| **A1. Основная иконка приложения (Squircle Mark)** | `apps/web/public/cal-com-icon.svg` | SVG (56×56, viewBox 0 0 56 56) | Тёмный сквиркл `#212226` с монограммой K (`#F6EFE4`), вышивкой и ягодами калины (`#C23636`) | `Logo.tsx` (при `icon=true`), `/api/logo?type=icon`, PWA shortcut | **Обязательно (MVP Core)** |
| **A2. Светлый вариант иконки (Monochrome / Header)** | `apps/web/public/cal-com-icon-white.svg` | SVG (56×56, viewBox 0 0 56 56) | Монограмма K в белом/ivory цвете без заливки фона с ягодами калины | `constants.ts` (`LOGO_ICON`), свёрнутый сайдбар `SideBar.tsx` | **Обязательно (MVP Core)** |
| **A3. Высококачественный мастер PNG** | `apps/web/public/android-chrome-512x512.png` | PNG (512×512, 32-bit RGBA) | Тёмный сквиркл с калиной на прозрачном фоне | PWA Manifest, splash screens | **Обязательно (MVP Core)** |
| **A4. Средний мастер PNG** | `apps/web/public/android-chrome-256x256.png` | PNG (256×256, 32-bit RGBA) | Тёмный сквиркл с калиной на прозрачном фоне | PWA Manifest, `logoDefinitions["android-chrome-256"]` | **Обязательно (MVP Core)** |
| **B1. Векторный фавикон** | `apps/web/public/favicon.svg` *(новый)* | SVG (32×32, viewBox 0 0 32 32) | Оптимизированный силуэт K + вышивка + ягоды калины (без микро-шума) | Modern browsers `<link rel="icon" type="image/svg+xml">` | **Обязательно (MVP Core)** |
| **B2. Растровые фавиконы** | `apps/web/public/favicon-32x32.png`, `favicon-16x16.png` | PNG (32×32, 16×16) | Адаптированный силуэт K для экстремально малых размеров | `constants.ts` (`FAVICON_32`, `FAVICON_16`), `/api/logo` | **Обязательно (MVP Core)** |
| **B3. Контейнер Favicon ICO** | `apps/web/public/favicon.ico` | ICO (16×16, 32×32, 48×48) | Классический фавикон для всех браузеров | Корень веб-сервера `/favicon.ico` | **Обязательно (MVP Core)** |
| **C1. Горизонтальный логотип (Light)** | `apps/web/public/cal-logo-word.svg` (а также `cal-logo-word-black.svg`) | SVG (viewBox `0 0 160 40` или соразмерный) | Монограмма K + текстовое начертание Kalinka в тёмно-графитовом цвете (`#1A1A1B`) с красными ягодами | Шапка авторизации `AuthContainer.tsx`, десктопная навигация `TopNav.tsx` | **Обязательно (MVP Core)** |
| **C2. Горизонтальный логотип (Dark)** | `apps/web/public/calcom-logo-white-word.svg` (а также `cal-logo-word-dark.svg`) | SVG (viewBox `0 0 160 40`) | Монограмма K + слово Kalinka в цвете Warm Ivory (`#F6EFE4`) с красными ягодами | Тёмная тема в `TopNav.tsx`, `AuthContainer.tsx` | **Обязательно (MVP Core)** |
| **D1. Apple Touch Icon** | `apps/web/public/apple-touch-icon.png` | PNG (180×180, без прозрачности) | Сквиркл с фоном `#212226`, монограмма K с калиной по центру | iOS Safari закладки, `constants.ts` (`APPLE_TOUCH_ICON`), `/api/logo` | **Обязательно (MVP Core)** |
| **D2. Android PWA Icon** | `apps/web/public/android-chrome-192x192.png` | PNG (192×192) | Иконка PWA с безопасной зоной (safe zone padding) | `site.webmanifest`, Android home screen | **Обязательно (MVP Core)** |
| **D3. PWA Webmanifest** | `apps/web/public/site.webmanifest` | JSON | `"name": "Kalinka"`, `"short_name": "Kalinka"`, theme `#212226` | Браузерные PWA-установщики | **Обязательно (MVP Core)** |
| **E1. Email Header Logo** | `apps/web/public/emails/logo.png` (и `@2x.png`) | PNG (123×38, retina 246×76) | Горизонтальный логотип Kalinka для светлых email-клиентов | `packages/emails/src/components/EmailBodyLogo.tsx` | **Обязательно (MVP Core)** |
| **F1. Windows Metro Tiles** | `apps/web/public/mstile-150x150.png` | PNG (150×150) | Иконка плитки Windows | `browserconfig.xml` | *Можно отложить (Secondary)* |
| **F2. Social Sharing OpenGraph** | `apps/web/public/video-og-image.png` | PNG (1200×630) | Карточка с логотипом Kalinka на тёмном/кремовом фоне | Telegram/VK превью ссылок, `constants.ts` (`SEO_IMG_OGIMG_VIDEO`) | *Можно отложить (Secondary)* |

---

## 2. Использование одного исходного SVG для генерации производных ресурсов

- **Можно ли использовать единый мастер-вектор?**
  - **Да, для всех растровых иконок и фавиконов**: Из единого мастер-вектора монограммы K на сквиркле генерируются:
    - PNG 512×512, 384×384, 256×256, 192×192 (`android-chrome-*`)
    - PNG 180×180 (`apple-touch-icon.png`)
    - PNG 32×32, 16×16 (`favicon-*.png`) и `favicon.ico`
    - PNG 150×150 (`mstile-*`)
  - **Нюанс оптической компенсации для фавиконов (16×16 и 32×32)**:
    - При сжатии до 16×16 тонкие прожилки листьев и точки микровышивки сливаются в визуальную грязь.
    - Для микро-фавикона создаётся **упрощённый слой**: монограмма K + чистые силуэты ягод калины без внутренних субпиксельных перекрестий, что гарантирует мгновенную узнаваемость во вкладке браузера.
  - **Для горизонтальных логотипов (`cal-logo-word.svg` / `calcom-logo-white-word.svg`)**:
    - Используется отдельный векторный мастер-локап: знак K слева + аутентичный шрифтовой контур «Kalinka» справа (шрифты конвертируются в кривые `<path>`, исключая внешние веб-шрифтовые зависимости).

---

## 3. Критический аудит компонента `Logo.tsx` и фильтра `dark:invert`

В файле `packages/ui/components/logo/Logo.tsx`:
```tsx
<img
  className={classNames(small ? "h-4 w-auto" : "h-5 w-auto", "dark:invert")}
  alt="Cal.diy"
  title="Cal.diy"
  src={src}
/>
```
> [!CAUTION]
> **Архитектурный дефект исходника:** Класс `dark:invert` в тёмной теме инвертирует цвета изображения через CSS-фильтр `filter: invert(1)`. Для монохромного чёрно-белого Cal.com это работало, но для цветного знака Kalinka это **недопустимо**:
> - Насыщенно-красные ягоды калины (`#C23636`) при инверсии превратятся в **ядовито-бирюзовый (cyan/green)** цвет!
> - Тёплый крем (`#F6EFE4`) превратится в грязно-синий.
>
> **Обязательное решение:**
> 1. Удалить класс `dark:invert` из `packages/ui/components/logo/Logo.tsx`.
> 2. В `Logo.tsx` передавать тему или использовать селекторы темы: в светлой теме запрашивать `/api/logo?type=logo`, в тёмной теме — `/api/logo?type=logo-dark` (или отдавать адаптивный SVG с медиа-запросом `@media (prefers-color-scheme: dark)`).

---

## 4. Аудит внешних ссылок и юридических документов Cal.com

В коде найдены следующие внешние URL-адреса:
1. `WEBSITE_PRIVACY_POLICY_URL`: `process.env.NEXT_PUBLIC_WEBSITE_PRIVACY_POLICY_URL || "https://cal.com/privacy"`
   - Используется: футер формы бронирования `BookEventForm.tsx`, страница регистрации `signup-view.tsx`.
2. `WEBSITE_TERMS_URL`: `process.env.NEXT_PUBLIC_WEBSITE_TERMS_URL || "https://cal.com/terms"`
   - Используется: чекбокс согласия при регистрации и бронировании.
3. `DOCS_URL`: `"https://cal.com/docs"`
   - Используется: страница 404 (`apps/web/app/notFoundClient.tsx`), swagger API v2.
4. `DEVELOPER_DOCS`: `"https://developer.cal.com"`
5. `ROADMAP`: `"https://cal.com/roadmap"`
6. `SUPPORT_MAIL_ADDRESS`: `process.env.NEXT_PUBLIC_SUPPORT_MAIL_ADDRESS || "help@cal.com"`
7. `POWERED_BY_URL`: `"https://go.cal.com/booking"`

> [!IMPORTANT]
> **Принцип честности контактов:**
> Мы **не создаём фиктивных юридических документов или неработающих почтовых ящиков** от имени Kalinka.
> - `WEBSITE_PRIVACY_POLICY_URL` и `WEBSITE_TERMS_URL`: в MVP сохраняются ссылки на стандартные открытые условия Cal.diy/Cal.com либо нейтральный локальный роут `/terms` с базовой заглушкой открытой лицензии MIT, если пользователь определит его переменными окружения `NEXT_PUBLIC_WEBSITE_TERMS_URL`.
> - `SUPPORT_MAIL_ADDRESS`: не заменяется на фиктивный email, а настраивается через `NEXT_PUBLIC_SUPPORT_MAIL_ADDRESS` только при наличии реального почтового сервера у владельца проекта.
> - `POWERED_BY_URL`: перенаправляется на репозиторий форка `https://github.com/p1nkma/kalinka` или заменяется на надпись «Работает на Kalinka (Open Source)».

---

## 5. Точный маппинг дизайн-токенов в `tokens.css` (Стиль Folk-tech)

По результатам проверки контрастности WCAG 2.1 (AA/AAA) для утверждённой палитры:
- **Canvas Cream (`#FAF6F0` / `#F6EFE4`)**:
  - `Embroidery Red (#C23636)` на кремовом фоне имеет контраст **4.74:1** (Превосходит норматив WCAG AA 4.5:1 для обычного текста и 3.0:1 для кнопок и иконок).
  - Текст кнопок: белый (`#FFFFFF`, контраст **5.42:1**) или Warm Ivory (`#F6EFE4`, контраст **4.74:1**).
- **Dark Mode (Muted Black `#1A1A1B` / Charcoal `#2B2B2E`)**:
  - Для основного акцента интерактивных элементов в тёмной теме используется калиброванный ягодный оттенок `Berry Red (#E85D5D)` или `(#D35A63)`, обеспечивающий контрастность от **3.64:1** до **4.48:1**.

### Маппинг в `packages/config/theme/tokens.css`:
```css
/* Light Mode (:root, :host) */
--cal-brand: #C23636;                  /* Утверждённый Viburnum Red */
--cal-brand-emphasis: #A82A2A;         /* Тёмно-красный для hover состояний */
--cal-brand-text: #FFFFFF;             /* Высококонтрастный текст кнопок */
--cal-brand-subtle: #D35A63;           /* Вторичный ягодный оттенок */
--cal-brand-accent: #F6EFE4;           /* Warm Ivory акцент */

/* Backgrounds (опционально для editorial-вклада) */
--cal-bg: #FFFFFF;                     /* Чистые белые карточки */
--cal-bg-subtle: #FAF6F0;              /* Тёплый кремовый холст */
--cal-bg-muted: #F2ECE1;               /* Разделители и инпуты */

/* Dark Mode (.dark) */
--cal-brand: #E85D5D;                  /* Читаемый в темноте оттенок калины */
--cal-brand-emphasis: #C23636;         /* Акцент при наведении */
--cal-brand-text: #1A1A1B;             /* Контрастный тёмный текст на светящейся кнопке */
--cal-bg: #1A1A1B;                     /* Muted Black холст */
--cal-bg-subtle: #212226;              /* Графитовые карточки (как на сквиркле) */
--cal-bg-emphasis: #2B2B2E;            /* Выделенные блоки */
```
