import SwiftUI
import Testing
@testable import PPDesign

@Suite("Colors")
struct PPColorTests {
    @Test("A color gives its light value in light and its dark value in dark")
    func picksByAppearance() {
        let color = PPColor(light: 0xFFFFFF, dark: 0x000000)

        #expect(color.hex(for: .light) == 0xFFFFFF)
        #expect(color.hex(for: .dark) == 0x000000)
    }

    @Test("Hex digits split into red, green and blue")
    func splitsChannels() {
        let (red, green, blue) = PPColor.channels(of: 0xFF8000)

        #expect(red == 1)
        #expect(abs(green - 128.0 / 255.0) < 0.0001)
        #expect(blue == 0)
    }

    @Test("Black and white are the most readable pair there is")
    func extremeContrast() {
        let black = PPColor(light: 0x000000, dark: 0x000000)
        let white = PPColor(light: 0xFFFFFF, dark: 0xFFFFFF)

        // 21 is the top of the WCAG scale.
        #expect(abs(black.contrastRatio(against: white, in: .light) - 21) < 0.01)
    }

    @Test("A color against itself is invisible")
    func noContrastWithItself() {
        let color = PPColor(light: 0x0E6E62, dark: 0x4FD1C5)

        #expect(abs(color.contrastRatio(against: color, in: .light) - 1) < 0.0001)
        #expect(abs(color.contrastRatio(against: color, in: .dark) - 1) < 0.0001)
    }

    @Test("Contrast reads the same in either order")
    func contrastIsSymmetric() {
        let ink = PPColor(light: 0x1A1A1A, dark: 0xF2F0EE)
        let paper = PPColor(light: 0xFBF9F7, dark: 0x121212)

        #expect(
            abs(
                ink.contrastRatio(against: paper, in: .light)
                    - paper.contrastRatio(against: ink, in: .light)
            ) < 0.0001
        )
    }

    @Test("Green reads as brighter than blue at the same number")
    func luminanceIsWeighted() {
        // Not an implementation detail worth pinning down to a decimal — it is
        // the reason a plain average of the three channels is the wrong maths,
        // and the reason this is copied from the specification.
        #expect(PPColor.relativeLuminance(of: 0x00FF00) > PPColor.relativeLuminance(of: 0x0000FF))
        #expect(PPColor.relativeLuminance(of: 0x000000) == 0)
        #expect(abs(PPColor.relativeLuminance(of: 0xFFFFFF) - 1) < 0.0001)
    }
}
