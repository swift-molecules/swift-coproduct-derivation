public import SwiftSyntax

/// The canonical syntactic description of a finite coproduct declaration.
///
/// The analysis retains syntax nodes rather than lowering declarations to text so
/// that every coproduct-derived view agrees on case shape, payload shape, access,
/// and generic references.
extension Coproduct {
    public struct Analysis {
        public struct Case {
            public let element: EnumCaseElementSyntax
            public let name: TokenSyntax
            public let parameters: [EnumCaseParameterSyntax]
            public let payload: TypeSyntax

            public init(_ element: EnumCaseElementSyntax) {
                self.element = element
                name = element.name
                parameters = element.parameterClause.map {
                    Array($0.parameters)
                } ?? []
                payload = Self.payload(of: parameters)
            }

            public func references(_ parameter: TokenSyntax) -> Bool {
                parameters.contains { parameterDeclaration in
                    TypeReference.contains(
                        parameterDeclaration.type,
                        named: parameter.text
                    )
                }
            }

            public func isDirectReference(to parameter: TokenSyntax) -> Bool {
                guard
                    parameters.count == 1,
                    let identifier = parameters[0].type.as(IdentifierTypeSyntax.self)
                else { return false }
                return identifier.moduleSelector == nil
                    && identifier.genericArgumentClause == nil
                    && identifier.name.text == parameter.text
            }

            /// The label of an element in the multi-value payload tuple.
            public func tupleLabel(at offset: Int) -> TokenSyntax? {
                Self.tupleLabel(of: parameters[offset])
            }

            /// The label required when reconstructing this enum case.
            public func constructorLabel(at offset: Int) -> TokenSyntax? {
                let first = parameters[offset].firstName
                return first?.tokenKind == .wildcard ? nil : first
            }

            private static func payload(
                of parameters: [EnumCaseParameterSyntax]
            ) -> TypeSyntax {
                switch parameters.count {
                case 0:
                    return TypeSyntax(
                        IdentifierTypeSyntax(name: .identifier("Void"))
                    )
                case 1:
                    return parameters[0].type
                default:
                    let elements = parameters.enumerated().map { offset, parameter in
                        let label = tupleLabel(of: parameter)
                        return TupleTypeElementSyntax(
                            firstName: label,
                            colon: label == nil ? nil : .colonToken(trailingTrivia: .space),
                            type: parameter.type,
                            trailingComma: offset == parameters.count - 1
                                ? nil
                                : .commaToken(trailingTrivia: .space)
                        )
                    }
                    return TypeSyntax(
                        TupleTypeSyntax(elements: TupleTypeElementListSyntax(elements))
                    )
                }
            }

            private static func tupleLabel(
                of parameter: EnumCaseParameterSyntax
            ) -> TokenSyntax? {
                if let first = parameter.firstName, first.tokenKind != .wildcard {
                    return first
                }
                if let second = parameter.secondName, second.tokenKind != .wildcard {
                    return second
                }
                return nil
            }
        }

        public let declaration: EnumDeclSyntax?
        public let whole: TypeSyntax
        public let access: DeclModifierSyntax?
        public let cases: [Case]
        public let genericParameter: TokenSyntax?
        public let isCopyableSuppressed: Bool

        public init(_ declaration: EnumDeclSyntax) {
            let elements = declaration.memberBlock.members
                .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
                .flatMap(\.elements)
            self.init(
                declaration: declaration,
                whole: TypeSyntax(IdentifierTypeSyntax(name: declaration.name)),
                access: Self.access(of: declaration),
                cases: Array(elements),
                genericParameter: Self.unconstrainedParameter(of: declaration),
                isCopyableSuppressed: Self.suppressesCopyable(declaration)
            )
        }

        public init(
            whole: TypeSyntax,
            access: DeclModifierSyntax?,
            cases: [EnumCaseElementSyntax],
            genericParameter: TokenSyntax?,
            isCopyableSuppressed: Bool = false
        ) {
            self.init(
                declaration: nil,
                whole: whole,
                access: access,
                cases: cases,
                genericParameter: genericParameter,
                isCopyableSuppressed: isCopyableSuppressed
            )
        }

        private init(
            declaration: EnumDeclSyntax?,
            whole: TypeSyntax,
            access: DeclModifierSyntax?,
            cases: [EnumCaseElementSyntax],
            genericParameter: TokenSyntax?,
            isCopyableSuppressed: Bool
        ) {
            self.declaration = declaration
            self.whole = whole
            self.access = access
            self.cases = cases.map(Case.init)
            self.genericParameter = genericParameter
            self.isCopyableSuppressed = isCopyableSuppressed
        }

        private static func suppressesCopyable(
            _ declaration: EnumDeclSyntax
        ) -> Bool {
            declaration.inheritanceClause?.inheritedTypes.contains { inherited in
                guard
                    let suppressed = inherited.type.as(SuppressedTypeSyntax.self),
                    let identifier = suppressed.type.as(IdentifierTypeSyntax.self)
                else { return false }
                return identifier.moduleSelector == nil
                    && identifier.genericArgumentClause == nil
                    && identifier.name.text == "Copyable"
            } ?? false
        }

        private static func unconstrainedParameter(
            of declaration: EnumDeclSyntax
        ) -> TokenSyntax? {
            guard
                declaration.genericWhereClause == nil,
                let parameters = declaration.genericParameterClause?.parameters,
                parameters.count == 1,
                let parameter = parameters.first,
                parameter.attributes.isEmpty,
                parameter.specifier == nil,
                parameter.colon == nil,
                parameter.inheritedType == nil
            else { return nil }
            return parameter.name
        }

        private static func access(
            of declaration: EnumDeclSyntax
        ) -> DeclModifierSyntax? {
            for modifier in declaration.modifiers {
                switch modifier.name.tokenKind {
                case .keyword(.public), .keyword(.package), .keyword(.fileprivate):
                    return modifier
                case .keyword(.private):
                    return DeclModifierSyntax(name: .keyword(.fileprivate))
                default:
                    continue
                }
            }
            return nil
        }
    }
}

private final class TypeReference: SyntaxVisitor {
    private let name: String
    private var found = false

    private init(name: String) {
        self.name = name
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(
        _ node: IdentifierTypeSyntax
    ) -> SyntaxVisitorContinueKind {
        if node.name.text == name {
            found = true
            return .skipChildren
        }
        return .visitChildren
    }

    static func contains(_ type: TypeSyntax, named name: String) -> Bool {
        let reference = TypeReference(name: name)
        reference.walk(type)
        return reference.found
    }
}
