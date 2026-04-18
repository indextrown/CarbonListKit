#if canImport(UIKit)
import UIKit

/// 리스트 컴포넌트의 컨텍스트를 나타내는 구조체입니다.
/// 코디네이터를 포함하여 컴포넌트와 뷰 간의 상호작용을 관리합니다.
public struct ListComponentContext<Coordinator> {
  /// 코디네이터 인스턴스
  public let coordinator: Coordinator

  /// ListComponentContext를 초기화합니다.
  /// - Parameter coordinator: 코디네이터 인스턴스
  public init(coordinator: Coordinator) {
    self.coordinator = coordinator
  }
}

/// 리스트에서 사용할 수 있는 컴포넌트를 정의하는 프로토콜입니다.
/// 뷰 모델, 뷰, 코디네이터를 포함하여 재사용 가능한 UI 컴포넌트를 만듭니다.
public protocol ListComponent {
  /// 뷰 모델 타입 (Equatable이어야 함)
  associatedtype ViewModel: Equatable
  /// 뷰 타입 (UIView의 서브클래스)
  associatedtype View: UIView
  /// 코디네이터 타입 (기본값: Void)
  associatedtype Coordinator = Void

  /// 뷰 모델
  var viewModel: ViewModel { get }
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
