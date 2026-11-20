# Nebula — VLESS/Xray клиент (SwiftUI, Material You 3)

## Получить IPA (без Mac)
1. Создайте репозиторий на GitHub, залейте эту папку.
2. Actions → "Build IPA" → Run workflow → скачайте артефакт `Nebula.ipa`.
3. Установите через Sideloadly / AltStore / TrollStore (подпишут вашим Apple ID).

## Локально (Mac)
`brew install xcodegen && xcodegen generate && open Nebula.xcodeproj`

## Что работает
UI, парсер vless:// (tcp/ws/grpc, tls/reality), генерация Xray-конфига, хранение серверов.
Реальный туннель: добавить Network Extension таргет (Tunnel/), libXray.xcframework и tun2socks,
платный dev-аккаунт. Без этого кнопка работает в демо-режиме.
