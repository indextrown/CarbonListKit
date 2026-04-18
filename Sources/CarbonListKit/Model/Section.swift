#if canImport(UIKit)
import DifferenceKit
import UIKit

/// 리스트의 섹션을 나타내는 구조체입니다.
/// 행들의 컬렉션과 레이아웃 정보를 포함합니다.
public struct Section: Identifiable, Equatable {
  /// 섹션의 고유 식별자
  public let id: AnyHashable
  /// 섹션에 포함된 행들
  public var rows: [Row]
  /// 섹션의 레이아웃
  public var layout: ListLayout
  /// 섹션의 콘텐츠 인셋
  public var contentInsets: NSDirectionalEdgeInsets

  /// Section을 초기화합니다.
  /// - Parameters:
  ///   - id: 섹션의 고유 식별자
  ///   - rows: 행 배열
  ///   - layout: 레이아웃 (기본값: 수직 레이아웃)
  ///   - contentInsets: 콘텐츠 인셋 (기본값: .zero)
  public init(
    id: some Hashable,
    rows: [Row],
    layout: ListLayout = .vertical(),
    contentInsets: NSDirectionalEdgeInsets = .zero
  ) {
    self.id = id
    self.rows = rows
    self.layout = layout
    self.contentInsets = contentInsets
  }

  /// 행 빌더 클로저로 Section을 초기화합니다.
  /// - Parameters:
  ///   - id: 섹션의 고유 식별자
  ///   - layout: 레이아웃 (기본값: 수직 레이아웃)
  ///   - contentInsets: 콘텐츠 인셋 (기본값: .zero)
  ///   - rows: 행 배열을 반환하는 클로저
  public init(
    id: some Hashable,
    layout: ListLayout = .vertical(),
    contentInsets: NSDirectionalEdgeInsets = .zero,
    @RowsBuilder _ rows: () -> [Row]
  ) {
    self.id = id
    self.rows = rows()
    self.layout = layout
    self.contentInsets = contentInsets
  }

  /// 섹션의 레이아웃을 설정합니다.
  /// - Parameter layout: 적용할 레이아웃
  /// - Returns: 레이아웃이 설정된 새로운 Section
  public func layout(_ layout: ListLayout) -> Self {
    var copy = self
    copy.layout = layout
    return copy
  }

  /// 섹션 레이아웃을 설정합니다. (layout 메서드의 별칭)
  /// - Parameter layout: 적용할 레이아웃
  /// - Returns: 레이아웃이 설정된 새로운 Section
  public func withSectionLayout(_ layout: ListLayout) -> Self {
    self.layout(layout)
  }

  /// 섹션의 콘텐츠 인셋을 설정합니다.
  /// - Parameter insets: 적용할 인셋
  /// - Returns: 인셋이 설정된 새로운 Section
  public func contentInsets(_ insets: NSDirectionalEdgeInsets) -> Self {
    var copy = self
    copy.contentInsets = insets
    return copy
  }

  /// 섹션 콘텐츠 인셋을 설정합니다. (contentInsets 메서드의 별칭)
  /// - Parameter insets: 적용할 인셋
  /// - Returns: 인셋이 설정된 새로운 Section
  public func withSectionContentInsets(_ insets: NSDirectionalEdgeInsets) -> Self {
    contentInsets(insets)
  }

  /// 두 Section이 같은지 비교합니다.
  /// id, layout, contentInsets를 비교합니다.
  public static func == (lhs: Section, rhs: Section) -> Bool {
    lhs.id == rhs.id
      && lhs.layout == rhs.layout
      && lhs.contentInsets.top == rhs.contentInsets.top
      && lhs.contentInsets.leading == rhs.contentInsets.leading
      && lhs.contentInsets.bottom == rhs.contentInsets.bottom
      && lhs.contentInsets.trailing == rhs.contentInsets.trailing
  }
}

extension Section: DifferentiableSection {
  /// 차등 업데이트를 위한 식별자
  public var differenceIdentifier: AnyHashable {
    id
  }

  /// 차등 업데이트를 위한 요소들
  public var elements: [Row] {
    rows
  }

  /// 차등 업데이트를 위한 초기화 메서드
  public init<C>(source: Section, elements: C) where C: Swift.Collection, Row == C.Element {
    self = source
    self.rows = Array(elements)
  }

  /// 콘텐츠가 같은지 비교합니다.
  public func isContentEqual(to source: Section) -> Bool {
    self == source
  }
}
#endif
