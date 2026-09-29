# Aery Air

A native macOS reimplementation of the Aery32 model-glider design tool. Aery Air is designed for Apple-silicon Macs, including the MacBook Air M3.

## Run on a Mac

Install Xcode 16 or newer, then either open `Package.swift` in Xcode and press Run, or use Terminal:

```sh
swift run AeryAir
```

The app is intentionally self-contained: edit the wing, tail, mass, and balance values; the planform and flight assessment update immediately.

## Easy install

Download `AeryAir-macOS.dmg` from the latest GitHub release, open it, and drag **Aery Air** to Applications. It is built for macOS 14+ and Apple Silicon. The bundle is ad-hoc signed but not notarized; on first launch, macOS may ask you to Control-click the app and choose **Open**.

## Scope

This is a clean-room SwiftUI implementation based on the published Aery32 documentation and observed behavior. It does not reuse the original Visual Basic binary or source code.

Original Aery/Aery32: Copyright © 1996–2013 Alan S. Estenson. The original documentation permits free non-commercial distribution and disclaims warranties. Aery Air is an independent project; it is not affiliated with or endorsed by the original author.
