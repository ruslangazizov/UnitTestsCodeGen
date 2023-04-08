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
        guard commandLineManager.checkSourceryPresence() else {
            print("Unable to locate sourcery. Please install it - https://github.com/krzysztofzablocki/Sourcery.")
            return
        }
        commandLineManager.placeMockTemplateFile()
        print("""
        You entered: type name = \(cliArgs.typeName),
                     file name = \(cliArgs.fileName ?? "nil"),
                     folder name for generated mocks = \(cliArgs.mocksFolderName),
                     additional imports = \(cliArgs.imports),
                     additional testable imports = \(cliArgs.testableImports).
        """)
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
            print("Found init method with params: \(params.description)")
        } else {
            print("Did not find init method and could not infer it. Initialization with no parameters will be used.")
        }

        guard let testsFilePath = testFileManager.createFile(fileName: cliArgs.fileName,
                                                             typeName: cliArgs.typeName) else {
            print("Failure creating file at \(fileManager.currentDirectoryPath)")
            return
        }
        print("Created file \(testsFilePath)")

        if !params.isEmpty {
            params = addMocks(for: params, tempFilePath: testsFilePath)
        }

        let unitTestDataArray = extractNonPrivateMethodsAndProperties(from: filesSubStructures)
        print("Generating test file...")
        testFileManager.generateFileContents(imports: cliArgs.imports,
                                             testableImports: cliArgs.testableImports,
                                             typeName: cliArgs.typeName,
                                             params: params,
                                             unitTestDataArray: unitTestDataArray)
        print("Done generating test file!")
    }

    // MARK: - Private

    private func extractNonPrivateMethodsAndProperties(from filesSubStructures: [SyntaxStructure]) -> [UnitTestData] {
        var data: [UnitTestData] = []
        for fileSubStructure in filesSubStructures {
            for subStructure in fileSubStructure.substructures ?? [] {
                guard subStructure.isNonPrivateInstanceMethodOrProperty(),
                      !subStructure.isInitMethod(),
                      let name = subStructure.getActualName() else { continue }
                let arguments = subStructure.isInstanceMethod() ? subStructure.parseMethodParams() : nil
                data.append(UnitTestData(name: name,
                                         arguments: arguments,
                                         returningType: subStructure.typename))
            }
        }
        return data
    }

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

    private func addMocks(for params: [SwiftMethodArgument],
                          tempFilePath: String) -> [SwiftMethodArgument] {
        var params = substituteTypesWithMocks(for: params)
        var mocksParams = params.filter { $0.typeName.isMockOrStub() }
        let nonMocksParams = params.filter { !$0.typeName.isMockOrStub() }
        if !mocksParams.isEmpty {
            print("Found mocks for several params: \(mocksParams.description)")
        }

        generateSourceryExtensions(in: tempFilePath, for: nonMocksParams)

        print("Running Sourcery...")
        if let result = commandLineManager.runSourcery(imports: cliArgs.imports,
                                                       testableImports: cliArgs.testableImports,
                                                       mocksFolderName: cliArgs.mocksFolderName) {
            if !result.isEmpty {
                print(result)
            }
        }
        print("Done running Sourcery!")

        let mocksFolderPath = fileManager.currentDirectoryPath + "/" + cliArgs.mocksFolderName
        params = substituteTypesWithMocks(for: params, in: mocksFolderPath)
        mocksParams = params.filter { $0.typeName.isMockOrStub() }
        if !mocksParams.isEmpty {
            print("Found mocks for several params: \(mocksParams.description)")
        }

        return params
    }

    private func generateSourceryExtensions(in filePath: String,
                                            for params: [SwiftMethodArgument]) {
        let sourceryExtensions: [String] = params.compactMap { param in
            if param.typeName.isMockOrStub() { return nil }
            var name = param.typeName
            if name.hasSuffix("?") { name = name.trimmingQuestionMarksCharacters() }
            return "extension \(name): AutoMockable {}"
        }
        let contents = ["protocol AutoMockable {}"] + sourceryExtensions
        testFileManager.writeToFile(path: filePath, content: contents.joined(separator: "\n"))
    }

    private func substituteTypesWithMocks(for params: [SwiftMethodArgument],
                                          in directoryPath: String? = nil) -> [SwiftMethodArgument] {
        let mocksParams = params.filter { $0.typeName.isMockOrStub() }
        var nonMocksParams = params.filter { !$0.typeName.isMockOrStub() }
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
                    for (index, param) in nonMocksParams.enumerated() {
                        let paramType = param.typeName.trimmingQuestionMarksCharacters()
                        if inheritedTypes.contains(paramType) {
                            nonMocksParams[index] = SwiftMethodArgument(name: param.name,
                                                                           usingName: param.usingName,
                                                                           typeName: name)
                            break
                        }
                    }
                }
            }
        }
        return mocksParams + nonMocksParams
    }
}
