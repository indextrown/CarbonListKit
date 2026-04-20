#if canImport(UIKit)
import Foundation

/// 원격 이미지 prefetch를 수행하는 프로토콜입니다.
public protocol RemoteImagePrefetching {

  /// 주어진 URL에서 이미지를 prefetch합니다.
  ///
  /// - Parameter url: prefetch할 이미지의 URL
  /// - Returns: prefetch 작업을 나타내는 UUID. 필요시 작업을 취소하는 데 사용할 수 있습니다.
  func prefetchImage(url: URL) -> UUID?

  /// 주어진 UUID로 prefetch 작업을 취소합니다.
  ///
  /// - Parameter uuid: 취소할 prefetch 작업의 UUID
  func cancelTask(uuid: UUID)
}
#endif
