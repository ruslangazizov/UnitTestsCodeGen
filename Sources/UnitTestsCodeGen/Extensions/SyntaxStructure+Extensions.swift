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

    func getClassesOrStructsOrExtensions(with name: String?) -> [SyntaxStructure] {
        var subStructures: [SyntaxStructure] = []
        for subStructure in substructures ?? [] {
            if subStructure.isClassOrStructOrExtension() && subStructure.name == name {
                subStructures.append(subStructure)
            }
        }
        return subStructures
    }

    func getInheritedTypes() -> [String] {
        inheritedTypes?.compactMap { $0.name } ?? []
    }

    func getInitParams(in file: File) -> [SwiftMethodArgument] {
        let params = parseInitMethod()
        if params.isEmpty && kind == "source.lang.swift.decl.struct" {
            return parseStructSynthesizedInit(in: file)
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

    func isMockOrStub() -> Bool {
        guard let name = name?.lowercased() else { return false }
        return name.isMockOrStub()
    }

    func isInitMethod() -> Bool {
        kind == "source.lang.swift.decl.function.method.instance" &&
        name?.hasPrefix("init(") == true
    }

    func isInstanceMethod() -> Bool {
        kind == "source.lang.swift.decl.function.method.instance"
    }

    func isNonPrivateInstanceMethodOrProperty() -> Bool {
        accessibility != "source.lang.swift.accessibility.private" &&
        accessibility != "source.lang.swift.accessibility.fileprivate" &&
        (
            isInstanceMethod() ||
            kind == "source.lang.swift.decl.var.instance"
        )
    }

    func getActualName() -> String? {
        guard let name = name else { return nil }
        return String(name.prefix(while: { $0 != "(" }))
    }

    func parseMethodParams() -> [SwiftMethodArgument] {
        guard let name = name,
              let substructures = substructures,
              let methodParamsStringOpeningBracketIndex = name.firstIndex(of: "("),
              let methodParamsStringClosingBracketIndex = name.lastIndex(of: ")") else { return [] }

        let methodParamsStringStartIndex = name.index(after: methodParamsStringOpeningBracketIndex)
        let methodParamsStringLastIndex = name.index(before: methodParamsStringClosingBracketIndex)
        guard methodParamsStringStartIndex < methodParamsStringLastIndex else { return [] }
        let methodParamsLabelsString = name[methodParamsStringStartIndex...methodParamsStringLastIndex]
        let methodParamsLabels = methodParamsLabelsString.split(separator: ":").map { String($0) }

        var params: [SwiftMethodArgument] = []
        for (paramStructure, paramLabel) in zip(substructures, methodParamsLabels) {
            guard let name = paramStructure.name,
                  let typename = paramStructure.typename else { continue }
            let usingName = paramLabel == "_" ? nil : paramLabel
            params.append(SwiftMethodArgument(name: name, usingName: usingName, typeName: typename))
        }
        return params
    }
}

private extension SyntaxStructure {

    func isClassOrStruct() -> Bool {
        kind == "source.lang.swift.decl.class" || kind == "source.lang.swift.decl.struct"
    }

    func isClassOrStructOrExtension() -> Bool {
        isClassOrStruct() || kind == "source.lang.swift.decl.extension"
    }

    func parseInitMethod() -> [SwiftMethodArgument] {
        substructures?.first(where: { $0.isInitMethod() })?.parseMethodParams() ?? []
    }

    func parseStructSynthesizedInit(in file: File) -> [SwiftMethodArgument] {
        let fileContents = file.contents.utf8
        var params: [SwiftMethodArgument] = []
        for subStructure in substructures ?? [] {
            guard subStructure.kind == "source.lang.swift.decl.var.instance",
                  subStructure.bodylength == nil,
                  !subStructure.attributesContainLazy(),
                  let offset = subStructure.offset,
                  let length = subStructure.length else { continue }
            let start = fileContents.index(fileContents.startIndex, offsetBy: offset)
            let end = fileContents.index(start, offsetBy: length)
            if let propertyLine = String(fileContents[start..<end]),
               !propertyLine.contains("="),
               !(propertyLine.hasPrefix("var") && propertyLine.hasSuffix("?")),
               let name = subStructure.name,
               let typename = subStructure.typename {
                params.append(SwiftMethodArgument(name: name, usingName: name, typeName: typename))
            }
        }
        return params
    }
}
