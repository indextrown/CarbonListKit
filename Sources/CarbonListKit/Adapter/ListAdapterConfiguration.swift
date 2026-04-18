#if canImport(UIKit)
import UIKit

/// ListAdapter의 설정을 정의하는 구조체입니다.
/// 배치 업데이트 동작을 제어합니다.
public struct ListAdapterConfiguration {
  /// 배치 업데이트 중단 카운트
  /// 이 값보다 많은 변경사항이 있으면 전체 리로드로 전환합니다.
  public var batchUpdateInterruptCount: Int
  /// reloadData 이후 즉시 layoutIfNeeded를 호출할지 여부
  public var performsLayoutAfterReload: Bool
  /// self-sizing 결과를 캐시할지 여부
  public var isSizeCachingEnabled: Bool

  /// ListAdapterConfiguration을 초기화합니다.
  /// - Parameters:
  ///   - batchUpdateInterruptCount: 배치 업데이트 중단 카운트 (기본값: 200)
  ///   - performsLayoutAfterReload: reloadData 이후 즉시 layoutIfNeeded를 호출할지 여부 (기본값: true)
  ///   - isSizeCachingEnabled: self-sizing 결과를 캐시할지 여부 (기본값: true)
  public init(
    batchUpdateInterruptCount: Int = 200,
    performsLayoutAfterReload: Bool = true,
    isSizeCachingEnabled: Bool = true
  ) {
    self.batchUpdateInterruptCount = batchUpdateInterruptCount
    self.performsLayoutAfterReload = performsLayoutAfterReload
    self.isSizeCachingEnabled = isSizeCachingEnabled
  }

  /// 기본 설정을 반환합니다.
  public static var `default`: Self {
    .init()
  }
}
#endif
