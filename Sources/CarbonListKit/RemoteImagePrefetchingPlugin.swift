#if canImport(UIKit)
import Combine
import Foundation

/// CollectionViewPrefetchingPlugin 프로토콜의 구체적인 구현 클래스입니다.
/// RemoteImagePrefetching 프로토콜을 준수하는 인스턴스를 사용하여 원격 이미지를 prefetch합니다.
public final class RemoteImagePrefetchingPlugin: CollectionViewPrefetchingPlugin {

  private let remoteImagePrefetcher: RemoteImagePrefetching

  /// RemoteImagePrefetchingPlugin의 새 인스턴스를 초기화합니다.
  ///
  /// - Parameter remoteImagePrefetcher: 원격 이미지를 prefetch할 RemoteImagePrefetching 프로토콜을 준수하는 인스턴스
  public init(remoteImagePrefetcher: RemoteImagePrefetching) {
    self.remoteImagePrefetcher = remoteImagePrefetcher
  }

  /// 주어진 컴포넌트의 리소스를 prefetch합니다.
  ///
  /// - Parameter component: 리소스를 prefetch할 컴포넌트
  /// - Returns: 필요시 prefetch 작업을 취소하는 데 사용할 수 있는 AnyCancellable 인스턴스 (옵션)
  public func prefetch(with component: ComponentResourcePrefetchable) -> AnyCancellable? {
    guard let component = component as? ComponentRemoteImagePrefetchable else {
      return nil
    }

    let uuids = component.remoteImageURLs.compactMap {
      remoteImagePrefetcher.prefetchImage(url: $0)
    }

    return AnyCancellable { [weak self] in
      for uuid in uuids {
        self?.remoteImagePrefetcher.cancelTask(uuid: uuid)
      }
    }
  }
}
#endif