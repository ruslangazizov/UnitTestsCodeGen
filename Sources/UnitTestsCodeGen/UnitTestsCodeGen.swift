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

    private func findFile(by typeName: String) -> (path: String, structure: SyntaxStructure)? {
        let manager = FileManager.default
        let directoryPath = manager.currentDirectoryPath
        let enumerator = manager.enumerator(atPath: directoryPath)
        while let element = enumerator?.nextObject() as? String {
            let filePath = "\(directoryPath)/\(element)"
            guard !element.hasPrefix("."),
                  element.hasSuffix(".swift"),
                  let file = File(path: filePath),
                  let structure = SyntaxStructure.from(file),
                  let targetStructure = structure.getClassOrStruct(),
                  targetStructure.name == typeName else { continue }
            return (filePath, targetStructure)
        }
        return nil
    }
}
