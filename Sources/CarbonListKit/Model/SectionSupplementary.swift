#if canImport(UIKit)
import UIKit

/// 섹션의 header/footer에서 사용할 supplementary 컴포넌트입니다.
public struct SectionSupplementary: Identifiable, Equatable {
  /// supplementary의 고유 식별자
  public let id: AnyHashable
  /// 표시할 컴포넌트
  public let component: AnyListComponent
  /// compositional layout에 사용할 크기
  public var layoutSize: ListSupplementaryLayoutSize

  /// SectionSupplementary를 초기화합니다.
  /// - Parameters:
  ///   - id: supplementary의 고유 식별자
  ///   - component: 표시할 컴포넌트
  ///   - layoutSize: 레이아웃 크기 (기본값: 전체 너비, estimated 44 높이)
  public init(
    id: some Hashable,
    component: some ListComponent,
    layoutSize: ListSupplementaryLayoutSize = .estimated(height: 44)
  ) {
    self.id = id
    self.component = AnyListComponent(component)
    self.layoutSize = layoutSize
  }

  /// 두 SectionSupplementary가 같은지 비교합니다.
  public static func == (lhs: SectionSupplementary, rhs: SectionSupplementary) -> Bool {
    lhs.id == rhs.id
      && lhs.component == rhs.component
      && lhs.layoutSize == rhs.layoutSize
  }
}

/// header DSL 별칭입니다.
public typealias Header = SectionSupplementary

/// footer DSL 별칭입니다.
public typealias Footer = SectionSupplementary

/// supplementary layout size를 Equatable하게 표현합니다.
public struct ListSupplementaryLayoutSize: Equatable {
  public var widthDimension: ListSupplementaryLayoutDimension
  public var heightDimension: ListSupplementaryLayoutDimension

  public init(
    widthDimension: ListSupplementaryLayoutDimension = .fractionalWidth(1),
    heightDimension: ListSupplementaryLayoutDimension
  ) {
    self.widthDimension = widthDimension
    self.heightDimension = heightDimension
  }

  public static func estimated(height: CGFloat) -> Self {
    .init(heightDimension: .estimated(height))
  }

  public static func absolute(height: CGFloat) -> Self {
    .init(heightDimension: .absolute(height))
  }

  var collectionLayoutSize: NSCollectionLayoutSize {
    NSCollectionLayoutSize(
      widthDimension: widthDimension.collectionLayoutDimension,
      heightDimension: heightDimension.collectionLayoutDimension
    )
  }

  func addingHeight(_ height: CGFloat) -> Self {
    guard height > 0 else {
      return self
    }

    var copy = self
    copy.heightDimension = copy.heightDimension.adding(height)
    return copy
  }
}

/// NSCollectionLayoutDimension을 DSL에서 사용할 수 있게 감싼 타입입니다.
public enum ListSupplementaryLayoutDimension: Equatable {
  case absolute(CGFloat)
  case estimated(CGFloat)
  case fractionalWidth(CGFloat)
  case fractionalHeight(CGFloat)

  var collectionLayoutDimension: NSCollectionLayoutDimension {
    switch self {
    case .absolute(let value):
      return .absolute(value)
    case .estimated(let value):
      return .estimated(value)
    case .fractionalWidth(let value):
      return .fractionalWidth(value)
    case .fractionalHeight(let value):
      return .fractionalHeight(value)
    }
  }

  func adding(_ value: CGFloat) -> Self {
    guard value > 0 else {
      return self
    }

    switch self {
    case .absolute(let height):
      return .absolute(height + value)
    case .estimated(let height):
      return .estimated(height + value)
    case .fractionalWidth, .fractionalHeight:
      return self
    }
  }
}
#endif
