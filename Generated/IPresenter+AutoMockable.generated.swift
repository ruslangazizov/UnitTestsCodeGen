// Generated using Sourcery 2.0.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

argument = ["C": 1, "imports": [A, B], "testable_imports": B, "D": 1]


final class IPresenterMock: IPresenter {


    var dataSource: [String] = []


    // MARK: - viewDidLoad

    var viewDidLoadCallsCount = 0
    var viewDidLoadCalled: Bool {
        return viewDidLoadCallsCount > 0
    }
    var viewDidLoadClosure: (() -> Void)?

    func viewDidLoad() {
        viewDidLoadCallsCount += 1
        viewDidLoadClosure?()
    }

    // MARK: - viewDidAppear

    var viewDidAppearCallsCount = 0
    var viewDidAppearCalled: Bool {
        return viewDidAppearCallsCount > 0
    }
    var viewDidAppearReturnValue: Bool!
    var viewDidAppearClosure: (() -> Bool)?

    func viewDidAppear() -> Bool {
        viewDidAppearCallsCount += 1
        if let viewDidAppearClosure = viewDidAppearClosure {
            return viewDidAppearClosure()
        } else {
            return viewDidAppearReturnValue
        }
    }

}
