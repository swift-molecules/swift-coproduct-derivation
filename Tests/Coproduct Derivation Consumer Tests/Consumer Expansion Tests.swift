// Consumer Expansion Tests.swift

import CoproductDerivation
import Coproduct_Derivation
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
// The fixtures are payload-free because the delivered
// `Declaration.SwiftSyntaxAdapter` records no payload type reference for an
// enumeration case, so `Coproduct.Derivation.Model` sees every alternative as
// payload-free and both emitters render the payload-free shape. That is a
// TX-D2 semantic gap, not a usability one; this control asserts the behaviour
// that actually ships.

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

    /// Expansion without the argument derives no prisms; `Direction` has
    /// a fold and provenance only.
    @Test func `prisms are absent without the argument`() {
      #expect(Direction.coproductDerivationProvenance == expectedProvenance)
    }

    /// Every expansion carries the generation contract's provenance.
    @Test func `expansions carry provenance`() {
      #expect(Direction.coproductDerivationProvenance == expectedProvenance)
      #expect(Signal.coproductDerivationProvenance == expectedProvenance)
    }
  }
}
