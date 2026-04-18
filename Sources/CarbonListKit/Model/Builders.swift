#if canImport(UIKit)
import UIKit

/// 리스트를 구축하기 위한 결과 빌더입니다.
/// 섹션들의 DSL을 지원합니다.
@resultBuilder
public enum ListBuilder {
  /// 여러 섹션 블록을 결합합니다.
  public static func buildBlock(_ components: [Section]...) -> [Section] {
    components.flatMap { $0 }
  }

  /// 단일 섹션을 표현식으로 변환합니다.
  public static func buildExpression(_ expression: Section) -> [Section] {
    [expression]
  }

  /// 섹션 배열을 표현식으로 변환합니다.
  public static func buildExpression(_ expression: [Section]) -> [Section] {
    expression
  }

  /// 옵션 섹션을 처리합니다.
  public static func buildOptional(_ component: [Section]?) -> [Section] {
    component ?? []
  }

  /// 첫 번째 분기를 선택합니다.
  public static func buildEither(first component: [Section]) -> [Section] {
    component
  }

  /// 두 번째 분기를 선택합니다.
  public static func buildEither(second component: [Section]) -> [Section] {
    component
  }

  /// 섹션 배열들을 결합합니다.
  public static func buildArray(_ components: [[Section]]) -> [Section] {
    components.flatMap { $0 }
  }
}

/// 행들을 구축하기 위한 결과 빌더입니다.
/// 행들의 DSL을 지원합니다.
@resultBuilder
public enum RowsBuilder {
  /// 여러 행 블록을 결합합니다.
  public static func buildBlock(_ components: [Row]...) -> [Row] {
    components.flatMap { $0 }
  }

  /// 단일 행을 표현식으로 변환합니다.
  public static func buildExpression(_ expression: Row) -> [Row] {
    [expression]
  }

  /// 행 배열을 표현식으로 변환합니다.
  public static func buildExpression(_ expression: [Row]) -> [Row] {
    expression
  }

  /// 옵션 행을 처리합니다.
  public static func buildOptional(_ component: [Row]?) -> [Row] {
    component ?? []
  }

  /// 첫 번째 분기를 선택합니다.
  public static func buildEither(first component: [Row]) -> [Row] {
    component
  }

  /// 두 번째 분기를 선택합니다.
  public static func buildEither(second component: [Row]) -> [Row] {
    component
  }

  /// 행 배열들을 결합합니다.
  public static func buildArray(_ components: [[Row]]) -> [Row] {
    components.flatMap { $0 }
  }
}

/// 섹션 header/footer를 구축하기 위한 결과 빌더입니다.
/// SwiftUI의 `Section { ... } header: { ... } footer: { ... }` 형태를 지원합니다.
@resultBuilder
public enum SectionSupplementaryBuilder {
  /// supplementary가 없는 블록을 처리합니다.
  public static func buildBlock() -> SectionSupplementary? {
    nil
  }

  /// 단일 supplementary를 반환합니다.
  public static func buildBlock(_ component: SectionSupplementary) -> SectionSupplementary? {
    component
  }

  /// optional supplementary를 반환합니다.
  public static func buildBlock(_ component: SectionSupplementary?) -> SectionSupplementary? {
    component
  }

  /// supplementary 표현식을 처리합니다.
  public static func buildExpression(_ expression: SectionSupplementary) -> SectionSupplementary? {
    expression
  }

  /// optional supplementary 표현식을 처리합니다.
  public static func buildExpression(_ expression: SectionSupplementary?) -> SectionSupplementary? {
    expression
  }

  /// optional supplementary를 처리합니다.
  public static func buildOptional(_ component: SectionSupplementary?) -> SectionSupplementary? {
    component
  }

  /// 첫 번째 분기를 선택합니다.
  public static func buildEither(first component: SectionSupplementary?) -> SectionSupplementary? {
    component
  }

  /// 두 번째 분기를 선택합니다.
  public static func buildEither(second component: SectionSupplementary?) -> SectionSupplementary? {
    component
  }
}
#endif
