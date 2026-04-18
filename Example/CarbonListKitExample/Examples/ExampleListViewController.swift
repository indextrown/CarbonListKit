import CarbonListKit
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
            viewModel: .init(
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
            viewModel: .init(
              title: "Entity to ViewModel",
              subtitle: "Keep domain entities separate from component view models.",
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
            viewModel: .init(
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
          id: "prefetch",
          component: ExampleMenuComponent(
            viewModel: .init(
              title: "Prefetch",
              subtitle: "Prefetch images before they appear on screen.",
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
            viewModel: .init(
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
            viewModel: .init(
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
          id: "korean-complete",
          component: ExampleMenuComponent(
            viewModel: .init(
              title: "한글 종합 예제",
              subtitle: "한 화면에서 diff, ViewModel, 이벤트, 레이아웃, 무한 스크롤을 모두 확인합니다.",
              badge: "Korean",
              tintColor: .systemPink
            )
          )
        )
        .onSelect { [weak self] _ in
          self?.navigationController?.pushViewController(KoreanCompleteExampleViewController(), animated: true)
        }
        
        Row(
          id: "practice",
          component: ExampleMenuComponent(
            viewModel: .init(
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
  struct ViewModel: Equatable {
    let title: String
    let subtitle: String
    let badge: String
    let tintColor: UIColor
  }

  let viewModel: ViewModel

  func makeView(context: ListComponentContext<Void>) -> ExampleMenuView {
    ExampleMenuView()
  }

  func updateView(_ view: ExampleMenuView, context: ListComponentContext<Void>) {
    view.configure(
      title: viewModel.title,
      subtitle: viewModel.subtitle,
      badge: viewModel.badge,
      tintColor: viewModel.tintColor
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
      subtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),

      chevronImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
      chevronImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
      chevronImageView.widthAnchor.constraint(equalToConstant: 12),
      chevronImageView.heightAnchor.constraint(equalToConstant: 20)
    ])
  }
}
