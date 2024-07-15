//
//  PageBasedLoadingTests.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 17.06.2024.
//

import XCTest
@testable import SSTableViewPresenter
import UIKit

@MainActor
final class PageBasedLoadingTests: XCTestCase {
    // MARK: - ViewModel Page Management

    func test_set_page_stores_and_merges_sections() {
        // Given
        var vm = SSTableViewModel()
        let section = SSTableViewModel.SectionInfo(
            rows: makeCellInfos(from: makeSampleConfigs(3)),
            identifier: "MainConfigSection"
        )

        // When
        vm.setPage(0, sections: [section])

        // Then
        XCTAssertEqual(vm.count, 1)
        XCTAssertEqual(vm[0].count, 3)
        XCTAssertEqual(vm[0].identifier, "MainConfigSection")
        XCTAssertTrue(vm.hasPageData)
        XCTAssertEqual(vm.pageCount, 1)
    }

    func test_multiple_pages_with_same_identifier_merge_rows() {
        // Given
        var vm = SSTableViewModel()

        // When
        vm.setPage(0, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)), identifier: "aaa")
        ])
        vm.setPage(1, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(5)), identifier: "aaa")
        ])

        // Then
        XCTAssertEqual(vm.count, 1, "Should merge into one section")
        XCTAssertEqual(vm[0].count, 8, "Should have 3 + 5 = 8 rows")
    }

    func test_pages_with_different_identifiers_append_sections() {
        // Given
        var vm = SSTableViewModel()

        // When
        vm.setPage(0, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(2)), identifier: "AccountConfigSection"),
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(4)), identifier: "LocalConfigSection")
        ])
        vm.setPage(1, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)), identifier: "LocalConfigSection")
        ])

        // Then
        XCTAssertEqual(vm.count, 2, "Should have 2 distinct sections")
        XCTAssertEqual(vm[0].identifier, "AccountConfigSection")
        XCTAssertEqual(vm[0].count, 2)
        XCTAssertEqual(vm[1].identifier, "LocalConfigSection")
        XCTAssertEqual(vm[1].count, 7, "4 from page 0 + 3 from page 1")
    }

    func test_nil_identifier_sections_never_merge() {
        // Given
        var vm = SSTableViewModel()

        // When
        vm.setPage(0, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(2)))
        ])
        vm.setPage(1, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)))
        ])

        // Then
        XCTAssertEqual(vm.count, 2, "Nil-identifier sections should not merge")
        XCTAssertEqual(vm[0].count, 2)
        XCTAssertEqual(vm[1].count, 3)
    }

    func test_remove_page_rebuilds() {
        // Given
        var vm = SSTableViewModel()
        vm.setPage(0, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)), identifier: "bbb")
        ])
        vm.setPage(1, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(5)), identifier: "bbb")
        ])
        XCTAssertEqual(vm[0].count, 8)

        // When
        vm.removePage(1)

        // Then
        XCTAssertEqual(vm.count, 1)
        XCTAssertEqual(vm[0].count, 3, "Only page 0 rows should remain")
        XCTAssertEqual(vm.pageCount, 1)
    }

    func test_remove_all_pages_clears_everything() {
        // Given
        var vm = SSTableViewModel()
        vm.setPage(0, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)))
        ])
        vm.setPage(1, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(5)))
        ])

        // When
        vm.removeAllPages()

        // Then
        XCTAssertTrue(vm.isEmpty)
        XCTAssertFalse(vm.hasPageData)
        XCTAssertEqual(vm.pageCount, 0)
        XCTAssertEqual(vm.page, 0)
        XCTAssertFalse(vm.hasNext)
    }

    func test_page_replacement_rebuilds_correctly() {
        // Given
        var vm = SSTableViewModel()
        vm.setPage(0, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)), identifier: "dddd")
        ])
        XCTAssertEqual(vm[0].count, 3)

        // When — replace page 0 with different data
        vm.setPage(0, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(7)), identifier: "dddd")
        ])

        // Then
        XCTAssertEqual(vm[0].count, 7, "Replaced page should use new rows")
        XCTAssertEqual(vm.pageCount, 1)
    }

    func test_empty_page_does_not_affect_merge() {
        // Given
        var vm = SSTableViewModel()
        vm.setPage(0, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(5)))
        ])

        // When
        vm.setPage(1, sections: [])

        // Then
        XCTAssertEqual(vm.count, 1)
        XCTAssertEqual(vm[0].count, 5)
    }

    func test_sections_for_page_returns_correct_data() {
        // Given
        var vm = SSTableViewModel()
        let sections0 = [SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)))]
        vm.setPage(0, sections: sections0)

        // Then
        XCTAssertNotNil(vm.sections(forPage: 0))
        XCTAssertEqual(vm.sections(forPage: 0)?.count, 1)
        XCTAssertNil(vm.sections(forPage: 4))
    }

    func test_out_of_order_page_loading_merges_in_sorted_order() {
        // Given
        var vm = SSTableViewModel()

        // When — load page 2 before page 1
        vm.setPage(2, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(2)), identifier: "fgh")
        ])
        vm.setPage(0, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)), identifier: "ijk"),
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(4)), identifier: "fgh")
        ])
        vm.setPage(1, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(5)), identifier: "fgh")
        ])

        // Then — merged order should be page 0, 1, 2
        XCTAssertEqual(vm.count, 2)
        XCTAssertEqual(vm[0].identifier, "ijk")
        XCTAssertEqual(vm[0].count, 3)
        XCTAssertEqual(vm[1].identifier, "fgh")
        XCTAssertEqual(vm[1].count, 11, "4 + 5 + 2 rows from pages 0, 1, 2")
    }

    func test_header_footer_override_from_later_page() {
        // Given
        var vm = SSTableViewModel()
        let header0 = SSTableViewModel.HeaderFooterViewInfo(
            BindingStore<TestHeaderData, TestHeaderView>(state: TestHeaderData(title: "Page0Header"))
        )
        let header1 = SSTableViewModel.HeaderFooterViewInfo(
            BindingStore<TestHeaderData, TestHeaderView>(state: TestHeaderData(title: "Page1Header"))
        )

        // When
        vm.setPage(0, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(2)), header: header0, identifier: "kkk")
        ])
        vm.setPage(1, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)), header: header1, identifier: "kkk")
        ])

        // Then
        XCTAssertNotNil(vm[0].headerInfo(), "Header should exist")
        XCTAssertEqual(vm[0].count, 5)
    }

    func test_set_page_updates_page_property() {
        // Given
        var vm = SSTableViewModel()

        // When
        vm.setPage(0, sections: [])
        XCTAssertEqual(vm.page, 0)

        vm.setPage(3, sections: [])
        XCTAssertEqual(vm.page, 3)
    }

    func test_find_page_for_section_identifier() {
        // Given
        var vm = SSTableViewModel()
        vm.setPage(0, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(2)), identifier: "AccountConfig"),
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)), identifier: "MainConfigs")
        ])
        vm.setPage(1, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)), identifier: "MainConfigs")
        ])
        vm.setPage(2, sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)), identifier: "MainConfigs")
        ])

        // Then
        XCTAssertEqual(vm.findPage(forSectionIdentifier: "AccountConfig"), 0)
        XCTAssertEqual(vm.findPage(forSectionIdentifier: "MainConfigs"), 2)
        XCTAssertNil(vm.findPage(forSectionIdentifier: "AsdfQwer"))
    }

    // MARK: - Presenter Page-Based API

    func test_load_page_via_presenter() {
        // Given
        let tv = makeTableView()

        // When
        let result = tv.ss.loadPage(0, hasNext: true) { builder in
            builder.section {
                builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 5)
        XCTAssertTrue(result.hasNext)
        XCTAssertTrue(result.hasPageData)
    }

    func test_load_multiple_pages_via_presenter() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.loadPage(0, hasNext: true) { builder in
            builder.section("AccountConfig") { builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self) }
            builder.section("ProductList") { builder.cells(makeSampleConfigs(4), cellType: TestConfigCell.self) }
        }

        // When
        let result = tv.ss.loadPage(1, hasNext: false) { builder in
            builder.section("ProductList") { builder.cells(makeSampleConfigs(6), cellType: TestConfigCell.self) }
        }

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].count, 2, "AccountConfig section unchanged")
        XCTAssertEqual(result[1].count, 10, "ProductList section: 4 + 6")
        XCTAssertFalse(result.hasNext)
    }

    func test_reset_pages_via_presenter() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.loadPage(0, hasNext: true) { builder in
            builder.section { builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self) }
        }

        // When
        tv.ss.setViewModel(with: SSTableViewModel())

        // Then
        let vm = tv.ss.getViewModel()
        XCTAssertNotNil(vm)
        XCTAssertTrue(vm?.isEmpty ?? false)
        XCTAssertFalse(vm?.hasPageData ?? true)
    }

    func test_remove_page_via_presenter() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.loadPage(0, hasNext: true) { builder in
            builder.section("AccountConfig") { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }
        _ = tv.ss.loadPage(1, hasNext: false) { builder in
            builder.section("AccountConfig") { builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self) }
        }

        // When
        let result = tv.ss.removePage(1)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?[0].count, 3, "Only page 0 rows remain")
    }

    func test_load_page_after_reset_starts_fresh() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.loadPage(0, hasNext: true) { builder in
            builder.section("ConfigSection") { builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self) }
        }
        _ = tv.ss.loadPage(1, hasNext: false) { builder in
            builder.section("ConfigSection") { builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self) }
        }

        // When — simulate pull-to-refresh
        tv.ss.setViewModel(with: SSTableViewModel())
        let result = tv.ss.loadPage(0, hasNext: true) { builder in
            builder.section("ConfigSection") { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 3, "Should only have new page 0 data")
        XCTAssertEqual(result.pageCount, 1)
        XCTAssertTrue(result.hasNext)
    }
}
