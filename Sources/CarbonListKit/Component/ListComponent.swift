#if canImport(UIKit)
import UIKit

/// 리스트 컴포넌트의 컨텍스트를 나타내는 구조체입니다.
/// 코디네이터를 포함하여 컴포넌트와 뷰 간의 상호작용을 관리합니다.
public struct ListComponentContext<Coordinator> {
  /// 코디네이터 인스턴스
  public let coordinator: Coordinator

  /// 컨테이너의 현재 너비
  public let containerWidth: CGFloat

  /// ListComponentContext를 초기화합니다.
  /// - Parameters:
  ///   - coordinator: 코디네이터 인스턴스
  ///   - containerWidth: 컨테이너의 현재 너비
  public init(coordinator: Coordinator, containerWidth: CGFloat = 0) {
    self.coordinator = coordinator
    self.containerWidth = containerWidth
  }
}

/// 컴포넌트 높이를 계산할 때 사용할 컨텍스트입니다.
public struct ListComponentHeightContext {
  /// 컨테이너의 현재 너비
  public let containerWidth: CGFloat

  /// ListComponentHeightContext를 초기화합니다.
  /// - Parameter containerWidth: 컨테이너의 현재 너비
  public init(containerWidth: CGFloat) {
    self.containerWidth = containerWidth
  }
}

/// 리스트 컴포넌트의 높이 결정 방식을 나타냅니다.
public enum ListComponentHeight: Equatable {
  /// Auto Layout 기반 self-sizing으로 높이를 계산합니다.
  case automatic
  /// 지정한 값으로 높이를 고정합니다.
  case absolute(CGFloat)
  /// 셀의 너비와 같은 높이를 사용합니다.
  case square
}

/// 리스트에서 사용할 수 있는 컴포넌트를 정의하는 프로토콜입니다.
/// 뷰 모델, 뷰, 코디네이터를 포함하여 재사용 가능한 UI 컴포넌트를 만듭니다.
public protocol ListComponent {
  /// 컴포넌트에 주입할 콘텐츠 타입 (Equatable이어야 함)
  associatedtype Content: Equatable
  /// 뷰 타입 (UIView의 서브클래스)
  associatedtype View: UIView
  /// 코디네이터 타입 (기본값: Void)
  associatedtype Coordinator = Void

  /// 컴포넌트 콘텐츠
  var content: Content { get }
  /// 컴포넌트 높이를 컨텍스트를 기반으로 계산합니다.
  func height(context: ListComponentHeightContext) -> ListComponentHeight
  /// 컴포넌트 높이의 정적 기본값입니다.
  @available(*, deprecated, message: "Use height(context:) instead.")
  var height: ListComponentHeight { get }
  /// 재사용 식별자
  var reuseIdentifier: String { get }

  /// 코디네이터를 생성합니다.
  func makeCoordinator() -> Coordinator
  /// 뷰를 생성합니다.
  func makeView(context: ListComponentContext<Coordinator>) -> View
  /// 뷰를 업데이트합니다.
  func updateView(_ view: View, context: ListComponentContext<Coordinator>)
  /// 뷰를 컨테이너에 레이아웃합니다.
  func layoutView(_ view: View, in container: UIView)
}

extension ListComponent {
  /// 기본 높이는 Auto Layout 기반 self-sizing입니다.
  @available(*, deprecated, message: "Use height(context:) instead.")
  public var height: ListComponentHeight {
    .automatic
  }

  /// 기본 높이 계산은 정적인 `height` 값을 그대로 사용합니다.
  public func height(context: ListComponentHeightContext) -> ListComponentHeight {
    height
  }

  /// 기본 재사용 식별자를 반환합니다.
  /// 타입 이름을 문자열로 변환하여 사용합니다.
  public var reuseIdentifier: String {
    String(reflecting: Self.self)
  }

  /// 뷰를 컨테이너에 기본 레이아웃으로 배치합니다.
  /// 뷰의 제약 조건을 컨테이너의 가장자리에 맞춥니다.
  /// - Parameters:
  ///   - view: 레이아웃할 뷰
  ///   - container: 컨테이너 뷰
  public func layoutView(_ view: View, in container: UIView) {
    view.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(view)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: container.topAnchor),
      view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
    ])
  }
}

extension ListComponent where Coordinator == Void {
  /// 코디네이터가 Void인 경우 빈 튜플을 반환합니다.
  public func makeCoordinator() -> Coordinator {
    ()
  }
}
#endif
