//
//  CommandLineManager.swift
//  UnitTestsCodeGen
//
//  Created by Руслан on 27.03.2023.
//

import Foundation

final class CommandLineManager {

    // MARK: - Internal

    func runSourcery(imports: [String], testableImports: [String]) -> String? {
        let importsString = imports.map { "--args imports=\($0)" }.joined(separator: " ")
        let testableImportsString = testableImports.map { "--args testable_imports=\($0)" }.joined(separator: " ")
        let args = ["--sources .",
                    "--exclude-sources .build",
                    "--templates ./tools/templates/AutoMockable.stencil",
                    "--output Generated",
                    importsString,
                    testableImportsString] // --verbose
        return try? shell("./tools/bin/sourcery " + args.joined(separator: " "))
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
}
