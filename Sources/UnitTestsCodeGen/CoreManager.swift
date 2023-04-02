//
//  CoreManager.swift
//  UnitTestsCodeGen
//
//  Created by Руслан on 27.03.2023.
//

import Foundation
import SourceKittenFramework

final class CoreManager {

    // Dependencies
    private let fileManager = FileManager.default
    private let commandLineManager: CommandLineManager
    private let testFileManager: TestFileManager

    // Properties
    private let cliArgs: CommandLineArguments

    // MARK: - Init

    init(commandLineManager: CommandLineManager,
         testFileManager: TestFileManager,
         commandLineArguments: CommandLineArguments) {
        self.commandLineManager = commandLineManager
        self.testFileManager = testFileManager
        self.cliArgs = commandLineArguments
    }

    // MARK: - Internal

    func run() {
        print("""
        You entered: type name = \(cliArgs.typeName),
                     file name = \(String(describing: cliArgs.fileName))
                     folder name for generated mocks = \(cliArgs.mocksFolderName)
        """)
        // filesSubStructures нужны, чтобы по ним пройтись и собрать все >=internal методы/свойства
        guard let (targetFile,
                   targetStructure,
                   filesSubStructures) = findFile(by: cliArgs.typeName),
              let filePath = targetFile.path else {
            print("Did not find \(cliArgs.typeName) anywhere :(")
            return
        }

        print("Found \(cliArgs.typeName) in file \(filePath)")

        var params = targetStructure.getInitParams(in: targetFile)
        if !params.isEmpty {
            print("Found init method with params: \(params)")
        } else {
            print("Did not find init method and could not infer it. Initialization with no parameters will be used.")
        }

        guard let testsFilePath = testFileManager.createFile(fileName: cliArgs.fileName,
                                                             typeName: cliArgs.typeName) else {
            print("Failure creating file at \(fileManager.currentDirectoryPath)"); return
        }
        print("Created file \(testsFilePath)")

        if !params.isEmpty {
            params = addMocks(for: params, tempFilePath: testsFilePath)
        }

        testFileManager.generateFileContents(typeName: cliArgs.typeName,
                                             params: params,
                                             filesSubStructures: filesSubStructures)

//        print((try! Structure(file: targetFile)).description)
    }

    // MARK: - Private

    private func findFile(by typeName: String) -> (targetFile: File,
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

    private func addMocks(for params: [String: String], tempFilePath: String) -> [String: String] {
        var params = substituteTypesWithMocks(for: params)
        var mocksParams = params.filter { $1.isMockOrStub() }
        let nonMocksParams = params.filter { !$1.isMockOrStub() }
        if !mocksParams.isEmpty {
            print("Found mocks for several params: \(mocksParams)")
        }

        generateSourceryExtensions(in: tempFilePath, for: nonMocksParams)

        print("Running Sourcery...")
        if let result = commandLineManager.runSourcery(imports: cliArgs.imports,
                                                       testableImports: cliArgs.testableImports) {
            print(result)
        }
        print("Done running Sourcery!")

        let mocksFolderPath = fileManager.currentDirectoryPath + "/" + cliArgs.mocksFolderName
        params = substituteTypesWithMocks(for: params, in: mocksFolderPath)
        mocksParams = params.filter { $1.isMockOrStub() }
        if !mocksParams.isEmpty {
            print("Found mocks for several params: \(mocksParams)")
        }

        return params
    }

    private func generateSourceryExtensions(in filePath: String, for params: [String: String]) {
        let sourceryExtensions: [String] = params.values.compactMap {
            if $0.isMockOrStub() { return nil }
            var name = $0
            if name.hasSuffix("?") { name = name.trimmingQuestionMarksCharacters() }
            return "extension \(name): AutoMockable {}"
        }
        let contents = ["protocol AutoMockable {}"] + sourceryExtensions
        testFileManager.writeToFile(path: filePath, content: contents.joined(separator: "\n"))
    }

    private func substituteTypesWithMocks(for params: [String: String],
                                          in directoryPath: String? = nil) -> [String: String] {
        let mocksParams = params.filter { $1.isMockOrStub() }
        var nonMocksParams = params.filter { !$1.isMockOrStub() }
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
                    for (paramName, paramType) in nonMocksParams {
                        let paramType = paramType.trimmingQuestionMarksCharacters()
                        if inheritedTypes.contains(paramType) {
                            nonMocksParams[paramName] = name
                            break
                        }
                    }
                }
            }
        }
        return mocksParams.merging(nonMocksParams) { first, _ in first }
    }
}
