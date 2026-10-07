# Aery

A native macOS port of the Aery32 model-glider design tool. It follows the original five-tab workflow: Main, Wing, Stabilizer, Vertical Tail, and Information.

## Run on a Mac

Install Xcode 16 or newer, then either open `Package.swift` in Xcode and press Run, or use Terminal:

```sh
swift run AeryAir
```

Use the slider bars for quick adjustments or enter a precise value beside a bar. The app reads and writes Aery32 `.ae` design files, including the geometry and embedded wood configuration, so original sample designs can be opened directly.

## Easy install

Download `AeryAir-macOS.dmg` from the latest GitHub release, open it, and drag **Aery** to Applications. It is built for macOS 14+ and Apple Silicon. The bundle is ad-hoc signed but not notarized; on first launch, macOS may ask you to Control-click the app and choose **Open**.

## Scope

This is a clean-room SwiftUI implementation based on the original Aery32 documentation, data files, and observed interface. It does not reuse the original Visual Basic binary or source code.

Original Aery/Aery32: Copyright © 1996–2013 Alan S. Estenson. The original documentation permits free non-commercial distribution and disclaims warranties. Aery Air is an independent project; it is not affiliated with or endorsed by the original author.
