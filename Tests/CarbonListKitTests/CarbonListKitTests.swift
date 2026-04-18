import XCTest
@testable import CarbonListKit

#if canImport(UIKit)
import UIKit
#endif

final class CarbonListKitTests: XCTestCase {
  func testPackageLoads() {
    XCTAssertTrue(true)
  }

  #if canImport(UIKit)
  func testSectionHeaderAndFooterAffectEquality() {
    let base = Section(id: "section") {
      Row(id: "row", component: TestComponent(viewModel: .init(text: "row")))
    }

    let withHeader = base.header(
      Header(id: "header", component: TestComponent(viewModel: .init(text: "header")))
    )
    let withFooter = base.footer(
      Footer(id: "footer", component: TestComponent(viewModel: .init(text: "footer")))
    )

    XCTAssertNotEqual(base, withHeader)
    XCTAssertNotEqual(base, withFooter)
  }

  func testSupplementaryLayoutSizeEquality() {
    XCTAssertEqual(
      ListSupplementaryLayoutSize.estimated(height: 44),
      .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44))
    )
    XCTAssertNotEqual(
      ListSupplementaryLayoutSize.estimated(height: 44),
      ListSupplementaryLayoutSize.absolute(height: 44)
    )
  }
  #endif
}

#if canImport(UIKit)
private struct TestComponent: ListComponent {
  struct ViewModel: Equatable {
    let text: String
  }

  let viewModel: ViewModel

  func makeView(context: ListComponentContext<Void>) -> UILabel {
    UILabel()
  }

  func updateView(_ view: UILabel, context: ListComponentContext<Void>) {
    view.text = viewModel.text
  }
}
#endif
