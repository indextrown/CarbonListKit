import CarbonListKit
import SwiftUI
import UIKit

struct SwiftUICarbonListExampleView: View {
  @State private var items = SwiftUIExampleItem.samples

  var body: some View {
    VStack(spacing: 0) {
      controlBar

      CarbonList(updateStrategy: .animated, backgroundColor: .systemGroupedBackground) {
        Section(id: "summary") {
          Row(
            id: "summary",
            component: SwiftUIExampleSummaryComponent(
              viewModel: .init(
                title: "SwiftUI + CarbonList",
                subtitle: "SwiftUI state changes rebuild the List DSL. The UIKit adapter still handles diffing, layout, and rendering."
              )
            )
          )
        } footer: {
          Footer(
            id: "summary-footer",
            component: SwiftUIExampleFooterComponent(
              viewModel: .init(text: "Tap a row to favorite it. Use the buttons above to mutate SwiftUI state.")
            )
          )
        }
        .layout(.vertical(spacing: 10))
        .contentInsets(.init(top: 16, leading: 0, bottom: 16, trailing: 0))
        .sectionSpacing(10)

        Section(id: "items") {
          for item in items {
            Row(
              id: item.id,
              component: SwiftUIExampleItemComponent(viewModel: .init(item: item))
            )
            .onSelect { _ in
              toggleFavorite(itemID: item.id)
            }
          }
        } header: {
          Header(
            id: "items-header",
            component: SwiftUIExampleHeaderComponent(
              viewModel: .init(title: "SwiftUI state", subtitle: "\(items.count) rows")
            )
          )
        }
        .layout(.vertical(spacing: 10))
        .contentInsets(.init(top: 0, leading: 0, bottom: 20, trailing: 0))
      }
    }
    .background(Color(uiColor: .systemGroupedBackground))
    .navigationTitle("SwiftUI CarbonList")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var controlBar: some View {
    HStack(spacing: 8) {
      Button("Add") {
        addItem()
      }

      Button("Shuffle") {
        shuffleItems()
      }

      Button("Reset") {
        items = SwiftUIExampleItem.samples
      }
    }
    .buttonStyle(.bordered)
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color(uiColor: .systemBackground))
  }

  private func addItem() {
    let nextNumber = items.count + 1
    items.insert(
      SwiftUIExampleItem(
        id: UUID(),
        title: "SwiftUI row \(nextNumber)",
        subtitle: "Inserted from @State",
        tintColor: [.systemBlue, .systemGreen, .systemOrange, .systemPink, .systemTeal].randomElement() ?? .systemBlue,
        isFavorite: false
      ),
      at: 0
    )
  }

  private func toggleFavorite(itemID: UUID) {
    items = items.map { item in
      guard item.id == itemID else {
        return item
      }

      var copy = item
      copy.isFavorite.toggle()
      return copy
    }
  }

  private func shuffleItems() {
    guard items.count > 1 else {
      return
    }

    let currentIDs = items.map(\.id)
    var shuffledItems = items.shuffled()

    if shuffledItems.map(\.id) == currentIDs {
      shuffledItems.append(shuffledItems.removeFirst())
    }

    items = shuffledItems
  }
}

private struct SwiftUIExampleItem: Identifiable, Equatable {
  let id: UUID
  let title: String
  let subtitle: String
  let tintColor: UIColor
  var isFavorite: Bool

  static let samples: [Self] = [
    .init(
      id: UUID(uuidString: "7A1965F0-E1AB-4D82-9B06-73A4E59D9D91")!,
      title: "Declarative data",
      subtitle: "Rows are rebuilt from SwiftUI state.",
      tintColor: .systemBlue,
      isFavorite: false
    ),
    .init(
      id: UUID(uuidString: "9E8B04F7-7FB9-4BF2-8CF6-C31335083A3A")!,
      title: "UIKit rendering",
      subtitle: "Each row is still a ListComponent-backed UIView.",
      tintColor: .systemGreen,
      isFavorite: true
    ),
    .init(
      id: UUID(uuidString: "1C7ED5F7-296A-4D8B-84BF-5B0E19875B4F")!,
      title: "Animated diff",
      subtitle: "The same ListAdapter applies changes under the hood.",
      tintColor: .systemOrange,
      isFavorite: false
    )
  ]
}

private struct SwiftUIExampleSummaryComponent: ListComponent {
  struct ViewModel: Equatable {
    let title: String
    let subtitle: String
  }

  let viewModel: ViewModel

  func makeView(context: ListComponentContext<Void>) -> SwiftUIExampleSummaryView {
    SwiftUIExampleSummaryView()
  }

  func updateView(_ view: SwiftUIExampleSummaryView, context: ListComponentContext<Void>) {
    view.configure(title: viewModel.title, subtitle: viewModel.subtitle)
  }
}

private struct SwiftUIExampleItemComponent: ListComponent {
  struct ViewModel: Equatable {
    let title: String
    let subtitle: String
    let tintColor: UIColor
    let isFavorite: Bool

    init(item: SwiftUIExampleItem) {
      title = item.title
      subtitle = item.subtitle
      tintColor = item.tintColor
      isFavorite = item.isFavorite
    }
  }

  let viewModel: ViewModel

  func makeView(context: ListComponentContext<Void>) -> SwiftUIExampleItemView {
    SwiftUIExampleItemView()
  }

  func updateView(_ view: SwiftUIExampleItemView, context: ListComponentContext<Void>) {
    view.configure(
      title: viewModel.title,
      subtitle: viewModel.subtitle,
      tintColor: viewModel.tintColor,
      isFavorite: viewModel.isFavorite
    )
  }
}

private struct SwiftUIExampleHeaderComponent: ListComponent {
  struct ViewModel: Equatable {
    let title: String
    let subtitle: String
  }

  let viewModel: ViewModel

  func makeView(context: ListComponentContext<Void>) -> SwiftUIExampleHeaderView {
    SwiftUIExampleHeaderView()
  }

  func updateView(_ view: SwiftUIExampleHeaderView, context: ListComponentContext<Void>) {
    view.configure(title: viewModel.title, subtitle: viewModel.subtitle)
  }
}

private struct SwiftUIExampleFooterComponent: ListComponent {
  struct ViewModel: Equatable {
    let text: String
  }

  let viewModel: ViewModel

  func makeView(context: ListComponentContext<Void>) -> SwiftUIExampleFooterView {
    SwiftUIExampleFooterView()
  }

  func updateView(_ view: SwiftUIExampleFooterView, context: ListComponentContext<Void>) {
    view.configure(text: viewModel.text)
  }
}

private final class SwiftUIExampleSummaryView: UIView {
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

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .label

    subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0

    let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    stackView.axis = .vertical
    stackView.spacing = 6

    addSubview(containerView)
    containerView.addSubview(stackView)
    containerView.translatesAutoresizingMaskIntoConstraints = false
    stackView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
      stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
      stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
      stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
    ])
  }
}

private final class SwiftUIExampleItemView: UIView {
  private let containerView = UIView()
  private let iconView = UIView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let favoriteLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(title: String, subtitle: String, tintColor: UIColor, isFavorite: Bool) {
    titleLabel.text = title
    subtitleLabel.text = subtitle
    iconView.backgroundColor = tintColor
    favoriteLabel.text = isFavorite ? "Favorite" : "Tap to favorite"
    favoriteLabel.textColor = isFavorite ? .systemPink : .secondaryLabel
    favoriteLabel.backgroundColor = isFavorite
      ? UIColor.systemPink.withAlphaComponent(0.12)
      : UIColor.tertiarySystemFill
  }

  private func setup() {
    backgroundColor = .clear
    containerView.backgroundColor = .secondarySystemGroupedBackground
    containerView.layer.cornerRadius = 8

    iconView.layer.cornerRadius = 7
    iconView.widthAnchor.constraint(equalToConstant: 14).isActive = true
    iconView.heightAnchor.constraint(equalToConstant: 14).isActive = true

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .label

    subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0

    favoriteLabel.font = .preferredFont(forTextStyle: .caption1)
    favoriteLabel.textAlignment = .center
    favoriteLabel.layer.cornerRadius = 6
    favoriteLabel.layer.masksToBounds = true
    favoriteLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

    let textStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    textStackView.axis = .vertical
    textStackView.spacing = 4

    let rowStackView = UIStackView(arrangedSubviews: [iconView, textStackView, favoriteLabel])
    rowStackView.alignment = .center
    rowStackView.spacing = 12

    addSubview(containerView)
    containerView.addSubview(rowStackView)
    containerView.translatesAutoresizingMaskIntoConstraints = false
    rowStackView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
      rowStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
      rowStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      rowStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
      rowStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -14),
      favoriteLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 92),
      favoriteLabel.heightAnchor.constraint(equalToConstant: 28)
    ])
  }
}

private final class SwiftUIExampleHeaderView: UIView {
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
    backgroundColor = .systemGroupedBackground

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .label

    subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
    subtitleLabel.textColor = .secondaryLabel

    let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    stackView.axis = .vertical
    stackView.spacing = 2

    addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
    ])
  }
}

private final class SwiftUIExampleFooterView: UIView {
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
    backgroundColor = .systemGroupedBackground
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0

    addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
      label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
    ])
  }
}
