#if canImport(UIKit) && canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI에서 CarbonListKit의 List DSL을 사용할 수 있게 해주는 view입니다.
///
/// 기존 `ListAdapter`를 감싸는 얇은 브릿지이며, row/section rendering과 diff update는
/// UIKit 어댑터가 그대로 담당합니다.
@available(iOS 13.0, *)
public struct CarbonListView: UIViewRepresentable {
  public var list: List
  public var updateStrategy: UpdateStrategy
  public var configuration: ListAdapterConfiguration
  public var prefetchingPlugins: [CollectionViewPrefetchingPlugin]
  public var backgroundColor: UIColor?
  public var showsVerticalScrollIndicator: Bool
  public var showsHorizontalScrollIndicator: Bool

  /// List 모델로 SwiftUI view를 초기화합니다.
  public init(
    _ list: List,
    updateStrategy: UpdateStrategy = .animated,
    configuration: ListAdapterConfiguration = .default,
    prefetchingPlugins: [CollectionViewPrefetchingPlugin] = [],
    backgroundColor: UIColor? = .clear,
    showsVerticalScrollIndicator: Bool = true,
    showsHorizontalScrollIndicator: Bool = false
  ) {
    self.list = list
    self.updateStrategy = updateStrategy
    self.configuration = configuration
    self.prefetchingPlugins = prefetchingPlugins
    self.backgroundColor = backgroundColor
    self.showsVerticalScrollIndicator = showsVerticalScrollIndicator
    self.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
  }

  /// List DSL로 SwiftUI view를 초기화합니다.
  public init(
    updateStrategy: UpdateStrategy = .animated,
    configuration: ListAdapterConfiguration = .default,
    prefetchingPlugins: [CollectionViewPrefetchingPlugin] = [],
    backgroundColor: UIColor? = .clear,
    showsVerticalScrollIndicator: Bool = true,
    showsHorizontalScrollIndicator: Bool = false,
    @ListBuilder _ content: () -> [Section]
  ) {
    self.init(
      List(sections: content()),
      updateStrategy: updateStrategy,
      configuration: configuration,
      prefetchingPlugins: prefetchingPlugins,
      backgroundColor: backgroundColor,
      showsVerticalScrollIndicator: showsVerticalScrollIndicator,
      showsHorizontalScrollIndicator: showsHorizontalScrollIndicator
    )
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  public func makeUIView(context: Context) -> UICollectionView {
    let collectionView = UICollectionView(
      frame: .zero,
      collectionViewLayout: UICollectionViewFlowLayout()
    )
    collectionView.backgroundColor = backgroundColor
    collectionView.alwaysBounceVertical = true
    collectionView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
    collectionView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator

    context.coordinator.adapter = ListAdapter(
      collectionView: collectionView,
      configuration: configuration,
      prefetchingPlugins: prefetchingPlugins
    )

    return collectionView
  }

  public func updateUIView(_ collectionView: UICollectionView, context: Context) {
    collectionView.backgroundColor = backgroundColor
    collectionView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
    collectionView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator

    let adapter = context.coordinator.adapter ?? ListAdapter(
      collectionView: collectionView,
      configuration: configuration,
      prefetchingPlugins: prefetchingPlugins
    )
    context.coordinator.adapter = adapter
    adapter.configuration = configuration

    adapter.apply(list, updateStrategy: updateStrategy)
  }

  public final class Coordinator {
    var adapter: ListAdapter?
  }
}

/// SwiftUI에서 더 짧게 사용할 수 있는 CarbonListView 별칭입니다.
@available(iOS 13.0, *)
public typealias CarbonList = CarbonListView
#endif
