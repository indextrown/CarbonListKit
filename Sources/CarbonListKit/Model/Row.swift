#if canImport(UIKit)
import DifferenceKit
import UIKit

/// 리스트의 행을 나타내는 구조체입니다.
/// 컴포넌트와 이벤트 핸들러를 포함합니다.
public struct Row: Identifiable, Equatable {
  /// 행의 고유 식별자
  public let id: AnyHashable
  /// 행의 컴포넌트
  public let component: AnyListComponent
  var events: RowEvents

  /// Row를 초기화합니다.
  /// - Parameters:
  ///   - id: 행의 고유 식별자
  ///   - component: 행의 컴포넌트
  public init(id: some Hashable, component: some ListComponent) {
    self.id = id
    self.component = AnyListComponent(component)
    self.events = RowEvents()
  }

  /// 행 선택 이벤트를 설정합니다.
  /// - Parameter handler: 이벤트 핸들러
  /// - Returns: 이벤트가 설정된 새로운 Row
  public func onSelect(_ handler: @escaping (RowEventContext) -> Void) -> Self {
    var copy = self
    copy.events.onSelect = handler
    return copy
  }

  /// 행 표시 이벤트를 설정합니다.
  /// - Parameter handler: 이벤트 핸들러
  /// - Returns: 이벤트가 설정된 새로운 Row
  public func onDisplay(_ handler: @escaping (RowEventContext) -> Void) -> Self {
    var copy = self
    copy.events.onDisplay = handler
    return copy
  }

  /// 행 표시 종료 이벤트를 설정합니다.
  /// - Parameter handler: 이벤트 핸들러
  /// - Returns: 이벤트가 설정된 새로운 Row
  public func onEndDisplay(_ handler: @escaping (RowEventContext) -> Void) -> Self {
    var copy = self
    copy.events.onEndDisplay = handler
    return copy
  }

  /// 행 선택 이벤트를 설정합니다. (onSelect의 별칭)
  /// - Parameter handler: 이벤트 핸들러
  /// - Returns: 이벤트가 설정된 새로운 Row
  public func didSelect(_ handler: @escaping (RowEventContext) -> Void) -> Self {
    onSelect(handler)
  }

  /// 행 표시 이벤트를 설정합니다. (onDisplay의 별칭)
  /// - Parameter handler: 이벤트 핸들러
  /// - Returns: 이벤트가 설정된 새로운 Row
  public func willDisplay(_ handler: @escaping (RowEventContext) -> Void) -> Self {
    onDisplay(handler)
  }

  /// 두 Row가 같은지 비교합니다.
  /// id와 component를 비교합니다.
  public static func == (lhs: Row, rhs: Row) -> Bool {
    lhs.id == rhs.id && lhs.component == rhs.component
  }
}

/// Row의 타입 별칭입니다.
/// 코드 가독성을 위해 사용됩니다.
public typealias Cell = Row

extension Row: Differentiable {
  /// 차등 업데이트를 위한 식별자
  public var differenceIdentifier: AnyHashable {
    id
  }

  /// 콘텐츠가 같은지 비교합니다.
  public func isContentEqual(to source: Row) -> Bool {
    self == source
  }
}

struct RowEvents {
  var onSelect: ((RowEventContext) -> Void)?
  var onDisplay: ((RowEventContext) -> Void)?
  var onEndDisplay: ((RowEventContext) -> Void)?
}

/// 행 이벤트의 컨텍스트입니다.
/// 이벤트 발생 시 관련 정보를 제공합니다.
public struct RowEventContext {
  /// 행의 인덱스 경로
  public let indexPath: IndexPath
  /// 행의 ID
  public let rowID: AnyHashable
  /// 행의 컴포넌트
  public let component: AnyListComponent
  /// 관련된 컬렉션 뷰 (약한 참조)
  public weak var collectionView: UICollectionView?
  /// 관련된 셀 (약한 참조)
  public weak var cell: UICollectionViewCell?
  /// 컴포넌트의 콘텐츠 뷰 (약한 참조)
  public weak var contentView: UIView?

  /// RowEventContext를 초기화합니다.
  /// - Parameters:
  ///   - indexPath: 인덱스 경로
  ///   - rowID: 행 ID
  ///   - component: 컴포넌트
  ///   - collectionView: 컬렉션 뷰
  ///   - cell: 셀
  ///   - contentView: 콘텐츠 뷰
  public init(
    indexPath: IndexPath,
    rowID: AnyHashable,
    component: AnyListComponent,
    collectionView: UICollectionView?,
    cell: UICollectionViewCell?,
    contentView: UIView?
  ) {
    self.indexPath = indexPath
    self.rowID = rowID
    self.component = component
    self.collectionView = collectionView
    self.cell = cell
    self.contentView = contentView
  }
}
#endif
