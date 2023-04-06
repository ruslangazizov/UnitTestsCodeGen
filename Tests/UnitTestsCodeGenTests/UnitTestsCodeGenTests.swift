import XCTest
@testable import UnitTestsCodeGen

final class UnitTestsCodeGenTests: XCTestCase {

    // System under test
    private var sut: Presenter!
    // Dependencies
//    private var viewModelsFactory: ViewModelsFactoryMock!

    override func setUp() {
        super.setUp()
//        viewModelsFactory = ViewModelsFactoryMock()
//        sut = Presenter(viewModelsFactory: viewModelsFactory)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
//        viewModelsFactory = nil
    }

    // MARK: - Tests
    
    func test_dataSource() throws {
        // given
//        let expectedResult: [String] = <#[DataSourceItem]#>

        // when
        let result = sut.dataSource

        // then
//        XCTAssertEqual(result, expectedResult)
    }

    func test_viewDidLoad() throws {
        // given


        // when
        sut.viewDidLoad()

        // then
        
    }

    func test_viewDidAppear() throws {
        // given


        // when
        sut.viewDidAppear()

        // then
        
    }
}
