//
//  ViewModelsFactory.swift
//  UnitTestsCodeGenTests
//
//  Created by Руслан on 19.03.2023.
//

import Foundation

protocol IViewModelsFactory {
    func buildViewModel() -> [String]
}

final class ViewModelsFactory: IViewModelsFactory {

    // MARK: - IViewModelsFactory

    func buildViewModel() -> [String] {
        return ["Element1", "Element2", "Element3"]
    }
}
