import CarbonListKit
import Kingfisher
import UIKit

final class PrefetchExampleViewController: UIViewController {
  private enum Const {
    static let pageSize = 24
    static let maximumItemCount = 3200
  }

  private let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewLayout()
  )

  private let imagePrefetcher = KingfisherImagePrefetcher()

  private lazy var adapter = ListAdapter(
    collectionView: collectionView,
    prefetchingPlugins: [RemoteImagePrefetchingPlugin(remoteImagePrefetcher: imagePrefetcher)]
  )

  private var images: [ImageItem] = []
  private var isLoadingNextPage = false

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Prefetch + Kingfisher"
    view.backgroundColor = .systemBackground
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Clear",
      style: .plain,
      target: self,
      action: #selector(clearCacheTapped)
    )
    setupCollectionView()
    appendNextPage()
  }

  private func setupCollectionView() {
    collectionView.backgroundColor = .systemGroupedBackground
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(collectionView)

    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }

  private func appendNextPage() {
    guard isLoadingNextPage == false,
          images.count < Const.maximumItemCount else {
      return
    }

    isLoadingNextPage = true

    let nextStartIndex = images.count + 1
    let nextEndIndex = min(images.count + Const.pageSize, Const.maximumItemCount)
    let newImages = (nextStartIndex...nextEndIndex).map { index in
      ImageItem(
        id: "image_\(index)",
        imageURL: URL(string: "https://picsum.photos/seed/\(index)/300/200")!,
        title: "이미지 \(index)"
      )
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
      guard let self else {
        return
      }

      self.images.append(contentsOf: newImages)
      self.isLoadingNextPage = false
      self.render()
    }
  }

  private func render() {
    let canLoadMore = images.count < Const.maximumItemCount

    adapter.apply(
      List {
        Section(id: "images") {
          for image in images {
            Row(
              id: image.id,
              component: KingfisherImageComponent(content: .init(image: image))
            )
          }
        }
        .layout(.grid(columns: 4, itemSpacing: 8, lineSpacing: 8))
        .contentInsets(.init(top: 16, leading: 16, bottom: 16, trailing: 16))

        Section(id: "footer") {
          Row(
            id: "footer",
            component: FooterComponent(
              content: .init(
                title: canLoadMore ? "Loading next page..." : "No more items",
                subtitle: "\(images.count) / \(Const.maximumItemCount) items"
              )
            )
          )
        }
        .layout(.vertical(spacing: 0))
        .contentInsets(.init(top: 0, leading: 16, bottom: 24, trailing: 16))
      }
      .onReachEnd(offsetFromEnd: .relativeToContainerSize(multiplier: 1.0)) { [weak self] _ in
        self?.appendNextPage()
      },
      updateStrategy: .animated
    )
  }

  @objc
  private func clearCacheTapped() {
    ImageCache.default.clearMemoryCache()
    ImageCache.default.clearDiskCache { [weak self] in
      DispatchQueue.main.async {
        guard let self else {
          return
        }

        let alert = UIAlertController(
          title: "Done",
          message: "Kingfisher memory and disk cache were cleared.",
          preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
      }
    }
  }
}

// MARK: - Models

struct ImageItem: Identifiable, Equatable {
  let id: String
  let imageURL: URL
  let title: String
}

// MARK: - Components

struct KingfisherImageComponent: ListComponent, ComponentRemoteImagePrefetchable {
  struct Content: Equatable {
    let imageURL: URL
    let title: String

    init(image: ImageItem) {
      self.imageURL = image.imageURL
      self.title = image.title
    }
  }

  let content: Content

  func height(context: ListComponentHeightContext) -> ListComponentHeight {
    .square
  }

  var remoteImageURLs: [URL] {
    [content.imageURL]
  }

  func makeView(context: ListComponentContext<Void>) -> KingfisherImageCellView {
    KingfisherImageCellView()
  }

  func updateView(_ view: KingfisherImageCellView, context: ListComponentContext<Void>) {
    view.configure(title: content.title, imageURL: content.imageURL)
  }
}

// MARK: - Views

final class KingfisherImageCellView: UIView {
  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.backgroundColor = .systemGray5
    return imageView
  }()

  private let titleLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 14, weight: .medium)
    label.textColor = .label
    label.textAlignment = .center
    label.numberOfLines = 1
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupView() {
    backgroundColor = .systemBackground
    layer.cornerRadius = 8
    layer.borderWidth = 1
    layer.borderColor = UIColor.systemGray4.cgColor

    addSubview(imageView)
    addSubview(titleLabel)

    imageView.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
      imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
      imageView.heightAnchor.constraint(equalToConstant: 40),

      titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
    ])
  }

  func configure(title: String, imageURL: URL) {
    imageView.kf.cancelDownloadTask()
    imageView.image = nil
    imageView.backgroundColor = .systemGray4
    titleLabel.text = title

    imageView.kf.setImage(
      with: imageURL,
      placeholder: nil,
      options: [
        .transition(.fade(0.2))
      ]
    )
  }
}

private struct FooterComponent: ListComponent {
  struct Content: Equatable {
    let title: String
    let subtitle: String
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> FooterView {
    FooterView()
  }

  func updateView(_ view: FooterView, context: ListComponentContext<Void>) {
    view.configure(title: content.title, subtitle: content.subtitle)
  }
}

private final class FooterView: UIView {
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
    containerView.layer.cornerRadius = 10
    containerView.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .label
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
    subtitleLabel.textColor = .secondaryLabel
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
      titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
      subtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
    ])
  }
}

// MARK: - Kingfisher Prefetcher
final class KingfisherImagePrefetcher: RemoteImagePrefetching {
  private var prefetchers: [UUID: ImagePrefetcher] = [:]

  func prefetchImage(url: URL) -> UUID? {
    let uuid = UUID()
    let prefetcher = ImagePrefetcher(urls: [url], completionHandler: { [weak self] _, _, _ in
      self?.prefetchers.removeValue(forKey: uuid)
    })

    prefetchers[uuid] = prefetcher
    prefetcher.start()

    return uuid
  }

  func cancelTask(uuid: UUID) {
    prefetchers[uuid]?.stop()
    prefetchers.removeValue(forKey: uuid)
  }
}
