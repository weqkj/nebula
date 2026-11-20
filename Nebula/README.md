# Nebula (iOS SwiftUI)

Нативный клиент Xray в стиле **Material You 3** и **Liquid Glass**.

## Структура проекта
- `App/NebulaApp.swift` — точка входа
- `App/Theme.swift` — тональные палитры Material 3, обои, приветствие по времени суток
- `App/Models.swift` — парсер VLESS / TCP / Trojan / VMess / HTTPS подписок
- `App/VPNManager.swift` — управление профилями и `NETunnelProviderManager`
- `App/Views.swift` — Onboarding, Liquid Glass Tab Bar, экраны туннеля, узлов и стиля
- `Tunnel/PacketTunnelProvider.swift` — расширение `NEPacketTunnelProvider` для ядра Xray/Sing-box

## Сборка .ipa через GitHub Actions
1. Загрузите содержимое папки `Nebula/` в репозиторий GitHub.
2. Откройте **Actions → Build Nebula IPA → Run workflow**.
3. Скачайте артефакт `Nebula-IPA` и установите через TrollStore, AltStore или SideStore.
