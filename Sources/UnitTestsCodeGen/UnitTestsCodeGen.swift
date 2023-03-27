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
    static let mocksFolderNameAbstract = "Name of folder for generated mocks"
    static let importsAbstract = "Additional imports for generated mocks files separated with comma without spaces"
    static let testableImportsAbstract = "Imports with @testable annotation for generated mocks files separated with comma without spaces"
}

struct CommandLineArguments {
    let typeName: String
    let fileName: String?
    let mocksFolderName: String
    let imports: [String]
    let testableImports: [String]
}

struct UnitTestsCodeGen: ParsableCommand {

    // Properties
    private lazy var arguments = {
        CommandLineArguments(typeName: typeName,
                             fileName: fileName,
                             mocksFolderName: mocksFolderName,
                             imports: imports?.components(separatedBy: ",") ?? [],
                             testableImports: testableImports?.components(separatedBy: ",") ?? [])
    }()
    private lazy var manager = FileManager.default
    private lazy var persistenceManager = {
        PersistenceManager(commandLineManager: CommandLineManager(),
                           commandLineArguments: arguments)
    }()

    // MARK: - Arguments and options

    @Argument(help: .init(.typeNameAbstract)) var typeName: String
    @Option(name: .shortAndLong, help: .init(.fileNameAbstract)) var fileName: String?
    @Option(name: .shortAndLong, help: .init(.mocksFolderNameAbstract)) var mocksFolderName: String = "Generated"
    @Option(name: .shortAndLong, help: .init(.importsAbstract)) var imports: String?
    @Option(name: .shortAndLong, help: .init(.testableImportsAbstract)) var testableImports: String?

    // MARK: - ParsableCommand

    static let configuration = CommandConfiguration(abstract: .configurationAbstract, version: "0.1.0")

    mutating func run() throws {
        print("""
        You entered: type name = \(typeName),
                     file name = \(String(describing: fileName))
                     folder name for generated mocks = \(mocksFolderName)
        """)
        // filesSubStructures нужны, чтобы по ним пройтись и собрать все >=internal методы/свойства
        guard let (targetFile,
                   targetStructure,
                   filesSubStructures) = persistenceManager.findFile(by: typeName),
              let filePath = targetFile.path else {
            print("Did not find \(typeName) anywhere :(")
            return
        }

        print("Found \(typeName) in file \(filePath)")

        let params = targetStructure.getInitParams(in: targetFile)
        if !params.isEmpty {
            print("Found init method with params: \(params)")
        } else {
            print("Did not find init method and could not infer it. Initialization with no parameters will be used.")
        }

        guard let testsFilePath = persistenceManager.createTestsFile() else {
            print("Failure creating file at \(manager.currentDirectoryPath)"); return
        }
        print("Created file \(testsFilePath)")

        if !params.isEmpty {
            persistenceManager.findMocks(for: params, tempFilePath: testsFilePath)
        }

//        print((try! Structure(file: targetFile)).description)
    }
}
