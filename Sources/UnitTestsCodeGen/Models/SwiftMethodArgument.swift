//
//  SwiftMethodArgument.swift
//  UnitTestsCodeGen
//
//  Created by Руслан on 08.04.2023.
//

import Foundation

struct SwiftMethodArgument {
    let name: String // argument name
    let usingName: String? // argument label or nil in case of _
    let typeName: String // argument type
}

extension Array where Element == SwiftMethodArgument {

    var description: String {
        let string = map { $0.name + ": " + $0.typeName }.joined(separator: ", ")
        return "(\(string))"
    }
}
