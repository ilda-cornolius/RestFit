# RestFit

A cross-platform wellness app built with **Swift** and **SwiftUI**, targeting **iOS**, **Android**, and **macOS** from a single codebase using [Skip](https://skip.dev).

RestFit helps you track **intermittent fasting**, **sleep quality**, and **weight**, with personalized guidance based on your daily rhythm.

## Features

- **Fasting tracker** — live timer, progress ring, protocol selection (16:8, 18:6, 20:4)
- **Sleep tracking** — quality scores, weekly trends, log sleep sessions
- **Weight journey** — current weight vs target, trend charts
- **Personalized guidance** — coaching tips based on your fasting, sleep, and weight data
- **Dark wellness UI** — ported from your UXPilot React design (mint/coral palette)

## Platform support

| Platform | Support | How |
|----------|---------|-----|
| iOS | ✅ | Native SwiftUI |
| Android | ✅ | Skip → Jetpack Compose |
| macOS | ✅ | Native SwiftUI (desktop) |
| Web | ❌ | Not supported by Skip today |

> **Note:** Pure Swift via Skip covers iOS and Android natively. macOS works through the same SwiftUI codebase. For web, you would need a separate target (e.g. your React export) or a framework like Flutter/React Native.

## Requirements

- macOS with **Xcode 15+** (full Xcode, not just Command Line Tools)
- [Skip](https://skip.dev/docs/gettingstarted/) (`brew tap skiptools/skip && brew trust skiptools/skip && brew install skip`)
- Android Studio (for Android emulator)

## Getting started

1. **Verify Skip setup:**
   ```bash
   skip checkup
   ```

2. **Open in Xcode:**
   ```bash
   open Project.xcworkspace
   ```

3. **Run on iOS:** Select the "RestFit App" scheme and an iPhone simulator, then press Run.

4. **Run on Android:**
   ```bash
   skip android emulator create   # first time only
   skip android emulator launch
   ```
   Then run from Xcode — Skip builds both platforms simultaneously.

5. **Run on macOS:** Add a macOS destination in Xcode (the project already targets macOS 14+).

## Project structure

```
Sources/RestFit/
├── Models/          # Fasting, sleep, weight data models
├── Services/        # WellnessStore (persistence) + WellnessGuide (coaching)
├── Theme/           # Colors and shared UI styles
└── Views/           # Home, Fast, Sleep, Profile screens
```

## Origin

The UI is based on your UXPilot React export (`uxpilot-react-export`), reimplemented in SwiftUI for native cross-platform performance.

## License

See Skip project defaults. Customize as needed for your app store release.
