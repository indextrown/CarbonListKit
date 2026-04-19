#if canImport(UIKit) && canImport(SwiftUI)
import SwiftUI

/// UIKit 기반 `ListComponent`를 SwiftUI에서도 직접 사용할 수 있게 해주는 프로토콜입니다.
///
/// `SwiftUIComponent`를 채택하면 같은 컴포넌트를:
/// - CarbonListKit의 UIKit 리스트 안에서 `ListComponent`로 사용하고
/// - SwiftUI 화면에서는 `View`로 바로 사용할 수 있습니다.
public protocol SwiftUIComponent: ListComponent, SwiftUI.View where Body == SwiftUIView {
  /// SwiftUI에서 렌더링할 뷰 타입입니다.
  associatedtype SwiftUIView: SwiftUI.View

  /// SwiftUI에서 사용할 뷰를 만듭니다.
  @ViewBuilder func makeSwiftUIView() -> SwiftUIView
}

public extension SwiftUIComponent {
  var body: SwiftUIView {
    makeSwiftUIView()
  }
}
#endif
