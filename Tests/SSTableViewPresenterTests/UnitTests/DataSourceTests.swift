//
//  DataSourceTests.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 17.06.2024.
//

import XCTest
@testable import SSTableViewPresenter
import UIKit

@MainActor
final class DataSourceTests: XCTestCase {
    // MARK: - numberOfSections / numberOfItemsInSection

    func test_number_of_sections_matches_view_model() {
        // Given
        let tv = makeTableView()
        let section1 = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(23)))
        let section2 = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(11)))
        let viewModel = SSTableViewModel(sections: [section1, section2])

        // When
        tv.ss.setViewModel(with: viewModel)
        tv.reloadData()

        // Then
        let sectionCount = tv.dataSource?.numberOfSections?(in: tv)
        XCTAssertEqual(sectionCount, 2)
    }

    func test_number_of_rows_in_section_matches_cell_count() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs(10)
        let cellInfos = makeCellInfos(from: configs)
        let section = SSTableViewModel.SectionInfo(rows: cellInfos)
        tv.ss.setViewModel(with: SSTableViewModel(sections: [section]))
        tv.reloadData()

        // When
        let rowCount = tv.dataSource?.tableView(tv, numberOfRowsInSection: 0)

        // Then
        XCTAssertEqual(rowCount, 10)
    }

    func test_number_of_sections_returns_zero_with_no_view_model() {
        // Given
        let tv = makeTableView()
        tv.reloadData()

        // When
        let sectionCount = tv.dataSource?.numberOfSections?(in: tv)

        // Then
        XCTAssertEqual(sectionCount, 0)
    }

    func test_number_of_sections_with_multiple_sections() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
            builder.section { builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self) }
            builder.section { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }
        tv.reloadData()

        // Then
        XCTAssertEqual(tv.dataSource?.numberOfSections?(in: tv), 3)
        XCTAssertEqual(tv.dataSource?.tableView(tv, numberOfRowsInSection: 0), 1)
        XCTAssertEqual(tv.dataSource?.tableView(tv, numberOfRowsInSection: 1), 2)
        XCTAssertEqual(tv.dataSource?.tableView(tv, numberOfRowsInSection: 2), 3)
    }

    // MARK: - CellForItemAt & Data Binding

    func test_cell_for_row_at_dequeues_correct_cell() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs()
        let cellInfos = makeCellInfos(from: configs)
        let section = SSTableViewModel.SectionInfo(rows: cellInfos)
        tv.ss.setViewModel(with: SSTableViewModel(sections: [section]))
        tv.reloadData()

        // When
        let indexPath = IndexPath(row: 0, section: 0)
        let cell = tv.dataSource?.tableView(tv, cellForRowAt: indexPath)

        // Then
        XCTAssertTrue(cell is TestConfigCell, "Should dequeue a TestConfigCell")
    }

    func test_cell_data_binding_applies_to_cell() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs()
        let cellInfos = makeCellInfos(from: configs)
        let section = SSTableViewModel.SectionInfo(rows: cellInfos)
        tv.ss.setViewModel(with: SSTableViewModel(sections: [section]))
        tv.reloadData()

        // When
        let indexPath = IndexPath(row: 1, section: 0)
        guard let cell = tv.dataSource?.tableView(tv, cellForRowAt: indexPath) as? TestConfigCell else {
            XCTFail("Failed to dequeue TestConfigCell")
            return
        }

        // Then
        XCTAssertEqual(cell.titleLabel.text, "Config 1")
    }

    func test_cell_for_row_at_with_nil_view_model_returns_default_cell() {
        // Given
        let tv = makeTableView()
        tv.reloadData()

        // When
        let cell = tv.dataSource?.tableView(tv, cellForRowAt: IndexPath(row: 0, section: 0))

        // Then
        XCTAssertNotNil(cell)
        XCTAssertFalse(cell is TestConfigCell, "Should return a default UITableViewCell, not TestConfigCell")
    }

    // MARK: - Supplementary Views

    func test_view_for_header_dequeues_correctly() {
        // Given
        let tv = makeTableView()
        var section = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)))
        section.setHeaderInfo(TestHeaderData(title: "TestHeader"), viewType: TestHeaderView.self)
        tv.ss.setViewModel(with: SSTableViewModel(sections: [section]))
        tv.reloadData()
        tv.layoutIfNeeded()

        // When
        let headerView = tv.delegate?.tableView?(tv, viewForHeaderInSection: 0)

        // Then
        XCTAssertNotNil(headerView)
        XCTAssertTrue(headerView is TestHeaderView)
    }

    func test_view_for_footer_dequeues_correctly() {
        // Given
        let tv = makeTableView()
        var section = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)))
        section.setFooterInfo(TestFooterData(text: "TestFooter"), viewType: TestFooterView.self)
        tv.ss.setViewModel(with: SSTableViewModel(sections: [section]))
        tv.reloadData()
        tv.layoutIfNeeded()

        // When
        let footerView = tv.delegate?.tableView?(tv, viewForFooterInSection: 0)

        // Then
        XCTAssertNotNil(footerView)
        XCTAssertTrue(footerView is TestFooterView)
    }

    // MARK: - Index Titles

    func test_index_titles_returns_nil_when_disabled() {
        // Given
        let tv = makeTableView()

        let configs0 = makeSampleConfigs(5)
        let cellInfos0 = makeCellInfos(from: configs0)
        var section0 = SSTableViewModel.SectionInfo(rows: cellInfos0)
        section0.indexTitle = "A"

        let configs1 = makeSampleConfigs(6)
        let cellInfos1 = makeCellInfos(from: configs1)
        var section1 = SSTableViewModel.SectionInfo(rows: cellInfos1)
        section1.indexTitle = "B"

        let viewModel = SSTableViewModel(sections: [section0, section1], isIndexTitlesEnabled: false)
        tv.ss.setViewModel(with: viewModel)
        tv.reloadData()

        // When
        let indexTitles = tv.dataSource?.sectionIndexTitles?(for: tv)

        // Then
        XCTAssertNil(indexTitles, "indexTitles should be nil when isIndexTitlesEnabled is false")
    }

    func test_index_titles_returns_titles_when_enabled() {
        // Given
        let tv = makeTableView()

        let configs0 = makeSampleConfigs(5)
        let cellInfos0 = makeCellInfos(from: configs0)
        var section0 = SSTableViewModel.SectionInfo(rows: cellInfos0)
        section0.indexTitle = "A"

        let configs1 = makeSampleConfigs(6)
        let cellInfos1 = makeCellInfos(from: configs1)
        var section1 = SSTableViewModel.SectionInfo(rows: cellInfos1)
        section1.indexTitle = "B"

        let viewModel = SSTableViewModel(sections: [section0, section1], isIndexTitlesEnabled: true)
        tv.ss.setViewModel(with: viewModel)
        tv.reloadData()

        // When
        let indexTitles = tv.dataSource?.sectionIndexTitles?(for: tv)

        // Then
        XCTAssertNotNil(indexTitles)
        XCTAssertEqual(indexTitles?.count, 2, "Should contain unique index titles")
        XCTAssertTrue(indexTitles?.contains("A") ?? false)
        XCTAssertTrue(indexTitles?.contains("B") ?? false)
    }
}
