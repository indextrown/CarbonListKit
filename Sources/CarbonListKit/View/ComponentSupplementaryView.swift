#if canImport(UIKit)
import UIKit

/// 리스트 컴포넌트를 렌더링하는 컬렉션 뷰 supplementary view입니다.
final class ComponentSupplementaryView: UICollectionReusableView {
  struct SizeCacheKey: Hashable {
    let sectionID: AnyHashable
    let supplementaryID: AnyHashable
    let kind: String
    let componentTypeID: ObjectIdentifier
    let width: Int
    let bottomSpacing: Int
  }

  struct SizeCacheEntry {
    let component: AnyListComponent
    let height: CGFloat
  }

  private let contentContainerView = UIView()
  private var renderedView: UIView?
  private var renderedComponent: AnyListComponent?
  private var coordinator: Any?
  private var renderedContainerWidth: CGFloat?
  private var contentContainerBottomConstraint: NSLayoutConstraint?
  private var sectionID: AnyHashable?
  private var supplementaryID: AnyHashable?
  private var kind: String?
  private var sizeCacheReader: ((SizeCacheKey) -> SizeCacheEntry?)?
  private var sizeCacheWriter: ((SizeCacheKey, SizeCacheEntry) -> Void)?

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
    renderedContainerWidth = nil
    sectionID = nil
    supplementaryID = nil
    kind = nil
    sizeCacheReader = nil
    sizeCacheWriter = nil
  }

  override func preferredLayoutAttributesFitting(
    _ layoutAttributes: UICollectionViewLayoutAttributes
  ) -> UICollectionViewLayoutAttributes {
    let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
    let width = layoutAttributes.size.width

    if let key = sizeCacheKey(width: width),
       let entry = sizeCacheReader?(key),
       entry.component == renderedComponent {
      attributes.size.height = entry.height
      return attributes
    }

    let targetSize = CGSize(
      width: width,
      height: UIView.layoutFittingCompressedSize.height
    )

    let size = systemLayoutSizeFitting(
      targetSize,
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    let height = ceil(size.height)
    attributes.size.height = height

    if let key = sizeCacheKey(width: width),
       let renderedComponent {
      sizeCacheWriter?(
        key,
        .init(component: renderedComponent, height: height)
      )
    }

    return attributes
  }

  /// 컴포넌트를 렌더링합니다.
  /// - Parameter component: 렌더링할 컴포넌트
  func render(component: AnyListComponent) {
    render(component: component, containerWidth: contentContainerView.bounds.width)
  }

  func render(component: AnyListComponent, containerWidth: CGFloat) {
    if renderedComponent?.componentTypeID != component.componentTypeID {
      renderedView?.removeFromSuperview()
      coordinator = component.makeCoordinator()
      let view = component.makeView(
        coordinator: coordinator ?? (),
        containerWidth: containerWidth
      )
      component.layout(view: view, in: contentContainerView)
      renderedView = view
    }

    if let renderedView {
      component.update(
        view: renderedView,
        coordinator: coordinator ?? (),
        containerWidth: containerWidth
      )
    }

    renderedComponent = component
    renderedContainerWidth = containerWidth
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let width = contentContainerView.bounds.width
    guard let renderedComponent,
          let renderedView,
          renderedContainerWidth != width else {
      return
    }

    renderedComponent.update(
      view: renderedView,
      coordinator: coordinator ?? (),
      containerWidth: width
    )
    renderedContainerWidth = width
  }

  /// supplementary view의 size cache 입출력 클로저를 설정합니다.
  func configureSizeCaching(
    sectionID: AnyHashable,
    supplementaryID: AnyHashable,
    kind: String,
    reader: ((SizeCacheKey) -> SizeCacheEntry?)?,
    writer: ((SizeCacheKey, SizeCacheEntry) -> Void)?
  ) {
    self.sectionID = sectionID
    self.supplementaryID = supplementaryID
    self.kind = kind
    self.sizeCacheReader = reader
    self.sizeCacheWriter = writer
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

  private func sizeCacheKey(width: CGFloat) -> SizeCacheKey? {
    guard let sectionID,
          let supplementaryID,
          let kind,
          let renderedComponent else {
      return nil
    }

    return .init(
      sectionID: sectionID,
      supplementaryID: supplementaryID,
      kind: kind,
      componentTypeID: renderedComponent.componentTypeID,
      width: Int(width.rounded(.toNearestOrAwayFromZero)),
      bottomSpacing: Int(bottomSpacing.rounded(.toNearestOrAwayFromZero))
    )
  }
}
#endif
