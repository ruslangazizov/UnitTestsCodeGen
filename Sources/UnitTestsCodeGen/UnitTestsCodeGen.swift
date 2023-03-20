//
//  UnitTestsCodeGen.swift
//  UnitTestsCodeGen
//
//  Created by Руслан on 05.03.2023.
//

import Foundation
import ArgumentParser
import SourceKittenFramework

// MARK: - Abstracts

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
        guard let (path, fileStructure, targetStructure) = findFile(by: typeName) else {
            print("Did not find \(typeName) anywhere :(")
            return
        }

        let names = fileStructure.getInheritedTypes(for: typeName)
        print("Found \(typeName) in file \(path) inherited from \(names)")

        let params = targetStructure.getInitParams(at: path)
        if !params.isEmpty {
            print("Found init method with params: \(params)")
        } else {
            print("Did not find init method and could not infer it :(")
            return
        }
    }

    // MARK: - Private

    private func findFile(by typeName: String) -> (path: String,
                                                   fileStructure: SyntaxStructure,
                                                   targetStructure: SyntaxStructure)? {
        let manager = FileManager.default
        let directoryPath = manager.currentDirectoryPath
        let enumerator = manager.enumerator(atPath: directoryPath)
        while let element = enumerator?.nextObject() as? String {
            let filePath = "\(directoryPath)/\(element)"
            guard !element.hasPrefix("."),
                  element.hasSuffix(".swift"),
                  let file = File(path: filePath),
                  let fileStructure = SyntaxStructure.from(file),
                  let targetStructure = fileStructure.getClassOrStruct(with: typeName) else { continue }
            return (filePath, fileStructure, targetStructure)
        }
        return nil
    }
}
