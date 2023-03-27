//
//  String+Extensions.swift
//  UnitTestsCodeGen
//
//  Created by Руслан on 27.03.2023.
//

import Foundation

extension String {

    func trimmingQuestionMarksCharacters() -> String {
        trimmingCharacters(in: .init(charactersIn: "?"))
    }
}
