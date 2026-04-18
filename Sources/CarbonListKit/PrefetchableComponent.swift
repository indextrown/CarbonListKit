#if canImport(UIKit)
import Foundation

/// 리소스 prefetch가 필요한 컴포넌트를 위한 프로토콜입니다.
public protocol ComponentResourcePrefetchable {}

/// 원격 이미지 prefetch가 필요한 컴포넌트를 위한 프로토콜입니다.
public protocol ComponentRemoteImagePrefetchable: ComponentResourcePrefetchable {

  /// prefetch가 필요한 원격 이미지 URL들입니다.
  var remoteImageURLs: [URL] { get }
}
#endif