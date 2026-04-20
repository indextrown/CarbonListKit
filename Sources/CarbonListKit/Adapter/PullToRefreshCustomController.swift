#if canImport(UIKit)
import UIKit

final class PullToRefreshCustomController {
  private enum Animation {
    static let duration: TimeInterval = 0.25
  }

  private weak var collectionView: UICollectionView?
  private weak var refreshView: PullToRefreshControlView?
  private var event: PullToRefreshEvent?
  private var isRefreshing = false
  private var refreshTask: Task<Void, Never>?
  private var storedContentInsetTop: CGFloat = 0

  func update(event: PullToRefreshEvent?, collectionView: UICollectionView?) {
    self.collectionView = collectionView
    self.event = event

    guard let collectionView else {
      removeRefreshView()
      return
    }

    guard case .custom(let style) = event?.style else {
      if isRefreshing {
        endRefreshing()
      }
      removeRefreshView()
      return
    }

    let refreshView = ensureRefreshView(in: collectionView)
    refreshView.configure(style: style)
    layoutRefreshViewIfNeeded()
    collectionView.bringSubviewToFront(refreshView)
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard let collectionView,
          scrollView === collectionView,
          let refreshView,
          isVertical(collectionView) else {
      return
    }

    layoutRefreshViewIfNeeded()

    if isRefreshing {
      refreshView.setRefreshing(true)
      return
    }

    let pullDistance = pullDistance(for: scrollView)
    let progress = max(0, min(1, pullDistance / refreshView.triggerHeight))
    refreshView.setProgress(progress)
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
    guard let collectionView,
          scrollView === collectionView,
          isRefreshing == false,
          let event,
          let refreshView,
          isVertical(collectionView) else {
      return
    }

    let pullDistance = pullDistance(for: scrollView)
    guard pullDistance >= refreshView.triggerHeight else {
      return
    }

    beginRefreshing(with: event)
  }

  func endRefreshing() {
    guard isRefreshing else {
      return
    }

    isRefreshing = false
    refreshTask?.cancel()
    refreshTask = nil

    guard let collectionView,
          let refreshView else {
      return
    }

    let targetInsetTop = storedContentInsetTop
    let targetOffsetY = -(collectionView.adjustedContentInset.top - refreshView.preferredHeight)

    animateScrollState(
      contentInsetTop: targetInsetTop,
      targetOffsetY: targetOffsetY,
      on: collectionView
    )

    refreshView.setRefreshing(false)
    refreshView.setProgress(0)
    layoutRefreshViewIfNeeded()
  }

  private func beginRefreshing(with event: PullToRefreshEvent) {
    guard let collectionView,
          let refreshView,
          isRefreshing == false else {
      return
    }

    isRefreshing = true
    storedContentInsetTop = collectionView.contentInset.top

    let refreshHeight = refreshView.preferredHeight
    refreshView.setRefreshing(true)
    refreshView.setProgress(1)
    layoutRefreshViewIfNeeded()

    let targetInsetTop = storedContentInsetTop + refreshHeight
    let targetOffsetY = -(collectionView.adjustedContentInset.top + refreshHeight)

    animateScrollState(
      contentInsetTop: targetInsetTop,
      targetOffsetY: targetOffsetY,
      on: collectionView
    )

    refreshTask?.cancel()
    refreshTask = Task { [weak self] in
      await event.handler()
      await MainActor.run {
        self?.endRefreshing()
      }
    }
  }

  private func ensureRefreshView(in collectionView: UICollectionView) -> PullToRefreshControlView {
    if let refreshView {
      return refreshView
    }

    let refreshView = PullToRefreshControlView()
    refreshView.isUserInteractionEnabled = false
    refreshView.frame = CGRect(
      x: 0,
      y: -refreshView.preferredHeight,
      width: collectionView.bounds.width,
      height: refreshView.preferredHeight
    )
    collectionView.addSubview(refreshView)
    self.refreshView = refreshView
    return refreshView
  }

  private func removeRefreshView() {
    refreshView?.removeFromSuperview()
    refreshView = nil
    refreshTask?.cancel()
    refreshTask = nil
    isRefreshing = false
  }

  private func layoutRefreshViewIfNeeded() {
    guard let collectionView,
          let refreshView else {
      return
    }

    let height = refreshView.preferredHeight
    refreshView.frame = CGRect(
      x: 0,
      y: -height,
      width: collectionView.bounds.width,
      height: height
    )
  }

  private func animateScrollState(
    contentInsetTop: CGFloat,
    targetOffsetY: CGFloat,
    on collectionView: UICollectionView
  ) {
    var inset = collectionView.contentInset
    inset.top = contentInsetTop

    UIView.animate(
      withDuration: Animation.duration,
      delay: 0,
      options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseOut]
    ) {
      collectionView.contentInset = inset
      collectionView.contentOffset = CGPoint(x: collectionView.contentOffset.x, y: targetOffsetY)
      collectionView.layoutIfNeeded()
    }
  }

  private func pullDistance(for scrollView: UIScrollView) -> CGFloat {
    max(0, -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top))
  }

  private func isVertical(_ collectionView: UICollectionView) -> Bool {
    let layout = collectionView.collectionViewLayout as? UICollectionViewCompositionalLayout
    return layout?.configuration.scrollDirection != .horizontal
  }
}

private final class PullToRefreshControlView: UIView {
  private let contentView = UIView()
  private let titleLabel = UILabel()
  private let indicatorContainerView = UIView()
  private var indicatorKind: IndicatorKind?
  private var indicatorWidthConstraint: NSLayoutConstraint?
  private var indicatorHeightConstraint: NSLayoutConstraint?
  private var containerWidthConstraint: NSLayoutConstraint?
  private var containerHeightConstraint: NSLayoutConstraint?

  private(set) var preferredHeight: CGFloat = 64
  private(set) var triggerHeight: CGFloat = 64

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(style: PullToRefreshCustomStyle) {
    titleLabel.text = style.title
    titleLabel.textColor = style.titleColor
    titleLabel.font = style.titleFont
    applyIndicator(style.indicator)
    contentView.alpha = 0
    setNeedsLayout()
    layoutIfNeeded()
    recalculateSizing()
  }

  func setProgress(_ progress: CGFloat) {
    let clamped = max(0, min(1, progress))
    contentView.alpha = clamped
    if clamped > 0 {
      indicatorKind?.stopAnimating()
    }
  }

  func setRefreshing(_ isRefreshing: Bool) {
    if isRefreshing {
      contentView.alpha = 1
      indicatorKind?.startAnimating()
    } else {
      indicatorKind?.stopAnimating()
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    recalculateSizing()
  }

  private func setup() {
    backgroundColor = .clear
    isOpaque = false

    contentView.backgroundColor = .clear
    contentView.translatesAutoresizingMaskIntoConstraints = false

    let stackView = UIStackView(arrangedSubviews: [titleLabel, indicatorContainerView])
    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.spacing = 8
    stackView.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.numberOfLines = 1
    titleLabel.lineBreakMode = .byTruncatingTail
    titleLabel.textAlignment = .center

    indicatorContainerView.translatesAutoresizingMaskIntoConstraints = false

    addSubview(contentView)
    contentView.addSubview(stackView)

    NSLayoutConstraint.activate([
      contentView.topAnchor.constraint(equalTo: topAnchor),
      contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
      contentView.bottomAnchor.constraint(equalTo: bottomAnchor),

      stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      stackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
      stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      stackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
      stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
    ])

    recalculateSizing()
  }

  private func applyIndicator(_ indicator: PullToRefreshIndicator) {
    switch indicator {
    case .activity(let style, let tintColor, let size):
      let activityIndicator = UIActivityIndicatorView(style: style)
      activityIndicator.color = tintColor
      activityIndicator.hidesWhenStopped = true
      setIndicatorView(activityIndicator, size: size)
      indicatorKind = .activity(activityIndicator)
    case .image(let image, let tintColor, let contentMode, let size, let rotatesWhileRefreshing, let rotationDuration):
      let imageView = UIImageView(image: image.withRenderingMode(tintColor == nil ? .alwaysOriginal : .alwaysTemplate))
      imageView.tintColor = tintColor
      imageView.contentMode = contentMode
      setIndicatorView(imageView, size: size)
      indicatorKind = .image(
        imageView,
        rotatesWhileRefreshing: rotatesWhileRefreshing,
        rotationDuration: rotationDuration
      )
    case .custom(let size, let makeView):
      let customView = makeView()
      setIndicatorView(customView, size: size)
      indicatorKind = .custom(customView)
    }
  }

  private func setIndicatorView(_ view: UIView, size: CGSize) {
    indicatorKind?.view.removeFromSuperview()
    indicatorContainerView.subviews.forEach { $0.removeFromSuperview() }

    NSLayoutConstraint.deactivate([
      indicatorWidthConstraint,
      indicatorHeightConstraint,
      containerWidthConstraint,
      containerHeightConstraint
    ].compactMap { $0 })

    view.translatesAutoresizingMaskIntoConstraints = false
    indicatorContainerView.addSubview(view)

    indicatorWidthConstraint = view.widthAnchor.constraint(equalToConstant: size.width)
    indicatorHeightConstraint = view.heightAnchor.constraint(equalToConstant: size.height)
    containerWidthConstraint = indicatorContainerView.widthAnchor.constraint(equalToConstant: size.width)
    containerHeightConstraint = indicatorContainerView.heightAnchor.constraint(equalToConstant: size.height)

    NSLayoutConstraint.activate([
      view.centerXAnchor.constraint(equalTo: indicatorContainerView.centerXAnchor),
      view.centerYAnchor.constraint(equalTo: indicatorContainerView.centerYAnchor),
      indicatorWidthConstraint!,
      indicatorHeightConstraint!,
      containerWidthConstraint!,
      containerHeightConstraint!
    ])

    indicatorContainerView.layoutIfNeeded()
  }

  private func recalculateSizing() {
    let targetSize = CGSize(width: bounds.width, height: UIView.layoutFittingCompressedSize.height)
    let fittingSize = systemLayoutSizeFitting(
      targetSize,
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )

    let height = max(64, fittingSize.height)
    preferredHeight = height
    triggerHeight = height
  }
}

private enum IndicatorKind {
  case activity(UIActivityIndicatorView)
  case image(
    UIImageView,
    rotatesWhileRefreshing: Bool,
    rotationDuration: TimeInterval
  )
  case custom(UIView)

  var view: UIView {
    switch self {
    case .activity(let view):
      return view
    case .image(let view, _, _):
      return view
    case .custom(let view):
      return view
    }
  }

  func startAnimating() {
    switch self {
    case .activity(let view):
      view.startAnimating()
    case .image(let view, let rotatesWhileRefreshing, let rotationDuration):
      guard rotatesWhileRefreshing else {
        return
      }
      view.startRotation(duration: rotationDuration)
    case .custom:
      break
    }
  }

  func stopAnimating() {
    switch self {
    case .activity(let view):
      view.stopAnimating()
    case .image(let view, let rotatesWhileRefreshing, _):
      guard rotatesWhileRefreshing else {
        return
      }
      view.stopRotation()
    case .custom:
      break
    }
  }
}

private extension UIImageView {
  func startRotation(duration: TimeInterval) {
    if layer.animation(forKey: "pullToRefresh.rotation") != nil {
      return
    }

    let animation = CABasicAnimation(keyPath: "transform.rotation.z")
    animation.fromValue = 0
    animation.toValue = Double.pi * 2
    animation.duration = max(0.01, duration)
    animation.repeatCount = .infinity
    animation.isRemovedOnCompletion = false
    layer.add(animation, forKey: "pullToRefresh.rotation")
  }

  func stopRotation() {
    layer.removeAnimation(forKey: "pullToRefresh.rotation")
    transform = .identity
  }
}
#endif
