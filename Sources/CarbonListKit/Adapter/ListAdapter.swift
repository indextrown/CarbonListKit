#if canImport(UIKit)
import DifferenceKit
import UIKit
#if canImport(Combine)
import Combine
#endif

/// CarbonListKit의 핵심 어댑터 클래스입니다.
/// UICollectionView와 List 모델을 연결하여 데이터를 표시하고 업데이트합니다.
/// 차등 업데이트를 지원하여 효율적인 UI 갱신을 제공합니다.
public final class ListAdapter: NSObject {
  private static let sectionSpacingElementKind = "CarbonListKit.SectionSpacing"
  private static let sectionSpacingReuseIdentifier = "CarbonListKit.SectionSpacing"

  public private(set) var list = List(sections: [])
  public var configuration: ListAdapterConfiguration

  private weak var collectionView: UICollectionView?
  private var registeredCellReuseIdentifiers = Set<String>()
  private var registeredSupplementaryReuseIdentifiers = Set<String>()
  private var isUpdating = false
  private var queuedUpdate: (
    list: List,
    updateStrategy: UpdateStrategy,
    completion: (() -> Void)?
  )?

  private(set) var prefetchingIndexPathOperations = [IndexPath: [AnyCancellable]]()
  private let prefetchingPlugins: [CollectionViewPrefetchingPlugin]

  /// ListAdapter를 초기화합니다.
  /// - Parameters:
  ///   - collectionView: 데이터를 표시할 UICollectionView
  ///   - configuration: 어댑터 설정 (기본값: .default)
  ///   - prefetchingPlugins: prefetch 플러그인들 (기본값: 빈 배열)
  public init(
    collectionView: UICollectionView,
    configuration: ListAdapterConfiguration = .default,
    prefetchingPlugins: [CollectionViewPrefetchingPlugin] = []
  ) {
    self.configuration = configuration
    self.prefetchingPlugins = prefetchingPlugins
    self.collectionView = collectionView
    super.init()

    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.collectionViewLayout = makeCompositionalLayout()
    collectionView.register(
      UICollectionReusableView.self,
      forSupplementaryViewOfKind: Self.sectionSpacingElementKind,
      withReuseIdentifier: Self.sectionSpacingReuseIdentifier
    )

    #if canImport(Combine)
    if prefetchingPlugins.isEmpty == false {
      collectionView.prefetchDataSource = self
    }
    #endif
  }

  /// 리스트를 적용하여 컬렉션 뷰를 업데이트합니다.
  /// - Parameters:
  ///   - list: 적용할 List 모델
  ///   - updateStrategy: 업데이트 전략 (기본값: .animated)
  ///   - completion: 업데이트 완료 후 호출될 클로저 (옵션)
  public func apply(
    _ list: List,
    updateStrategy: UpdateStrategy = .animated,
    completion: (() -> Void)? = nil
  ) {
    guard let collectionView else {
      return
    }

    guard isUpdating == false else {
      queuedUpdate = (list, updateStrategy, completion)
      return
    }

    isUpdating = true
    registerComponents(in: list)

    let finishUpdate: () -> Void = { [weak self] in
      guard let self else {
        return
      }

      completion?()

      if let queuedUpdate {
        self.queuedUpdate = nil
        self.isUpdating = false
        self.apply(
          queuedUpdate.list,
          updateStrategy: queuedUpdate.updateStrategy,
          completion: queuedUpdate.completion
        )
      } else {
        self.isUpdating = false
      }
    }

    guard self.list.sections.isEmpty == false else {
      self.list = list
      collectionView.reloadData()
      collectionView.layoutIfNeeded()
      finishUpdate()
      return
    }

    switch updateStrategy {
    case .animated:
      performDifferentialUpdates(newList: list) {
        finishUpdate()
      }
    case .nonAnimated:
      let wasAnimationsEnabled = UIView.areAnimationsEnabled
      UIView.setAnimationsEnabled(false)
      performDifferentialUpdates(newList: list) {
        UIView.setAnimationsEnabled(wasAnimationsEnabled)
        finishUpdate()
      }
    case .reloadData:
      self.list = list
      collectionView.reloadData()
      collectionView.layoutIfNeeded()
      finishUpdate()
    }
  }

  /// 리스트 빌더를 사용하여 리스트를 적용합니다.
  /// - Parameters:
  ///   - updateStrategy: 업데이트 전략 (기본값: .animated)
  ///   - content: 섹션 배열을 반환하는 클로저
  ///   - completion: 업데이트 완료 후 호출될 클로저 (옵션)
  public func apply(
    updateStrategy: UpdateStrategy = .animated,
    @ListBuilder _ content: () -> [Section],
    completion: (() -> Void)? = nil
  ) {
    apply(
      List(sections: content()),
      updateStrategy: updateStrategy,
      completion: completion
    )
  }

  /// 현재 리스트의 스냅샷을 반환합니다.
  /// - Returns: 현재 적용된 List 모델
  public func snapshot() -> List {
    list
  }

  private func row(at indexPath: IndexPath) -> Row? {
    guard list.sections.indices.contains(indexPath.section) else {
      return nil
    }

    let rows = list.sections[indexPath.section].rows
    guard rows.indices.contains(indexPath.item) else {
      return nil
    }

    return rows[indexPath.item]
  }

  private func supplementary(
    ofKind kind: String,
    at indexPath: IndexPath
  ) -> SectionSupplementary? {
    guard list.sections.indices.contains(indexPath.section) else {
      return nil
    }

    switch kind {
    case UICollectionView.elementKindSectionHeader:
      return list.sections[indexPath.section].header
    case UICollectionView.elementKindSectionFooter:
      return list.sections[indexPath.section].footer
    default:
      return nil
    }
  }

  private func registerComponents(in list: List) {
    for row in list.sections.flatMap(\.rows) {
      let reuseIdentifier = row.component.reuseIdentifier
      guard registeredCellReuseIdentifiers.contains(reuseIdentifier) == false else {
        continue
      }

      registeredCellReuseIdentifiers.insert(reuseIdentifier)
      collectionView?.register(ComponentCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }

    for section in list.sections {
      registerSupplementary(section.header, kind: UICollectionView.elementKindSectionHeader)
      registerSupplementary(section.footer, kind: UICollectionView.elementKindSectionFooter)
    }
  }

  private func registerSupplementary(
    _ supplementary: SectionSupplementary?,
    kind: String
  ) {
    guard let supplementary else {
      return
    }

    let reuseIdentifier = supplementary.component.reuseIdentifier
    let registrationKey = "\(kind):\(reuseIdentifier)"
    guard registeredSupplementaryReuseIdentifiers.contains(registrationKey) == false else {
      return
    }

    registeredSupplementaryReuseIdentifiers.insert(registrationKey)
    collectionView?.register(
      ComponentSupplementaryView.self,
      forSupplementaryViewOfKind: kind,
      withReuseIdentifier: reuseIdentifier
    )
  }

  private func performDifferentialUpdates(
    newList: List,
    completion: @escaping () -> Void
  ) {
    guard let collectionView else {
      return
    }

    let changeset = StagedChangeset(
      source: list.sections,
      target: newList.sections
    )

    let stagedChanges = Array(changeset)

    guard stagedChanges.isEmpty == false else {
      self.list = newList
      completion()
      return
    }

    if collectionView.window == nil {
      self.list = newList
      collectionView.reloadData()
      collectionView.layoutIfNeeded()
      completion()
      return
    }

    if stagedChanges.contains(where: { $0.changeCount > configuration.batchUpdateInterruptCount }) {
      self.list = newList
      collectionView.reloadData()
      collectionView.layoutIfNeeded()
      completion()
      return
    }

    apply(stagedChanges: stagedChanges, at: 0) { [weak self] in
      self?.list.events = newList.events
      completion()
    }
  }

  private func apply(
    stagedChanges: [Changeset<[Section]>],
    at index: Int,
    completion: @escaping () -> Void
  ) {
    guard let collectionView else {
      completion()
      return
    }

    guard stagedChanges.indices.contains(index) else {
      completion()
      return
    }

    let changeset = stagedChanges[index]
    collectionView.performBatchUpdates {
      list.sections = changeset.data

      if changeset.sectionDeleted.isEmpty == false {
        collectionView.deleteSections(IndexSet(changeset.sectionDeleted))
      }

      if changeset.sectionInserted.isEmpty == false {
        collectionView.insertSections(IndexSet(changeset.sectionInserted))
      }

      if changeset.sectionUpdated.isEmpty == false {
        collectionView.reloadSections(IndexSet(changeset.sectionUpdated))
      }

      for (source, target) in changeset.sectionMoved {
        collectionView.moveSection(source, toSection: target)
      }

      if changeset.elementDeleted.isEmpty == false {
        collectionView.deleteItems(
          at: changeset.elementDeleted.map {
            IndexPath(item: $0.element, section: $0.section)
          }
        )
      }

      if changeset.elementInserted.isEmpty == false {
        collectionView.insertItems(
          at: changeset.elementInserted.map {
            IndexPath(item: $0.element, section: $0.section)
          }
        )
      }

      reconfigureVisibleItems(at: changeset.elementUpdated)

      for (source, target) in changeset.elementMoved {
        collectionView.moveItem(
          at: IndexPath(item: source.element, section: source.section),
          to: IndexPath(item: target.element, section: target.section)
        )
      }
    } completion: { [weak self] _ in
      self?.apply(
        stagedChanges: stagedChanges,
        at: index + 1,
        completion: completion
      )
    }
  }

  private func reconfigureVisibleItems(at elementPaths: [ElementPath]) {
    guard let collectionView else {
      return
    }

    for elementPath in elementPaths {
      let indexPath = IndexPath(item: elementPath.element, section: elementPath.section)
      guard let row = row(at: indexPath),
            let cell = collectionView.cellForItem(at: indexPath) as? ComponentCell else {
        continue
      }

      cell.render(component: row.component)
      cell.setNeedsLayout()
    }
  }

  private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
    UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
      guard let self,
            self.list.sections.indices.contains(sectionIndex) else {
        return Self.makeVerticalSection(spacing: 0)
      }

      let section = self.list.sections[sectionIndex]
      let layoutSection: NSCollectionLayoutSection
      let layoutSectionContentInsets: NSDirectionalEdgeInsets
      switch section.layout {
      case .vertical(let spacing):
        layoutSection = Self.makeVerticalSection(
          spacing: spacing,
          horizontalInsets: section.horizontalContentInsets
        )
        layoutSectionContentInsets = section.sectionInsets.adding(section.verticalContentInsets)
      case .grid(let columns, let itemSpacing, let lineSpacing):
        layoutSection = Self.makeGridSection(
          columns: columns,
          itemSpacing: itemSpacing,
          lineSpacing: lineSpacing,
          horizontalInsets: section.horizontalContentInsets
        )
        layoutSectionContentInsets = section.sectionInsets.adding(section.verticalContentInsets)
      case .custom(let provider):
        layoutSection = provider(
          .init(
            section: section,
            sectionIndex: sectionIndex,
            environment: environment
          )
        )
        layoutSectionContentInsets = section.sectionInsets.adding(section.contentInsets)
      }

      layoutSection.contentInsets = layoutSectionContentInsets
      layoutSection.boundarySupplementaryItems += Self.makeBoundarySupplementaryItems(
        for: section,
        isLastSection: sectionIndex == self.list.sections.index(before: self.list.sections.endIndex)
      )
      return layoutSection
    }
  }

  private static func makeBoundarySupplementaryItems(
    for section: Section,
    isLastSection: Bool
  ) -> [NSCollectionLayoutBoundarySupplementaryItem] {
    var items = [NSCollectionLayoutBoundarySupplementaryItem]()
    let sectionSpacing = isLastSection ? 0 : section.sectionSpacing

    if let header = section.header {
      items.append(
        NSCollectionLayoutBoundarySupplementaryItem(
          layoutSize: header.layoutSize.collectionLayoutSize,
          elementKind: UICollectionView.elementKindSectionHeader,
          alignment: .top
        )
      )
    }

    if let footer = section.footer {
      items.append(
        NSCollectionLayoutBoundarySupplementaryItem(
          layoutSize: footer.layoutSize.addingHeight(sectionSpacing).collectionLayoutSize,
          elementKind: UICollectionView.elementKindSectionFooter,
          alignment: .bottom
        )
      )
    } else if sectionSpacing > 0 {
      items.append(
        NSCollectionLayoutBoundarySupplementaryItem(
          layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(sectionSpacing)
          ),
          elementKind: Self.sectionSpacingElementKind,
          alignment: .bottom
        )
      )
    }

    return items
  }

  private static func makeVerticalSection(
    spacing: CGFloat,
    horizontalInsets: NSDirectionalEdgeInsets = .zero
  ) -> NSCollectionLayoutSection {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .estimated(44)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let group = NSCollectionLayoutGroup.vertical(
      layoutSize: itemSize,
      subitems: [item]
    )
    group.contentInsets = horizontalInsets

    let section = NSCollectionLayoutSection(group: group)
    section.interGroupSpacing = spacing
    return section
  }

  private static func makeGridSection(
    columns: Int,
    itemSpacing: CGFloat,
    lineSpacing: CGFloat,
    horizontalInsets: NSDirectionalEdgeInsets = .zero
  ) -> NSCollectionLayoutSection {
    let columns = max(columns, 1)
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .estimated(44)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .estimated(44)
    )
    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: groupSize,
      subitem: item,
      count: columns
    )
    group.contentInsets = horizontalInsets
    group.interItemSpacing = .fixed(itemSpacing)

    let section = NSCollectionLayoutSection(group: group)
    section.interGroupSpacing = lineSpacing
    return section
  }
}

private extension Section {
  var horizontalContentInsets: NSDirectionalEdgeInsets {
    .init(
      top: 0,
      leading: contentInsets.leading,
      bottom: 0,
      trailing: contentInsets.trailing
    )
  }

  var verticalContentInsets: NSDirectionalEdgeInsets {
    .init(
      top: contentInsets.top,
      leading: 0,
      bottom: contentInsets.bottom,
      trailing: 0
    )
  }
}

private extension NSDirectionalEdgeInsets {
  func adding(_ other: NSDirectionalEdgeInsets) -> NSDirectionalEdgeInsets {
    .init(
      top: top + other.top,
      leading: leading + other.leading,
      bottom: bottom + other.bottom,
      trailing: trailing + other.trailing
    )
  }
}

extension ListAdapter: UICollectionViewDataSource {
  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    list.sections.count
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    guard list.sections.indices.contains(section) else {
      return 0
    }

    return list.sections[section].rows.count
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    guard let row = row(at: indexPath) else {
      return UICollectionViewCell()
    }

    guard let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: row.component.reuseIdentifier,
      for: indexPath
    ) as? ComponentCell else {
      return UICollectionViewCell()
    }

    cell.render(component: row.component)
    return cell
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    viewForSupplementaryElementOfKind kind: String,
    at indexPath: IndexPath
  ) -> UICollectionReusableView {
    if kind == Self.sectionSpacingElementKind {
      return collectionView.dequeueReusableSupplementaryView(
        ofKind: kind,
        withReuseIdentifier: Self.sectionSpacingReuseIdentifier,
        for: indexPath
      )
    }

    guard let supplementary = supplementary(ofKind: kind, at: indexPath) else {
      return UICollectionReusableView()
    }

    guard let view = collectionView.dequeueReusableSupplementaryView(
      ofKind: kind,
      withReuseIdentifier: supplementary.component.reuseIdentifier,
      for: indexPath
    ) as? ComponentSupplementaryView else {
      return UICollectionReusableView()
    }

    if kind == UICollectionView.elementKindSectionFooter,
       list.sections.indices.contains(indexPath.section),
       indexPath.section != list.sections.index(before: list.sections.endIndex) {
      view.bottomSpacing = list.sections[indexPath.section].sectionSpacing
    } else {
      view.bottomSpacing = 0
    }
    view.render(component: supplementary.component)
    return view
  }
}

extension ListAdapter: UICollectionViewDelegate {
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let row = row(at: indexPath) else {
      return
    }

    let cell = collectionView.cellForItem(at: indexPath) as? ComponentCell
    row.events.onSelect?(
      .init(
        indexPath: indexPath,
        rowID: row.id,
        component: row.component,
        collectionView: collectionView,
        cell: cell,
        contentView: cell?.renderedContentView()
      )
    )
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    willDisplay cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    guard let row = row(at: indexPath) else {
      return
    }

    let componentCell = cell as? ComponentCell
    row.events.onDisplay?(
      .init(
        indexPath: indexPath,
        rowID: row.id,
        component: row.component,
        collectionView: collectionView,
        cell: cell,
        contentView: componentCell?.renderedContentView()
      )
    )
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    didEndDisplaying cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    guard let row = row(at: indexPath) else {
      return
    }

    let componentCell = cell as? ComponentCell
    row.events.onEndDisplay?(
      .init(
        indexPath: indexPath,
        rowID: row.id,
        component: row.component,
        collectionView: collectionView,
        cell: cell,
        contentView: componentCell?.renderedContentView()
      )
    )
  }

  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    triggerReachEndIfNeeded(contentOffset: scrollView.contentOffset)
  }

  public func scrollViewWillEndDragging(
    _ scrollView: UIScrollView,
    withVelocity velocity: CGPoint,
    targetContentOffset: UnsafeMutablePointer<CGPoint>
  ) {
    triggerReachEndIfNeeded(contentOffset: targetContentOffset.pointee)
  }

  private func triggerReachEndIfNeeded(contentOffset: CGPoint) {
    guard let collectionView,
          let event = list.events.onReachEnd,
          collectionView.bounds.isEmpty == false else {
      return
    }

    let viewLength: CGFloat
    let contentLength: CGFloat
    let offset: CGFloat

    switch scrollDirection {
    case .horizontal:
      viewLength = collectionView.bounds.width
      contentLength = collectionView.contentSize.width
      offset = contentOffset.x
    default:
      viewLength = collectionView.bounds.height
      contentLength = collectionView.contentSize.height
      offset = contentOffset.y
    }

    if contentLength < viewLength {
      event.handler(.init(collectionView: collectionView))
      return
    }

    let triggerDistance: CGFloat
    switch event.offset {
    case .absolute(let value):
      triggerDistance = value
    case .relativeToContainerSize(let multiplier):
      triggerDistance = viewLength * multiplier
    }

    let remainingDistance = contentLength - viewLength - offset
    if remainingDistance <= triggerDistance {
      event.handler(.init(collectionView: collectionView))
    }
  }

  private var scrollDirection: UICollectionView.ScrollDirection {
    let layout = collectionView?.collectionViewLayout as? UICollectionViewCompositionalLayout
    return layout?.configuration.scrollDirection ?? .vertical
  }
}

#if canImport(Combine)
// MARK: - UICollectionViewDataSourcePrefetching

extension ListAdapter: UICollectionViewDataSourcePrefetching {
  public func collectionView(
    _ collectionView: UICollectionView,
    prefetchItemsAt indexPaths: [IndexPath]
  ) {
    for indexPath in indexPaths {
      guard prefetchingIndexPathOperations[indexPath] == nil else {
        continue
      }

      guard let row = row(at: indexPath),
            let prefetchableComponent = row.component as? ComponentResourcePrefetchable else {
        continue
      }

      prefetchingIndexPathOperations[indexPath] = prefetchingPlugins.compactMap {
        $0.prefetch(with: prefetchableComponent)
      }
    }
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    cancelPrefetchingForItemsAt indexPaths: [IndexPath]
  ) {
    for indexPath in indexPaths {
      prefetchingIndexPathOperations.removeValue(forKey: indexPath)?.forEach {
        $0.cancel()
      }
    }
  }
}
#endif
#endif
