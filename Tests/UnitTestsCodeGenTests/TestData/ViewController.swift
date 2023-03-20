//
//  ViewController.swift
//  UnitTestsCodeGenTests
//
//  Created by Руслан on 19.03.2023.
//

import Foundation

protocol IViewController {
    func reloadData()
}

struct ViewController: CustomStringConvertible {

    let presenter: IPresenter
//    internal let secondLet      =     ""
//    private let thirdLet: String = ""
//
//    internal var firstVar = [String]()
//    var secondVar: Int
//
//    private var firstComputedVar: String {""}
//
//    lazy var firstSpecialVar: String = {
//        return ""
//    }()
}

extension ViewController: IViewController {

    func reloadData() {}
}

extension ViewController {

    var description: String {
        ""
    }
}
