//
//  SyntaxStructure.swift
//  UnitTestsCodeGen
//
//  Created by Руслан on 12.03.2023.
//

import Foundation
import SourceKittenFramework

struct SyntaxStructure: Codable {

    let accessibility: String?
    let attribute: String?
    let attributes: [SyntaxStructure]?
    let bodylength: Int?
    let bodyoffset: Int?
    let diagnosticstage: String?
    let elements: [SyntaxStructure]?
    let inheritedTypes: [SyntaxStructure]?
    let kind: String?
    let length: Int?
    let name: String?
    let namelength: Int?
    let nameoffset: Int?
    let offset: Int?
    let runtimename: String?
    let substructure: [SyntaxStructure]?
    let typename: String?

    enum CodingKeys: String, CodingKey {
        case accessibility = "key.accessibility"
        case attribute = "key.attribute"
        case attributes = "key.attributes"
        case bodylength = "key.bodylength"
        case bodyoffset = "key.bodyoffset"
        case diagnosticstage = "key.diagnostic_stage"
        case elements = "key.elements"
        case inheritedTypes = "key.inheritedtypes"
        case kind = "key.kind"
        case length = "key.length"
        case name = "key.name"
        case namelength = "key.namelength"
        case nameoffset = "key.nameoffset"
        case offset = "key.offset"
        case runtimename = "key.runtime_name"
        case substructure = "key.substructure"
        case typename = "key.typename"
    }
}

extension SyntaxStructure {

    static func from(_ file: File) -> SyntaxStructure? {
        do {
            let structure = try Structure(file: file)
            guard let jsonData = structure.description.data(using: .utf8) else { return nil }
            return try JSONDecoder().decode(SyntaxStructure.self, from: jsonData)
        } catch {
            print(error)
            return nil
        }
    }

    func getClassOrStruct() -> SyntaxStructure? {
        if self.isClassOrStruct() {
            return self
        }
        for subStructure in self.substructure ?? [] {
            if let targetStructure = subStructure.getClassOrStruct() {
                return targetStructure
            }
        }
        return nil
    }
}

private extension SyntaxStructure {

    func isClassOrStruct() -> Bool {
        kind == "source.lang.swift.decl.class" ||
        kind == "source.lang.swift.decl.struct"
    }
}
