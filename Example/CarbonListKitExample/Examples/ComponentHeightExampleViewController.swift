import CarbonListKit
import UIKit

final class ComponentHeightExampleViewController: UIViewController {
  private let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewLayout()
  )

  private lazy var adapter = ListAdapter(collectionView: collectionView)

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Component Height"
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
          id: "automatic-short",
          component: AutomaticHeightComponent(
            content: .init(
              title: "Automatic height",
              body: "height를 구현하지 않으면 Auto Layout으로 필요한 높이를 계산합니다.",
              tintColor: .systemBlue
            )
          )
        )

        Row(
          id: "automatic-long",
          component: AutomaticHeightComponent(
            content: .init(
              title: "Automatic height with long text",
              body: "여러 줄 텍스트가 들어오면 estimated 80에서 시작하더라도 systemLayoutSizeFitting 결과에 맞춰 row가 자연스럽게 커집니다. 기존 컴포넌트는 아무 코드도 바꾸지 않아도 이 경로를 그대로 사용합니다.",
              tintColor: .systemGreen
            )
          )
        )
      } header: {
        Header(
          id: "automatic-header",
          component: HeightHeaderComponent(
            content: .init(
              title: "Default: .automatic",
              subtitle: "컴포넌트에서 height를 정의하지 않은 상태"
            )
          )
        )
      }
      .layout(.vertical(spacing: 10))
      .contentInsets(.init(top: 0, leading: 16, bottom: 0, trailing: 16))
      .sectionSpacing(24)

      Section {
        Row(
          id: "fixed-72",
          component: FixedHeightComponent(
            content: .init(
              title: "Fixed 72",
              subtitle: "var height: .absolute(72)",
              height: 72,
              tintColor: .systemOrange
            )
          )
        )

        Row(
          id: "fixed-120",
          component: FixedHeightComponent(
            content: .init(
              title: "Fixed 120",
              subtitle: "Auto Layout 측정 없이 지정 높이를 바로 사용합니다.",
              height: 120,
              tintColor: .systemPink
            )
          )
        )
      } header: {
        Header(
          id: "fixed-header",
          component: HeightHeaderComponent(
            content: .init(
              title: "Explicit: .absolute",
              subtitle: "컴포넌트가 직접 row 높이를 결정하는 상태"
            )
          )
        )
      } footer: {
        Footer(
          id: "fixed-footer",
          component: HeightFooterComponent(
            content: .init(text: "높이를 직접 지정하면 self-sizing 측정을 건너뛰어 예측 가능한 높이와 더 적은 측정 비용을 얻을 수 있습니다.")
          )
        )
      }
      .layout(.vertical(spacing: 10))
      .contentInsets(.init(top: 0, leading: 16, bottom: 0, trailing: 16))
    }
  }
}

@available(iOS 17.0)
#Preview {
  ComponentHeightExampleViewController()
}

private struct HeightHeaderComponent: ListComponent {
  struct Content: Equatable {
    let title: String
    let subtitle: String
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> HeightHeaderView {
    HeightHeaderView()
  }

  func updateView(_ view: HeightHeaderView, context: ListComponentContext<Void>) {
    view.configure(title: content.title, subtitle: content.subtitle)
  }
}

private final class HeightHeaderView: UIView {
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let stackView = UIStackView()

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
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.numberOfLines = 0

    subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0

    stackView.axis = .vertical
    stackView.spacing = 4
    stackView.translatesAutoresizingMaskIntoConstraints = false

    addSubview(stackView)
    stackView.addArrangedSubview(titleLabel)
    stackView.addArrangedSubview(subtitleLabel)

    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
    ])
  }
}

private struct AutomaticHeightComponent: ListComponent {
  struct Content: Equatable {
    let title: String
    let body: String
    let tintColor: UIColor
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> HeightCardView {
    HeightCardView()
  }

  func updateView(_ view: HeightCardView, context: ListComponentContext<Void>) {
    view.configure(
      title: content.title,
      subtitle: content.body,
      badge: ".automatic",
      tintColor: content.tintColor
    )
  }
}

private struct FixedHeightComponent: ListComponent {
  struct Content: Equatable {
    let title: String
    let subtitle: String
    let height: CGFloat
    let tintColor: UIColor
  }

  let content: Content

  var height: ListComponentHeight {
     .absolute(content.height)
  }

  func makeView(context: ListComponentContext<Void>) -> HeightCardView {
    HeightCardView()
  }

  func updateView(_ view: HeightCardView, context: ListComponentContext<Void>) {
    view.configure(
      title: content.title,
      subtitle: content.subtitle,
      badge: ".absolute(\(Int(content.height)))",
      tintColor: content.tintColor
    )
  }
}

private final class HeightCardView: UIView {
  private let badgeLabel = UILabel()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let stackView = UIStackView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(title: String, subtitle: String, badge: String, tintColor: UIColor) {
    titleLabel.text = title
    subtitleLabel.text = subtitle
    badgeLabel.text = badge
    badgeLabel.textColor = tintColor
    badgeLabel.backgroundColor = tintColor.withAlphaComponent(0.12)
  }

  private func setup() {
    backgroundColor = .secondarySystemGroupedBackground
    layer.cornerRadius = 8

    badgeLabel.font = .preferredFont(forTextStyle: .caption1)
    badgeLabel.layer.cornerRadius = 6
    badgeLabel.layer.masksToBounds = true
    badgeLabel.textAlignment = .center

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.numberOfLines = 0

    subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0

    stackView.axis = .vertical
    stackView.spacing = 6
    stackView.translatesAutoresizingMaskIntoConstraints = false

    addSubview(stackView)
    stackView.addArrangedSubview(badgeLabel)
    stackView.addArrangedSubview(titleLabel)
    stackView.addArrangedSubview(subtitleLabel)

    NSLayoutConstraint.activate([
      badgeLabel.heightAnchor.constraint(equalToConstant: 24),
      badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 96),
      stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 12),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
      stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12)
    ])
  }
}

private struct HeightFooterComponent: ListComponent {
  struct Content: Equatable {
    let text: String
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> HeightFooterView {
    HeightFooterView()
  }

  func updateView(_ view: HeightFooterView, context: ListComponentContext<Void>) {
    view.configure(text: content.text)
  }
}

private final class HeightFooterView: UIView {
  private let label = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(text: String) {
    label.text = text
  }

  private func setup() {
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false

    addSubview(label)

    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: topAnchor, constant: 10),
      label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
    ])
  }
}
