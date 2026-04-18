#if canImport(UIKit)
import UIKit

/// 리스트 섹션의 레이아웃을 정의하는 열거형입니다.
/// 수직, 그리드, 커스텀 레이아웃을 지원합니다.
public enum ListLayout: Equatable {
  /// 수직 레이아웃 (기본값: 간격 0)
  case vertical(spacing: CGFloat = 0)
  /// 그리드 레이아웃 (열 수, 아이템 간격, 라인 간격)
  case grid(columns: Int, itemSpacing: CGFloat = 0, lineSpacing: CGFloat = 0)
  /// 커스텀 레이아웃 (섹션 제공 클로저)
  case custom((ListLayoutContext) -> NSCollectionLayoutSection)

  /// 두 ListLayout이 같은지 비교합니다.
  /// 커스텀 레이아웃은 항상 false를 반환합니다.
  public static func == (lhs: ListLayout, rhs: ListLayout) -> Bool {
    switch (lhs, rhs) {
    case (.vertical(let lhsSpacing), .vertical(let rhsSpacing)):
      return lhsSpacing == rhsSpacing
    case (.grid(let lhsColumns, let lhsItemSpacing, let lhsLineSpacing), .grid(let rhsColumns, let rhsItemSpacing, let rhsLineSpacing)):
      return lhsColumns == rhsColumns && lhsItemSpacing == rhsItemSpacing && lhsLineSpacing == rhsLineSpacing
    case (.custom, .custom):
      return false
    default:
      return false
    }
  }
}

/// 리스트 레이아웃 컨텍스트입니다.
/// 커스텀 레이아웃 제공 시 필요한 정보를 포함합니다.
public struct ListLayoutContext {
  /// 레이아웃을 적용할 섹션
  public let section: Section
  /// 섹션의 인덱스
  public let sectionIndex: Int
  /// 컬렉션 뷰의 레이아웃 환경
  public let environment: NSCollectionLayoutEnvironment

  /// ListLayoutContext를 초기화합니다.
  /// - Parameters:
  ///   - section: 섹션
  ///   - sectionIndex: 섹션 인덱스
  /// - environment: 레이아웃 환경
  public init(
    section: Section,
    sectionIndex: Int,
    environment: NSCollectionLayoutEnvironment
  ) {
    self.section = section
    self.sectionIndex = sectionIndex
    self.environment = environment
  }
}
#endif
