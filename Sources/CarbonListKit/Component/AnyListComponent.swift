#if canImport(UIKit)
import UIKit

/// 타입을 지워서 ListComponent를 저장하는 구조체입니다.
/// 다양한 타입의 컴포넌트를 동일하게 다룰 수 있게 합니다.
public struct AnyListComponent: Equatable {
  private let box: any AnyListComponentBox

  /// 컴포넌트의 타입 식별자
  public var componentTypeID: ObjectIdentifier {
    box.componentTypeID
  }

  /// 재사용 식별자
  public var reuseIdentifier: String {
    box.reuseIdentifier
  }

  /// 컴포넌트 높이
  @available(*, deprecated, message: "Use height(context:) instead.")
  public var height: ListComponentHeight {
    box.height(context: .init(containerWidth: 0))
  }

  /// 컨테이너 너비를 반영한 컴포넌트 높이
  public func height(context: ListComponentHeightContext) -> ListComponentHeight {
    box.height(context: context)
  }

  var content: AnyEquatableValue {
    box.content
  }

  /// AnyListComponent를 초기화합니다.
  /// - Parameter component: 타입이 지워질 컴포넌트
  public init(_ component: some ListComponent) {
    self.box = ListComponentBox(component)
  }

  /// 코디네이터를 생성합니다.
  func makeCoordinator() -> Any {
    box.makeCoordinator()
  }

  /// 뷰를 생성합니다.
  func makeView(coordinator: Any, containerWidth: CGFloat) -> UIView {
    box.makeView(coordinator: coordinator, containerWidth: containerWidth)
  }

  /// 뷰를 업데이트합니다.
  func update(view: UIView, coordinator: Any, containerWidth: CGFloat) {
    box.update(view: view, coordinator: coordinator, containerWidth: containerWidth)
  }

  /// 뷰를 레이아웃합니다.
  func layout(view: UIView, in container: UIView) {
    box.layout(view: view, in: container)
  }

  /// 컴포넌트를 특정 타입으로 캐스팅합니다.
  /// - Parameter type: 캐스팅할 타입
  /// - Returns: 캐스팅된 컴포넌트 (옵션)
  func `as`<T>(_ type: T.Type) -> T? {
    box as? T
  }

  /// 두 AnyListComponent가 같은지 비교합니다.
  /// 타입, 뷰 모델, 높이를 비교합니다.
  public static func == (lhs: AnyListComponent, rhs: AnyListComponent) -> Bool {
    lhs.componentTypeID == rhs.componentTypeID
      && lhs.content == rhs.content
      && lhs.height(context: .init(containerWidth: 0)) == rhs.height(context: .init(containerWidth: 0))
  }
}

/// Equatable 타입을 감싸는 구조체입니다.
/// 타입 안전성을 유지하면서 비교를 가능하게 합니다.
struct AnyEquatableValue: Equatable {
  private let base: any Equatable

  /// AnyEquatableValue를 초기화합니다.
  /// - Parameter base: 감쌀 Equatable 값
  init(_ base: any Equatable) {
    self.base = base
  }

  /// 두 AnyEquatableValue가 같은지 비교합니다.
  static func == (lhs: AnyEquatableValue, rhs: AnyEquatableValue) -> Bool {
    lhs.base.isEqual(to: rhs.base)
  }
}

private protocol AnyListComponentBox {
  var componentTypeID: ObjectIdentifier { get }
  var reuseIdentifier: String { get }
  var content: AnyEquatableValue { get }

  func height(context: ListComponentHeightContext) -> ListComponentHeight

  func makeCoordinator() -> Any
  func makeView(coordinator: Any, containerWidth: CGFloat) -> UIView
  func update(view: UIView, coordinator: Any, containerWidth: CGFloat)
  func layout(view: UIView, in container: UIView)
}

private struct ListComponentBox<Component: ListComponent>: AnyListComponentBox {
  let component: Component

  /// 컴포넌트의 타입 식별자
  var componentTypeID: ObjectIdentifier {
    ObjectIdentifier(Component.self)
  }

  /// 재사용 식별자
  var reuseIdentifier: String {
    component.reuseIdentifier
  }

  func height(context: ListComponentHeightContext) -> ListComponentHeight {
    component.height(context: context)
  }

  /// 컴포넌트 콘텐츠
  var content: AnyEquatableValue {
    AnyEquatableValue(component.content)
  }

  /// ListComponentBox를 초기화합니다.
  /// - Parameter component: 저장할 컴포넌트
  init(_ component: Component) {
    self.component = component
  }

  /// 코디네이터를 생성합니다.
  func makeCoordinator() -> Any {
    component.makeCoordinator()
  }

  /// 뷰를 생성합니다.
  func makeView(coordinator: Any, containerWidth: CGFloat) -> UIView {
    let coordinator = coordinator as! Component.Coordinator
    return component.makeView(
      context: .init(coordinator: coordinator, containerWidth: containerWidth)
    )
  }

  /// 뷰를 업데이트합니다.
  func update(view: UIView, coordinator: Any, containerWidth: CGFloat) {
    guard let view = view as? Component.View,
          let coordinator = coordinator as? Component.Coordinator else {
      return
    }

    component.updateView(
      view,
      context: .init(coordinator: coordinator, containerWidth: containerWidth)
    )
  }

  /// 뷰를 레이아웃합니다.
  func layout(view: UIView, in container: UIView) {
    guard let view = view as? Component.View else {
      return
    }

    component.layoutView(view, in: container)
  }
}

private extension Equatable {
  /// 다른 Equatable과 같은지 비교합니다.
  func isEqual(to other: any Equatable) -> Bool {
    guard let other = other as? Self else {
      return false
    }

    return self == other
  }
}
#endif
