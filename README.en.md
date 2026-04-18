# CarbonListKit

[한국어](README.md) | English

CarbonListKit is a UIKit list adapter for building `UICollectionView` screens from declarative lists, sections, rows, and components.

It removes repeated collection view boilerplate from view controllers:

- cell registration
- data source and delegate plumbing
- component rendering
- Auto Layout based sizing
- row selection and display events
- DifferenceKit based diff updates
- compositional layout setup
- list reach-end events

CarbonListKit is still early. The current implementation focuses on the core list adapter and example app. Supplementary views, refresh, prefetching, and size caching are planned next.

## Requirements

- iOS 13+
- Swift 5.9+
- UIKit
- Swift Package Manager

## Installation

Add CarbonListKit as a local or remote Swift Package dependency.

For local development, the example app uses a local package reference:

```text
Example/CarbonListKitExample.xcodeproj
  -> local package ../
  -> product CarbonListKit
```

## Quick Start

```swift
import CarbonListKit
import UIKit

final class FeedViewController: UIViewController {
  private let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewLayout()
  )

  private lazy var adapter = ListAdapter(collectionView: collectionView)

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(collectionView)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])

    render()
  }

  private func render() {
    adapter.apply(updateStrategy: .animated) {
      Section(id: "posts") {
        Row(
          id: "post-1",
          component: PostComponent(
            viewModel: .init(
              title: "Hello CarbonListKit",
              subtitle: "A UIKit row rendered from a component."
            )
          )
        )
        .onSelect { context in
          print("selected", context.indexPath)
        }
      }
      .layout(.vertical(spacing: 12))
      .contentInsets(.init(top: 16, leading: 0, bottom: 16, trailing: 0))
    }
  }
}
```

## Core Concepts

### ListAdapter

`ListAdapter` owns the collection view data source and delegate.

```swift
private lazy var adapter = ListAdapter(
  collectionView: collectionView,
  configuration: .init(batchUpdateInterruptCount: 200)
)
```

Do not set `collectionView.dataSource` or `collectionView.delegate` directly after creating the adapter.

Use `snapshot()` when you need the currently applied list state.

```swift
let currentList = adapter.snapshot()
```

`batchUpdateInterruptCount` is a safety switch that falls back to `reloadData` when one animated diff contains too many changes.

### List

`List` is the full snapshot of the collection view.

```swift
let list = List {
  Section(id: "main") {
    Row(id: "row", component: MyComponent(viewModel: model))
  }
}

adapter.apply(list)
```

You can also use the builder overload:

```swift
adapter.apply {
  Section(id: "main") {
    Row(id: "row", component: MyComponent(viewModel: model))
  }
}
```

### Section

`Section` groups rows and owns section-level layout.

```swift
Section(id: "articles") {
  for article in articles {
    Row(
      id: article.id,
      component: ArticleRowComponent(
        viewModel: .init(article: article)
      )
    )
  }
}
.layout(.vertical(spacing: 10))
.contentInsets(.init(top: 16, leading: 0, bottom: 16, trailing: 0))
```

Compatibility-style modifiers are also available:

```swift
Section(id: "articles") {
  // rows
}
.withSectionLayout(.vertical(spacing: 10))
.withSectionContentInsets(.init(top: 16, leading: 0, bottom: 16, trailing: 0))
```

### Row

`Row` represents one collection view item.

```swift
Row(id: article.id, component: ArticleRowComponent(viewModel: .init(article: article)))
  .onSelect { context in
    print(context.rowID)
  }
  .onDisplay { context in
    print("displayed", context.indexPath)
  }
  .onEndDisplay { context in
    print("ended", context.indexPath)
  }
```

`Cell` is currently a typealias for `Row` for users who prefer cell-oriented naming:

```swift
Cell(id: "summary", component: SummaryComponent(viewModel: summary))
  .didSelect { context in
    print(context.indexPath)
  }
  .willDisplay { context in
    print(context.indexPath)
  }
```

## Components

Components turn app data into UIKit views. They are similar in spirit to `UIViewRepresentable`.

```swift
struct PostComponent: ListComponent {
  struct ViewModel: Equatable {
    let title: String
    let subtitle: String
  }

  let viewModel: ViewModel

  func makeView(context: ListComponentContext<Void>) -> PostView {
    PostView()
  }

  func updateView(_ view: PostView, context: ListComponentContext<Void>) {
    view.configure(
      title: viewModel.title,
      subtitle: viewModel.subtitle
    )
  }
}
```

When `ViewModel` is `Equatable`, CarbonListKit can detect content changes for rows that keep the same identity.

The default component layout pins the view to the cell content view edges with Auto Layout.

You can override it:

```swift
func layoutView(_ view: PostView, in container: UIView) {
  view.translatesAutoresizingMaskIntoConstraints = false
  container.addSubview(view)
  NSLayoutConstraint.activate([
    view.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
    view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
    view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
    view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
  ])
}
```

Use a coordinator when a component needs an owned state object. The default coordinator is `Void`.

```swift
struct TimerComponent: ListComponent {
  struct ViewModel: Equatable {
    let title: String
  }

  final class Coordinator {
    var tickCount = 0
  }

  let viewModel: ViewModel

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeView(context: ListComponentContext<Coordinator>) -> TimerView {
    TimerView()
  }

  func updateView(_ view: TimerView, context: ListComponentContext<Coordinator>) {
    context.coordinator.tickCount += 1
    view.configure(title: viewModel.title, tickCount: context.coordinator.tickCount)
  }
}
```

Cell reuse identifiers default to the component type name. Override `reuseIdentifier` when one component type needs multiple cell registrations.

```swift
var reuseIdentifier: String {
  "ArticleRowComponent.compact"
}
```

## Entity vs Component ViewModel

App entities should stay separate from component view models.

```swift
struct Article: Identifiable, Equatable {
  let id: String
  let title: String
  let author: String
  let readTimeMinutes: Int
  let isRead: Bool
}
```

`Article` is app/domain data. The component `ViewModel` is the render-ready shape for one UIKit view.

```swift
struct ArticleRowComponent: ListComponent {
  struct ViewModel: Equatable {
    let title: String
    let metadata: String
    let readStateTitle: String
    let readStateColor: UIColor

    init(article: Article) {
      self.title = article.title
      self.metadata = "\(article.author) · \(article.readTimeMinutes) min read"
      self.readStateTitle = article.isRead ? "Read" : "Unread"
      self.readStateColor = article.isRead ? .systemGray : .systemGreen
    }
  }

  let viewModel: ViewModel

  func makeView(context: ListComponentContext<Void>) -> ArticleRowView {
    ArticleRowView()
  }

  func updateView(_ view: ArticleRowView, context: ListComponentContext<Void>) {
    view.configure(
      title: viewModel.title,
      metadata: viewModel.metadata,
      readStateTitle: viewModel.readStateTitle,
      readStateColor: viewModel.readStateColor
    )
  }
}
```

## Layout

CarbonListKit currently supports vertical, grid, and custom compositional layouts.

### Vertical

```swift
Section(id: "feed") {
  // rows
}
.layout(.vertical(spacing: 12))
```

### Grid

```swift
Section(id: "metrics") {
  Row(id: "one", component: MetricComponent(viewModel: one))
  Row(id: "two", component: MetricComponent(viewModel: two))
}
.layout(.grid(columns: 2, itemSpacing: 10, lineSpacing: 10))
.contentInsets(.init(top: 0, leading: 16, bottom: 16, trailing: 16))
```

### Custom

```swift
Section(id: "custom") {
  Row(id: "custom-row", component: CustomComponent(viewModel: model))
}
.layout(.custom { context in
  print(context.section.id, context.sectionIndex, context.environment.container.effectiveContentSize)

  let itemSize = NSCollectionLayoutSize(
    widthDimension: .fractionalWidth(1),
    heightDimension: .estimated(44)
  )
  let item = NSCollectionLayoutItem(layoutSize: itemSize)
  let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
  let section = NSCollectionLayoutSection(group: group)
  section.interGroupSpacing = 12
  return section
})
```

## Updating

CarbonListKit uses DifferenceKit to apply section and row changes.

```swift
adapter.apply(list, updateStrategy: .animated)
```

The builder overload also supports completion.

```swift
adapter.apply(updateStrategy: .nonAnimated) {
  Section(id: "articles") {
    for article in articles {
      Row(id: article.id, component: ArticleRowComponent(viewModel: .init(article: article)))
    }
  }
} completion: {
  print("applied")
}
```

Supported strategies:

```swift
public enum UpdateStrategy {
  case animated
  case nonAnimated
  case reloadData
}
```

### Identity and Equality

Diff identity:

- section identity: `Section.id`
- row identity: `Row.id`

Content equality:

- row content equality uses `AnyListComponent`
- component equality uses component type plus component view model

This means a row can keep the same identity while its component content changes.

```swift
articles = articles.map { article in
  article.id == selectedID ? article.togglingRead() : article
}

adapter.apply(updateStrategy: .animated) {
  Section(id: "articles") {
    for article in articles {
      Row(
        id: article.id,
        component: ArticleRowComponent(viewModel: .init(article: article))
      )
    }
  }
}
```

### Update Queue

If `apply` is called while another update is running, CarbonListKit keeps the latest requested update and applies it after the current update finishes.

The current policy is last-write-wins.

## Events

Row event modifiers:

```swift
Row(id: "row", component: Component(viewModel: model))
  .onSelect { context in
    print(context.indexPath)
  }
  .onDisplay { context in
    print(context.contentView as Any)
  }
  .onEndDisplay { context in
    print(context.rowID)
  }
```

Compatibility names:

```swift
Cell(id: "row", component: Component(viewModel: model))
  .didSelect { context in
    print(context.indexPath)
  }
  .willDisplay { context in
    print(context.indexPath)
  }
```

`RowEventContext` contains:

- `indexPath`
- `rowID`
- `component`
- `collectionView`
- `cell`
- `contentView`

List-level reach-end events are also available. Use them for infinite scrolling or next-page loading.

`onReachEnd` is a `List` modifier. Pass `List { ... }.onReachEnd(...)` to `adapter.apply(_:)` instead of placing it inside the builder overload.

```swift
adapter.apply(
  List {
    Section(id: "feed") {
      for item in items {
        Row(id: item.id, component: FeedItemComponent(viewModel: .init(item: item)))
      }
    }
    .layout(.vertical(spacing: 10))
  }
  .onReachEnd(offsetFromEnd: .relativeToContainerSize(multiplier: 1.0)) { context in
    loadNextPage()
  }
)
```

Supported offsets:

- `.relativeToContainerSize(multiplier:)`: computes the threshold from the collection view length
- `.absolute(_:)`: uses a fixed point distance

`onReachEnd` fires while scrolling when the remaining distance is less than or equal to the offset. For horizontal layouts it uses width/contentSize.width, and otherwise it uses height/contentSize.height.

For page loading, keep a loading flag near your data source. `onReachEnd` can be called more than once while the user stays near the end.

```swift
private var isLoadingNextPage = false

private func loadNextPageIfNeeded() {
  guard isLoadingNextPage == false else {
    return
  }

  isLoadingNextPage = true
  api.fetchNextPage { [weak self] newItems in
    guard let self else {
      return
    }

    self.items.append(contentsOf: newItems)
    self.isLoadingNextPage = false
    self.render()
  }
}
```

Use `ReachEndContext` when the handler needs access to the collection view.

```swift
.onReachEnd(offsetFromEnd: .absolute(240)) { context in
  print(context.collectionView?.contentOffset as Any)
}
```

## Example App

The repository includes a SwiftUI based example app:

```text
Example/
  CarbonListKitExample.xcodeproj
  CarbonListKitExample/
```

The SwiftUI app hosts UIKit view controllers through `UIViewControllerRepresentable`.

Examples:

- `Diff updates`: add, shuffle, and update rows
- `Entity to ViewModel`: maps domain entities into component view models and shows available modifiers/layouts
- `Infinite Scroll`: appends the next page when the list reaches the end

Build:

```bash
xcodebuild -project Example/CarbonListKitExample.xcodeproj \
  -scheme CarbonListKitExample \
  -sdk iphonesimulator \
  -derivedDataPath /tmp/CarbonListKitExampleDerivedData \
  build
```

## Current Feature Set

Implemented:

- Swift Package library target
- `ListAdapter`
- `ListAdapterConfiguration`
- `List`
- `Section`
- `Row`
- `Cell` typealias
- compatibility-style modifiers
- `ListComponent`
- `AnyListComponent`
- `ListComponentContext`
- result builders
  - `@ListBuilder`
  - `@RowsBuilder`
- automatic cell registration
- UIKit data source ownership
- UIKit delegate ownership
- Auto Layout based component rendering
- self-sizing collection view cells
- component coordinators
- component reuseIdentifier override
- vertical layout
- grid layout
- custom layout
- custom layout context
- section content insets
- row selection event
- row display events
- list reach-end events
- DifferenceKit based diff updates
- update strategies
- apply completion
- snapshot access
- last-write-wins queued updates
- SwiftUI example app with UIKit controllers

Planned:

- supplementary views
  - header
  - footer
- horizontal orthogonal sections
- refresh control
- prefetch events
- size cache
- more tests
- DocC

## Verification

Known working commands:

```bash
swift build
swift test
swift build --sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.4.sdk --triple arm64-apple-ios13.0-simulator
xcodebuild -project Example/CarbonListKitExample.xcodeproj -scheme CarbonListKitExample -sdk iphonesimulator -derivedDataPath /tmp/CarbonListKitExampleDerivedData build
```

## Inspiration

CarbonListKit takes inspiration from component-based list frameworks such as KarrotListKit, IGListKit, Airbnb Epoxy, and DifferenceKit.
