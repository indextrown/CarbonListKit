#if canImport(UIKit)
import UIKit

/// 리스트 업데이트 전략을 정의하는 열거형입니다.
/// 애니메이션 적용 여부를 결정합니다.
public enum UpdateStrategy {
  /// 애니메이션과 함께 업데이트합니다.
  case animated
  /// 애니메이션 없이 업데이트합니다.
  case nonAnimated
  /// 데이터를 완전히 다시 로드합니다.
  case reloadData
}
#endif
