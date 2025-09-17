# Vitrine

Vitrine is a Flutter app with a small shop and a live device list. It signs in against [DummyJSON](https://dummyjson.com), sells from its 194-product sample catalog, and shows simulated sensor readings for devices from [restful-api.dev](https://restful-api.dev).

**Try it:** the [web demo](https://hbproductionofficial.github.io/vitrine-flutter/), or the APK on the [Releases](https://github.com/HBProductionOfficial/vitrine-flutter/releases) page. The demo account is `emilys` / `emilyspass`, and the login screen can fill it in for you.

## Background

I started this as a take-home assignment for a Flutter job in November 2025. The brief asked for biometric login and a device list from restful-api.dev with a few specific behaviours:

- one row open at a time, with the open row scrolled fully into view
- a simulated update every 10 seconds that makes a changed value blink in an open row
- a dot on closed rows that changed, which clears when you open them
- clean architecture, plus tests for the login and the API calls

In October 2026 I rebuilt it from an empty project and kept going. The login is real now, and there's a shop, a cart and settings in three languages. The device list still behaves the way the brief describes.

## Features

- **Sign in** uses DummyJSON tokens, which refresh on their own when they expire. You can stay signed in, or unlock with a fingerprint or face after one password sign-in.
- **Shop** loads 20 products at a time and has search, categories and sorting. Each product page has a photo gallery, stock, shipping details and reviews, and you can add a review of your own.
- **Cart and saved items** stay on the device, separately for each account. Checkout sends the order to DummyJSON.
- **Devices** keeps the assignment's accordion and live readings, and you can add, edit and delete your own devices.
- **Settings** cover English, Georgian and Russian, light and dark themes, and biometric sign-in.

On a phone the tabs sit at the bottom. On tablets and the web they move to a side rail and the content stays centred.

## How it's built

Flutter 3.35 with Riverpod 3 for state, go_router for navigation and Dio for HTTP.

```
lib/src/
  core/        theme, networking, storage, biometrics, shared widgets
  features/
    auth/      data/  domain/  presentation/
    devices/
    shop/
    cart/
    saved/
    profile/
    settings/
    shell/     bottom bar and side rail
```

Each feature splits into three layers. `data` talks to the API, `domain` holds plain models and repository interfaces, and `presentation` has the Riverpod notifiers and the screens. Notifiers only see repository interfaces, so the tests can hand them fakes.

## Things to know

- DummyJSON doesn't store anything you send. Sign-up, password reset and orders get a believable response, and the app tells you nothing was saved. It has no way to post a review at all, so reviews you write stay on the phone.
- restful-api.dev allows about 50 requests a day. The app caches the device list and shows the saved copy with a note when the limit is reached. The 13 sample devices are read-only, so Edit and Delete only appear on devices you added.
- Android reports biometric strength, not the sensor type. Most Android phones therefore get a "Sign in with biometrics" button, while an iPhone with Face ID gets "Sign in with face".
- The web build has no biometric sign-in.
- Sorting uses DummyJSON's list price, but the grid shows the price after discount, so two neighbours can look a few cents out of order.
- The release APK is signed with the debug key. It installs from the file but isn't ready for an app store.

## Running it locally

```sh
flutter pub get
flutter run
```

`flutter test` runs 84 tests. They cover sign-in and session restore, the biometric checks, the token refresh, the device list (including the dot and the blink), the shop's paging and search, the cart totals, and your own reviews.

The app icon is drawn in code by the same painter as the logo on the login screen. `tool/render_icon.dart` has the two commands that regenerate it.

## License

[MIT](LICENSE)
