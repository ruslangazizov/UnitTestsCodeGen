//
//  Presenter.swift
//  UnitTestsCodeGen
//
//  Created by Руслан on 12.03.2023.
//

import Foundation

protocol IPresenter: AnyObject {
    var dataSource: [String]
    func viewDidLoad()
}

final class Presenter: IPresenter {
    
    let dataSource: [String] = ["Element1",
                                "Element2",
                                "Element3"]
    
    func viewDidLoad() {}
}
