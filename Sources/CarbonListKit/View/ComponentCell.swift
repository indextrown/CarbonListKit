#if canImport(UIKit)
import UIKit

/// 리스트 컴포넌트를 렌더링하는 컬렉션 뷰 셀입니다.
/// 컴포넌트의 뷰를 생성하고 관리합니다.
final class ComponentCell: UICollectionViewCell {
  private var renderedView: UIView?
  private var renderedComponent: AnyListComponent?
  private var coordinator: Any?

  /// ComponentCell을 초기화합니다.
  /// 배경색을 투명으로 설정합니다.
  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = .clear
    contentView.backgroundColor = .clear
  }

  /// 코더를 사용한 초기화는 지원하지 않습니다.
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// 셀이 재사용되기 전에 호출됩니다.
  /// 기본 구현을 호출합니다.
  override func prepareForReuse() {
    super.prepareForReuse()
  }

  /// 선호하는 레이아웃 속성을 계산합니다.
  /// 콘텐츠 뷰의 크기를 기반으로 높이를 조정합니다.
  override func preferredLayoutAttributesFitting(
    _ layoutAttributes: UICollectionViewLayoutAttributes
  ) -> UICollectionViewLayoutAttributes {
    let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
    let targetSize = CGSize(
      width: layoutAttributes.size.width,
      height: UIView.layoutFittingCompressedSize.height
    )

    let size = contentView.systemLayoutSizeFitting(
      targetSize,
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    attributes.size.height = ceil(size.height)
    return attributes
  }

  /// 컴포넌트를 렌더링합니다.
  /// 컴포넌트 타입이 변경되면 뷰를 새로 생성하고, 그렇지 않으면 업데이트합니다.
  /// - Parameter component: 렌더링할 컴포넌트
  func render(component: AnyListComponent) {
    if renderedComponent?.componentTypeID != component.componentTypeID {
      renderedView?.removeFromSuperview()
      coordinator = component.makeCoordinator()
      let view = component.makeView(coordinator: coordinator ?? ())
      component.layout(view: view, in: contentView)
      renderedView = view
    }

    if let renderedView {
      component.update(view: renderedView, coordinator: coordinator ?? ())
    }

    renderedComponent = component
  }

  /// 렌더링된 콘텐츠 뷰를 반환합니다.
  /// - Returns: 렌더링된 뷰 (옵션)
  func renderedContentView() -> UIView? {
    renderedView
  }
}
#endif
