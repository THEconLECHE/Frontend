# RoomieHub · App móvil (Flutter)

App para roomies: reparte los quehaceres según el esfuerzo acumulado de cada quien y registra los gastos compartidos
y quién confirmó cada pago. La API, el diagrama de arquitectura y los ADRs están en
[Ardillatron/RoomieHub_backend](https://github.com/Ardillatron/RoomieHub_backend).

## Equipo

- Josué Isaac Palacios Aguado — 333351 — Backend (Spring Boot), app Flutter, despliegue
- Isaías Rangel Ledezma — 333318 — Requerimientos, reglas de negocio, ADRs y pruebas

## Stack

Flutter (Dart), `http`, `flutter_secure_storage` para la sesión y Firebase Cloud Messaging para push.

## Arquitectura

Por módulo y luego por capa, en `lib/features/<módulo>/` (auth, house, chores, finances, board, chat, profile):

- `domain/`: entidades, repositorios abstractos (`FinanceRepository`) y casos de uso (`ConfirmPayment`)
- `data/`: implementaciones concretas (`HttpFinanceRepository`) y versiones en memoria para pruebas
- `presentation/`: páginas y widgets; llaman casos de uso, nunca HTTP directo

## Cómo correrlo

1. Requisitos: Flutter SDK con Dart 3.13 o posterior y un emulador o teléfono Android.
2. `flutter pub get`
3. `flutter run` (usa la API en Render). Para una API local:
   `flutter run --dart-define=API_URL=http://10.0.2.2:8080`
4. Pruebas: `flutter test`

## Descargar APK

[Descargar roomiehub.apk](https://github.com/Ardillatron/Frontonend/raw/main/apk/roomiehub.apk) (Android, apunta al backend en Render)
