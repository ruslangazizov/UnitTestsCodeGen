//
//  TestFileManager.swift
//  UnitTestsCodeGen
//
//  Created by Руслан on 02.04.2023.
//

import Foundation

final class TestFileManager {

    // Dependencies
    private let fileManager = FileManager.default

    // Properties
    var className: String?
    var testsFilePath: String?

    // MARK: - Internal

    func createFile(fileName: String?, typeName: String) -> String? {
        let className = fileName ?? (typeName + "Tests")
        let fileName = className + ".swift"
        let testsFilePath = fileManager.currentDirectoryPath + "/" + fileName
        if fileManager.createFile(atPath: testsFilePath, contents: nil) {
            self.className = className
            self.testsFilePath = testsFilePath
            return testsFilePath
        } else {
            return nil
        }
    }

    func writeToFile(path: String, content: String) {
        if let fileHandle = FileHandle(forWritingAtPath: path),
           let data = content.data(using: .utf8) {
            try? fileHandle.write(contentsOf: data)
            try? fileHandle.close()
        }
    }

    func generateFileContents(imports: [String],
                              testableImports: [String],
                              typeName: String,
                              params: [UnitTestMethodArgument],
                              unitTestDataArray: [UnitTestData]) {
        guard let className = className,
              let testsFilePath = testsFilePath else { return }
        var contents: [String] = []
        contents.append("""
        // Auto-Generated by UnitTestsCodeGen

        import Foundation
        \(getPlatformSpecificImport() ?? "")
        import XCTest
        """)
        if imports.count + testableImports.count != 0 {
            contents.append("")
        }
        for import_ in imports {
            contents.append("import \(import_)")
        }
        for testableImport in testableImports {
            contents.append("@testable import \(testableImport)")
        }
        contents.append("")
        contents.append("final class \(className): XCTestCase {")

        var indentedContents: [String] = [""]
        indentedContents.append("// System under test")
        indentedContents.append("private var sut: \(typeName)!")

        if !params.isEmpty {
            indentedContents.append("// Dependencies")
        }
        for param in params {
            indentedContents.append("private var \(param.name): \(param.typeName)!")
        }
        indentedContents.append("")

        let setUpMethodContents = generateSetUpMethod(typeName: typeName, params: params)
        indentedContents += setUpMethodContents
        indentedContents.append("")

        let tearDownMethodContents = generateTearDownMethod(params: params)
        indentedContents += tearDownMethodContents
        indentedContents.append("")

        indentedContents.append("// MARK: - Tests")

        for data in unitTestDataArray {
            indentedContents.append("")
            indentedContents.append("func test_\(data.name)() throws {")

            var methodContents: [String] = ["// given"]
            if let arguments = data.arguments {
                for argument in arguments {
                    let placeholder = createPlaceholder(with: argument.typeName)
                    methodContents.append("let \(argument.name): \(argument.typeName) = \(placeholder)")
                }
            }
            if let typeName = data.returningType {
                let placeholder = createPlaceholder(with: typeName)
                methodContents.append("let expectedResult: \(typeName) = \(placeholder)")
            } else {
                methodContents.append("")
            }
            methodContents.append("")
            methodContents.append("// when")
            var whenString = "sut.\(data.name)"
            if let arguments = data.arguments {
                whenString.append("(")
                let argsString = arguments.map {
                    if let usingName = $0.usingName {
                        return "\(usingName): \($0.name)"
                    } else {
                        return $0.name
                    }
                }
                whenString.append(argsString.joined(separator: ", "))
                whenString.append(")")
            }
            if data.returningType != nil {
                whenString = "let result = " + whenString
            }
            methodContents.append(whenString)
            methodContents.append("")
            methodContents.append("// then")
            if data.returningType != nil {
                methodContents.append("XCTAssertEqual(result, expectedResult)")
            } else {
                methodContents.append("")
            }

            indentedContents += methodContents.map { "    " + $0 }
            indentedContents.append("}")
        }

        contents += indentedContents.map { "    " + $0 }
        contents.append("}")
        writeToFile(path: testsFilePath, content: contents.joined(separator: "\n"))
    }

    // MARK: - Private

    private func getPlatformSpecificImport() -> String? {
#if os(iOS) || os(tvOS) || os(watchOS)
        return "import UIKit"
#elseif os(OSX)
        return "import AppKit"
#else
        return nil
#endif
    }

    private func generateSetUpMethod(typeName: String,
                                     params: [UnitTestMethodArgument]) -> [String] {
        var contents: [String] = []
        contents.append("override func setUp() {")
        contents.append("    super.setUp()")
        var initParams: [String] = []
        for param in params {
            contents.append("    \(param.name) = \(param.typeName)()")
            if let usingName = param.usingName {
                initParams.append("\(usingName): \(param.name)")
            } else {
                initParams.append(param.name)
            }
        }
        let initParamsString = initParams.joined(separator: ", ")
        contents.append("    sut = \(typeName)(\(initParamsString))")
        contents.append("}")
        return contents
    }

    private func generateTearDownMethod(params: [UnitTestMethodArgument]) -> [String] {
        var contents: [String] = []
        contents.append("override func tearDown() {")
        contents.append("    super.tearDown()")
        contents.append("    sut = nil")
        for param in params {
            contents.append("    \(param.name) = nil")
        }
        contents.append("}")
        return contents
    }

    private func createPlaceholder(with content: String) -> String {
        let begining = "<#"
        let ending = "#>"
        return begining + content + ending
    }
}
