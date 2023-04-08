//
//  CommandLineManager.swift
//  UnitTestsCodeGen
//
//  Created by Руслан on 27.03.2023.
//

import Foundation

final class CommandLineManager {
    
    // Dependencies
    private let fileManager = FileManager.default

    // Properties
    private let hiddenDirName = ".unit-tests-code-gen"
    private let templateFileName = "AutoMockable.stencil"

    // MARK: - Internal

    func runSourcery(imports: [String],
                     testableImports: [String],
                     mocksFolderName: String) -> String? {
        let additionalArgs = createAdditionalArgs(imports: imports, testableImports: testableImports)
        let args = ["--sources .",
                    "--exclude-sources .build",
                    "--templates \(hiddenDirName)/\(templateFileName)",
                    "--output \(mocksFolderName)",
                    additionalArgs,
                    "--quiet"] // --verbose
        return try? shell("sourcery " + args.joined(separator: " "))
    }

    func checkSourceryPresence() -> Bool {
        let result = try? shell("which sourcery")
        return result?.contains("sourcery not found") == false
    }

    func placeMockTemplateFile() {
        let pathToHiddenDir = fileManager.currentDirectoryPath.appending("/" + hiddenDirName)
        let directoryURL = URL(fileURLWithPath: pathToHiddenDir)
        do {
            try fileManager.createDirectory(at: directoryURL,
                                            withIntermediateDirectories: true)
        } catch {
            print("Error creating directory: \(error.localizedDescription)")
            return
        }
        let pathToTemplateFile = pathToHiddenDir.appending("/" + templateFileName)
        if let fileHandle = FileHandle(forReadingAtPath: pathToTemplateFile),
           let data = try? fileHandle.readToEnd(),
           let content = String(data: data, encoding: .utf8),
           !content.isEmpty {
            // file already exists with some content
        } else {
            let templateFileContents = Templates.autoMockable.data(using: .utf8)
            fileManager.createFile(atPath: pathToTemplateFile, contents: templateFileContents)
        }
    }

    // MARK: - Private

    private func shell(_ command: String) throws -> String? {
        let task = Process()
        let pipe = Pipe()
        task.standardInput = nil
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")

        try task.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }

    private func createAdditionalArgs(imports: [String], testableImports: [String]) -> String {
        let importsArgsString = imports.isEmpty ? nil : "--args imports=\(imports.joined(separator: ":"))"
        let testableImportsArgsString = testableImports.isEmpty ? nil : "--args testable_imports=\(testableImports.joined(separator: ":"))"
        return [importsArgsString, testableImportsArgsString].compactMap { $0 }.joined(separator: " ")
    }
}
