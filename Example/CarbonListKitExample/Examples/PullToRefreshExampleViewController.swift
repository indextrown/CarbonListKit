import CarbonListKit
import UIKit

struct PullToRefreshDemoConfiguration {
  let title: String
  let introTitle: String
  let introSubtitle: String
  let badgeTitle: String
  let badgeTintColor: UIColor
  let pullToRefreshStyle: PullToRefreshStyle
}

class PullToRefreshDemoViewController: UIViewController {
  private enum Const {
    static let refreshDelay: UInt64 = 700_000_000
    static let maxItems = 12
  }

  private let configuration: PullToRefreshDemoConfiguration
  private let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewLayout()
  )

  private lazy var adapter = ListAdapter(collectionView: collectionView)
  private var items: [RefreshItem] = RefreshItem.samples
  private var refreshCount = 0
  private var isRefreshing = false

  init(configuration: PullToRefreshDemoConfiguration) {
    self.configuration = configuration
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = configuration.title
    view.backgroundColor = .systemBackground
    setupCollectionView()
    render()
  }

  private func setupCollectionView() {
    collectionView.backgroundColor = .systemGroupedBackground
    collectionView.alwaysBounceVertical = true
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(collectionView)

    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }

  private func render() {
    adapter.apply(
      List {
        Section(id: "status") {
          Row(
            id: "status-row",
            component: PullToRefreshStatusComponent(
              content: .init(
                title: configuration.introTitle,
                subtitle: configuration.introSubtitle,
                badgeTitle: configuration.badgeTitle,
                badgeTintColor: configuration.badgeTintColor,
                refreshCount: refreshCount,
                isRefreshing: isRefreshing
              )
            )
          )
        }
        .layout(.vertical(spacing: 10))
        .contentInsets(.init(top: 16, leading: 0, bottom: 12, trailing: 0))

        Section(id: "items") {
          for item in items {
            Row(
              id: item.id,
              component: RefreshItemComponent(content: .init(item: item))
            )
          }
        }
        .layout(.vertical(spacing: 10))
        .contentInsets(.init(top: 0, leading: 0, bottom: 16, trailing: 0))
      }
      .pullToRefresh(style: configuration.pullToRefreshStyle) { [weak self] in
        guard let self else {
          return
        }

        await self.reloadItems()
      },
      updateStrategy: .animated
    )
  }

  @MainActor
  private func reloadItems() async {
    guard isRefreshing == false else {
      return
    }

    isRefreshing = true
    render()

    try? await Task.sleep(nanoseconds: Const.refreshDelay)

    refreshCount += 1
    items.shuffle()

    if let first = items.first {
      items.insert(
        RefreshItem(
          id: "latest-\(refreshCount)",
          title: "\(configuration.title) refresh \(refreshCount)",
          subtitle: "Based on \(first.title)",
          tintColor: RefreshItem.palette[refreshCount % RefreshItem.palette.count]
        ),
        at: 0
      )
    }

    if items.count > Const.maxItems {
      items.removeLast(items.count - Const.maxItems)
    }

    isRefreshing = false
    render()
  }
}

final class PullToRefreshExampleViewController: PullToRefreshDemoViewController {
  init() {
    super.init(configuration: .system)
  }
}

final class PullToRefreshCustomActivityIndicatorExampleViewController: PullToRefreshDemoViewController {
  init() {
    super.init(configuration: .customActivityIndicator)
  }
}

final class PullToRefreshCustomImageIndicatorExampleViewController: PullToRefreshDemoViewController {
  init() {
    super.init(configuration: .customImageIndicator)
  }
}

final class PullToRefreshCustomViewIndicatorExampleViewController: PullToRefreshDemoViewController {
  init() {
    super.init(configuration: .customViewIndicator)
  }
}

private extension PullToRefreshDemoConfiguration {
  static let system = Self(
    title: "Pull To Refresh",
    introTitle: "시스템 UIRefreshControl 예제",
    introSubtitle: "기본 새로고침 컨트롤을 그대로 사용하면서도, title은 `attributedTitle`로 넣을 수 있습니다.",
    badgeTitle: "System",
    badgeTintColor: .systemBlue,
    pullToRefreshStyle: .system(.init(
      title: "시스템 새로고침",
      titleColor: .secondaryLabel,
      titleFont: .systemFont(ofSize: 12, weight: .medium),
      tintColor: .systemBlue
    ))
  )

  static let customActivityIndicator = Self(
    title: "Pull To Refresh",
    introTitle: "커스텀 activity indicator 예제",
    introSubtitle: "문구, 색상, 폰트와 activity indicator 크기를 함께 바꿀 수 있습니다.",
    badgeTitle: "Activity",
    badgeTintColor: .systemGreen,
    pullToRefreshStyle: .custom(.init(
      title: "아래로 당겨 새로고침",
      titleColor: .secondaryLabel,
      titleFont: .systemFont(ofSize: 14, weight: .medium),
      indicator: .activity(
        style: .medium,
        tintColor: .systemGreen,
        size: .init(width: 18, height: 18)
      )
    ))
  )

  static let customImageIndicator = Self(
    title: "Pull To Refresh",
    introTitle: "커스텀 image indicator 예제",
    introSubtitle: "SF Symbol 이미지를 사용해 새로고침 아이콘을 바꾸고, refreshing 중에는 회전도 시킬 수 있습니다.",
    badgeTitle: "Image",
    badgeTintColor: .systemOrange,
    pullToRefreshStyle: .custom(.init(
      title: "새로고침",
      titleColor: .secondaryLabel,
      titleFont: .systemFont(ofSize: 14, weight: .medium),
      indicator: .image(
        image: UIImage(systemName: "arrow.clockwise")!,
        tintColor: .systemOrange,
        contentMode: .scaleAspectFit,
        size: .init(width: 22, height: 22),
        rotatesWhileRefreshing: true,
        rotationDuration: 0.8
      )
    ))
  )

  static let customViewIndicator = Self(
    title: "Pull To Refresh",
    introTitle: "커스텀 view indicator 예제",
    introSubtitle: "완전히 커스텀한 UIView를 인디케이터로 넣는 방식입니다.",
    badgeTitle: "Custom View",
    badgeTintColor: .systemPurple,
    pullToRefreshStyle: .custom(.init(
      title: "커스텀 뷰로 새로고침",
      titleColor: .secondaryLabel,
      titleFont: .systemFont(ofSize: 14, weight: .medium),
      indicator: .custom(
        size: .init(width: 96, height: 30),
        makeView: { PullToRefreshBadgeIndicatorView() }
      )
    ))
  )
}

private struct RefreshItem: Equatable {
  let id: String
  let title: String
  let subtitle: String
  let tintColor: UIColor

  static let palette: [UIColor] = [
    .systemBlue,
    .systemGreen,
    .systemOrange,
    .systemPink,
    .systemPurple,
    .systemTeal
  ]

  static let samples: [Self] = [
    .init(id: "refresh-1", title: "First item", subtitle: "Pull to refresh to reshuffle.", tintColor: .systemBlue),
    .init(id: "refresh-2", title: "Second item", subtitle: "The indicator size is configurable.", tintColor: .systemGreen),
    .init(id: "refresh-3", title: "Third item", subtitle: "The label color and font are configurable too.", tintColor: .systemOrange)
  ]
}

private struct PullToRefreshStatusComponent: ListComponent {
  struct Content: Equatable {
    let title: String
    let subtitle: String
    let badgeTitle: String
    let badgeTintColor: UIColor
    let refreshCount: Int
    let isRefreshing: Bool
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> PullToRefreshStatusView {
    PullToRefreshStatusView()
  }

  func updateView(_ view: PullToRefreshStatusView, context: ListComponentContext<Void>) {
    view.configure(
      title: content.title,
      subtitle: content.subtitle,
      badgeTitle: content.badgeTitle,
      badgeTintColor: content.badgeTintColor,
      refreshCount: content.refreshCount,
      isRefreshing: content.isRefreshing
    )
  }
}

private final class PullToRefreshStatusView: UIView {
  private let containerView = UIView()
  private let badgeLabel = UILabel()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let counterLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(
    title: String,
    subtitle: String,
    badgeTitle: String,
    badgeTintColor: UIColor,
    refreshCount: Int,
    isRefreshing: Bool
  ) {
    titleLabel.text = title
    subtitleLabel.text = subtitle
    badgeLabel.text = badgeTitle
    badgeLabel.textColor = badgeTintColor
    badgeLabel.backgroundColor = badgeTintColor.withAlphaComponent(0.12)
    counterLabel.text = isRefreshing ? "Refreshing..." : "Refresh count: \(refreshCount)"
    counterLabel.textColor = badgeTintColor
    containerView.layer.borderColor = isRefreshing ? badgeTintColor.cgColor : UIColor.clear.cgColor
  }

  private func setup() {
    backgroundColor = .clear

    containerView.backgroundColor = .secondarySystemGroupedBackground
    containerView.layer.cornerRadius = 18
    containerView.layer.borderWidth = 1
    containerView.layer.borderColor = UIColor.clear.cgColor
    containerView.translatesAutoresizingMaskIntoConstraints = false

    badgeLabel.font = .preferredFont(forTextStyle: .caption1)
    badgeLabel.textAlignment = .center
    badgeLabel.layer.cornerRadius = 6
    badgeLabel.layer.masksToBounds = true
    badgeLabel.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

    counterLabel.font = .preferredFont(forTextStyle: .caption1)
    counterLabel.translatesAutoresizingMaskIntoConstraints = false

    addSubview(containerView)
    containerView.addSubview(badgeLabel)
    containerView.addSubview(titleLabel)
    containerView.addSubview(subtitleLabel)
    containerView.addSubview(counterLabel)

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

      badgeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      badgeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      badgeLabel.heightAnchor.constraint(equalToConstant: 24),
      badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 72),

      titleLabel.topAnchor.constraint(equalTo: badgeLabel.bottomAnchor, constant: 10),
      titleLabel.leadingAnchor.constraint(equalTo: badgeLabel.leadingAnchor),
      titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

      counterLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 10),
      counterLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      counterLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
      counterLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
    ])
  }
}

private struct RefreshItemComponent: ListComponent {
  struct Content: Equatable {
    let item: RefreshItem
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> RefreshItemView {
    RefreshItemView()
  }

  func updateView(_ view: RefreshItemView, context: ListComponentContext<Void>) {
    view.configure(
      title: content.item.title,
      subtitle: content.item.subtitle,
      tintColor: content.item.tintColor
    )
  }
}

private final class RefreshItemView: UIView {
  private let containerView = UIView()
  private let accentView = UIView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(title: String, subtitle: String, tintColor: UIColor) {
    titleLabel.text = title
    subtitleLabel.text = subtitle
    accentView.backgroundColor = tintColor
  }

  private func setup() {
    backgroundColor = .clear

    containerView.backgroundColor = .secondarySystemGroupedBackground
    containerView.layer.cornerRadius = 14
    containerView.translatesAutoresizingMaskIntoConstraints = false

    accentView.layer.cornerRadius = 5
    accentView.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

    addSubview(containerView)
    containerView.addSubview(accentView)
    containerView.addSubview(titleLabel)
    containerView.addSubview(subtitleLabel)

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

      accentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      accentView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
      accentView.widthAnchor.constraint(equalToConstant: 10),
      accentView.heightAnchor.constraint(equalToConstant: 10),

      titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      titleLabel.leadingAnchor.constraint(equalTo: accentView.trailingAnchor, constant: 12),
      titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
      subtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
    ])
  }
}

private final class PullToRefreshBadgeIndicatorView: UIView {
  private let pillView = UIView()
  private let dotView = UIView()
  private let titleLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setup() {
    backgroundColor = .clear

    pillView.backgroundColor = .systemPurple.withAlphaComponent(0.14)
    pillView.layer.cornerRadius = 15
    pillView.translatesAutoresizingMaskIntoConstraints = false

    dotView.backgroundColor = .systemPurple
    dotView.layer.cornerRadius = 4
    dotView.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.text = "Custom View"
    titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
    titleLabel.textColor = .systemPurple
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    addSubview(pillView)
    pillView.addSubview(dotView)
    pillView.addSubview(titleLabel)

    NSLayoutConstraint.activate([
      pillView.topAnchor.constraint(equalTo: topAnchor),
      pillView.leadingAnchor.constraint(equalTo: leadingAnchor),
      pillView.trailingAnchor.constraint(equalTo: trailingAnchor),
      pillView.bottomAnchor.constraint(equalTo: bottomAnchor),

      dotView.leadingAnchor.constraint(equalTo: pillView.leadingAnchor, constant: 12),
      dotView.centerYAnchor.constraint(equalTo: pillView.centerYAnchor),
      dotView.widthAnchor.constraint(equalToConstant: 8),
      dotView.heightAnchor.constraint(equalToConstant: 8),

      titleLabel.leadingAnchor.constraint(equalTo: dotView.trailingAnchor, constant: 8),
      titleLabel.trailingAnchor.constraint(equalTo: pillView.trailingAnchor, constant: -12),
      titleLabel.centerYAnchor.constraint(equalTo: pillView.centerYAnchor)
    ])
  }
}
