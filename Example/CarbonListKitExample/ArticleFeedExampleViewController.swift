import CarbonListKit
import UIKit

final class ArticleFeedExampleViewController: UIViewController {
  private enum DemoUpdateStrategy: String, CaseIterable {
    case animated
    case nonAnimated
    case reloadData

    var title: String {
      switch self {
      case .animated:
        return "Animated"
      case .nonAnimated:
        return "Non-animated"
      case .reloadData:
        return "Reload data"
      }
    }

    var subtitle: String {
      switch self {
      case .animated:
        return "Uses staged DifferenceKit updates with collection view animations."
      case .nonAnimated:
        return "Uses the same diff path while suppressing UIKit animations."
      case .reloadData:
        return "Replaces the list with a full collection view reload."
      }
    }

    var updateStrategy: UpdateStrategy {
      switch self {
      case .animated:
        return .animated
      case .nonAnimated:
        return .nonAnimated
      case .reloadData:
        return .reloadData
      }
    }
  }

  private let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewLayout()
  )

  private lazy var adapter = ListAdapter(collectionView: collectionView)
  private var articles = Article.sampleArticles
  private var selectedUpdateStrategy: DemoUpdateStrategy = .animated
  private var eventCount = 0

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Entity to ViewModel"
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
      collectionView.topAnchor.constraint(equalTo: view.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }

  private func render() {
    adapter.apply(updateStrategy: selectedUpdateStrategy.updateStrategy) {
      Section(id: "note") {
        Row(
          id: "explanation",
          component: ArticleNoteComponent(
            viewModel: .init(
              title: "Domain entity stays outside the component",
              message: "`Article` is app data. `ArticleRowComponent.ViewModel` is only the render-ready shape for a UIKit row."
            )
          )
        )
        .willDisplay { [weak self] _ in
          self?.recordEvent("note willDisplay")
        }
        .onEndDisplay { [weak self] _ in
          self?.recordEvent("note didEndDisplay")
        }
      }
      .layout(.vertical(spacing: 10))
      .contentInsets(.init(top: 16, leading: 0, bottom: 12, trailing: 0))

      Section(id: "update-strategy") {
        for strategy in DemoUpdateStrategy.allCases {
          Row(
            id: strategy.rawValue,
            component: ArticleActionComponent(
              viewModel: .init(
                title: strategy.title,
                subtitle: strategy.subtitle,
                isSelected: selectedUpdateStrategy == strategy
              )
            )
          )
          .didSelect { [weak self] _ in
            self?.selectUpdateStrategy(strategy)
          }
        }
      }
      .withSectionLayout(.vertical(spacing: 10))
      .withSectionContentInsets(.init(top: 0, leading: 0, bottom: 12, trailing: 0))

      Section(id: "layout-modifiers") {
        Cell(
          id: "row",
          component: ArticlePillComponent(
            viewModel: .init(title: "Row", subtitle: "Cell alias")
          )
        )

        Cell(
          id: "section",
          component: ArticlePillComponent(
            viewModel: .init(title: "Section", subtitle: "contentInsets")
          )
        )

        Cell(
          id: "grid",
          component: ArticlePillComponent(
            viewModel: .init(title: "Grid", subtitle: "2 columns")
          )
        )

        Cell(
          id: "custom",
          component: ArticlePillComponent(
            viewModel: .init(title: "Custom", subtitle: "layout")
          )
        )
      }
      .layout(.grid(columns: 2, itemSpacing: 10, lineSpacing: 10))
      .contentInsets(.init(top: 0, leading: 16, bottom: 12, trailing: 16))

      Section(id: "custom-layout") {
        Row(
          id: "custom-layout-note",
          component: ArticleNoteComponent(
            viewModel: .init(
              title: "Custom layout escape hatch",
              message: "This section uses `.layout(.custom { ... })` and returns a native `NSCollectionLayoutSection`."
            )
          )
        )
      }
      .layout(.custom { _ in
        ArticleFeedExampleViewController.makeCustomLayoutSection()
      })
      .contentInsets(.init(top: 0, leading: 0, bottom: 12, trailing: 0))

      Section(id: "articles") {
        for article in articles {
          Row(
            id: article.id,
            component: ArticleRowComponent(viewModel: ArticleRowComponent.ViewModel(article: article))
          )
          .onSelect { [weak self] _ in
            self?.toggleRead(articleID: article.id)
          }
          .onDisplay { [weak self] _ in
            self?.recordEvent("article displayed: \(article.id)")
          }
          .onEndDisplay { [weak self] _ in
            self?.recordEvent("article ended display: \(article.id)")
          }
        }
      }
      .layout(.vertical(spacing: 10))
      .contentInsets(.init(top: 0, leading: 0, bottom: 16, trailing: 0))
    }
  }

  private static func makeCustomLayoutSection() -> NSCollectionLayoutSection {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .estimated(44)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
    let section = NSCollectionLayoutSection(group: group)
    section.interGroupSpacing = 10
    return section
  }

  private func selectUpdateStrategy(_ strategy: DemoUpdateStrategy) {
    selectedUpdateStrategy = strategy
    articles = articles.reversed()
    render()
  }

  private func toggleRead(articleID: Article.ID) {
    articles = articles.map { article in
      guard article.id == articleID else {
        return article
      }

      return article.togglingRead()
    }
    render()
  }

  private func recordEvent(_ message: String) {
    eventCount += 1
    print("[CarbonListKit Example] \(eventCount): \(message)")
  }
}

private struct Article: Identifiable, Equatable {
  let id: String
  let title: String
  let author: String
  let readTimeMinutes: Int
  let isRead: Bool

  func togglingRead() -> Self {
    .init(
      id: id,
      title: title,
      author: author,
      readTimeMinutes: readTimeMinutes,
      isRead: !isRead
    )
  }

  static let sampleArticles: [Article] = [
    .init(
      id: "component-boundary",
      title: "Drawing a Boundary Around Components",
      author: "Carbon Team",
      readTimeMinutes: 4,
      isRead: false
    ),
    .init(
      id: "diffing",
      title: "Identity, Equality, and Smooth Updates",
      author: "Carbon Team",
      readTimeMinutes: 6,
      isRead: true
    ),
    .init(
      id: "uikit-views",
      title: "Keeping UIKit Views Small",
      author: "Carbon Team",
      readTimeMinutes: 3,
      isRead: false
    )
  ]
}

private struct ArticleNoteComponent: ListComponent {
  struct ViewModel: Equatable {
    let title: String
    let message: String
  }

  let viewModel: ViewModel

  func makeView(context: ListComponentContext<Void>) -> ArticleNoteView {
    ArticleNoteView()
  }

  func updateView(_ view: ArticleNoteView, context: ListComponentContext<Void>) {
    view.configure(title: viewModel.title, message: viewModel.message)
  }
}

private final class ArticleNoteView: UIView {
  private let containerView = UIView()
  private let titleLabel = UILabel()
  private let messageLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(title: String, message: String) {
    titleLabel.text = title
    messageLabel.text = message
  }

  private func setup() {
    backgroundColor = .clear

    containerView.backgroundColor = .systemBlue.withAlphaComponent(0.12)
    containerView.layer.cornerRadius = 8
    containerView.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    messageLabel.font = .preferredFont(forTextStyle: .subheadline)
    messageLabel.textColor = .secondaryLabel
    messageLabel.numberOfLines = 0
    messageLabel.translatesAutoresizingMaskIntoConstraints = false

    addSubview(containerView)
    containerView.addSubview(titleLabel)
    containerView.addSubview(messageLabel)

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

      titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

      messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
      messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      messageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
      messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
    ])
  }
}

private struct ArticleActionComponent: ListComponent {
  struct ViewModel: Equatable {
    let title: String
    let subtitle: String
    let isSelected: Bool
  }

  let viewModel: ViewModel

  func makeView(context: ListComponentContext<Void>) -> ArticleActionView {
    ArticleActionView()
  }

  func updateView(_ view: ArticleActionView, context: ListComponentContext<Void>) {
    view.configure(
      title: viewModel.title,
      subtitle: viewModel.subtitle,
      isSelected: viewModel.isSelected
    )
  }
}

private final class ArticleActionView: UIView {
  private let containerView = UIView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(title: String, subtitle: String, isSelected: Bool) {
    titleLabel.text = title
    subtitleLabel.text = subtitle
    checkmarkImageView.isHidden = !isSelected
    containerView.layer.borderWidth = isSelected ? 1 : 0
  }

  private func setup() {
    backgroundColor = .clear

    containerView.backgroundColor = .secondarySystemGroupedBackground
    containerView.layer.cornerRadius = 8
    containerView.layer.borderColor = UIColor.systemGreen.cgColor
    containerView.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

    checkmarkImageView.tintColor = .systemGreen
    checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false

    addSubview(containerView)
    containerView.addSubview(titleLabel)
    containerView.addSubview(subtitleLabel)
    containerView.addSubview(checkmarkImageView)

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

      titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: checkmarkImageView.leadingAnchor, constant: -12),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
      subtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),

      checkmarkImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      checkmarkImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
      checkmarkImageView.widthAnchor.constraint(equalToConstant: 22),
      checkmarkImageView.heightAnchor.constraint(equalToConstant: 22)
    ])
  }
}

private struct ArticlePillComponent: ListComponent {
  struct ViewModel: Equatable {
    let title: String
    let subtitle: String
  }

  let viewModel: ViewModel

  func makeView(context: ListComponentContext<Void>) -> ArticlePillView {
    ArticlePillView()
  }

  func updateView(_ view: ArticlePillView, context: ListComponentContext<Void>) {
    view.configure(title: viewModel.title, subtitle: viewModel.subtitle)
  }
}

private final class ArticlePillView: UIView {
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

    containerView.backgroundColor = .secondarySystemGroupedBackground
    containerView.layer.cornerRadius = 8
    containerView.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0
    titleLabel.textAlignment = .center
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0
    subtitleLabel.textAlignment = .center
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

    addSubview(containerView)
    containerView.addSubview(titleLabel)
    containerView.addSubview(subtitleLabel)

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

      titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
      titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
      subtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
    ])
  }
}

private struct ArticleRowComponent: ListComponent {
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

private final class ArticleRowView: UIView {
  private let containerView = UIView()
  private let titleLabel = UILabel()
  private let metadataLabel = UILabel()
  private let readStateLabel = UILabel()

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
    metadata: String,
    readStateTitle: String,
    readStateColor: UIColor
  ) {
    titleLabel.text = title
    metadataLabel.text = metadata
    readStateLabel.text = readStateTitle
    readStateLabel.textColor = readStateColor
    readStateLabel.backgroundColor = readStateColor.withAlphaComponent(0.12)
  }

  private func setup() {
    backgroundColor = .clear

    containerView.backgroundColor = .secondarySystemGroupedBackground
    containerView.layer.cornerRadius = 8
    containerView.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    metadataLabel.font = .preferredFont(forTextStyle: .subheadline)
    metadataLabel.textColor = .secondaryLabel
    metadataLabel.numberOfLines = 0
    metadataLabel.translatesAutoresizingMaskIntoConstraints = false

    readStateLabel.font = .preferredFont(forTextStyle: .caption1)
    readStateLabel.textAlignment = .center
    readStateLabel.layer.cornerRadius = 6
    readStateLabel.layer.masksToBounds = true
    readStateLabel.translatesAutoresizingMaskIntoConstraints = false

    addSubview(containerView)
    containerView.addSubview(titleLabel)
    containerView.addSubview(metadataLabel)
    containerView.addSubview(readStateLabel)

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

      titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: readStateLabel.leadingAnchor, constant: -12),

      metadataLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
      metadataLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      metadataLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
      metadataLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),

      readStateLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      readStateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
      readStateLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),
      readStateLabel.heightAnchor.constraint(equalToConstant: 24)
    ])
  }
}
