//
//  UnitTestData.swift
//  UnitTestsCodeGen
//
//  Created by Руслан on 05.04.2023.
//

import Foundation

struct UnitTestData {
    let name: String
    let arguments: [UnitTestMethodArgument]?
    let returningType: String?
}

struct UnitTestMethodArgument {
    let name: String // имя аргумента
    let usingName: String? // лейбл аргумента или nil в случае _
    let typeName: String // тип аргумента
}
