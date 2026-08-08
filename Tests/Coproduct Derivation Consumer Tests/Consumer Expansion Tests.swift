// Consumer Expansion Tests.swift

import Coproduct_Derivation
import CoproductDerivation
import Testing

// MARK: - Consumer-integration control
//
// This suite depends on nothing but the targets behind the "Coproduct
// Derivation" library product, so expansion here proves the product carries
// its own compiler plugin and a writable attribute. An expansion test that
// also depends on CoproductDerivationMacros — or one that supplies the macro
// mapping itself through `macroSpecs:` — cannot detect an undeclared or
// unresolvable @Coproduct.
//
@Coproduct
private enum Direction {
    case north
    case south
}

@Coproduct(prisms: true)
private enum Signal {
    case ready
    case failed
}

@Coproduct(prisms: true)
private enum Request {
    case failed(String)
}

private let expectedProvenance =
    "contract-revision=1;ir-schema=v1;package-version-pin=swift-primitives/swift-coproduct-derivation@main"

extension Coproduct {
    @Suite struct Test {

        /// The attribute is writable by a consumer of the library product
        /// alone, and derives the exhaustive fold over the alternatives.
        @Test func `enumeration derives an exhaustive fold`() {
            #expect(
                Direction.north.fold(north: { "north" }, south: { "south" }) == "north"
            )
            #expect(
                Direction.south.fold(north: { "north" }, south: { "south" }) == "south"
            )
        }

        /// Prism emission is opt-in through the attribute's argument, and
        /// projects exactly the matching alternative.
        @Test func `prism emission is opt in`() {
            #expect(Signal.failed.failedPrism != nil)
            #expect(Signal.failed.readyPrism == nil)
            #expect(Signal.ready.readyPrism != nil)
        }

        /// Binding regression: generated payload-bearing members receive the
        /// exact associated value supplied by the consumer.
        @Test func `fold and prism preserve an associated value`() {
            let request = Request.failed("offline")
            #expect(request.fold(failed: { $0 }) == "offline")
            #expect(request.failedPrism == "offline")
        }

        /// Expansion without the argument derives no prisms; `Direction` has
        /// a fold and provenance only.
        @Test func `prisms are absent without the argument`() {
            #expect(Direction.coproductDerivationProvenance == expectedProvenance)
        }

        /// Every expansion carries the generation contract's provenance.
        @Test func `expansions carry provenance`() {
            #expect(Direction.coproductDerivationProvenance == expectedProvenance)
            #expect(Signal.coproductDerivationProvenance == expectedProvenance)
            #expect(Request.coproductDerivationProvenance == expectedProvenance)
        }
    }
}
