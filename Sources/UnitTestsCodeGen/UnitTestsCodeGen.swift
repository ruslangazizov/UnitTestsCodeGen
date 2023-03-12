//
//  UnitTestsCodeGen.swift
//  UnitTestsCodeGen
//
//  Created by Руслан on 05.03.2023.
//

import Foundation
import ArgumentParser
import SourceKittenFramework

private extension String {
    static let typeNameAbstract = "Name of a class or struct to test"
    static let fileNameAbstract = "Name of a file to be generated (without .swift extension)"
    static let configurationAbstract = "Generates unit test case class"
}

struct UnitTestsCodeGen: ParsableCommand {
    
    // MARK: - Arguments and options
    
    @Argument(help: .init(.typeNameAbstract)) var typeName: String
    @Option(name: .shortAndLong, help: .init(.fileNameAbstract)) var fileName: String?
    
    // MARK: - ParsableCommand
    
    static let configuration = CommandConfiguration(abstract: .configurationAbstract, version: "0.1.0")
    
    mutating func run() throws {
        print("You entered: typeName = \(typeName), fileName = \(String(describing: fileName))")
        if let (path, structure) = findFile(by: typeName) {
            let names = structure.inheritedTypes?.compactMap { $0.name } ?? []
            print("Found \(typeName) at file \(path) inherited from \(names)")
        } else {
            print("Did not find \(typeName) anywhere :(")
        }
    }
    
    // MARK: - Private
    
    private func findFile(by typeName: String) -> (path: String, SyntaxStructure)? {
        let manager = FileManager.default
        let path = manager.currentDirectoryPath
        let enumerator = manager.enumerator(atPath: path)
        while let element = enumerator?.nextObject() as? String {
            guard !element.hasPrefix("."),
                  element.hasSuffix(".swift"),
                  let file = File(path: "\(path)/\(element)"),
                  let structure = syntaxStructure(from: file),
                  let targetStructure = getClassOrStruct(structure) else { continue }
            if targetStructure.name == typeName {
                return ("\(path)/\(element)", targetStructure)
            }
        }
        return nil
    }
    
    private func getClassOrStruct(_ structure: SyntaxStructure) -> SyntaxStructure? {
        if isClassOrStruct(structure) {
            return structure
        }
        for subStructure in structure.substructure ?? [] {
            if let targetStructure = getClassOrStruct(subStructure) {
                return targetStructure
            }
        }
        return nil
    }
    
    private func isClassOrStruct(_ structure: SyntaxStructure) -> Bool {
        structure.kind == "source.lang.swift.decl.class" ||
        structure.kind == "source.lang.swift.decl.struct"
    }
    
    private func syntaxStructure(from file: File) -> SyntaxStructure? {
        do {
            let structure = try Structure(file: file)
            let jsonData = structure.description.data(using: .utf8)!
            return try JSONDecoder().decode(SyntaxStructure.self, from: jsonData)
        } catch {
            print(error)
            return nil
        }
    }
}
