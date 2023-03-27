//
//  PersistenceManager.swift
//  UnitTestsCodeGen
//
//  Created by Руслан on 27.03.2023.
//

import Foundation
import SourceKittenFramework

final class PersistenceManager {

    // Dependencies
    private let fileManager = FileManager.default
    private let commandLineManager: CommandLineManager

    // Properties
    private let cliArgs: CommandLineArguments

    // MARK: - Init

    init(commandLineManager: CommandLineManager,
         commandLineArguments: CommandLineArguments) {
        self.commandLineManager = commandLineManager
        self.cliArgs = commandLineArguments
    }

    // MARK: - Internal

    func findFile(by typeName: String) -> (targetFile: File,
                                           targetStructure: SyntaxStructure,
                                           filesSubStructures: [SyntaxStructure])? {
        let directoryPath = fileManager.currentDirectoryPath
        let enumerator = fileManager.enumerator(atPath: directoryPath)
        var targetFile: File?
        var targetStructure: SyntaxStructure?
        var filesSubStructures: [SyntaxStructure] = []
        while let element = enumerator?.nextObject() as? String {
            if !element.hasPrefix("."),
               element.hasSuffix(".swift"),
               let file = File(path: "\(directoryPath)/\(element)"),
               let fileStructure = SyntaxStructure.from(file) {
                filesSubStructures += fileStructure.getClassesOrStructsOrExtensions(with: typeName)
                if let structure = fileStructure.getClassOrStruct(with: typeName) {
                    targetFile = file
                    targetStructure = structure
                }
            }
        }
        if let targetFile = targetFile, let targetStructure = targetStructure {
            return (targetFile, targetStructure, filesSubStructures)
        }
        return nil
    }

    func createTestsFile() -> String? {
        let className = cliArgs.fileName ?? (cliArgs.typeName + "Tests")
        let fileName = className + ".swift"
        let testsFilePath = fileManager.currentDirectoryPath + "/" + fileName
        if fileManager.createFile(atPath: testsFilePath, contents: nil) {
            return testsFilePath
        } else {
            return nil
        }
    }

    func findMocks(for params: [String: String], tempFilePath: String) {
        let params = substituteTypesWithMocks(for: params)
        var paramsMocks = params.filter { $1.isMockOrStub() }
        if !paramsMocks.isEmpty {
            print("Found mocks for several params: \(paramsMocks)")
        }

        generateSourceryExtensions(in: tempFilePath, for: params)

        if let result = commandLineManager.runSourcery(imports: cliArgs.imports,
                                                       testableImports: cliArgs.testableImports) {
            print(result)
        }

        let mocksFolderPath = fileManager.currentDirectoryPath + "/" + cliArgs.mocksFolderName
        paramsMocks = substituteTypesWithMocks(for: params, in: mocksFolderPath)
    }

    // MARK: - Private

    private func generateSourceryExtensions(in filePath: String, for params: [String: String]) {
        let sourceryExtensions: [String] = params.values.compactMap {
            if $0.isMockOrStub() { return nil }
            var name = $0
            if name.hasSuffix("?") { name = name.trimmingQuestionMarksCharacters() }
            return "extension \(name): AutoMockable {}"
        }
        let contents = ["protocol AutoMockable {}"] + sourceryExtensions
        writeToFile(path: filePath, content: contents.joined(separator: "\n"))
    }

    private func writeToFile(path: String, content: String) {
        if let fileHandle = FileHandle(forWritingAtPath: path),
           let data = content.data(using: .utf8) {
            try? fileHandle.write(contentsOf: data)
            try? fileHandle.close()
        }
    }

    private func substituteTypesWithMocks(for params: [String: String],
                                          in directoryPath: String? = nil) -> [String: String] {
        var params = params.filter { !$1.isMockOrStub() }
        let directoryPath = directoryPath ?? fileManager.currentDirectoryPath
        let enumerator = fileManager.enumerator(atPath: directoryPath)
        while let element = enumerator?.nextObject() as? String {
            if !element.hasPrefix("."),
               element.hasSuffix(".swift"),
               let file = File(path: "\(directoryPath)/\(element)"),
               let fileStructure = SyntaxStructure.from(file) {
                for subStructure in fileStructure.substructures ?? [] {
                    guard subStructure.isMockOrStub(),
                          let name = subStructure.name else { continue }
                    let inheritedTypes = subStructure.getInheritedTypes()
                    for (paramName, paramType) in params {
                        let paramType = paramType.trimmingQuestionMarksCharacters()
                        if inheritedTypes.contains(paramType) {
                            params[paramName] = name
                            break
                        }
                    }
                }
            }
        }
        return params
    }
}
