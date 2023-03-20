//
//  SyntaxStructure+Extensions.swift
//  UnitTestsCodeGen
//
//  Created by Руслан on 20.03.2023.
//

import Foundation
import SourceKittenFramework

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
}

extension SyntaxStructure {

    func getClassOrStruct(with name: String?) -> SyntaxStructure? {
        for subStructure in substructures ?? [] {
            if subStructure.isClassOrStruct() && subStructure.name == name {
                return subStructure
            }
        }
        return nil
    }

    func getInheritedTypes(for typeName: String) -> [String] {
        var inheritedTypes: [String] = []
        for subStructure in substructures ?? [] {
            if subStructure.isClassOrStructOrExtension() && subStructure.name == typeName {
                inheritedTypes += subStructure.inheritedTypes?.compactMap { $0.name } ?? []
            }
        }
        return inheritedTypes
    }

    func getInitParams(at path: String) -> [String: String] {
        let params = parseInitMethod()
        if params.isEmpty && kind == "source.lang.swift.decl.struct" {
            return parseStructSynthesizedInit(at: path)
        }
        return params
    }

    func attributesContainLazy() -> Bool {
        if let attributesNames = attributes?.compactMap({ $0.attribute }) {
            return attributesNames.contains("lazy")
        } else {
            return false
        }
    }
}

private extension SyntaxStructure {

    func isClassOrStruct() -> Bool {
        kind == "source.lang.swift.decl.class" || kind == "source.lang.swift.decl.struct"
    }

    func isClassOrStructOrExtension() -> Bool {
        isClassOrStruct() || kind == "source.lang.swift.decl.extension"
    }

    func parseInitMethod() -> [String: String] {
        var params: [String: String] = [:]
        for subStructure in substructures ?? [] {
            guard subStructure.kind == "source.lang.swift.decl.function.method.instance",
                  subStructure.name?.hasPrefix("init(") == true else { continue}
            for paramStructure in subStructure.substructures ?? [] {
                guard let name = paramStructure.name,
                      let typename = paramStructure.typename else { continue }
                params[name] = typename
            }
        }
        return params
    }

    func parseStructSynthesizedInit(at path: String) -> [String: String] {
        guard let contents = File(path: path)?.contents.utf8 else { return [:] }
        var params: [String: String] = [:]
        for subStructure in substructures ?? [] {
            guard subStructure.kind == "source.lang.swift.decl.var.instance",
                  subStructure.bodylength == nil,
                  !subStructure.attributesContainLazy(),
                  let offset = subStructure.offset,
                  let length = subStructure.length else { continue }
            let start = contents.index(contents.startIndex, offsetBy: offset)
            let end = contents.index(start, offsetBy: length)
            if let propertyLine = String(contents[start..<end]),
               !propertyLine.contains("="),
               let name = subStructure.name,
               let typename = subStructure.typename {
                params[name] = typename
            }
        }
        return params
    }
}
