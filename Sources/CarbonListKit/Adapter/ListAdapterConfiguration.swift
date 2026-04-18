#if canImport(UIKit)
import UIKit

/// ListAdapter의 설정을 정의하는 구조체입니다.
/// 배치 업데이트 동작을 제어합니다.
public struct ListAdapterConfiguration {
  /// 배치 업데이트 중단 카운트
  /// 이 값보다 많은 변경사항이 있으면 전체 리로드로 전환합니다.
  public var batchUpdateInterruptCount: Int

  /// ListAdapterConfiguration을 초기화합니다.
  /// - Parameter batchUpdateInterruptCount: 배치 업데이트 중단 카운트 (기본값: 200)
  public init(batchUpdateInterruptCount: Int = 200) {
    self.batchUpdateInterruptCount = batchUpdateInterruptCount
  }

  /// 기본 설정을 반환합니다.
  public static var `default`: Self {
    .init()
  }
}
#endif
