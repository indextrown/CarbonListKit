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
  /// orthogonal scrolling 동작
  public var orthogonalScrollingBehavior: ListOrthogonalScrollingBehavior?
  /// 섹션의 콘텐츠 인셋
  public var contentInsets: NSDirectionalEdgeInsets
  /// header/footer를 포함한 전체 섹션 인셋
  public var sectionInsets: NSDirectionalEdgeInsets
  /// 다음 섹션과의 간격
  public var sectionSpacing: CGFloat
  /// 섹션 header
  public var header: SectionSupplementary?
  /// 섹션 footer
  public var footer: SectionSupplementary?

  private struct AutomaticID: Hashable {
    let fileID: String
    let line: UInt
    let column: UInt
  }

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
    orthogonalScrollingBehavior: ListOrthogonalScrollingBehavior? = nil,
    contentInsets: NSDirectionalEdgeInsets = .zero,
    sectionInsets: NSDirectionalEdgeInsets = .zero,
    sectionSpacing: CGFloat = 0,
    header: SectionSupplementary? = nil,
    footer: SectionSupplementary? = nil
  ) {
    self.id = id
    self.rows = rows
    self.layout = layout
    self.orthogonalScrollingBehavior = orthogonalScrollingBehavior
    self.contentInsets = contentInsets
    self.sectionInsets = sectionInsets
    self.sectionSpacing = sectionSpacing
    self.header = header
    self.footer = footer
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
    orthogonalScrollingBehavior: ListOrthogonalScrollingBehavior? = nil,
    contentInsets: NSDirectionalEdgeInsets = .zero,
    sectionInsets: NSDirectionalEdgeInsets = .zero,
    sectionSpacing: CGFloat = 0,
    header: SectionSupplementary? = nil,
    footer: SectionSupplementary? = nil,
    @RowsBuilder _ rows: () -> [Row]
  ) {
    self.id = id
    self.rows = rows()
    self.layout = layout
    self.orthogonalScrollingBehavior = orthogonalScrollingBehavior
    self.contentInsets = contentInsets
    self.sectionInsets = sectionInsets
    self.sectionSpacing = sectionSpacing
    self.header = header
    self.footer = footer
  }

  /// SwiftUI 스타일로 rows 뒤에 header와 footer 클로저를 붙여 Section을 초기화합니다.
  ///
  /// ```swift
  /// Section(id: "section") {
  ///   Row(id: "row", component: RowComponent(...))
  /// } header: {
  ///   Header(id: "header", component: HeaderComponent(...))
  /// } footer: {
  ///   Footer(id: "footer", component: FooterComponent(...))
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - id: 섹션의 고유 식별자
  ///   - layout: 레이아웃 (기본값: 수직 레이아웃)
  ///   - contentInsets: 콘텐츠 인셋 (기본값: .zero)
  ///   - rows: 행 배열을 반환하는 클로저
  ///   - header: header를 반환하는 클로저
  ///   - footer: footer를 반환하는 클로저
  public init(
    id: some Hashable,
    layout: ListLayout = .vertical(),
    orthogonalScrollingBehavior: ListOrthogonalScrollingBehavior? = nil,
    contentInsets: NSDirectionalEdgeInsets = .zero,
    sectionInsets: NSDirectionalEdgeInsets = .zero,
    sectionSpacing: CGFloat = 0,
    @RowsBuilder _ rows: () -> [Row],
    @SectionSupplementaryBuilder header: () -> SectionSupplementary?,
    @SectionSupplementaryBuilder footer: () -> SectionSupplementary?
  ) {
    self.id = id
    self.rows = rows()
    self.layout = layout
    self.orthogonalScrollingBehavior = orthogonalScrollingBehavior
    self.contentInsets = contentInsets
    self.sectionInsets = sectionInsets
    self.sectionSpacing = sectionSpacing
    self.header = header()
    self.footer = footer()
  }

  /// SwiftUI 스타일로 id를 생략하고 Section을 초기화합니다.
  /// 자동 id는 호출 위치(`#fileID`, `#line`, `#column`)를 기반으로 만들어집니다.
  ///
  /// diff 안정성이 중요한 동적 섹션에서는 명시적인 `id:` 사용을 권장합니다.
  public init(
    layout: ListLayout = .vertical(),
    orthogonalScrollingBehavior: ListOrthogonalScrollingBehavior? = nil,
    contentInsets: NSDirectionalEdgeInsets = .zero,
    sectionInsets: NSDirectionalEdgeInsets = .zero,
    sectionSpacing: CGFloat = 0,
    @RowsBuilder _ rows: () -> [Row],
    fileID: StaticString = #fileID,
    line: UInt = #line,
    column: UInt = #column
  ) {
    self.init(
      id: Self.automaticID(fileID: fileID, line: line, column: column),
      layout: layout,
      orthogonalScrollingBehavior: orthogonalScrollingBehavior,
      contentInsets: contentInsets,
      sectionInsets: sectionInsets,
      sectionSpacing: sectionSpacing,
      rows
    )
  }

  /// SwiftUI 스타일로 id를 생략하고 rows 뒤에 header와 footer 클로저를 붙여 Section을 초기화합니다.
  /// 자동 id는 호출 위치(`#fileID`, `#line`, `#column`)를 기반으로 만들어집니다.
  public init(
    layout: ListLayout = .vertical(),
    orthogonalScrollingBehavior: ListOrthogonalScrollingBehavior? = nil,
    contentInsets: NSDirectionalEdgeInsets = .zero,
    sectionInsets: NSDirectionalEdgeInsets = .zero,
    sectionSpacing: CGFloat = 0,
    @RowsBuilder _ rows: () -> [Row],
    @SectionSupplementaryBuilder header: () -> SectionSupplementary?,
    @SectionSupplementaryBuilder footer: () -> SectionSupplementary?,
    fileID: StaticString = #fileID,
    line: UInt = #line,
    column: UInt = #column
  ) {
    self.init(
      id: Self.automaticID(fileID: fileID, line: line, column: column),
      layout: layout,
      orthogonalScrollingBehavior: orthogonalScrollingBehavior,
      contentInsets: contentInsets,
      sectionInsets: sectionInsets,
      sectionSpacing: sectionSpacing,
      rows,
      header: header,
      footer: footer
    )
  }

  /// SwiftUI 스타일로 rows 뒤에 header 클로저를 붙여 Section을 초기화합니다.
  public init(
    id: some Hashable,
    layout: ListLayout = .vertical(),
    orthogonalScrollingBehavior: ListOrthogonalScrollingBehavior? = nil,
    contentInsets: NSDirectionalEdgeInsets = .zero,
    sectionInsets: NSDirectionalEdgeInsets = .zero,
    sectionSpacing: CGFloat = 0,
    @RowsBuilder _ rows: () -> [Row],
    @SectionSupplementaryBuilder header: () -> SectionSupplementary?
  ) {
    self.init(
      id: id,
      layout: layout,
      orthogonalScrollingBehavior: orthogonalScrollingBehavior,
      contentInsets: contentInsets,
      sectionInsets: sectionInsets,
      sectionSpacing: sectionSpacing,
      rows,
      header: header,
      footer: { nil }
    )
  }

  /// SwiftUI 스타일로 id를 생략하고 rows 뒤에 header 클로저를 붙여 Section을 초기화합니다.
  /// 자동 id는 호출 위치(`#fileID`, `#line`, `#column`)를 기반으로 만들어집니다.
  public init(
    layout: ListLayout = .vertical(),
    orthogonalScrollingBehavior: ListOrthogonalScrollingBehavior? = nil,
    contentInsets: NSDirectionalEdgeInsets = .zero,
    sectionInsets: NSDirectionalEdgeInsets = .zero,
    sectionSpacing: CGFloat = 0,
    @RowsBuilder _ rows: () -> [Row],
    @SectionSupplementaryBuilder header: () -> SectionSupplementary?,
    fileID: StaticString = #fileID,
    line: UInt = #line,
    column: UInt = #column
  ) {
    self.init(
      id: Self.automaticID(fileID: fileID, line: line, column: column),
      layout: layout,
      orthogonalScrollingBehavior: orthogonalScrollingBehavior,
      contentInsets: contentInsets,
      sectionInsets: sectionInsets,
      sectionSpacing: sectionSpacing,
      rows,
      header: header,
      footer: { nil }
    )
  }

  /// SwiftUI 스타일로 rows 뒤에 footer 클로저를 붙여 Section을 초기화합니다.
  public init(
    id: some Hashable,
    layout: ListLayout = .vertical(),
    orthogonalScrollingBehavior: ListOrthogonalScrollingBehavior? = nil,
    contentInsets: NSDirectionalEdgeInsets = .zero,
    sectionInsets: NSDirectionalEdgeInsets = .zero,
    sectionSpacing: CGFloat = 0,
    @RowsBuilder _ rows: () -> [Row],
    @SectionSupplementaryBuilder footer: () -> SectionSupplementary?
  ) {
    self.init(
      id: id,
      layout: layout,
      orthogonalScrollingBehavior: orthogonalScrollingBehavior,
      contentInsets: contentInsets,
      sectionInsets: sectionInsets,
      sectionSpacing: sectionSpacing,
      rows,
      header: { nil },
      footer: footer
    )
  }

  /// SwiftUI 스타일로 id를 생략하고 rows 뒤에 footer 클로저를 붙여 Section을 초기화합니다.
  /// 자동 id는 호출 위치(`#fileID`, `#line`, `#column`)를 기반으로 만들어집니다.
  public init(
    layout: ListLayout = .vertical(),
    orthogonalScrollingBehavior: ListOrthogonalScrollingBehavior? = nil,
    contentInsets: NSDirectionalEdgeInsets = .zero,
    sectionInsets: NSDirectionalEdgeInsets = .zero,
    sectionSpacing: CGFloat = 0,
    @RowsBuilder _ rows: () -> [Row],
    @SectionSupplementaryBuilder footer: () -> SectionSupplementary?,
    fileID: StaticString = #fileID,
    line: UInt = #line,
    column: UInt = #column
  ) {
    self.init(
      id: Self.automaticID(fileID: fileID, line: line, column: column),
      layout: layout,
      orthogonalScrollingBehavior: orthogonalScrollingBehavior,
      contentInsets: contentInsets,
      sectionInsets: sectionInsets,
      sectionSpacing: sectionSpacing,
      rows,
      header: { nil },
      footer: footer
    )
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

  /// 섹션 내부 아이템의 orthogonal scrolling 동작을 설정합니다.
  /// - Parameter behavior: 적용할 orthogonal scrolling 동작
  /// - Returns: orthogonal scrolling 동작이 설정된 새로운 Section
  public func orthogonalScrollingBehavior(
    _ behavior: ListOrthogonalScrollingBehavior?
  ) -> Self {
    var copy = self
    copy.orthogonalScrollingBehavior = behavior
    return copy
  }

  /// 섹션 내부 아이템의 orthogonal scrolling 동작을 설정합니다. (orthogonalScrollingBehavior 메서드의 별칭)
  /// - Parameter behavior: 적용할 orthogonal scrolling 동작
  /// - Returns: orthogonal scrolling 동작이 설정된 새로운 Section
  public func withOrthogonalScrollingBehavior(
    _ behavior: ListOrthogonalScrollingBehavior?
  ) -> Self {
    orthogonalScrollingBehavior(behavior)
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

  /// header/footer를 포함한 전체 섹션 인셋을 설정합니다.
  /// - Parameter insets: 적용할 인셋
  /// - Returns: 전체 섹션 인셋이 설정된 새로운 Section
  public func sectionInsets(_ insets: NSDirectionalEdgeInsets) -> Self {
    var copy = self
    copy.sectionInsets = insets
    return copy
  }

  /// header/footer를 포함한 전체 섹션 인셋을 설정합니다. (sectionInsets 메서드의 별칭)
  /// - Parameter insets: 적용할 인셋
  /// - Returns: 전체 섹션 인셋이 설정된 새로운 Section
  public func withSectionInsets(_ insets: NSDirectionalEdgeInsets) -> Self {
    sectionInsets(insets)
  }

  /// 다음 섹션과의 간격을 설정합니다.
  /// - Parameter spacing: 적용할 간격
  /// - Returns: 섹션 간격이 설정된 새로운 Section
  public func sectionSpacing(_ spacing: CGFloat) -> Self {
    var copy = self
    copy.sectionSpacing = spacing
    return copy
  }

  /// 다음 섹션과의 간격을 설정합니다. (sectionSpacing 메서드의 별칭)
  /// - Parameter spacing: 적용할 간격
  /// - Returns: 섹션 간격이 설정된 새로운 Section
  public func withSectionSpacing(_ spacing: CGFloat) -> Self {
    sectionSpacing(spacing)
  }

  /// 섹션 header를 설정합니다.
  /// - Parameter header: 적용할 header
  /// - Returns: header가 설정된 새로운 Section
  public func header(_ header: SectionSupplementary?) -> Self {
    var copy = self
    copy.header = header
    return copy
  }

  /// 섹션 header를 설정합니다. (header 메서드의 별칭)
  /// - Parameter header: 적용할 header
  /// - Returns: header가 설정된 새로운 Section
  public func withSectionHeader(_ header: SectionSupplementary?) -> Self {
    self.header(header)
  }

  /// 섹션 footer를 설정합니다.
  /// - Parameter footer: 적용할 footer
  /// - Returns: footer가 설정된 새로운 Section
  public func footer(_ footer: SectionSupplementary?) -> Self {
    var copy = self
    copy.footer = footer
    return copy
  }

  /// 섹션 footer를 설정합니다. (footer 메서드의 별칭)
  /// - Parameter footer: 적용할 footer
  /// - Returns: footer가 설정된 새로운 Section
  public func withSectionFooter(_ footer: SectionSupplementary?) -> Self {
    self.footer(footer)
  }

  /// 두 Section이 같은지 비교합니다.
  /// id, rows, layout, contentInsets를 비교합니다.
  public static func == (lhs: Section, rhs: Section) -> Bool {
    lhs.id == rhs.id
      && lhs.rows == rhs.rows
      && lhs.layout == rhs.layout
      && lhs.orthogonalScrollingBehavior == rhs.orthogonalScrollingBehavior
      && lhs.contentInsets.top == rhs.contentInsets.top
      && lhs.contentInsets.leading == rhs.contentInsets.leading
      && lhs.contentInsets.bottom == rhs.contentInsets.bottom
      && lhs.contentInsets.trailing == rhs.contentInsets.trailing
      && lhs.sectionInsets.top == rhs.sectionInsets.top
      && lhs.sectionInsets.leading == rhs.sectionInsets.leading
      && lhs.sectionInsets.bottom == rhs.sectionInsets.bottom
      && lhs.sectionInsets.trailing == rhs.sectionInsets.trailing
      && lhs.sectionSpacing == rhs.sectionSpacing
      && lhs.header == rhs.header
      && lhs.footer == rhs.footer
  }

  private static func automaticID(
    fileID: StaticString,
    line: UInt,
    column: UInt
  ) -> AnyHashable {
    AnyHashable(
      AutomaticID(
        fileID: String(describing: fileID),
        line: line,
        column: column
      )
    )
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

  /// 섹션 자체의 표시 콘텐츠가 같은지 비교합니다.
  /// rows는 element diff에서 별도로 비교하여 move 애니메이션을 유지합니다.
  public func isContentEqual(to source: Section) -> Bool {
    id == source.id
      && layout == source.layout
      && orthogonalScrollingBehavior == source.orthogonalScrollingBehavior
      && contentInsets.top == source.contentInsets.top
      && contentInsets.leading == source.contentInsets.leading
      && contentInsets.bottom == source.contentInsets.bottom
      && contentInsets.trailing == source.contentInsets.trailing
      && sectionInsets.top == source.sectionInsets.top
      && sectionInsets.leading == source.sectionInsets.leading
      && sectionInsets.bottom == source.sectionInsets.bottom
      && sectionInsets.trailing == source.sectionInsets.trailing
      && sectionSpacing == source.sectionSpacing
      && header == source.header
      && footer == source.footer
  }
}
#endif
