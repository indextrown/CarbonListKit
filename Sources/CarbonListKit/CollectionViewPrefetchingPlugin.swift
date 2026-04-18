#if canImport(UIKit)
import Combine
import Foundation

/// CollectionView에서 컴포넌트 리소스를 비동기로 prefetch하는 프로토콜입니다.
public protocol CollectionViewPrefetchingPlugin {

  /// 컴포넌트가 필요로 하는 리소스를 prefetch하는 작업을 수행합니다.
  /// prefetch 작업을 취소할 수 있는 AnyCancellable? 타입을 반환합니다.
  ///
  /// - Parameter component: 리소스를 prefetch할 컴포넌트
  /// - Returns: 필요시 prefetch 작업을 취소하는 데 사용할 수 있는 인스턴스 (옵션)
  func prefetch(with component: ComponentResourcePrefetchable) -> AnyCancellable?
}
#endif