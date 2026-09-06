import SwiftUI
import Testing
@testable import PPDesign

@Suite("Spacing and corners")
struct PPSpacingTests {
    @Test("The spacing scale only ever gets bigger")
    func scaleIncreases() {
        #expect(PPSpacing.scale == PPSpacing.scale.sorted())
        #expect(Set(PPSpacing.scale).count == PPSpacing.scale.count)
    }

    @Test("Every gap sits on a four-point grid")
    func scaleIsOnTheGrid() {
        // The reason two screens built by different people line up.
        for step in PPSpacing.scale {
            #expect(step > 0)
            #expect(step.truncatingRemainder(dividingBy: 4) == 0, "\(step) is off the grid")
        }
    }

    @Test("The smallest tappable thing is Apple's 44 points")
    func tapTargetMatchesApplesGuidance() {
        #expect(PPSpacing.minimumTapTarget == 44)
    }

    @Test("The screen margin is the everyday gap, until someone decides otherwise")
    func screenMarginStartsAtMedium() {
        #expect(PPSpacing.screenMargin == PPSpacing.medium)
    }

    @Test("Corners only ever get rounder")
    func radiusScaleIncreases() {
        #expect(PPRadius.scale == PPRadius.scale.sorted())
        #expect(Set(PPRadius.scale).count == PPRadius.scale.count)
        #expect(PPRadius.small > 0)
    }
}
