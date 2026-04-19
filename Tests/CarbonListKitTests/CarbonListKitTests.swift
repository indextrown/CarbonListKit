import Testing
@testable import CarbonListKit

@Test("패키지를 로드할 수 있다")
func packageLoads() {
  #expect(Bool(true))
}

#if canImport(UIKit)
import UIKit

@Suite("Section Header/Footer DSL")
struct SectionHeaderFooterDSLTests {
  @Test("SwiftUI 스타일 DSL로 header와 footer를 rows 아래에 선언할 수 있다")
  func sectionBuildsHeaderAndFooterWithTrailingClosures() {
    let section = Section(id: "section") {
      testRow(id: "row-1", text: "내용 1")
      testRow(id: "row-2", text: "내용 2")
    } header: {
      testHeader(id: "header", text: "헤더")
    } footer: {
      testFooter(id: "footer", text: "푸터")
    }

    #expect(section.rows.map(\.id) == ["row-1", "row-2"].map(AnyHashable.init))
    #expect(section.header?.id == AnyHashable("header"))
    #expect(section.footer?.id == AnyHashable("footer"))
  }

  @Test("id를 생략해도 DSL로 header와 footer를 선언할 수 있다")
  func sectionBuildsAutomaticIDWithHeaderAndFooter() {
    let section = Section {
      testRow(id: "row", text: "내용")
    } header: {
      testHeader(id: "header", text: "헤더")
    } footer: {
      testFooter(id: "footer", text: "푸터")
    }

    #expect(section.rows.count == 1)
    #expect(section.header?.id == AnyHashable("header"))
    #expect(section.footer?.id == AnyHashable("footer"))
  }

  @Test("header만 있는 DSL과 footer만 있는 DSL을 각각 사용할 수 있다")
  func sectionBuildsSingleSupplementaryDSLVariants() {
    let headerOnly = Section(id: "header-only") {
      testRow(id: "row", text: "내용")
    } header: {
      testHeader(id: "header", text: "헤더")
    }

    let footerOnly = Section(id: "footer-only") {
      testRow(id: "row", text: "내용")
    } footer: {
      testFooter(id: "footer", text: "푸터")
    }

    #expect(headerOnly.header?.id == AnyHashable("header"))
    #expect(headerOnly.footer == nil)
    #expect(footerOnly.header == nil)
    #expect(footerOnly.footer?.id == AnyHashable("footer"))
  }
}

@Suite("Section Modifiers")
struct SectionModifierTests {
  @Test("contentInsets는 내부 row 영역에만 저장된다")
  func contentInsetsAreStoredSeparatelyFromSectionInsets() {
    let insets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 12, trailing: 16)
    let section = makeSection().contentInsets(insets)

    #expect(section.contentInsets.isEqual(to: insets))
    #expect(section.sectionInsets.isEqual(to: .zero))
  }

  @Test("sectionInsets는 header/footer를 포함한 전체 섹션 여백으로 저장된다")
  func sectionInsetsAreStoredSeparatelyFromContentInsets() {
    let insets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 30, trailing: 40)
    let section = makeSection().sectionInsets(insets)

    #expect(section.contentInsets.isEqual(to: .zero))
    #expect(section.sectionInsets.isEqual(to: insets))
  }

  @Test("sectionSpacing은 다음 섹션과의 간격으로 저장된다")
  func sectionSpacingIsStoredOnSection() {
    let section = makeSection().sectionSpacing(24)

    #expect(section.sectionSpacing == 24)
  }

  @Test("orthogonal scrolling behavior는 저장되고 alias도 동일하다")
  func orthogonalScrollingBehaviorIsStoredOnSection() {
    let behavior: ListOrthogonalScrollingBehavior = .continuousGroupLeadingBoundary
    let primary = makeSection().orthogonalScrollingBehavior(behavior)
    let aliased = makeSection().withOrthogonalScrollingBehavior(behavior)

    #expect(primary.orthogonalScrollingBehavior == behavior)
    #expect(primary == aliased)
  }

  @Test("with 접두어 modifier는 기본 modifier와 같은 결과를 만든다")
  func legacyStyleModifierAliasesMatchPrimaryModifiers() {
    let contentInsets = NSDirectionalEdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)
    let sectionInsets = NSDirectionalEdgeInsets(top: 5, leading: 6, bottom: 7, trailing: 8)
    let header = testHeader(id: "header", text: "헤더")
    let footer = testFooter(id: "footer", text: "푸터")

    let primary = makeSection()
      .contentInsets(contentInsets)
      .sectionInsets(sectionInsets)
      .sectionSpacing(12)
      .header(header)
      .footer(footer)

    let aliased = makeSection()
      .withSectionContentInsets(contentInsets)
      .withSectionInsets(sectionInsets)
      .withSectionSpacing(12)
      .withSectionHeader(header)
      .withSectionFooter(footer)

    #expect(primary == aliased)
  }
}

@Suite("Supplementary Layout")
struct SupplementaryLayoutTests {
  @Test("기본 supplementary layout size는 전체 너비와 estimated height를 사용한다")
  func estimatedLayoutSizeUsesFractionalWidth() {
    #expect(
      ListSupplementaryLayoutSize.estimated(height: 44)
        == .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44))
    )
  }

  @Test("absolute와 estimated layout size는 다르게 비교된다")
  func layoutSizeEqualityIncludesDimensionKind() {
    #expect(ListSupplementaryLayoutSize.estimated(height: 44) != .absolute(height: 44))
  }

  @Test("sectionSpacing을 footer 높이에 더할 때 양수만 반영된다")
  func addingHeightIgnoresNonPositiveValues() {
    let base = ListSupplementaryLayoutSize.estimated(height: 44)

    #expect(base.addingHeight(16) == .init(heightDimension: .estimated(60)))
    #expect(base.addingHeight(0) == base)
    #expect(base.addingHeight(-8) == base)
  }

  @Test("supplementary equality는 id, component, layoutSize를 모두 비교한다")
  func supplementaryEqualityIncludesIDComponentAndLayoutSize() {
    let base = testHeader(id: "header", text: "헤더", height: 44)
    let same = testHeader(id: "header", text: "헤더", height: 44)
    let differentID = testHeader(id: "other", text: "헤더", height: 44)
    let differentComponent = testHeader(id: "header", text: "다른 헤더", height: 44)
    let differentLayout = testHeader(id: "header", text: "헤더", height: 60)

    #expect(base == same)
    #expect(base != differentID)
    #expect(base != differentComponent)
    #expect(base != differentLayout)
  }
}

@Suite("Section Equality")
struct SectionEqualityTests {
  @Test("Section equality는 layout, inset, spacing, header, footer를 비교한다")
  func sectionEqualityIncludesDisplayConfiguration() {
    let base = makeSection()

    #expect(base != base.layout(.grid(columns: 2, itemSpacing: 8, lineSpacing: 12)))
    #expect(base != base.layout(.orthogonal()))
    #expect(base != base.layout(.orthogonal(columns: 2, itemSpacing: 8, lineSpacing: 12)))
    #expect(base != base.layout(.orthogonal(reservedHeight: 120)))
    #expect(base != base.contentInsets(.init(top: 1, leading: 0, bottom: 0, trailing: 0)))
    #expect(base != base.sectionInsets(.init(top: 0, leading: 1, bottom: 0, trailing: 0)))
    #expect(base != base.sectionSpacing(20))
    #expect(base != base.orthogonalScrollingBehavior(.paging))
    #expect(base != base.header(testHeader(id: "header", text: "헤더")))
    #expect(base != base.footer(testFooter(id: "footer", text: "푸터")))
  }

  @Test("Section equality는 rows 변경과 순서를 비교한다")
  func sectionEqualityIncludesRowsAndOrder() {
    let base = Section(id: "section") {
      testRow(id: "row-1", text: "내용 1")
      testRow(id: "row-2", text: "내용 2")
    }
    let reordered = Section(id: "section") {
      testRow(id: "row-2", text: "내용 2")
      testRow(id: "row-1", text: "내용 1")
    }
    let inserted = Section(id: "section") {
      testRow(id: "row-0", text: "내용 0")
      testRow(id: "row-1", text: "내용 1")
      testRow(id: "row-2", text: "내용 2")
    }

    #expect(base != reordered)
    #expect(base != inserted)
  }

  @Test("DifferenceKit section content 비교는 rows 순서를 element diff에 맡긴다")
  func sectionContentEqualityIgnoresRowsForElementDiff() {
    let base = Section(id: "section") {
      testRow(id: "row-1", text: "내용 1")
      testRow(id: "row-2", text: "내용 2")
    }
    let reordered = Section(id: "section") {
      testRow(id: "row-2", text: "내용 2")
      testRow(id: "row-1", text: "내용 1")
    }

    #expect(base.isContentEqual(to: reordered))
    #expect(base != reordered)
  }

  @Test("Row equality는 id와 component를 비교하고 이벤트는 비교하지 않는다")
  func rowEqualityIncludesIDAndComponentButNotEvents() {
    let base = testRow(id: "row", text: "내용")
    let same = testRow(id: "row", text: "내용")
    let differentID = testRow(id: "other", text: "내용")
    let differentComponent = testRow(id: "row", text: "다른 내용")
    let withEvent = base.onSelect { _ in }

    #expect(base == same)
    #expect(base != differentID)
    #expect(base != differentComponent)
    #expect(base == withEvent)
  }
}

@Suite("Builders")
struct BuilderTests {
  @Test("ListBuilder는 배열, 조건문, 반복문을 조합한다")
  func listBuilderCombinesSupportedControlFlow() {
    let includeExtra = true
    let ids = ["dynamic-1", "dynamic-2"]

    let list = List {
      Section(id: "static") {
        testRow(id: "row", text: "내용")
      }

      if includeExtra {
        Section(id: "optional") {
          testRow(id: "optional-row", text: "옵션")
        }
      }

      for id in ids {
        Section(id: id) {
          testRow(id: "\(id)-row", text: id)
        }
      }
    }

    #expect(list.sections.map(\.id) == ["static", "optional", "dynamic-1", "dynamic-2"].map(AnyHashable.init))
  }

  @Test("RowsBuilder는 배열, 조건문, 반복문을 조합한다")
  func rowsBuilderCombinesSupportedControlFlow() {
    let includeExtra = true
    let ids = ["row-3", "row-4"]

    let section = Section(id: "section") {
      testRow(id: "row-1", text: "내용 1")

      if includeExtra {
        testRow(id: "row-2", text: "내용 2")
      }

      for id in ids {
        testRow(id: id, text: id)
      }
    }

    #expect(section.rows.map(\.id) == ["row-1", "row-2", "row-3", "row-4"].map(AnyHashable.init))
  }
}

@Suite("Events And Configuration")
struct EventsAndConfigurationTests {
  @Test("Row 이벤트 modifier는 각 이벤트 핸들러를 저장한다")
  func rowEventModifiersStoreHandlers() {
    let row = testRow(id: "row", text: "내용")
      .onSelect { _ in }
      .onDisplay { _ in }
      .onEndDisplay { _ in }

    #expect(row.events.onSelect != nil)
    #expect(row.events.onDisplay != nil)
    #expect(row.events.onEndDisplay != nil)
  }

  @Test("List 끝 도달 이벤트 modifier는 offset과 핸들러를 저장한다")
  func listReachEndModifierStoresOffsetAndHandler() {
    let list = List {
      makeSection()
    }.onReachEnd(offsetFromEnd: .absolute(120)) { _ in }

    #expect(list.events.onReachEnd?.offset == .absolute(120))
    #expect(list.events.onReachEnd?.handler != nil)
  }

  @Test("ListAdapterConfiguration 기본값은 성능 옵션을 켠 상태다")
  func configurationDefaultValues() {
    let configuration = ListAdapterConfiguration.default

    #expect(configuration.batchUpdateInterruptCount == 200)
    #expect(configuration.performsLayoutAfterReload)
    #expect(configuration.isSizeCachingEnabled)
  }

  @Test("ListAdapterConfiguration은 성능 옵션을 직접 설정할 수 있다")
  func configurationCustomValues() {
    let configuration = ListAdapterConfiguration(
      batchUpdateInterruptCount: 50,
      performsLayoutAfterReload: false,
      isSizeCachingEnabled: false
    )

    #expect(configuration.batchUpdateInterruptCount == 50)
    #expect(!configuration.performsLayoutAfterReload)
    #expect(!configuration.isSizeCachingEnabled)
  }
}

@Suite("Component Height")
struct ComponentHeightTests {
  @Test("ListComponent의 기본 높이는 automatic이다")
  func componentDefaultHeightIsAutomatic() {
    let component = TestComponent(viewModel: .init(text: "내용"))

    #expect(component.height == .automatic)
  }

  @Test("Row equality는 component height 변경을 비교한다")
  func rowEqualityIncludesComponentHeight() {
    let base = Row(
      id: "row",
      component: FixedHeightComponent(viewModel: .init(text: "내용"), height: .absolute(44))
    )
    let differentHeight = Row(
      id: "row",
      component: FixedHeightComponent(viewModel: .init(text: "내용"), height: .absolute(72))
    )

    #expect(base != differentHeight)
  }

  @MainActor
  @Test("ComponentCell은 absolute height면 Auto Layout 측정 대신 지정 높이를 사용한다")
  func componentCellUsesAbsoluteHeight() {
    let cell = ComponentCell(frame: CGRect(x: 0, y: 0, width: 100, height: 80))
    let component = FixedHeightComponent(viewModel: .init(text: "내용"), height: .absolute(123))
    cell.render(component: AnyListComponent(component))

    let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: 0, section: 0))
    attributes.size = CGSize(width: 100, height: 80)

    let fittedAttributes = cell.preferredLayoutAttributesFitting(attributes)

    #expect(fittedAttributes.size.height == 123)
  }
}

#if canImport(SwiftUI)
@Suite("SwiftUI Bridge")
struct SwiftUIBridgeTests {
  @Test("CarbonListView는 List 모델로 초기화할 수 있다")
  func carbonListViewBuildsWithListModel() {
    let list = List {
      makeSection()
    }
    let view = CarbonListView(list, updateStrategy: .reloadData)

    #expect(view.list.sections.count == 1)
    #expect(view.updateStrategy == .reloadData)
  }

  @Test("CarbonList 별칭은 List DSL로 초기화할 수 있다")
  func carbonListAliasBuildsWithListDSL() {
    let view = CarbonList {
      makeSection()
    }

    #expect(view.list.sections.map(\.id) == ["section"].map(AnyHashable.init))
  }

}
#endif

private func makeSection() -> Section {
  Section(id: "section") {
    testRow(id: "row", text: "내용")
  }
}

private func testRow(id: some Hashable, text: String) -> Row {
  Row(id: id, component: TestComponent(viewModel: .init(text: text)))
}

private func testHeader(id: some Hashable, text: String, height: CGFloat = 44) -> Header {
  Header(
    id: id,
    component: TestComponent(viewModel: .init(text: text)),
    layoutSize: .estimated(height: height)
  )
}

private func testFooter(id: some Hashable, text: String, height: CGFloat = 44) -> Footer {
  Footer(
    id: id,
    component: TestComponent(viewModel: .init(text: text)),
    layoutSize: .estimated(height: height)
  )
}

private struct TestComponent: ListComponent {
  struct ViewModel: Equatable {
    let text: String
  }

  let viewModel: ViewModel

  func makeView(context: ListComponentContext<Void>) -> UILabel {
    UILabel()
  }

  func updateView(_ view: UILabel, context: ListComponentContext<Void>) {
    view.text = viewModel.text
  }
}

private struct FixedHeightComponent: ListComponent {
  struct ViewModel: Equatable {
    let text: String
  }

  let viewModel: ViewModel
  let height: ListComponentHeight

  func makeView(context: ListComponentContext<Void>) -> UILabel {
    UILabel()
  }

  func updateView(_ view: UILabel, context: ListComponentContext<Void>) {
    view.text = viewModel.text
  }
}

private extension NSDirectionalEdgeInsets {
  func isEqual(to other: NSDirectionalEdgeInsets) -> Bool {
    top == other.top
      && leading == other.leading
      && bottom == other.bottom
      && trailing == other.trailing
  }
}
#endif
