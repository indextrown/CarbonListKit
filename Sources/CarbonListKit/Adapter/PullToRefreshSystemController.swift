#if canImport(UIKit)
import UIKit

final class PullToRefreshSystemController {
  private weak var collectionView: UICollectionView?
  private weak var refreshControl: UIRefreshControl?
  private var handler: (@Sendable () async -> Void)?
  private var isRefreshing = false
  private var refreshTask: Task<Void, Never>?

  func update(event: PullToRefreshEvent?, collectionView: UICollectionView?) {
    self.collectionView = collectionView

    guard let collectionView else {
      removeRefreshControl()
      return
    }

    guard case .system(let style) = event?.style else {
      if isRefreshing {
        endRefreshing()
      }
      removeRefreshControl()
      return
    }

    let refreshControl = ensureRefreshControl(in: collectionView)
    refreshControl.removeTarget(self, action: #selector(handleValueChanged), for: .valueChanged)
    refreshControl.addTarget(self, action: #selector(handleValueChanged), for: .valueChanged)
    refreshControl.attributedTitle = style.attributedTitle
    refreshControl.tintColor = style.tintColor
    handler = event?.handler
  }

  func endRefreshing() {
    guard isRefreshing else {
      return
    }

    isRefreshing = false
    refreshTask?.cancel()
    refreshTask = nil
    refreshControl?.endRefreshing()
  }

  @objc private func handleValueChanged() {
    guard let handler,
          isRefreshing == false else {
      return
    }

    isRefreshing = true
    refreshTask?.cancel()
    refreshTask = Task { [weak self] in
      await handler()
      await MainActor.run {
        self?.endRefreshing()
      }
    }
  }

  private func ensureRefreshControl(in collectionView: UICollectionView) -> UIRefreshControl {
    if let refreshControl {
      return refreshControl
    }

    let refreshControl = UIRefreshControl()
    collectionView.refreshControl = refreshControl
    self.refreshControl = refreshControl
    return refreshControl
  }

  private func removeRefreshControl() {
    refreshControl?.removeTarget(self, action: #selector(handleValueChanged), for: .valueChanged)
    if collectionView?.refreshControl === refreshControl {
      collectionView?.refreshControl = nil
    }
    refreshControl?.tintColor = nil
    refreshTask?.cancel()
    refreshTask = nil
    refreshControl = nil
    handler = nil
    isRefreshing = false
  }
}

private extension PullToRefreshSystemStyle {
  var attributedTitle: NSAttributedString? {
    guard let title else {
      return nil
    }

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    paragraphStyle.lineBreakMode = .byTruncatingTail

    return NSAttributedString(
      string: title,
      attributes: [
        .foregroundColor: titleColor,
        .font: titleFont,
        .paragraphStyle: paragraphStyle
      ]
    )
  }
}
#endif
