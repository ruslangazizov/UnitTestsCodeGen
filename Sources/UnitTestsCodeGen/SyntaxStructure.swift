//
//  SyntaxStructure.swift
//  UnitTestsCodeGen
//
//  Created by Руслан on 12.03.2023.
//

import Foundation

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
    let substructures: [SyntaxStructure]?
    let typename: String?
    let setteraccessibility: String?

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
        case substructures = "key.substructure"
        case typename = "key.typename"
        case setteraccessibility = "key.setter_accessibility"
    }
}
