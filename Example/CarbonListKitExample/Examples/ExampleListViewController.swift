import CarbonListKit
import SwiftUI
import UIKit

final class ExampleListViewController: UIViewController {
  private let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewLayout()
  )

  private lazy var adapter = ListAdapter(collectionView: collectionView)

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "CarbonListKit"
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
      Section(id: "getting-started") {
        Row(
          id: "diff-updates",
          component: ExampleMenuComponent(
            content: .init(
              title: "Diff updates",
              subtitle: "Add, shuffle, and update rows with animated DifferenceKit changes.",
              badge: "Basic",
              tintColor: .systemBlue
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.navigationController?.pushViewController(SampleListViewController(), animated: true)
        }

        Row(
          id: "entity-view-model",
          component: ExampleMenuComponent(
            content: .init(
              title: "Entity to Content",
              subtitle: "Keep domain entities separate from component Content.",
              badge: "Mapping",
              tintColor: .systemGreen
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.navigationController?.pushViewController(ArticleFeedExampleViewController(), animated: true)
        }

        Row(
          id: "infinite-scroll",
          component: ExampleMenuComponent(
            content: .init(
              title: "Infinite Scroll",
              subtitle: "Append the next page when the list reaches the end.",
              badge: "Paging",
              tintColor: .systemOrange
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.navigationController?.pushViewController(InfiniteScrollExampleViewController(), animated: true)
        }

        Row(
          id: "pull-to-refresh-system",
          component: ExampleMenuComponent(
            content: .init(
              title: "Pull To Refresh",
              subtitle: "System UIRefreshControl based refresh.",
              badge: "System",
              tintColor: .systemBlue
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.navigationController?.pushViewController(PullToRefreshExampleViewController(), animated: true)
        }

        Row(
          id: "pull-to-refresh-activity",
          component: ExampleMenuComponent(
            content: .init(
              title: "Pull To Refresh Activity",
              subtitle: "Custom title, color, font, and activity indicator.",
              badge: "Activity",
              tintColor: .systemGreen
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.navigationController?.pushViewController(PullToRefreshCustomActivityIndicatorExampleViewController(), animated: true)
        }

        Row(
          id: "pull-to-refresh-image",
          component: ExampleMenuComponent(
            content: .init(
              title: "Pull To Refresh Image",
              subtitle: "Use an SF Symbol as the refresh indicator.",
              badge: "Image",
              tintColor: .systemOrange
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.navigationController?.pushViewController(PullToRefreshCustomImageIndicatorExampleViewController(), animated: true)
        }

        Row(
          id: "pull-to-refresh-legacy",
          component: ExampleMenuComponent(
            content: .init(
              title: "Pull To Refresh Legacy",
              subtitle: "Use the completion-based refresh handler overload.",
              badge: "Legacy",
              tintColor: .systemRed
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.navigationController?.pushViewController(PullToRefreshLegacyCompletionExampleViewController(), animated: true)
        }

        Row(
          id: "pull-to-refresh-custom-view",
          component: ExampleMenuComponent(
            content: .init(
              title: "Pull To Refresh View",
              subtitle: "Provide a fully custom UIView as the indicator.",
              badge: "View",
              tintColor: .systemPurple
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.navigationController?.pushViewController(PullToRefreshCustomViewIndicatorExampleViewController(), animated: true)
        }

        Row(
          id: "prefetch",
          component: ExampleMenuComponent(
            content: .init(
              title: "Prefetch + Kingfisher",
              subtitle: "Prefetch images before they appear on screen and reuse Kingfisher cache.",
              badge: "Performance",
              tintColor: .systemPurple
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.navigationController?.pushViewController(PrefetchExampleViewController(), animated: true)
        }

        Row(
          id: "header-footer",
          component: ExampleMenuComponent(
            content: .init(
              title: "Header & Footer",
              subtitle: "Render section supplementary views with the same component model.",
              badge: "Layout",
              tintColor: .systemTeal
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.navigationController?.pushViewController(HeaderFooterExampleViewController(), animated: true)
        }

        Row(
          id: "header-footer-dsl",
          component: ExampleMenuComponent(
            content: .init(
              title: "Header & Footer DSL",
              subtitle: "Write rows first, then attach header and footer trailing closures.",
              badge: "DSL",
              tintColor: .systemIndigo
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.navigationController?.pushViewController(HeaderFooterDSLExampleViewController(), animated: true)
        }

        Row(
          id: "component-height",
          component: ExampleMenuComponent(
            content: .init(
              title: "Component Height",
              subtitle: "Compare automatic self-sizing rows with component-defined heights.",
              badge: "Height",
              tintColor: .systemBrown
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.navigationController?.pushViewController(ComponentHeightExampleViewController(), animated: true)
        }

        Row(
          id: "swiftui-carbon-list",
          component: ExampleMenuComponent(
            content: .init(
              title: "SwiftUI CarbonList",
              subtitle: "Use the same List DSL directly from a SwiftUI screen.",
              badge: "SwiftUI",
              tintColor: .systemCyan
            )
          )
        )
        .onSelect { [weak self] _ in
          let viewController = UIHostingController(rootView: SwiftUICarbonListExampleView())
          self?.navigationController?.pushViewController(viewController, animated: true)
        }

        Row(
          id: "korean-complete",
          component: ExampleMenuComponent(
            content: .init(
              title: "한글 종합 예제",
              subtitle: "한 화면에서 diff, Content, 이벤트, 레이아웃, 무한 스크롤을 모두 확인합니다.",
              badge: "Korean",
              tintColor: .systemPink
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.navigationController?.pushViewController(KoreanCompleteExampleViewController(), animated: true)
        }

        Row(
          id: "orthogonal-section",
          component: ExampleMenuComponent(
            content: .init(
              title: "Orthogonal Section",
              subtitle: "Scroll cards horizontally inside a vertical feed.",
              badge: "Carousel",
              tintColor: .systemRed
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.navigationController?.pushViewController(OrthogonalSectionExampleViewController(), animated: true)
        }

        Row(
          id: "practice",
          component: ExampleMenuComponent(
            content: .init(
              title: "컴포넌트 예제",
              subtitle: "컴포넌트 구현 예제입니다.",
              badge: "Component",
              tintColor: .systemMint
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.navigationController?
            .pushViewController(
              StudyVC(),
              animated: true
            )
        }
      }
      .layout(.vertical(spacing: 10))
      .contentInsets(.init(top: 16, leading: 0, bottom: 16, trailing: 0))
    }
  }
}

private struct ExampleMenuComponent: ListComponent {
  struct Content: Equatable {
    let title: String
    let subtitle: String
    let badge: String
    let tintColor: UIColor
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> ExampleMenuView {
    ExampleMenuView()
  }

  func updateView(_ view: ExampleMenuView, context: ListComponentContext<Void>) {
    view.configure(
      title: content.title,
      subtitle: content.subtitle,
      badge: content.badge,
      tintColor: content.tintColor
    )
  }
}

private final class ExampleMenuView: UIView {
  private let containerView = UIView()
  private let badgeLabel = UILabel()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))

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
    backgroundColor = .clear

    containerView.backgroundColor = .secondarySystemGroupedBackground
    containerView.layer.cornerRadius = 8
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

    chevronImageView.tintColor = .tertiaryLabel
    chevronImageView.contentMode = .scaleAspectFit
    chevronImageView.translatesAutoresizingMaskIntoConstraints = false

    addSubview(containerView)
    containerView.addSubview(badgeLabel)
    containerView.addSubview(titleLabel)
    containerView.addSubview(subtitleLabel)
    containerView.addSubview(chevronImageView)

    let subtitleBottomConstraint = subtitleLabel.bottomAnchor.constraint(
      equalTo: containerView.bottomAnchor,
      constant: -16
    )
    subtitleBottomConstraint.priority = .defaultHigh

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

      badgeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      badgeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      badgeLabel.heightAnchor.constraint(equalToConstant: 24),
      badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),

      titleLabel.topAnchor.constraint(equalTo: badgeLabel.bottomAnchor, constant: 10),
      titleLabel.leadingAnchor.constraint(equalTo: badgeLabel.leadingAnchor),
      titleLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -12),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
      subtitleBottomConstraint,

      chevronImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
      chevronImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
      chevronImageView.widthAnchor.constraint(equalToConstant: 12),
      chevronImageView.heightAnchor.constraint(equalToConstant: 20)
    ])
  }
}
