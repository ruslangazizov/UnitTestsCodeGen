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
    private lazy var coreManager = {
        CoreManager(commandLineManager: CommandLineManager(),
                    testFileManager: TestFileManager(),
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
        coreManager.run()
    }
}
