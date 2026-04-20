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
    refreshTask = Task { @MainActor [weak self] in
      await event.handler()
      self?.endRefreshing()
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
  private let titleLabel = UILabel()
  private let indicatorContainerView = UIView()
  private var indicatorKind: IndicatorKind?
  private var indicatorSize: CGSize = .zero

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
    alpha = 0
    setNeedsLayout()
    recalculateSizing()
  }

  func setProgress(_ progress: CGFloat) {
    let clamped = max(0, min(1, progress))
    alpha = clamped
    if clamped > 0 {
      indicatorKind?.stopAnimating()
    }
  }

  func setRefreshing(_ isRefreshing: Bool) {
    if isRefreshing {
      alpha = 1
      indicatorKind?.startAnimating()
    } else {
      indicatorKind?.stopAnimating()
    }
  }

  private func setup() {
    backgroundColor = .clear
    isOpaque = false

    titleLabel.backgroundColor = .clear
    titleLabel.numberOfLines = 1
    titleLabel.lineBreakMode = .byTruncatingTail
    titleLabel.textAlignment = .center
    titleLabel.translatesAutoresizingMaskIntoConstraints = true

    indicatorContainerView.backgroundColor = .clear
    indicatorContainerView.translatesAutoresizingMaskIntoConstraints = true

    addSubview(titleLabel)
    addSubview(indicatorContainerView)

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

    indicatorSize = size
    view.translatesAutoresizingMaskIntoConstraints = true
    indicatorContainerView.addSubview(view)
    setNeedsLayout()
  }

  private func recalculateSizing() {
    let availableWidth = max(0, bounds.width - 32)
    let titleSize = titleLabel.sizeThatFits(
      CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
    )
    let titleHeight = ceil(titleSize.height)
    let indicatorHeight = ceil(indicatorSize.height)
    let contentHeight = 12 + titleHeight + (titleHeight > 0 && indicatorHeight > 0 ? 8 : 0) + indicatorHeight + 12
    let height = max(64, contentHeight)
    preferredHeight = height
    triggerHeight = height
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    recalculateSizing()

    let horizontalPadding: CGFloat = 16
    let topPadding: CGFloat = 12
    let spacing: CGFloat = 8
    let bottomPadding: CGFloat = 12
    let availableWidth = max(0, bounds.width - horizontalPadding * 2)

    let titleSize = titleLabel.sizeThatFits(
      CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
    )
    let titleWidth = min(availableWidth, ceil(titleSize.width))
    let titleHeight = ceil(titleSize.height)
    let titleX = floor((bounds.width - titleWidth) / 2)
    titleLabel.frame = CGRect(x: titleX, y: topPadding, width: titleWidth, height: titleHeight)

    let indicatorWidth = ceil(indicatorSize.width)
    let indicatorHeight = ceil(indicatorSize.height)
    let indicatorX = floor((bounds.width - indicatorWidth) / 2)
    let indicatorY = titleLabel.frame.maxY + (titleHeight > 0 && indicatorHeight > 0 ? spacing : 0)
    indicatorContainerView.frame = CGRect(
      x: indicatorX,
      y: indicatorY,
      width: indicatorWidth,
      height: indicatorHeight
    )

    indicatorKind?.view.frame = CGRect(
      x: floor((indicatorContainerView.bounds.width - indicatorWidth) / 2),
      y: floor((indicatorContainerView.bounds.height - indicatorHeight) / 2),
      width: indicatorWidth,
      height: indicatorHeight
    )

    let requiredHeight = topPadding + titleHeight + (titleHeight > 0 && indicatorHeight > 0 ? spacing : 0) + indicatorHeight + bottomPadding
    preferredHeight = max(64, ceil(requiredHeight))
    triggerHeight = preferredHeight
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
