import CarbonListKit
import UIKit

final class HeaderFooterExampleViewController: UIViewController {
  // CarbonListKit은 UICollectionView를 직접 소유하지 않고,
  // 사용자가 만든 collectionView에 ListAdapter를 붙여서 사용합니다.
  private let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewLayout()
  )

  private lazy var adapter = ListAdapter(collectionView: collectionView)

  // 예제에서 표시할 row 데이터입니다.
  // Update 버튼을 누르면 순서를 섞어서 diff update가 동작하는지 볼 수 있습니다.
  private var items = HeaderFooterItem.samples

  // footer의 viewModel과 layoutSize를 바꿔서 supplementary 업데이트를 보여줍니다.
  private var isCompactFooter = false

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Header & Footer"
    view.backgroundColor = .systemBackground
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Update",
      style: .plain,
      target: self,
      action: #selector(updateList)
    )
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
      // 첫 번째 섹션은 header, rows, footer를 모두 가진 예제입니다.
      Section {
        // Section 본문은 기존처럼 Row 목록으로 작성합니다.
        // header/footer는 rows에 포함되지 않으므로 마지막 cell로 흉내 내지 않아도 됩니다.
        for item in items {
          Row(
            id: item.id,
            component: HeaderFooterRowComponent(viewModel: .init(item: item))
          )
        }
      } header: {
        // Header는 SectionSupplementary의 typealias입니다.
        // Row처럼 id와 component를 가지지만, cell이 아니라 section header로 렌더링됩니다.
        Header(
          id: "main-header",
          component: HeaderFooterBannerComponent(
            viewModel: .init(
              title: "Featured",
              subtitle: "\(items.count) rows rendered between a real section header and footer.",
              style: .header
            )
          )
        )
      } footer: {
        // Footer도 Header와 같은 모델을 사용합니다.
        // 차이는 UICollectionView.elementKindSectionFooter 위치에 붙는다는 점뿐입니다.
        Footer(
          id: "main-footer",
          component: HeaderFooterBannerComponent(
            viewModel: .init(
              title: isCompactFooter ? "Footer updated" : "Footer",
              subtitle: "This view is a supplementary footer, not the last cell.",
              style: .footer
            )
          ),

          // supplementary view의 layoutSize를 지정할 수 있습니다.
          // estimated는 Auto Layout으로 실제 높이를 계산하고,
          // absolute는 고정 높이로 배치합니다.
          layoutSize: isCompactFooter ? .absolute(height: 64) : .estimated(height: 78)
        )
      }
      .layout(.vertical(spacing: 10))
      .contentInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
      .sectionSpacing(20)

      // 두 번째 섹션은 grid layout에서도 header가 동일하게 동작하는지 보여줍니다.
      Section {
        for number in 1...6 {
          Row(
            id: "grid-\(number)",
            component: HeaderFooterPillComponent(
              viewModel: .init(title: "Item \(number)")
            )
          )
        }
      } header: {
        Header(
          id: "grid-header",
          component: HeaderFooterBannerComponent(
            viewModel: .init(
              title: "Grid section",
              subtitle: "Headers work with grid layouts too.",
              style: .header
            )
          )
        )
      }
      .layout(.grid(columns: 2, itemSpacing: 20, lineSpacing: 10))
      .contentInsets(.init(top: 0, leading: 0, bottom: 24, trailing: 0))
    }
  }

  @objc private func updateList() {
    // rows 순서와 footer 상태를 동시에 바꿉니다.
    // rows는 DifferenceKit element diff로 업데이트되고,
    // footer 변경은 Section equality 변화로 section update에 반영됩니다.
    items.shuffle()
    isCompactFooter.toggle()
    render()
  }
}

@available(iOS 17.0, *)
#Preview {
  HeaderFooterExampleViewController()
}

// 예제용 domain model입니다.
// 실제 앱에서는 이 데이터가 서버 응답이나 DB 모델일 수 있습니다.
private struct HeaderFooterItem: Equatable, Identifiable {
  let id: Int
  let title: String
  let detail: String

  static let samples = [
    HeaderFooterItem(id: 1, title: "Reusable models", detail: "Header and footer use the same ListComponent protocol."),
    HeaderFooterItem(id: 2, title: "Diff friendly", detail: "Changing supplementary view models updates the owning section."),
    HeaderFooterItem(id: 3, title: "Estimated height", detail: "Auto Layout can drive supplementary view height."),
    HeaderFooterItem(id: 4, title: "Layout size", detail: "Use estimated or absolute height per header and footer.")
  ]
}

// header/footer에서 공통으로 쓰는 component입니다.
// ListComponent를 구현하면 cell, header, footer 어디에서든 같은 방식으로 재사용할 수 있습니다.
private struct HeaderFooterBannerComponent: ListComponent {
  // 같은 view를 header/footer에서 함께 쓰되 색상만 다르게 보여주기 위한 상태입니다.
  enum Style: Equatable {
    case header
    case footer
  }

  // ViewModel이 Equatable이라서 값이 바뀌면 CarbonListKit이 변경을 감지할 수 있습니다.
  struct ViewModel: Equatable {
    let title: String
    let subtitle: String
    let style: Style
  }

  let viewModel: ViewModel

  // component가 처음 렌더링될 때 view를 만듭니다.
  func makeView(context: ListComponentContext<Void>) -> HeaderFooterBannerView {
    HeaderFooterBannerView()
  }

  // apply/render 때마다 최신 ViewModel을 view에 반영합니다.
  func updateView(_ view: HeaderFooterBannerView, context: ListComponentContext<Void>) {
    view.configure(viewModel)
  }
}

// header/footer의 실제 UIView입니다.
// Auto Layout 제약으로 높이를 계산하므로 .estimated(height:)와 잘 맞습니다.
private final class HeaderFooterBannerView: UIView {
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

  func configure(_ viewModel: HeaderFooterBannerComponent.ViewModel) {
    titleLabel.text = viewModel.title
    subtitleLabel.text = viewModel.subtitle

    // 하나의 component/view를 header와 footer에서 재사용한다는 것을 보여주기 위한 스타일 분기입니다.
    switch viewModel.style {
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
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: 14),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
    ])
  }
}

// 본문 row에서 쓰는 component입니다.
private struct HeaderFooterRowComponent: ListComponent {
  struct ViewModel: Equatable {
    let title: String
    let detail: String

    // domain model을 화면에 바로 필요한 ViewModel 형태로 변환합니다.
    init(item: HeaderFooterItem) {
      self.title = item.title
      self.detail = item.detail
    }
  }

  let viewModel: ViewModel

  func makeView(context: ListComponentContext<Void>) -> HeaderFooterRowView {
    HeaderFooterRowView()
  }

  func updateView(_ view: HeaderFooterRowView, context: ListComponentContext<Void>) {
    view.configure(title: viewModel.title, detail: viewModel.detail)
  }
}

// 본문 row의 실제 UIView입니다.
private final class HeaderFooterRowView: UIView {
  private let titleLabel = UILabel()
  private let detailLabel = UILabel()
  private let stackView = UIStackView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(title: String, detail: String) {
    titleLabel.text = title
    detailLabel.text = detail
  }

  private func setup() {
    backgroundColor = .secondarySystemGroupedBackground
    layer.cornerRadius = 8

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.numberOfLines = 0

    detailLabel.font = .preferredFont(forTextStyle: .subheadline)
    detailLabel.textColor = .secondaryLabel
    detailLabel.numberOfLines = 0

    stackView.axis = .vertical
    stackView.spacing = 4
    stackView.translatesAutoresizingMaskIntoConstraints = false

    addSubview(stackView)
    stackView.addArrangedSubview(titleLabel)
    stackView.addArrangedSubview(detailLabel)

    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
    ])
  }
}

// grid 섹션 row에서 쓰는 작은 component입니다.
private struct HeaderFooterPillComponent: ListComponent {
  struct ViewModel: Equatable {
    let title: String
  }

  let viewModel: ViewModel

  func makeView(context: ListComponentContext<Void>) -> HeaderFooterPillView {
    HeaderFooterPillView()
  }

  func updateView(_ view: HeaderFooterPillView, context: ListComponentContext<Void>) {
    view.configure(title: viewModel.title)
  }
}

// grid item의 실제 UIView입니다.
private final class HeaderFooterPillView: UIView {
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
