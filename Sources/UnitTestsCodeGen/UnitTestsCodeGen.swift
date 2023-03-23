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
        // filesSubStructures нужны, чтобы по ним пройтись и собрать все >=internal методы/свойства
        guard let (targetFile, targetStructure, filesSubStructures) = findFile(by: typeName),
              let filePath = targetFile.path else {
            print("Did not find \(typeName) anywhere :(")
            return
        }

//        let names = filesSubStructures.flatMap { $0.getInheritedTypes() }
        print("Found \(typeName) in file \(filePath)")

        let params = targetStructure.getInitParams(in: targetFile)
        if !params.isEmpty {
            print("Found init method with params: \(params)")
        } else {
            print("Did not find init method and could not infer it :(")
            return
        }

        let paramsMocks = substituteTypesWithMocks(for: params)
        print("Found mocks for several params: \(paramsMocks)")

        let className = fileName ?? typeName + "Tests"
        let fileName = className + ".swift"
        guard createFile(fileName: fileName) else { return }

        let sourceryExtensions: [String] = paramsMocks.values.compactMap {
            if $0.isMockOrStub() { return nil }
            return "extension \($0): AutoMockable {}"
        }
        let contents = ["protocol AutoMockable {}"] + sourceryExtensions
        writeToFile(fileName: fileName, content: contents.joined(separator: "\n"))

        runSourcery()

//        print((try! Structure(file: targetFile)).description)
    }

    // MARK: - Private

    private func runSourcery() {
        try? shell("sh ./tools/sourcery.sh")
    }

    func shell(_ command: String) throws {
        let task = Process()
//        let pipe = Pipe()

//        task.standardOutput = pipe
//        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.standardInput = nil

        try task.run()

//        let data = pipe.fileHandleForReading.readDataToEndOfFile()
//        let output = String(data: data, encoding: .utf8)!

//        return output
    }

    private func writeToFile(fileName: String, content: String) {
        let path = FileManager.default.currentDirectoryPath + "/" + fileName
        if let fileHandle = FileHandle(forWritingAtPath: path),
           let data = content.data(using: .utf8) {
            try? fileHandle.write(contentsOf: data)
            try? fileHandle.close()
        }
    }

    private func createFile(fileName: String) -> Bool {
        let manager = FileManager.default
        let path = manager.currentDirectoryPath + "/" + fileName
        let success = manager.createFile(atPath: path, contents: nil)
        if success {
            print("Created file \(path)")
        } else {
            print("Failure creating file at \(FileManager.default.currentDirectoryPath)")
        }
        return success
    }

    private func substituteTypesWithMocks(for params: [String: String]) -> [String: String] {
        var params = params
        let manager = FileManager.default
        let directoryPath = manager.currentDirectoryPath
        let enumerator = manager.enumerator(atPath: directoryPath)
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

    private func findFile(by typeName: String) -> (targetFile: File,
                                                   targetStructure: SyntaxStructure,
                                                   filesSubStructures: [SyntaxStructure])? {
        let manager = FileManager.default
        let directoryPath = manager.currentDirectoryPath
        let enumerator = manager.enumerator(atPath: directoryPath)
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
}
