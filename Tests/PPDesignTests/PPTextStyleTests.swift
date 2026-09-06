import SwiftUI
import Testing
@testable import PPDesign

@Suite("Typography")
struct PPTextStyleTests {
    @Test("Each style is built on the Apple text style it says it is")
    func mapsOntoApplesTextStyles() {
        // Every style is a named one of Apple's rather than a point size, which
        // is what makes the text grow when someone turns type size up in
        // Settings — the setting that decides whether the app is usable at all
        // for a lot of people. The type makes a fixed size impossible to write;
        // this pins down which style each name actually got.
        #expect(PPTextStyle.screenTitle.textStyle == .largeTitle)
        #expect(PPTextStyle.sectionTitle.textStyle == .title3)
        #expect(PPTextStyle.cardTitle.textStyle == .headline)
        #expect(PPTextStyle.body.textStyle == .body)
        #expect(PPTextStyle.caption.textStyle == .footnote)
        #expect(PPTextStyle.number.textStyle == .title)
        #expect(PPTextStyle.buttonLabel.textStyle == .body)
    }

    @Test("Numbers use monospaced digits, and nothing else does")
    func onlyNumbersAreMonospaced() {
        #expect(PPTextStyle.number.usesMonospacedDigits)

        for (name, style) in PPTextStyle.all where name != "number" {
            #expect(
                style.usesMonospacedDigits == false,
                "\(name) is monospaced, which will make ordinary words look wrong"
            )
        }
    }

    @Test("Text people read at length uses the plain typeface, not the rounded one")
    func readingTextIsNotRounded() {
        // Rounded is right for a heading or a big number and tiring over a
        // chapter of scripture or a page of lecture notes.
        for (name, style) in PPTextStyle.readingStyles {
            #expect(style.design == .default, "\(name) is set in a display typeface")
        }
    }

    @Test("Headings, numbers and buttons carry the family's rounded look")
    func furnitureIsRounded() {
        #expect(PPTextStyle.screenTitle.design == .rounded)
        #expect(PPTextStyle.sectionTitle.design == .rounded)
        #expect(PPTextStyle.cardTitle.design == .rounded)
        #expect(PPTextStyle.number.design == .rounded)
        #expect(PPTextStyle.buttonLabel.design == .rounded)
    }

    @Test("Headings get heavier as they get more important")
    func weightsAreOrdered() {
        #expect(PPTextStyle.screenTitle.weight == .bold)
        #expect(PPTextStyle.sectionTitle.weight == .semibold)
        #expect(PPTextStyle.body.weight == .regular)
    }

    @Test("The seven styles are seven different fonts")
    func stylesAreDistinct() {
        // Not a test of what each font is — that is the mapping above — but of
        // the thing that would make the whole set pointless: two names that
        // quietly produce the same thing.
        for (leftName, left) in PPTextStyle.all {
            for (rightName, right) in PPTextStyle.all where leftName != rightName {
                #expect(left != right, "\(leftName) and \(rightName) are the same style")
            }
        }

        #expect(PPTextStyle.all.count == 7)
        #expect(PPTextStyle.body.font != PPTextStyle.screenTitle.font)
    }
}
