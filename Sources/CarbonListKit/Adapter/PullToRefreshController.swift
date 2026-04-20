#if canImport(UIKit)
import UIKit

final class PullToRefreshController {
  private let systemController = PullToRefreshSystemController()
  private let customController = PullToRefreshCustomController()

  func update(event: PullToRefreshEvent?, collectionView: UICollectionView?) {
    systemController.update(event: event, collectionView: collectionView)
    customController.update(event: event, collectionView: collectionView)
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    customController.scrollViewDidScroll(scrollView)
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
    customController.scrollViewDidEndDragging(scrollView, willDecelerate: willDecelerate)
  }

  func endRefreshing() {
    systemController.endRefreshing()
    customController.endRefreshing()
  }
}
#endif
