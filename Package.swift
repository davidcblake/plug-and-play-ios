// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PlugAndPlay",
    platforms: [
        .iOS(.v18),
        // Not a shipping target. The apps are iPhone only (decision 0004), but CI
        // runs `swift build` / `swift test` on a Mac, which compiles for the *host*.
        // With no macOS minimum declared, SwiftPM falls back to a default old enough
        // that SwiftUI, os.Logger and OSAllocatedUnfairLock are all unavailable and
        // nothing compiles. Paired with the iOS minimum rather than set lower, so a
        // module cannot use an API on iOS that the CI build then rejects.
        .macOS(.v15)
    ],
    products: [
        .library(name: "PPCore", targets: ["PPCore"]),
        .library(name: "PPDesign", targets: ["PPDesign"]),
        .library(name: "PPData", targets: ["PPData"]),
        .library(name: "PPAuth", targets: ["PPAuth"]),
        .library(name: "PPPay", targets: ["PPPay"]),
        .library(name: "PPNotify", targets: ["PPNotify"]),
        .library(name: "PPInput", targets: ["PPInput"]),
        .library(name: "PPOnboard", targets: ["PPOnboard"]),
    ],
    targets: [
        .target(name: "PPCore"),
        .testTarget(name: "PPCoreTests", dependencies: ["PPCore"]),

        .target(name: "PPDesign", dependencies: ["PPCore"]),
        .testTarget(name: "PPDesignTests", dependencies: ["PPDesign"]),

        .target(name: "PPData", dependencies: ["PPCore"]),
        .testTarget(name: "PPDataTests", dependencies: ["PPData"]),

        .target(name: "PPAuth", dependencies: ["PPCore"]),
        .testTarget(name: "PPAuthTests", dependencies: ["PPAuth"]),

        .target(name: "PPPay", dependencies: ["PPCore"]),
        .testTarget(name: "PPPayTests", dependencies: ["PPPay"]),

        .target(name: "PPNotify", dependencies: ["PPCore"]),
        .testTarget(name: "PPNotifyTests", dependencies: ["PPNotify"]),

        .target(name: "PPInput", dependencies: ["PPCore"]),
        .testTarget(name: "PPInputTests", dependencies: ["PPInput"]),

        .target(name: "PPOnboard", dependencies: ["PPCore"]),
        .testTarget(name: "PPOnboardTests", dependencies: ["PPOnboard"]),
    ],
    swiftLanguageModes: [.v6]
)
