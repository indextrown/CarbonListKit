#if canImport(UIKit)
import UIKit

/// 리스트 컴포넌트를 렌더링하는 컬렉션 뷰 supplementary view입니다.
final class ComponentSupplementaryView: UICollectionReusableView {
  private let contentContainerView = UIView()
  private var renderedView: UIView?
  private var renderedComponent: AnyListComponent?
  private var coordinator: Any?
  private var contentContainerBottomConstraint: NSLayoutConstraint?

  var bottomSpacing: CGFloat = 0 {
    didSet {
      contentContainerBottomConstraint?.constant = -bottomSpacing
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = .clear
    setupContentContainerView()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    bottomSpacing = 0
  }

  override func preferredLayoutAttributesFitting(
    _ layoutAttributes: UICollectionViewLayoutAttributes
  ) -> UICollectionViewLayoutAttributes {
    let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
    let targetSize = CGSize(
      width: layoutAttributes.size.width,
      height: UIView.layoutFittingCompressedSize.height
    )

    let size = systemLayoutSizeFitting(
      targetSize,
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    attributes.size.height = ceil(size.height)
    return attributes
  }

  /// 컴포넌트를 렌더링합니다.
  /// - Parameter component: 렌더링할 컴포넌트
  func render(component: AnyListComponent) {
    if renderedComponent?.componentTypeID != component.componentTypeID {
      renderedView?.removeFromSuperview()
      coordinator = component.makeCoordinator()
      let view = component.makeView(coordinator: coordinator ?? ())
      component.layout(view: view, in: contentContainerView)
      renderedView = view
    }

    if let renderedView {
      component.update(view: renderedView, coordinator: coordinator ?? ())
    }

    renderedComponent = component
  }

  private func setupContentContainerView() {
    contentContainerView.backgroundColor = .clear
    contentContainerView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(contentContainerView)

    let bottomConstraint = contentContainerView.bottomAnchor.constraint(equalTo: bottomAnchor)
    contentContainerBottomConstraint = bottomConstraint

    NSLayoutConstraint.activate([
      contentContainerView.topAnchor.constraint(equalTo: topAnchor),
      contentContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
      contentContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
      bottomConstraint
    ])
  }
}
#endif
