import Coproduct_Derivation
import Coproduct_Derivation_Core
import Testing

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

@Coproduct(prisms: true)
private enum Callback {
    case callback(@Sendable () -> Void)
    case idle
}

private let expectedProvenance =
    "contract-revision=1;ir-schema=v1;package-version-pin=swift-molecules/swift-coproduct-derivation@main"

extension Coproduct {
    @Suite struct Test {

        @Test func `enumeration derives an exhaustive fold`() {
            #expect(
                Direction.north.fold(north: { "north" }, south: { "south" }) == "north"
            )
            #expect(
                Direction.south.fold(north: { "north" }, south: { "south" }) == "south"
            )
        }

        @Test func `prism emission is opt in`() {
            #expect(Signal.failed.failedPrism != nil)
            #expect(Signal.failed.readyPrism == nil)
            #expect(Signal.ready.readyPrism != nil)
        }

        @Test func `fold and prism preserve an associated value`() {
            let request = Request.failed("offline")
            #expect(request.fold(failed: { $0 }) == "offline")
            #expect(request.failedPrism == "offline")
        }

        @Test func `function payload prism extracts the matching case only`() {
            let callback: @Sendable () -> Void = {}
            let value = Callback.callback(callback)
            guard let extracted = value.callbackPrism else {
                Issue.record("the matching callback case must extract its payload")
                return
            }
            extracted()
            if Callback.idle.callbackPrism != nil {
                Issue.record("a nonmatching callback case must not extract a payload")
            }
        }

        @Test func `prisms are absent without the argument`() {
            #expect(Direction.coproductDerivationProvenance == expectedProvenance)
        }

        @Test func `expansions carry provenance`() {
            #expect(Direction.coproductDerivationProvenance == expectedProvenance)
            #expect(Signal.coproductDerivationProvenance == expectedProvenance)
            #expect(Request.coproductDerivationProvenance == expectedProvenance)
            #expect(Callback.coproductDerivationProvenance == expectedProvenance)
        }
    }
}
