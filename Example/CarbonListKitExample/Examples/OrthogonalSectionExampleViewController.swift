import CarbonListKit
import UIKit

final class OrthogonalSectionExampleViewController: UIViewController {
  private let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewLayout()
  )

  private lazy var adapter = ListAdapter(collectionView: collectionView)

  private let featuredCards: [OrthogonalCard] = [
    .init(title: "Fresh Picks", subtitle: "A horizontally scrolling section inside a vertical list.", tintColor: .systemBlue),
    .init(title: "Weekend Deals", subtitle: "Use orthogonal sections for carousel-style content.", tintColor: .systemOrange),
    .init(title: "Nearby", subtitle: "Great for recommendations, highlights, and featured content.", tintColor: .systemGreen),
    .init(title: "Trending", subtitle: "The section can keep its own scrolling behavior.", tintColor: .systemPurple),
    .init(title: "New Arrivals", subtitle: "Combine with headers, footers, and regular rows.", tintColor: .systemRed)
  ]

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Orthogonal Section"
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
    adapter.apply(updateStrategy: .animated) {
      Section(id: "intro") {
        Row(
          id: "explanation",
          component: OrthogonalNoteComponent(
            content: .init(
              title: "Orthogonal section scrolling",
              message: "This screen uses `.layout(.orthogonal(...))` so the cards scroll horizontally while the list itself stays vertical."
            )
          )
        )
      }
      .layout(.vertical(spacing: 12))
      .contentInsets(.init(top: 16, leading: 0, bottom: 12, trailing: 0))

      Section(id: "cards") {
        for card in featuredCards {
          Row(
            id: card.id,
            component: OrthogonalCardComponent(content: .init(card: card))
          )
        }
      }
      .layout(.orthogonal(itemSpacing: 20, lineSpacing: 12, scrollingBehavior: .continuous, reservedHeight: 100))
      .contentInsets(.init(top: 0, leading: 16, bottom: 12, trailing: 16))

      Section(id: "footer") {
        Row(
          id: "tip",
          component: OrthogonalNoteComponent(
            content: .init(
              title: "Tip",
              message: "Try changing the scrolling behavior to `.paging` or `.groupPagingCentered` if you want a more carousel-like feel."
            )
          )
        )
      }
      .layout(.vertical(spacing: 12))
      .contentInsets(.init(top: 0, leading: 0, bottom: 16, trailing: 0))
    }
  }
}

@available(iOS 17.0, *)
#Preview {
  OrthogonalSectionExampleViewController()
}

private struct OrthogonalCard: Identifiable, Equatable {
  let id = UUID()
  let title: String
  let subtitle: String
  let tintColor: UIColor
}

private struct OrthogonalCardComponent: ListComponent {
  struct Content: Equatable {
    let card: OrthogonalCard
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> OrthogonalCardView {
    OrthogonalCardView()
  }

  func updateView(_ view: OrthogonalCardView, context: ListComponentContext<Void>) {
    view.configure(
      title: content.card.title,
      subtitle: content.card.subtitle,
      tintColor: content.card.tintColor
    )
  }
}

private struct OrthogonalNoteComponent: ListComponent {
  struct Content: Equatable {
    let title: String
    let message: String
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> OrthogonalNoteView {
    OrthogonalNoteView()
  }

  func updateView(_ view: OrthogonalNoteView, context: ListComponentContext<Void>) {
    view.configure(title: content.title, message: content.message)
  }
}

private final class OrthogonalCardView: UIView {
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

  func configure(title: String, subtitle: String, tintColor: UIColor) {
    containerView.backgroundColor = tintColor.withAlphaComponent(0.14)
    titleLabel.text = title
    subtitleLabel.text = subtitle
  }

  private func setup() {
    backgroundColor = .clear

    containerView.layer.cornerRadius = 24
    containerView.layer.cornerCurve = .continuous
    containerView.clipsToBounds = true
    containerView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(containerView)

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.numberOfLines = 2
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(titleLabel)

    subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(subtitleLabel)

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

      titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
      subtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
    ])
  }
}

private final class OrthogonalNoteView: UIView {
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

    containerView.backgroundColor = .secondarySystemGroupedBackground
    containerView.layer.cornerRadius = 20
    containerView.layer.cornerCurve = .continuous
    containerView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(containerView)

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(titleLabel)

    messageLabel.font = .preferredFont(forTextStyle: .subheadline)
    messageLabel.textColor = .secondaryLabel
    messageLabel.numberOfLines = 0
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(messageLabel)

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

      titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

      messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
      messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
    ])
  }
}
