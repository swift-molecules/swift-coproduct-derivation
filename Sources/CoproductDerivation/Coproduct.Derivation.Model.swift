// Coproduct.Derivation.Model.swift

public import DeclarationDerivationDiagnostics
public import DeclarationDerivationModel

/// Namespace for nominal coproduct derivation.
///
/// `Coproduct` owns the coproduct view over the derivation family's shared
/// declaration model: the nominal coproduct model (`Coproduct.Derivation.Model`),
/// the exhaustive fold emitter (`Coproduct.Derivation.Emitter`), the optional
/// prism emitter (`Coproduct.Derivation.PrismEmitter`) and the generation
/// contract (`Coproduct.GenerationContract`). The `@Coproduct` attached macro
/// is a thin front over this core.
public enum Coproduct {}

extension Coproduct {
  /// Namespace for the coproduct derivation machinery.
  public enum Derivation {}
}

extension Coproduct.Derivation {
  /// The nominal coproduct view of a normalized declaration.
  ///
  /// The model consumes `Declaration.IR` — it never re-derives structure
  /// from syntax — and admits enumerations only: a nominal coproduct is a
  /// closed, ordered set of named alternatives. Case order is semantic:
  /// the derived fold preserves it. A case may carry one normalized
  /// payload type reference plus the label and default-value spellings the
  /// source declared, which the model preserves verbatim.
  public struct Model: Hashable, Sendable {

    /// One alternative of the coproduct.
    public struct Case: Hashable, Sendable {
      public let name: Declaration.Node.Name
      /// The normalized payload type, when the source declares one.
      public let payloadTypeReference: Declaration.Node.Member.TypeReference?
      /// The payload's explicit label, preserved verbatim.
      public let payloadLabel: Declaration.Node.Member.Label?
      /// The payload's default-value spelling, preserved verbatim.
      public let payloadDefaultValue: Declaration.Node.Member.DefaultValue?

      public init(
        name: Declaration.Node.Name,
        payloadTypeReference: Declaration.Node.Member.TypeReference? = nil,
        payloadLabel: Declaration.Node.Member.Label? = nil,
        payloadDefaultValue: Declaration.Node.Member.DefaultValue? = nil
      ) {
        self.name = name
        self.payloadTypeReference = payloadTypeReference
        self.payloadLabel = payloadLabel
        self.payloadDefaultValue = payloadDefaultValue
      }
    }

    public let name: Declaration.Node.Name
    /// Cases in declaration order.
    public let cases: [Case]

    /// The coproduct view of an analyzed IR.
    ///
    /// Throws the stable unsupported-kind diagnostic when the IR is not
    /// an enumeration: structures and actors are products, not
    /// coproducts, and stay outside this generation contract.
    public init(
      _ intermediateRepresentation: Declaration.IR
    ) throws(Declaration.Derivation.Diagnostic) {
      let node = intermediateRepresentation.node
      guard node.kind == .enumeration else {
        throw Declaration.Derivation.Diagnostic(
          code: .unsupportedDeclarationKind,
          subject: node.name,
          detail: "coproduct derivation covers enumerations only"
        )
      }
      self.name = node.name
      self.cases = node.members.map { member in
        Case(
          name: member.name,
          payloadTypeReference: member.typeReference,
          payloadLabel: member.label,
          payloadDefaultValue: member.defaultValue
        )
      }
    }
  }
}

extension Coproduct {
  /// The contract between the coproduct generator and its consumers.
  ///
  /// The contract answers two questions deterministically: which output
  /// the coproduct generator owns (so handwritten declarations outside the
  /// contract are never touched) and which provenance every generated
  /// expansion must carry (contract revision, IR schema version and the
  /// exact package version pin of the generator). Consumers admit
  /// expansion-behavior exceptions only when their resolved pin matches
  /// the receipt's pin exactly.
  public struct GenerationContract: Hashable, Sendable {

    public let revision: Declaration.GenerationContract.Revision
    public let schemaVersion: Declaration.IR.SchemaVersion
    public let packageVersionPin: Declaration.GenerationContract.PackageVersionPin

    public init(
      revision: Declaration.GenerationContract.Revision,
      schemaVersion: Declaration.IR.SchemaVersion,
      packageVersionPin: Declaration.GenerationContract.PackageVersionPin
    ) {
      self.revision = revision
      self.schemaVersion = schemaVersion
      self.packageVersionPin = packageVersionPin
    }
  }
}

extension Coproduct.GenerationContract {

  /// Coproduct.GenerationContract.v1 — the contract this package emits
  /// under at TX-D2.
  public static let version1 = Coproduct.GenerationContract(
    revision: Declaration.GenerationContract.Revision("1"),
    schemaVersion: .version1,
    packageVersionPin: Declaration.GenerationContract.PackageVersionPin(
      "swift-primitives/swift-coproduct-derivation@main"
    )
  )

  /// The file-name suffix that marks a rendered file as owned by the
  /// coproduct generation contract. Anything without the suffix is
  /// handwritten and outside the contract.
  public static let generatedFileNameSuffix = "+CoproductDerivation.generated.swift"

  /// Whether a file name identifies output owned by the coproduct
  /// generation contract.
  public func isGenerated(fileName: String) -> Bool {
    fileName.hasSuffix(Self.generatedFileNameSuffix)
  }

  /// The provenance record every generated expansion carries:
  /// contract revision, IR schema version and package pin.
  public var provenance: String {
    "contract-revision=\(revision.text);ir-schema=\(schemaVersion.identifier);package-version-pin=\(packageVersionPin.text)"
  }
}
