#if canImport(UIKit)
import UIKit

/// 리스트 새로고침 표시 스타일을 정의합니다.
public enum PullToRefreshStyle {
  /// 시스템 기본 스타일을 사용합니다.
  case system(PullToRefreshSystemStyle = .init())
  /// 문구/색상/크기까지 직접 지정합니다.
  case custom(PullToRefreshCustomStyle)
}

/// 시스템 pull-to-refresh 스타일 설정입니다.
public struct PullToRefreshSystemStyle {
  /// 새로고침 안내 문구입니다.
  public var title: String?
  /// 안내 문구 색상입니다.
  public var titleColor: UIColor
  /// 안내 문구 폰트입니다.
  public var titleFont: UIFont
  /// 시스템 인디케이터 색상입니다.
  public var tintColor: UIColor?

  /// 시스템 pull-to-refresh 스타일을 초기화합니다.
  /// - Parameters:
  ///   - title: 새로고침 안내 문구 (기본값: `nil`)
  ///   - titleColor: 안내 문구 색상 (기본값: `.secondaryLabel`)
  ///   - titleFont: 안내 문구 폰트 (기본값: `.systemFont(ofSize: 12, weight: .regular)`)
  public init(
    title: String? = nil,
    titleColor: UIColor = .secondaryLabel,
    titleFont: UIFont = .systemFont(ofSize: 12, weight: .regular),
    tintColor: UIColor? = nil
  ) {
    self.title = title
    self.titleColor = titleColor
    self.titleFont = titleFont
    self.tintColor = tintColor
  }
}

/// 커스텀 새로고침 스타일 설정입니다.
public struct PullToRefreshCustomStyle {
  /// 새로고침 안내 문구입니다.
  public var title: String
  /// 안내 문구 색상입니다.
  public var titleColor: UIColor
  /// 안내 문구 폰트입니다.
  public var titleFont: UIFont
  /// 인디케이터 스타일입니다.
  public var indicator: PullToRefreshIndicator

  /// 새로고침 스타일을 초기화합니다.
  /// - Parameters:
  ///   - title: 새로고침 안내 문구 (기본값: "새로고침")
  ///   - titleColor: 안내 문구 색상 (기본값: `.secondaryLabel`)
  ///   - titleFont: 안내 문구 폰트 (기본값: `.systemFont(ofSize: 14, weight: .medium)`)
  ///   - indicator: 인디케이터 스타일 (기본값: activity indicator)
  public init(
    title: String = "새로고침",
    titleColor: UIColor = .secondaryLabel,
    titleFont: UIFont = .systemFont(ofSize: 14, weight: .medium),
    indicator: PullToRefreshIndicator = .activity(
      style: .medium,
      tintColor: .systemBlue,
      size: .init(width: 18, height: 18)
    )
  ) {
    self.title = title
    self.titleColor = titleColor
    self.titleFont = titleFont
    self.indicator = indicator
  }
}

/// 커스텀 pull-to-refresh에서 사용할 인디케이터를 정의합니다.
public enum PullToRefreshIndicator {
  /// `UIActivityIndicatorView` 기반 인디케이터입니다.
  case activity(
    style: UIActivityIndicatorView.Style,
    tintColor: UIColor,
    size: CGSize
  )
  /// 이미지 기반 인디케이터입니다.
  case image(
    image: UIImage,
    tintColor: UIColor?,
    contentMode: UIView.ContentMode,
    size: CGSize,
    rotatesWhileRefreshing: Bool = false,
    rotationDuration: TimeInterval = 0.8
  )
  /// 완전히 커스텀한 view를 사용합니다.
  case custom(
    size: CGSize,
    makeView: () -> UIView
  )
}

struct PullToRefreshEvent {
  let style: PullToRefreshStyle
  let handler: @Sendable () async -> Void
}
#endif
