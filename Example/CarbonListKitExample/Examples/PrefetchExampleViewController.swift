import CarbonListKit
import UIKit

final class PrefetchExampleViewController: UIViewController {
  private let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewLayout()
  )

  // 간단한 이미지 prefetcher 구현
  private let imagePrefetcher = SimpleImagePrefetcher()

  private lazy var adapter = ListAdapter(
    collectionView: collectionView,
    prefetchingPlugins: [RemoteImagePrefetchingPlugin(remoteImagePrefetcher: imagePrefetcher)]
  )

  private var images: [ImageItem] = []

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Prefetch"
    view.backgroundColor = .systemBackground
    setupCollectionView()
    loadImages()
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

  private func loadImages() {
    // 샘플 이미지 데이터 생성
    images = (1...1000).map { index in
      ImageItem(
        id: "image_\(index)",
        imageURL: URL(string: "https://picsum.photos/seed/\(index)/300/200")!,
        // imageURL: URL(string: "https://picsum.photos/300/200?random=\(index)")!,
        title: "이미지 \(index)"
      )
    }
    render()
  }

  private func render() {
    adapter.apply(updateStrategy: .animated) {
      Section(id: "images") {
        for image in images {
          Row(
            id: image.id,
            component: ImageComponent(content: .init(image: image, prefetcher: imagePrefetcher))
          )
        }
      }
      .layout(.grid(columns: 4, itemSpacing: 8, lineSpacing: 8))
      .contentInsets(.init(top: 16, leading: 16, bottom: 16, trailing: 16))
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

struct ImageComponent: ListComponent, ComponentRemoteImagePrefetchable {
  struct Content: Equatable {
    let imageURL: URL
    let title: String
    // prefetcher는 Equatable 비교에서 제외
    let prefetcher: SimpleImagePrefetcher?

    init(image: ImageItem, prefetcher: SimpleImagePrefetcher? = nil) {
      self.imageURL = image.imageURL
      self.title = image.title
      self.prefetcher = prefetcher
    }

    static func == (lhs: Content, rhs: Content) -> Bool {
      lhs.imageURL == rhs.imageURL && lhs.title == rhs.title
    }
  }

  let content: Content

  var remoteImageURLs: [URL] {
    [content.imageURL]
  }

  func makeView(context: ListComponentContext<Void>) -> ImageCellView {
    ImageCellView()
  }

  func updateView(_ view: ImageCellView, context: ListComponentContext<Void>) {
    view.configure(title: content.title, imageURL: content.imageURL, prefetcher: content.prefetcher)
  }
}

// MARK: - Views

final class ImageCellView: UIView {
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

  private var currentImageURL: URL?
  private var currentImageLoadID: UUID?
  private var imageLoadTask: URLSessionDataTask?

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
      imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

      titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
    ])
  }

  func configure(title: String, imageURL: URL, prefetcher: SimpleImagePrefetcher?) {
    // 이전 작업 취소 및 상태 초기화
    imageLoadTask?.cancel()
    imageLoadTask = nil
    imageView.image = nil
    imageView.backgroundColor = .systemGray4

    titleLabel.text = title
    currentImageURL = imageURL
    currentImageLoadID = UUID()

    // 이미지 로딩 (실제 앱에서는 캐시를 사용)
    loadImage(from: imageURL, prefetcher: prefetcher, loadID: currentImageLoadID!)
  }

  private func loadImage(from url: URL, prefetcher: SimpleImagePrefetcher?, loadID: UUID) {
    // 간단한 이미지 로딩 구현
    // 실제 앱에서는 SDWebImage, Kingfisher 등의 라이브러리 사용
    imageView.backgroundColor = .systemGray4

    // 먼저 prefetch 캐시에서 이미지 확인
    if let prefetcher = prefetcher,
       let cachedImage = prefetcher.cachedImage(for: url) {
      // 로딩 ID와 URL이 모두 현재 것과 일치하는지 확인 (셀 재사용 체크)
      guard currentImageLoadID == loadID && currentImageURL == url else {
        print("❌ Prefetch cache hit but cell was reused: \(url.lastPathComponent)")
        return
      }
      imageView.image = cachedImage
      imageView.backgroundColor = .clear
      print("🚀 Used prefetched image: \(url.lastPathComponent)")
      return
    }

    // URLSession 작업 생성
    let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
      // 로딩 ID와 URL이 모두 현재 것과 일치하는지 확인 (셀 재사용으로 인한 취소 체크)
      guard let self = self, self.currentImageLoadID == loadID && self.currentImageURL == url else {
        print("❌ Network load completed but cell was reused: \(url.lastPathComponent)")
        return
      }

      guard let data = data,
            let image = UIImage(data: data) else {
        return
      }

      DispatchQueue.main.async {
        // 최종적으로도 로딩 ID와 URL 확인
        guard self.currentImageLoadID == loadID && self.currentImageURL == url else {
          print("❌ Network load display but cell was reused: \(url.lastPathComponent)")
          return
        }
        self.imageView.image = image
        self.imageView.backgroundColor = .clear
        print("📥 Loaded image: \(url.lastPathComponent)")
      }
    }

    imageLoadTask = task
    task.resume()
  }
}

// MARK: - Image Prefetcher

final class SimpleImagePrefetcher: RemoteImagePrefetching {
  private var prefetchTasks: [UUID: URLSessionDataTask] = [:]
  private var imageCache: [URL: UIImage] = [:]

  func prefetchImage(url: URL) -> UUID? {
    // 이미 캐시에 있는 경우 스킵
    if imageCache[url] != nil {
      return nil
    }

    let uuid = UUID()
    let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
      guard let self = self,
            let data = data,
            let image = UIImage(data: data) else {
        return
      }

      // 캐시에 저장
      self.imageCache[url] = image
      self.prefetchTasks[uuid] = nil

      print("✅ Prefetched image: \(url.lastPathComponent)")
    }

    prefetchTasks[uuid] = task
    task.resume()
    return uuid
  }

  func cancelTask(uuid: UUID) {
    prefetchTasks[uuid]?.cancel()
    prefetchTasks.removeValue(forKey: uuid)
  }

  // 캐시된 이미지 가져오기
  func cachedImage(for url: URL) -> UIImage? {
    return imageCache[url]
  }
}
