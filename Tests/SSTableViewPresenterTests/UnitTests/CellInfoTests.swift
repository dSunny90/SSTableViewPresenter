//
//  CellInfoTests.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 17.06.2024.
//

import XCTest
@testable import SSTableViewPresenter
import UIKit

@MainActor
final class CellInfoTests: XCTestCase {
    // MARK: - CellInfo Stores Data

    func test_cell_info_stores_content_data() {
        // Given
        let config = TestConfig(id: "523", title: "Hello, World!")
        let cellInfo = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))

        // Then
        XCTAssertTrue(cellInfo.binderType == TestConfigCell.self)
    }

    func test_cell_info_row_size() {
        // Given
        let config = TestConfig(id: "644", title: "Hello, SSTableViewPresenter!")
        let cellInfo = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))

        // When
        let size = cellInfo.size(constrainedTo: CGSize(width: 375, height: 200))

        // Then
        XCTAssertEqual(size, CGSize(width: 375, height: 44))
    }

    func test_cell_info_hashable() {
        // Given
        let config = TestConfig(id: "777", title: "Hello, Swift!")
        let cellInfo1 = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))
        let cellInfo2 = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))

        // Then
        XCTAssertNotEqual(cellInfo1, cellInfo2, "Each CellInfo should have a unique UUID")
        XCTAssertEqual(cellInfo1, cellInfo1, "Same instance should be equal")
    }

    // MARK: - CellInfo Apply / Interaction

    func test_cell_info_apply_binds_data_to_correct_binder() {
        // Given
        let config = TestConfig(id: "211", title: "ApplyTestRow")
        let cellInfo = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))
        let cell = TestConfigCell()

        // When
        cellInfo.apply(to: cell)

        // Then
        XCTAssertEqual(cell.titleLabel.text, "ApplyTestRow")
    }

    func test_cell_info_should_highlight_returns_true() {
        // Given
        let config = TestConfig(id: "444", title: "TestRow")
        let cellInfo = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))
        let cell = TestConfigCell()

        // When
        let shouldHighlight = cellInfo.shouldHighlight(to: cell)

        // Then
        XCTAssertTrue(shouldHighlight)
    }

    func test_cell_info_will_select_returns_true() {
        // Given
        let config = TestConfig(id: "500", title: "TestRow")
        let cellInfo = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))
        let cell = TestConfigCell()

        // When
        let willSelect = cellInfo.willSelect(to: cell)

        // Then
        XCTAssertTrue(willSelect)
    }

    func test_cell_info_will_deselect_returns_true() {
        // Given
        let config = TestConfig(id: "664", title: "TestRow")
        let cellInfo = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))
        let cell = TestConfigCell()

        // When
        let willDeselect = cellInfo.willDeselect(to: cell)

        // Then
        XCTAssertTrue(willDeselect)
    }

    func test_cell_info_did_select_calls_cell_method() {
        // Given
        let config = TestConfig(id: "423", title: "TestRow")
        let cellInfo = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))
        let cell = TestConfigCell()

        // When
        cellInfo.didSelect(to: cell)

        // Then
        XCTAssertTrue(cell.didSelectCalled)
        XCTAssertTrue(cellInfo.isSelected)
    }

    func test_cell_info_did_deselect_calls_cell_method() {
        // Given
        let config = TestConfig(id: "909", title: "TestRow")
        let cellInfo = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))
        let cell = TestConfigCell()
        cellInfo.didSelect(to: cell)

        // When
        cellInfo.didDeselect(to: cell)

        // Then
        XCTAssertTrue(cell.didDeselectCalled)
        XCTAssertFalse(cellInfo.isSelected)
    }

    func test_cell_info_did_highlight_calls_cell_method() {
        // Given
        let config = TestConfig(id: "159", title: "TestRow")
        let cellInfo = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))
        let cell = TestConfigCell()

        // When
        cellInfo.didHighlight(to: cell)

        // Then
        XCTAssertTrue(cell.didHighlightCalled)
        XCTAssertTrue(cellInfo.isHighlighted)
    }

    func test_cell_info_did_unhighlight_calls_cell_method() {
        // Given
        let config = TestConfig(id: "951", title: "TestRow")
        let cellInfo = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))
        let cell = TestConfigCell()
        cellInfo.didHighlight(to: cell)

        // When
        cellInfo.didUnhighlight(to: cell)

        // Then
        XCTAssertTrue(cell.didUnhighlightCalled)
        XCTAssertFalse(cellInfo.isHighlighted)
    }

    func test_cell_info_will_display_calls_cell_method() {
        // Given
        let config = TestConfig(id: "523", title: "Row")
        let cellInfo = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))
        let cell = TestConfigCell()

        // When
        cellInfo.willDisplay(to: cell)

        // Then
        XCTAssertTrue(cell.willDisplayCalled)
    }

    func test_cell_info_did_end_displaying_calls_cell_method() {
        // Given
        let config = TestConfig(id: "699", title: "Hello, Swift!")
        let cellInfo = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))
        let cell = TestConfigCell()

        // When
        cellInfo.didEndDisplaying(to: cell)

        // Then
        XCTAssertTrue(cell.didEndDisplayingCalled)
    }

    // MARK: - CellInfo Action Closure

    func test_cell_info_action_closure_initially_nil() {
        // Given
        let config = TestConfig(id: "777", title: "TestRow")
        let cellInfo = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))

        // Then
        XCTAssertNil(cellInfo.actionClosure)
    }

    func test_cell_info_action_closure_can_be_set() {
        // Given
        let config = TestConfig(id: "815", title: "TestRow")
        let cellInfo = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))
        var actionCalled = false

        // When
        cellInfo.actionClosure = { _, _, _, _ in
            actionCalled = true
        }
        let cell = TestConfigCell()
        let indexPath = IndexPath(row: 0, section: 0)
        cellInfo.actionClosure?(indexPath, cell, "testAction", nil)

        // Then
        XCTAssertNotNil(cellInfo.actionClosure)
        XCTAssertTrue(actionCalled)
    }

    // MARK: - CellInfo Selection State

    func test_cell_info_initial_selection_state() {
        // Given
        let config = TestConfig(id: "909", title: "TestRow")
        let cellInfo = SSTableViewModel.CellInfo(BindingStore<TestConfig, TestConfigCell>(state: config))

        // Then
        XCTAssertFalse(cellInfo.isSelected)
        XCTAssertFalse(cellInfo.isHighlighted)
    }

    // MARK: - UITableViewCell.indexPath

    func test_cell_index_path_returns_nil_when_not_in_table_view() {
        // Given
        let cell = TestConfigCell()

        // Then
        XCTAssertNil(cell.indexPath, "indexPath should be nil when cell is not in a table view")
    }

    func test_cell_index_path_returns_correct_index_path_when_visible() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs(10)
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(configs, cellType: TestConfigCell.self) }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        let expectedIndexPath = IndexPath(row: 3, section: 0)

        // When
        guard let cell = tv.cellForRow(at: expectedIndexPath) as? TestConfigCell else {
            XCTFail("Could not get cell at index path")
            return
        }
        let cellIndexPath = cell.indexPath

        // Then
        XCTAssertEqual(cellIndexPath, expectedIndexPath)
    }

    func test_cell_index_path_works_with_multiple_sections() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self) }
            builder.section { builder.cells(makeSampleConfigs(7), cellType: TestConfigCell.self) }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        let expectedIndexPath = IndexPath(row: 2, section: 1) // visible without scrolling

        // When
        guard let cell = tv.cellForRow(at: expectedIndexPath) as? TestConfigCell else {
            XCTFail("Could not get cell at index path")
            return
        }
        let cellIndexPath = cell.indexPath

        // Then
        XCTAssertEqual(cellIndexPath, expectedIndexPath)
    }
}
