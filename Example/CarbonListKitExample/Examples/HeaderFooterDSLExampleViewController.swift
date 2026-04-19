import CarbonListKit
import UIKit

final class HeaderFooterDSLExampleViewController: UIViewController {
  private let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewLayout()
  )

  private lazy var adapter = ListAdapter(collectionView: collectionView)

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Header & Footer DSL"
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
      Section {
        Row(
          id: "content-1",
          component: DSLRowComponent(content: .init(title: "내용 1"))
        )

        Row(
          id: "content-2",
          component: DSLRowComponent(content: .init(title: "내용 2"))
        )
      } header: {
        Header(
          id: "header",
          component: DSLSupplementaryComponent(
            content: .init(
              title: "헤더",
              message: "rows 아래에 header 클로저를 붙입니다.",
              style: .header
            )
          )
        )
      } footer: {
        Footer(
          id: "footer",
          component: DSLSupplementaryComponent(
            content: .init(
              title: "푸터",
              message: "footer 클로저도 같은 위치에 이어서 작성합니다.",
              style: .footer
            )
          )
        )
      }
      .layout(.vertical(spacing: 10))
      .contentInsets(.init(top: 0, leading: 16, bottom: 0, trailing: 16))
      .sectionSpacing(24)

      Section {
        for index in 1...4 {
          Row(
            id: "grid-\(index)",
            component: DSLGridComponent(content: .init(title: "Grid \(index)"))
          )
        }
      } header: {
        Header(
          id: "grid-header",
          component: DSLSupplementaryComponent(
            content: .init(
              title: "Grid 헤더",
              message: "grid layout에서도 같은 DSL을 사용합니다.",
              style: .header
            )
          )
        )
      } footer: {
        Footer(
          id: "grid-footer",
          component: DSLSupplementaryComponent(
            content: .init(
              title: "Grid 푸터",
              message: "itemSpacing은 item 사이 간격만 담당합니다.",
              style: .footer
            )
          )
        )
      }
      .layout(.grid(columns: 2, itemSpacing: 12, lineSpacing: 10))
      .sectionInsets(.init(top: 0, leading: 16, bottom: 0, trailing: 16))
    }
  }
}

@available(iOS 17.0)
#Preview {
  HeaderFooterDSLExampleViewController()
}

private struct DSLSupplementaryComponent: ListComponent {
  enum Style: Equatable {
    case header
    case footer
  }

  struct Content: Equatable {
    let title: String
    let message: String
    let style: Style
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> DSLSupplementaryView {
    DSLSupplementaryView()
  }

  func updateView(_ view: DSLSupplementaryView, context: ListComponentContext<Void>) {
    view.configure(content)
  }
}

private final class DSLSupplementaryView: UIView {
  private let titleLabel = UILabel()
  private let messageLabel = UILabel()
  private let stackView = UIStackView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ content: DSLSupplementaryComponent.Content) {
    titleLabel.text = content.title
    messageLabel.text = content.message

    switch content.style {
    case .header:
      backgroundColor = .systemTeal.withAlphaComponent(0.14)
      titleLabel.textColor = .label
    case .footer:
      backgroundColor = .systemGray5
      titleLabel.textColor = .secondaryLabel
    }
  }

  private func setup() {
    layer.cornerRadius = 8

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.numberOfLines = 0

    messageLabel.font = .preferredFont(forTextStyle: .subheadline)
    messageLabel.textColor = .secondaryLabel
    messageLabel.numberOfLines = 0

    stackView.axis = .vertical
    stackView.spacing = 4
    stackView.translatesAutoresizingMaskIntoConstraints = false

    addSubview(stackView)
    stackView.addArrangedSubview(titleLabel)
    stackView.addArrangedSubview(messageLabel)

    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: 14),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
    ])
  }
}

private struct DSLRowComponent: ListComponent {
  struct Content: Equatable {
    let title: String
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> DSLRowView {
    DSLRowView()
  }

  func updateView(_ view: DSLRowView, context: ListComponentContext<Void>) {
    view.configure(title: content.title)
  }
}

private final class DSLRowView: UIView {
  private let titleLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(title: String) {
    titleLabel.text = title
  }

  private func setup() {
    backgroundColor = .secondarySystemGroupedBackground
    layer.cornerRadius = 8

    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    addSubview(titleLabel)

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
    ])
  }
}

private struct DSLGridComponent: ListComponent {
  struct Content: Equatable {
    let title: String
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> DSLGridView {
    DSLGridView()
  }

  func updateView(_ view: DSLGridView, context: ListComponentContext<Void>) {
    view.configure(title: content.title)
  }
}

private final class DSLGridView: UIView {
  private let titleLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(title: String) {
    titleLabel.text = title
  }

  private func setup() {
    backgroundColor = .secondarySystemGroupedBackground
    layer.cornerRadius = 8

    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.textAlignment = .center
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    addSubview(titleLabel)

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18)
    ])
  }
}
