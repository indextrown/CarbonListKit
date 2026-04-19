import CarbonListKit
import UIKit

final class SampleListViewController: UIViewController {
  private enum SampleAction: String {
    case add
    case shuffle
    case update
  }

  private let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewLayout()
  )

  private lazy var adapter = ListAdapter(collectionView: collectionView)
  private var featureRows = SampleRow.demoRows
  private var generatedRowCount = 0
  private var updateCount = 0

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Diff updates"
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
          id: "hero",
          component: SampleRowComponent(
            content: .init(
              title: "Declarative UICollectionView",
              subtitle: "Build sections, rows, and UIKit views without repeating registration or data source code.",
              tintColor: .systemBlue
            )
          )
        )
      }
      .layout(.vertical(spacing: 12))
      .contentInsets(.init(top: 0, leading: 0, bottom: 12, trailing: 0))

      Section(id: "actions") {
        Row(
          id: SampleAction.add.rawValue,
          component: SampleRowComponent(
            content: .init(
              title: "Add row",
              subtitle: "Insert a new component with animated DifferenceKit updates.",
              tintColor: .systemTeal
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.addRow()
        }

        Row(
          id: SampleAction.shuffle.rawValue,
          component: SampleRowComponent(
            content: .init(
              title: "Shuffle rows",
              subtitle: "Move existing rows while preserving their identity.",
              tintColor: .systemPurple
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.shuffleRows()
        }

        Row(
          id: SampleAction.update.rawValue,
          component: SampleRowComponent(
            content: .init(
              title: "Update content",
              subtitle: "Change row content without changing row identity.",
              tintColor: .systemYellow
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.updateFirstRow()
        }
      }
      .layout(.vertical(spacing: 10))
      .contentInsets(.init(top: 0, leading: 0, bottom: 12, trailing: 0))

      Section(id: "features") {
        for row in featureRows {
          Row(
            id: row.id,
            component: SampleRowComponent(
              content: .init(
                title: row.title,
                subtitle: row.subtitle,
                tintColor: row.tintColor
              )
            )
          )
          .onSelect { [weak self] context in
            self?.showSelectionAlert(title: row.title, indexPath: context.indexPath)
          }
        }
      }
      .layout(.vertical(spacing: 10))
    }
  }

  private func addRow() {
    generatedRowCount += 1
    featureRows.insert(
      .init(
        id: "generated-\(generatedRowCount)",
        title: "Generated row \(generatedRowCount)",
        subtitle: "This row was inserted after the initial render.",
        tintColor: .systemCyan
      ),
      at: 0
    )
    render()
  }

  private func shuffleRows() {
    featureRows.shuffle()
    render()
  }

  private func updateFirstRow() {
    guard featureRows.isEmpty == false else {
      return
    }

    updateCount += 1
    featureRows[0] = featureRows[0].updating(
      subtitle: "Updated \(updateCount) time\(updateCount == 1 ? "" : "s") with the same row identity."
    )
    render()
  }

  private func showSelectionAlert(title: String, indexPath: IndexPath) {
    let alert = UIAlertController(
      title: title,
      message: "Selected item \(indexPath.item) in section \(indexPath.section).",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}

private struct SampleRow: Identifiable {
  let id: String
  let title: String
  let subtitle: String
  let tintColor: UIColor

  func updating(subtitle: String) -> Self {
    .init(
      id: id,
      title: title,
      subtitle: subtitle,
      tintColor: tintColor
    )
  }

  static let demoRows: [SampleRow] = [
    .init(
      id: "registration",
      title: "Automatic registration",
      subtitle: "Components provide reuse identifiers, and the adapter registers cells as lists are applied.",
      tintColor: .systemGreen
    ),
    .init(
      id: "component",
      title: "UIView components",
      subtitle: "Each row renders a plain UIKit view that owns its Auto Layout constraints.",
      tintColor: .systemIndigo
    ),
    .init(
      id: "events",
      title: "Row events",
      subtitle: "Selection and display callbacks live next to the row declaration.",
      tintColor: .systemOrange
    ),
    .init(
      id: "layout",
      title: "Section layout",
      subtitle: "Sections can choose vertical, grid, or custom compositional layouts.",
      tintColor: .systemPink
    )
  ]
}

private struct SampleRowComponent: ListComponent {
  struct Content: Equatable {
    let title: String
    let subtitle: String
    let tintColor: UIColor
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> SampleRowView {
    SampleRowView()
  }

  func updateView(_ view: SampleRowView, context: ListComponentContext<Void>) {
    view.configure(
      title: content.title,
      subtitle: content.subtitle,
      tintColor: content.tintColor
    )
  }
}

private final class SampleRowView: UIView {
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
    accentView.backgroundColor = tintColor
    titleLabel.text = title
    subtitleLabel.text = subtitle
  }

  private func setup() {
    backgroundColor = .clear

    containerView.backgroundColor = .secondarySystemGroupedBackground
    containerView.layer.cornerRadius = 8
    containerView.layer.masksToBounds = true
    containerView.translatesAutoresizingMaskIntoConstraints = false

    accentView.layer.cornerRadius = 3
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

      accentView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      accentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      accentView.widthAnchor.constraint(equalToConstant: 6),
      accentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),

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
