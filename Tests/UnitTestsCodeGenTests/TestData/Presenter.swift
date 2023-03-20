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
    func viewDidAppear()
}

final class Presenter: IPresenter {

    // Dependencies
    private let viewModelsFactory: IViewModelsFactory

    // Properties
    var dataSource: [String] = []

    // MARK: - Init

    internal init(viewModelsFactory: IViewModelsFactory) {
        self.viewModelsFactory = viewModelsFactory
    }

    // MARK: - IPresenter
    
    func viewDidLoad() {
        dataSource = viewModelsFactory.buildViewModel()
        _ = ViewController(presenter: self)
    }

    func viewDidAppear() {}
}