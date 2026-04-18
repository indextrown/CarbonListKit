import CarbonListKit
import UIKit

final class InfiniteScrollExampleViewController: UIViewController {
  private enum Const {
    static let pageSize = 24
    static let maximumItemCount = 320
  }

  private let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewLayout()
  )

  private lazy var adapter = ListAdapter(collectionView: collectionView)
  private var items: [FeedItem] = []
  private var isLoadingNextPage = false

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Infinite Scroll"
    view.backgroundColor = .systemBackground
    setupCollectionView()
    appendNextPage()
  }

  private func setupCollectionView() {
    collectionView.backgroundColor = .systemGroupedBackground
    collectionView.alwaysBounceVertical = true
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(collectionView)

    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }

  private func appendNextPage() {
    guard isLoadingNextPage == false,
          items.count < Const.maximumItemCount else {
      return
    }

    isLoadingNextPage = true
    let nextStartIndex = items.count + 1
    let nextEndIndex = min(items.count + Const.pageSize, Const.maximumItemCount)
    let newItems = (nextStartIndex...nextEndIndex).map { FeedItem(index: $0) }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
      guard let self else {
        return
      }

      self.items.append(contentsOf: newItems)
      self.isLoadingNextPage = false
      self.render()
    }
  }

  private func render() {
    let canLoadMore = items.count < Const.maximumItemCount

    adapter.apply(
      List {
        Section(id: "feed") {
          for item in items {
            Row(
              id: item.id,
              component: FeedItemComponent(viewModel: .init(item: item))
            )
          }
        }
        .withSectionLayout(.vertical(spacing: 10))
        .withSectionContentInsets(.init(top: 16, leading: 0, bottom: 12, trailing: 0))

        Section(id: "footer") {
          Row(
            id: "footer",
            component: FeedFooterComponent(
              viewModel: .init(
                title: canLoadMore ? "Loading next page..." : "No more items",
                subtitle: "\(items.count) / \(Const.maximumItemCount) items"
              )
            )
          )
        }
        .layout(.vertical(spacing: 0))
        .contentInsets(.init(top: 0, leading: 0, bottom: 24, trailing: 0))
      }
      .onReachEnd(offsetFromEnd: .relativeToContainerSize(multiplier: 1.0)) { [weak self] _ in
        self?.appendNextPage()
      },
      updateStrategy: .animated
    )
  }
}

private struct FeedItem: Identifiable, Equatable {
  let id: String
  let title: String
  let subtitle: String
  let tintColor: UIColor

  init(index: Int) {
    self.id = "feed-item-\(index)"
    self.title = "Feed item \(index)"
    self.subtitle = "Loaded by page-based infinite scrolling."
    self.tintColor = FeedItem.palette[index % FeedItem.palette.count]
  }

  private static let palette: [UIColor] = [
    .systemBlue,
    .systemGreen,
    .systemOrange,
    .systemPink,
    .systemPurple,
    .systemTeal
  ]
}

private struct FeedItemComponent: ListComponent {
  struct ViewModel: Equatable {
    let title: String
    let subtitle: String
    let tintColor: UIColor

    init(item: FeedItem) {
      self.title = item.title
      self.subtitle = item.subtitle
      self.tintColor = item.tintColor
    }
  }

  let viewModel: ViewModel

  func makeView(context: ListComponentContext<Void>) -> FeedItemView {
    FeedItemView()
  }

  func updateView(_ view: FeedItemView, context: ListComponentContext<Void>) {
    view.configure(
      title: viewModel.title,
      subtitle: viewModel.subtitle,
      tintColor: viewModel.tintColor
    )
  }
}

private final class FeedItemView: UIView {
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
    containerView.layer.cornerRadius = 8
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

private struct FeedFooterComponent: ListComponent {
  struct ViewModel: Equatable {
    let title: String
    let subtitle: String
  }

  let viewModel: ViewModel

  func makeView(context: ListComponentContext<Void>) -> FeedFooterView {
    FeedFooterView()
  }

  func updateView(_ view: FeedFooterView, context: ListComponentContext<Void>) {
    view.configure(title: viewModel.title, subtitle: viewModel.subtitle)
  }
}

private final class FeedFooterView: UIView {
  private let containerView = UIView()
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

  func configure(title: String, subtitle: String) {
    titleLabel.text = title
    subtitleLabel.text = subtitle
  }

  private func setup() {
    backgroundColor = .clear

    containerView.backgroundColor = .clear
    containerView.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .preferredFont(forTextStyle: .subheadline)
    titleLabel.textColor = .secondaryLabel
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 0
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
    subtitleLabel.textColor = .tertiaryLabel
    subtitleLabel.textAlignment = .center
    subtitleLabel.numberOfLines = 0
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

    addSubview(containerView)
    containerView.addSubview(titleLabel)
    containerView.addSubview(subtitleLabel)

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

      titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
      subtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
    ])
  }
}
