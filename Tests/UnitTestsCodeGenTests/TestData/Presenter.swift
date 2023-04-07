//
//  Presenter.swift
//  UnitTestsCodeGenTests
//
//  Created by Руслан on 12.03.2023.
//

import Foundation

protocol IPresenter: AnyObject {
    var dataSource: [String] { get }
    func viewDidLoad()
}

final class Presenter: IPresenter {

    // Dependencies
    private let viewModelsFactory: IViewModelsFactory
    var view: IViewController?

    // Properties
    var dataSource: [String] = []

    // MARK: - Init

    init(viewModelsFactory: IViewModelsFactory) {
        self.viewModelsFactory = viewModelsFactory
    }

    // MARK: - IPresenter
    
    func viewDidLoad() {
        dataSource = viewModelsFactory.buildViewModel()
        _ = ViewController(presenter: self, secondVar: 0)
    }

    func viewDidAppear(animated: Bool) -> Bool { true }
}

extension Presenter {

    func someMethodInExtension() {}
}
