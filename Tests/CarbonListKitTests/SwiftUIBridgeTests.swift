#if canImport(UIKit) && canImport(SwiftUI)
import SwiftUI
import Testing
import UIKit
@testable import CarbonListKit

@Suite("SwiftUI Import Compatibility")
struct SwiftUIImportCompatibilityTests {
  @Test("SwiftUI를 import한 파일에서도 CarbonList DSL을 사용할 수 있다")
  func carbonListDSLCompilesWithSwiftUIImported() {
    let view = CarbonList {
      Section(id: "swiftui") {
        Row(id: "row", component: SwiftUITestComponent(content: .init(text: "SwiftUI")))
      }
    }

    #expect(view.list.sections.map(\.id) == ["swiftui"].map(AnyHashable.init))
  }
}

private struct SwiftUITestComponent: ListComponent {
  struct Content: Equatable {
    let text: String
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> UILabel {
    UILabel()
  }

  func updateView(_ view: UILabel, context: ListComponentContext<Void>) {
    view.text = content.text
  }
}
#endif
