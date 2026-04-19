import CarbonListKit
import UIKit

final class KoreanCompleteExampleViewController: UIViewController {
  private enum DemoUpdateStrategy: String, CaseIterable {
    case animated
    case nonAnimated
    case reloadData

    var title: String {
      switch self {
      case .animated:
        return "애니메이션"
      case .nonAnimated:
        return "애니메이션 끄기"
      case .reloadData:
        return "전체 새로고침"
      }
    }

    var subtitle: String {
      switch self {
      case .animated:
        return "DifferenceKit 변경 사항을 자연스럽게 반영합니다."
      case .nonAnimated:
        return "동일한 diff 경로를 애니메이션 없이 적용합니다."
      case .reloadData:
        return "UICollectionView를 통째로 다시 그립니다."
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

  private enum DemoAction: String, CaseIterable {
    case add
    case shuffle
    case update

    var title: String {
      switch self {
      case .add:
        return "동네 소식 추가"
      case .shuffle:
        return "목록 섞기"
      case .update:
        return "첫 글 수정"
      }
    }

    var subtitle: String {
      switch self {
      case .add:
        return "새 Row를 맨 위에 삽입하고 diff 업데이트를 확인합니다."
      case .shuffle:
        return "같은 id를 유지한 채 Row 이동 애니메이션을 확인합니다."
      case .update:
        return "id는 그대로 두고 Content 내용만 바꿉니다."
      }
    }

    var tintColor: UIColor {
      switch self {
      case .add:
        return .systemGreen
      case .shuffle:
        return .systemPurple
      case .update:
        return .systemOrange
      }
    }
  }

  private let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewLayout()
  )

  private lazy var adapter = ListAdapter(collectionView: collectionView)
  private var posts = KoreanPost.samplePosts
  private var selectedUpdateStrategy: DemoUpdateStrategy = .animated
  private var generatedPostCount = 0
  private var revisionCount = 0
  private var eventCount = 0
  private var isLoadingNextPage = false

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "한글 종합 예제"
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
    adapter.apply(
      List {
        Section(id: "intro") {
          Row(
            id: "intro-card",
            component: KoreanInfoComponent(
              content: .init(
                title: "CarbonListKit 한글 종합 예제",
                message: "Section, Row, Cell 별칭, Content 매핑, 이벤트, 업데이트 전략, 세로/그리드/커스텀 레이아웃, 무한 스크롤을 한 화면에서 확인합니다."
              )
            )
          )
          .willDisplay { [weak self] _ in
            self?.recordEvent("intro willDisplay")
          }
          .onEndDisplay { [weak self] _ in
            self?.recordEvent("intro didEndDisplay")
          }
        }
        .layout(.vertical(spacing: 12))
        .contentInsets(.init(top: 16, leading: 0, bottom: 12, trailing: 0))

        Section(id: "update-strategy") {
          for strategy in DemoUpdateStrategy.allCases {
            Row(
              id: strategy.rawValue,
              component: KoreanChoiceComponent(
                content: .init(
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

        Section(id: "actions") {
          for action in DemoAction.allCases {
            Row(
              id: action.rawValue,
              component: KoreanActionComponent(
                content: .init(
                  title: action.title,
                  subtitle: action.subtitle,
                  tintColor: action.tintColor
                )
              )
            )
            .onSelect { [weak self] _ in
              self?.perform(action)
            }
          }
        }
        .layout(.vertical(spacing: 10))
        .contentInsets(.init(top: 0, leading: 0, bottom: 12, trailing: 0))

        Section(id: "feature-grid") {
          Cell(
            id: "cell-alias",
            component: KoreanBadgeComponent(
              content: .init(title: "Cell", subtitle: "Row 별칭")
            )
          )

          Cell(
            id: "section-insets",
            component: KoreanBadgeComponent(
              content: .init(title: "Insets", subtitle: "섹션 여백")
            )
          )

          Cell(
            id: "grid-layout",
            component: KoreanBadgeComponent(
              content: .init(title: "Grid", subtitle: "2열 배치")
            )
          )

          Cell(
            id: "events",
            component: KoreanBadgeComponent(
              content: .init(title: "Events", subtitle: "선택/표시")
            )
          )
        }
        .layout(.grid(columns: 2, itemSpacing: 10, lineSpacing: 10))
        .contentInsets(.init(top: 0, leading: 16, bottom: 12, trailing: 16))

        Section(id: "custom-layout") {
          Row(
            id: "custom-note",
            component: KoreanInfoComponent(
              content: .init(
                title: "커스텀 레이아웃",
                message: "이 섹션은 `.layout(.custom { ... })`로 직접 만든 NSCollectionLayoutSection을 사용합니다."
              )
            )
          )
        }
        .layout(.custom { context in
          KoreanCompleteExampleViewController.makeCustomLayoutSection(context: context)
        })
        .contentInsets(.init(top: 0, leading: 0, bottom: 12, trailing: 0))

        Section(id: "posts") {
          for post in posts {
            Row(
              id: post.id,
              component: KoreanPostComponent(content: .init(post: post))
            )
            .onSelect { [weak self] context in
              self?.toggleBookmark(postID: post.id, indexPath: context.indexPath)
            }
            .onDisplay { [weak self] _ in
              self?.recordEvent("post displayed: \(post.id)")
            }
            .onEndDisplay { [weak self] _ in
              self?.recordEvent("post ended display: \(post.id)")
            }
          }
        }
        .layout(.vertical(spacing: 10))
        .contentInsets(.init(top: 0, leading: 0, bottom: 12, trailing: 0))

        Section(id: "footer") {
          Row(
            id: "footer",
            component: KoreanFooterComponent(
              content: .init(
                title: isLoadingNextPage ? "다음 동네 소식을 불러오는 중..." : "아래로 더 내려보세요",
                subtitle: "현재 \(posts.count)개"
              )
            )
          )
        }
        .layout(.vertical())
        .contentInsets(.init(top: 0, leading: 0, bottom: 24, trailing: 0))
      }
      .onReachEnd(offsetFromEnd: .relativeToContainerSize(multiplier: 1.0)) { [weak self] _ in
        self?.appendNextPage()
      },
      updateStrategy: selectedUpdateStrategy.updateStrategy
    )
  }

  private static func makeCustomLayoutSection(context: ListLayoutContext) -> NSCollectionLayoutSection {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .estimated(44)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
    let section = NSCollectionLayoutSection(group: group)
    section.interGroupSpacing = CGFloat(8 + context.sectionIndex)
    return section
  }

  private func selectUpdateStrategy(_ strategy: DemoUpdateStrategy) {
    selectedUpdateStrategy = strategy
    posts = posts.reversed()
    render()
  }

  private func perform(_ action: DemoAction) {
    switch action {
    case .add:
      addPost()
    case .shuffle:
      posts.shuffle()
      render()
    case .update:
      updateFirstPost()
    }
  }

  private func addPost() {
    generatedPostCount += 1
    posts.insert(
      .init(
        id: "generated-\(generatedPostCount)",
        title: "새로 들어온 동네 소식 \(generatedPostCount)",
        neighborhood: "성수동",
        body: "방금 추가된 Row입니다. 같은 선언형 목록에서 삽입 애니메이션을 확인할 수 있습니다.",
        tag: "새소식",
        isBookmarked: false
      ),
      at: 0
    )
    render()
  }

  private func updateFirstPost() {
    guard posts.isEmpty == false else {
      return
    }

    revisionCount += 1
    posts[0] = posts[0].updating(
      body: "본문이 \(revisionCount)번 수정되었습니다. id는 유지되어 content diff만 발생합니다."
    )
    render()
  }

  private func toggleBookmark(postID: KoreanPost.ID, indexPath: IndexPath) {
    posts = posts.map { post in
      guard post.id == postID else {
        return post
      }

      return post.togglingBookmark()
    }
    recordEvent("selected row \(indexPath.item) in section \(indexPath.section)")
    render()
  }

  private func appendNextPage() {
    guard isLoadingNextPage == false else {
      return
    }

    isLoadingNextPage = true
    render()

    let startIndex = posts.count + 1
    let newPosts = (startIndex..<(startIndex + 6)).map(KoreanPost.generated)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
      guard let self else {
        return
      }

      self.posts.append(contentsOf: newPosts)
      self.isLoadingNextPage = false
      self.render()
    }
  }

  private func recordEvent(_ message: String) {
    eventCount += 1
    print("[CarbonListKit Korean Example] \(eventCount): \(message)")
  }
}

private struct KoreanPost: Identifiable, Equatable {
  let id: String
  let title: String
  let neighborhood: String
  let body: String
  let tag: String
  let isBookmarked: Bool

  func togglingBookmark() -> Self {
    .init(
      id: id,
      title: title,
      neighborhood: neighborhood,
      body: body,
      tag: tag,
      isBookmarked: !isBookmarked
    )
  }

  func updating(body: String) -> Self {
    .init(
      id: id,
      title: title,
      neighborhood: neighborhood,
      body: body,
      tag: tag,
      isBookmarked: isBookmarked
    )
  }

  static func generated(index: Int) -> Self {
    let neighborhoods = ["망원동", "연남동", "합정동", "문래동", "후암동", "옥수동"]
    let tags = ["나눔", "모임", "맛집", "질문", "소식", "산책"]

    return .init(
      id: "page-\(index)",
      title: "페이지로 불러온 한글 항목 \(index)",
      neighborhood: neighborhoods[index % neighborhoods.count],
      body: "목록 끝에 가까워지면 onReachEnd가 호출되어 새 항목을 붙입니다.",
      tag: tags[index % tags.count],
      isBookmarked: index.isMultiple(of: 3)
    )
  }

  static let samplePosts: [KoreanPost] = [
    .init(
      id: "market",
      title: "주말 플리마켓 같이 구경해요",
      neighborhood: "망원동",
      body: "오전 11시부터 작은 브랜드와 동네 가게들이 모입니다. 관심 있는 분들은 북마크해 두세요.",
      tag: "모임",
      isBookmarked: false
    ),
    .init(
      id: "coffee",
      title: "새로 생긴 로스터리 후기",
      neighborhood: "연남동",
      body: "산미가 선명한 원두가 좋았고 좌석 간격도 넓었습니다. 재방문 의사 있어요.",
      tag: "맛집",
      isBookmarked: true
    ),
    .init(
      id: "walk",
      title: "저녁 산책길 조명 공사 완료",
      neighborhood: "한남동",
      body: "어두웠던 골목 조명이 교체되어 밤에도 훨씬 편하게 걸을 수 있습니다.",
      tag: "소식",
      isBookmarked: false
    ),
    .init(
      id: "share",
      title: "아이 책장 무료 나눔합니다",
      neighborhood: "상수동",
      body: "사용감은 있지만 튼튼합니다. 이번 주 안에 가져가실 분을 찾습니다.",
      tag: "나눔",
      isBookmarked: false
    )
  ]
}

private struct KoreanInfoComponent: ListComponent {
  struct Content: Equatable {
    let title: String
    let message: String
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> KoreanInfoView {
    KoreanInfoView()
  }

  func updateView(_ view: KoreanInfoView, context: ListComponentContext<Void>) {
    view.configure(title: content.title, message: content.message)
  }
}

private final class KoreanInfoView: UIView {
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

private struct KoreanChoiceComponent: ListComponent {
  struct Content: Equatable {
    let title: String
    let subtitle: String
    let isSelected: Bool
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> KoreanChoiceView {
    KoreanChoiceView()
  }

  func updateView(_ view: KoreanChoiceView, context: ListComponentContext<Void>) {
    view.configure(
      title: content.title,
      subtitle: content.subtitle,
      isSelected: content.isSelected
    )
  }
}

private final class KoreanChoiceView: UIView {
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

private struct KoreanActionComponent: ListComponent {
  struct Content: Equatable {
    let title: String
    let subtitle: String
    let tintColor: UIColor
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> KoreanActionView {
    KoreanActionView()
  }

  func updateView(_ view: KoreanActionView, context: ListComponentContext<Void>) {
    view.configure(
      title: content.title,
      subtitle: content.subtitle,
      tintColor: content.tintColor
    )
  }
}

private final class KoreanActionView: UIView {
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

private struct KoreanBadgeComponent: ListComponent {
  struct Content: Equatable {
    let title: String
    let subtitle: String
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> KoreanBadgeView {
    KoreanBadgeView()
  }

  func updateView(_ view: KoreanBadgeView, context: ListComponentContext<Void>) {
    view.configure(title: content.title, subtitle: content.subtitle)
  }
}

private final class KoreanBadgeView: UIView {
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
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 0
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.textAlignment = .center
    subtitleLabel.numberOfLines = 0
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

private struct KoreanPostComponent: ListComponent {
  struct Content: Equatable {
    let title: String
    let metadata: String
    let body: String
    let bookmarkTitle: String
    let bookmarkColor: UIColor

    init(post: KoreanPost) {
      self.title = post.title
      self.metadata = "\(post.neighborhood) · \(post.tag)"
      self.body = post.body
      self.bookmarkTitle = post.isBookmarked ? "저장됨" : "저장"
      self.bookmarkColor = post.isBookmarked ? .systemGreen : .systemGray
    }
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> KoreanPostView {
    KoreanPostView()
  }

  func updateView(_ view: KoreanPostView, context: ListComponentContext<Void>) {
    view.configure(
      title: content.title,
      metadata: content.metadata,
      body: content.body,
      bookmarkTitle: content.bookmarkTitle,
      bookmarkColor: content.bookmarkColor
    )
  }
}

private final class KoreanPostView: UIView {
  private let containerView = UIView()
  private let titleLabel = UILabel()
  private let metadataLabel = UILabel()
  private let bodyLabel = UILabel()
  private let bookmarkLabel = UILabel()

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
    body: String,
    bookmarkTitle: String,
    bookmarkColor: UIColor
  ) {
    titleLabel.text = title
    metadataLabel.text = metadata
    bodyLabel.text = body
    bookmarkLabel.text = bookmarkTitle
    bookmarkLabel.textColor = bookmarkColor
    bookmarkLabel.backgroundColor = bookmarkColor.withAlphaComponent(0.12)
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

    bodyLabel.font = .preferredFont(forTextStyle: .body)
    bodyLabel.textColor = .label
    bodyLabel.numberOfLines = 0
    bodyLabel.translatesAutoresizingMaskIntoConstraints = false

    bookmarkLabel.font = .preferredFont(forTextStyle: .caption1)
    bookmarkLabel.textAlignment = .center
    bookmarkLabel.layer.cornerRadius = 6
    bookmarkLabel.layer.masksToBounds = true
    bookmarkLabel.translatesAutoresizingMaskIntoConstraints = false

    addSubview(containerView)
    containerView.addSubview(titleLabel)
    containerView.addSubview(metadataLabel)
    containerView.addSubview(bodyLabel)
    containerView.addSubview(bookmarkLabel)

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

      titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: bookmarkLabel.leadingAnchor, constant: -12),

      metadataLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
      metadataLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      metadataLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

      bodyLabel.topAnchor.constraint(equalTo: metadataLabel.bottomAnchor, constant: 10),
      bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      bodyLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
      bodyLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),

      bookmarkLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      bookmarkLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
      bookmarkLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 58),
      bookmarkLabel.heightAnchor.constraint(equalToConstant: 24)
    ])
  }
}

private struct KoreanFooterComponent: ListComponent {
  struct Content: Equatable {
    let title: String
    let subtitle: String
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> KoreanFooterView {
    KoreanFooterView()
  }

  func updateView(_ view: KoreanFooterView, context: ListComponentContext<Void>) {
    view.configure(title: content.title, subtitle: content.subtitle)
  }
}

private final class KoreanFooterView: UIView {
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

    addSubview(titleLabel)
    addSubview(subtitleLabel)

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
      subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
    ])
  }
}
