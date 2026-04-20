#if canImport(UIKit)
import UIKit

/// 리스트를 나타내는 구조체입니다.
/// 섹션들의 컬렉션과 이벤트 핸들러를 포함합니다.
public struct List: Equatable {
  /// 리스트의 섹션들
  public var sections: [Section]
  var events: ListEvents

  /// 섹션 배열로 List를 초기화합니다.
  /// - Parameter sections: 섹션 배열
  public init(sections: [Section]) {
    self.sections = sections
    self.events = ListEvents()
  }

  /// 리스트 빌더 클로저로 List를 초기화합니다.
  /// - Parameter sections: 섹션 배열을 반환하는 클로저
  public init(@ListBuilder _ sections: () -> [Section]) {
    self.sections = sections()
    self.events = ListEvents()
  }

  /// 리스트 끝에 도달했을 때의 이벤트를 설정합니다.
  /// - Parameters:
  ///   - offset: 끝에서 트리거할 오프셋 (기본값: 상대적 크기의 2배)
  ///   - handler: 이벤트 핸들러
  /// - Returns: 이벤트가 설정된 새로운 List
  public func onReachEnd(
    offsetFromEnd offset: ReachEndOffset = .relativeToContainerSize(multiplier: 2.0),
    _ handler: @escaping (ReachEndContext) -> Void
  ) -> Self {
    var copy = self
    copy.events.onReachEnd = .init(offset: offset, handler: handler)
    return copy
  }

  /// 아래로 당겨 새로고침 동작을 설정합니다.
  /// - Parameters:
  ///   - style: 새로고침 표시 스타일
  ///   - handler: 새로고침 트리거 시 호출할 비동기 작업
  /// - Returns: 새로고침 이벤트가 설정된 새로운 List
  public func pullToRefresh(
    style: PullToRefreshStyle = .system(),
    _ handler: @escaping @Sendable () async -> Void
  ) -> Self {
    var copy = self
    copy.events.onPullToRefresh = .init(style: style, handler: handler)
    return copy
  }

  /// 아래로 당겨 새로고침 동작을 설정합니다.
  /// - Parameters:
  ///   - style: 새로고침 표시 스타일
  ///   - handler: 새로고침 트리거 시 호출할 completion 기반 작업
  /// - Returns: 새로고침 이벤트가 설정된 새로운 List
  public func pullToRefresh(
    style: PullToRefreshStyle = .system(),
    _ handler: @escaping @Sendable (@escaping @Sendable () -> Void) -> Void
  ) -> Self {
    var copy = self
    copy.events.onPullToRefresh = .init(style: style) {
      await withCheckedContinuation { continuation in
        let once = CompletionOnce {
          continuation.resume()
        }

        handler {
          once.call()
        }
      }
    }
    return copy
  }

  /// 두 List가 같은지 비교합니다.
  /// 섹션들이 같은지 비교합니다.
  public static func == (lhs: List, rhs: List) -> Bool {
    lhs.sections == rhs.sections
  }
}

/// 리스트 끝 도달 오프셋을 정의하는 열거형입니다.
public enum ReachEndOffset: Equatable {
  /// 절대 오프셋 값
  case absolute(CGFloat)
  /// 컨테이너 크기에 상대적인 배수
  case relativeToContainerSize(multiplier: CGFloat)
}

/// 리스트 끝 도달 이벤트의 컨텍스트입니다.
public struct ReachEndContext {
  /// 관련된 컬렉션 뷰 (약한 참조)
  public weak var collectionView: UICollectionView?

  /// ReachEndContext를 초기화합니다.
  /// - Parameter collectionView: 컬렉션 뷰
  public init(collectionView: UICollectionView?) {
    self.collectionView = collectionView
  }
}

struct ListEvents {
  var onReachEnd: ReachEndEvent?
  var onPullToRefresh: PullToRefreshEvent?
}

struct ReachEndEvent {
  let offset: ReachEndOffset
  let handler: (ReachEndContext) -> Void
}

private final class CompletionOnce {
  private let lock = NSLock()
  private var didResume = false
  private let action: () -> Void

  init(_ action: @escaping () -> Void) {
    self.action = action
  }

  func call() {
    lock.lock()
    defer { lock.unlock() }

    guard didResume == false else {
      return
    }

    didResume = true
    action()
  }
}
#endif
