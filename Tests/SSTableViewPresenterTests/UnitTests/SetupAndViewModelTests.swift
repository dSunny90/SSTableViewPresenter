//
//  SetupAndViewModelTests.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 17.06.2024.
//

import XCTest
@testable import SSTableViewPresenter
import UIKit

@MainActor
final class SetupAndViewModelTests: XCTestCase {
    // MARK: - Presenter Setup

    func test_setup_presenter_creates_presenter() {
        // Given
        let tv = makeTableView()

        // Then
        XCTAssertNotNil(tv.presenter, "Presenter should be attached after setupPresenter()")
    }

    func test_setup_presenter_sets_delegate() {
        // Given
        let tv = makeTableView()

        // Then
        XCTAssertTrue(tv.delegate === tv.presenter)
    }

    func test_setup_presenter_sets_data_source() {
        // Given
        let tv = makeTableView()

        // Then
        XCTAssertTrue(tv.dataSource === tv.presenter)
    }

    // MARK: - Get / Set ViewModel

    func test_get_view_model_returns_nil_before_setting() {
        // Given
        let tv = makeTableView()

        // Then
        XCTAssertNil(tv.ss.getViewModel(), "ViewModel should be nil before setting")
    }

    func test_set_view_model_and_get_view_model() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs()
        let cellInfos = makeCellInfos(from: configs)
        let section = SSTableViewModel.SectionInfo(rows: cellInfos)
        let viewModel = SSTableViewModel(sections: [section])

        // When
        tv.ss.setViewModel(with: viewModel)

        // Then
        let retrieved = tv.ss.getViewModel()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.count, 1, "Should have 1 section")
        XCTAssertEqual(retrieved?[0].count, 8, "Section should have 8 rows (default)")
    }

    func test_reset_view_model_clears_all_data() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self)
            }
        }
        XCTAssertEqual(tv.ss.getViewModel()?.count, 1)

        // When
        tv.ss.resetViewModel()

        // Then
        let vm = tv.ss.getViewModel()
        XCTAssertNotNil(vm)
        XCTAssertTrue(vm?.isEmpty ?? false)
    }

    func test_set_view_model_replaces_existing() {
        // Given
        let tv = makeTableView()
        let first = SSTableViewModel(sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)))
        ])
        tv.ss.setViewModel(with: first)
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 3)

        // When
        let second = SSTableViewModel(sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(7)))
        ])
        tv.ss.setViewModel(with: second)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 1)
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 7)
    }

    // MARK: - ViewModel Basics

    func test_view_model_default_values() {
        // When
        let vm = SSTableViewModel()

        // Then
        XCTAssertEqual(vm.page, 0)
        XCTAssertFalse(vm.hasNext)
        XCTAssertTrue(vm.isEmpty)
        XCTAssertFalse(vm.isIndexTitlesEnabled, "isIndexTitlesEnabled should default to false")
    }

    func test_view_model_section_info_access() {
        // Given
        let cellInfos = makeCellInfos(from: makeSampleConfigs(7))
        let section = SSTableViewModel.SectionInfo(rows: cellInfos, identifier: "test")
        let vm = SSTableViewModel(sections: [section], page: 1, hasNext: true)

        // Then
        XCTAssertEqual(vm.count, 1)
        XCTAssertEqual(vm.page, 1)
        XCTAssertTrue(vm.hasNext)
        XCTAssertNotNil(vm.sectionInfo(at: 0))
        XCTAssertNil(vm.sectionInfo(at: 2), "Out of bounds should return nil")
    }

    // MARK: - ViewModel Operators

    func test_view_model_plus_operator() {
        // Given
        let section1 = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(11)))
        let section2 = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(23)))
        let vm1 = SSTableViewModel(sections: [section1])
        let vm2 = SSTableViewModel(sections: [section2])

        // When
        let combined = vm1 + vm2

        // Then
        XCTAssertEqual(combined.count, 2)
    }

    func test_view_model_plus_equal_operator() {
        // Given
        let section1 = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(30)))
        let section2 = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(44)))
        var vm = SSTableViewModel(sections: [section1])

        // When
        vm += SSTableViewModel(sections: [section2])

        // Then
        XCTAssertEqual(vm.count, 2)
    }

    func test_view_model_plus_section_info() {
        // Given
        let section1 = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(53)))
        let section2 = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(59)))
        let vm = SSTableViewModel(sections: [section1])

        // When
        let result = vm + section2

        // Then
        XCTAssertEqual(result.count, 2)
    }

    func test_view_model_plus_section_info_array_operator() {
        // Given
        let vm = SSTableViewModel(sections: [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(11)))
        ])
        let newSections = [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(19))),
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(23)))
        ]

        // When
        let result = vm + newSections

        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].count, 11)
        XCTAssertEqual(result[1].count, 19)
        XCTAssertEqual(result[2].count, 23)
    }

    // MARK: - Selected Rows

    func test_selected_rows_initially_empty() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self)
            }
        }

        // Then
        XCTAssertTrue(tv.ss.selectedRows.isEmpty)
    }

    func test_selected_rows_updated_when_cell_selected() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self)
            }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        let indexPath = IndexPath(row: 0, section: 0)

        // When
        guard tv.cellForRow(at: indexPath) is TestConfigCell else {
            XCTFail("Could not get cell")
            return
        }
        tv.presenter?.tableView(tv, didSelectRowAt: indexPath)

        // Then
        XCTAssertFalse(tv.ss.selectedRows.isEmpty)
        XCTAssertEqual(tv.ss.selectedRows.count, 1)
    }

    // MARK: - Clear Selected Items

    func test_clear_selected_rows_with_no_view_model_is_no_op() {
        // Given
        let tv = makeTableView()

        // When — should not crash
        tv.ss.clearSelectedRows()

        // Then
        XCTAssertTrue(tv.ss.selectedRows.isEmpty)
    }

    func test_clear_selected_rows_removes_all_selections() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self)
            }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        let indexPath = IndexPath(row: 0, section: 0)
        guard tv.cellForRow(at: indexPath) is TestConfigCell else {
            XCTFail("Could not get cell")
            return
        }
        tv.presenter?.tableView(tv, didSelectRowAt: indexPath)
        XCTAssertFalse(tv.ss.selectedRows.isEmpty)

        // When
        tv.ss.clearSelectedRows()

        // Then
        XCTAssertTrue(tv.ss.selectedRows.isEmpty)
    }
}
