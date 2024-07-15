//
//  CellLifecycleTests.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 17.06.2024.
//

import XCTest
@testable import SSTableViewPresenter
import UIKit

@MainActor
final class CellLifecycleTests: XCTestCase {
    // MARK: - willDisplay / didEndDisplaying (Cell)

    func test_will_display_cell_calls_lifecycle_method() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(configs, cellType: TestConfigCell.self) }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        let cell = TestConfigCell()
        let indexPath = IndexPath(row: 0, section: 0)

        // When
        tv.presenter?.tableView(tv, willDisplay: cell, forRowAt: indexPath)

        // Then
        XCTAssertTrue(cell.willDisplayCalled)
    }

    func test_will_display_cell_with_nil_view_model_is_no_op() {
        // Given
        let tv = makeTableView()
        let cell = TestConfigCell()

        // When — no viewModel set, should not crash
        tv.presenter?.tableView(tv, willDisplay: cell, forRowAt: IndexPath(row: 0, section: 0))

        // Then
        XCTAssertFalse(cell.willDisplayCalled)
    }

    func test_did_end_displaying_cell_calls_lifecycle_method() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(configs, cellType: TestConfigCell.self) }
        }
        tv.reloadData()

        let cell = TestConfigCell()
        let indexPath = IndexPath(row: 1, section: 0)

        // When
        tv.presenter?.tableView(tv, didEndDisplaying: cell, forRowAt: indexPath)

        // Then
        XCTAssertTrue(cell.didEndDisplayingCalled)
    }

    // MARK: - willDisplay / didEndDisplaying (Header/Footer)

    func test_will_display_header_view() {
        // Given
        let tv = makeTableView()
        var section = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)))
        section.setHeaderInfo(TestHeaderData(title: "Header"), viewType: TestHeaderView.self)
        tv.ss.setViewModel(with: SSTableViewModel(sections: [section]))
        tv.reloadData()

        let headerView = TestHeaderView()

        // When
        tv.presenter?.tableView(tv, willDisplayHeaderView: headerView, forSection: 0)

        // Then
        XCTAssertTrue(headerView.willDisplayCalled)
    }

    func test_will_display_footer_view() {
        // Given
        let tv = makeTableView()
        var section = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)))
        section.setFooterInfo(TestFooterData(text: "Footer"), viewType: TestFooterView.self)
        tv.ss.setViewModel(with: SSTableViewModel(sections: [section]))
        tv.reloadData()

        let footerView = TestFooterView()

        // When
        tv.presenter?.tableView(tv, willDisplayFooterView: footerView, forSection: 0)

        // Then
        XCTAssertTrue(footerView.willDisplayCalled)
    }

    func test_did_end_displaying_header_view_() {
        // Given
        let tv = makeTableView()
        var section = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)))
        section.setHeaderInfo(TestHeaderData(title: "Header"), viewType: TestHeaderView.self)
        tv.ss.setViewModel(with: SSTableViewModel(sections: [section]))
        tv.reloadData()

        let headerView = TestHeaderView()

        // When
        tv.presenter?.tableView(tv, didEndDisplayingHeaderView: headerView, forSection: 0)

        // Then
        XCTAssertTrue(headerView.didEndDisplayingCalled)
    }

    func test_did_end_displaying_footer_view() {
        // Given
        let tv = makeTableView()
        var section = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)))
        section.setFooterInfo(TestFooterData(text: "Footer"), viewType: TestFooterView.self)
        tv.ss.setViewModel(with: SSTableViewModel(sections: [section]))
        tv.reloadData()

        let footerView = TestFooterView()

        // When
        tv.presenter?.tableView(tv, didEndDisplayingFooterView: footerView, forSection: 0)

        // Then
        XCTAssertTrue(footerView.didEndDisplayingCalled)
    }

    // MARK: - Should Highlight / Will Select/Deselect

    func test_should_highlight_returns_true_by_default() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(configs, cellType: TestConfigCell.self) }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        let indexPath = IndexPath(row: 0, section: 0)

        // When
        let shouldHighlight = tv.presenter?.tableView(tv, shouldHighlightRowAt: indexPath)

        // Then
        XCTAssertTrue(shouldHighlight ?? false)
    }

    func test_will_select_returns_true_by_default() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(configs, cellType: TestConfigCell.self) }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        let indexPath = IndexPath(row: 0, section: 0)

        // When
        let willSelect = tv.presenter?.tableView(tv, willSelectRowAt: indexPath)

        // Then
        XCTAssertNotNil(willSelect)
    }

    func test_will_deselect_returns_true_by_default() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(configs, cellType: TestConfigCell.self) }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        let indexPath = IndexPath(row: 0, section: 0)

        // When
        let willDeselect = tv.presenter?.tableView(tv, willDeselectRowAt: indexPath)

        // Then
        XCTAssertNotNil(willDeselect)
    }

    // MARK: - Highlight / Select

    func test_did_select_row_calls_cell_method() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(configs, cellType: TestConfigCell.self) }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        let indexPath = IndexPath(row: 0, section: 0)

        // When
        guard let cell = tv.cellForRow(at: indexPath) as? TestConfigCell else {
            return
        }
        tv.presenter?.tableView(tv, didSelectRowAt: indexPath)

        // Then
        XCTAssertTrue(cell.didSelectCalled)
    }

    func test_did_deselect_row_calls_cell_method() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(configs, cellType: TestConfigCell.self) }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        let indexPath = IndexPath(row: 0, section: 0)

        // When
        guard let cell = tv.cellForRow(at: indexPath) as? TestConfigCell else { return }
        tv.presenter?.tableView(tv, didDeselectRowAt: indexPath)

        // Then
        XCTAssertTrue(cell.didDeselectCalled)
    }

    func test_did_highlight_row_calls_cell_method() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(configs, cellType: TestConfigCell.self) }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        let indexPath = IndexPath(row: 0, section: 0)

        // When
        guard let cell = tv.cellForRow(at: indexPath) as? TestConfigCell else { return }
        tv.presenter?.tableView(tv, didHighlightRowAt: indexPath)

        // Then
        XCTAssertTrue(cell.didHighlightCalled)
    }

    func test_did_unhighlight_row_calls_cell_method() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(configs, cellType: TestConfigCell.self) }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        let indexPath = IndexPath(row: 0, section: 0)

        // When
        guard let cell = tv.cellForRow(at: indexPath) as? TestConfigCell else { return }
        tv.presenter?.tableView(tv, didUnhighlightRowAt: indexPath)

        // Then
        XCTAssertTrue(cell.didUnhighlightCalled)
    }

    func test_did_select_with_nil_view_model_is_no_op() {
        // Given
        let tv = makeTableView()

        // When — no viewModel set, should not crash
        tv.presenter?.tableView(tv, didSelectRowAt: IndexPath(row: 0, section: 0))

        // Then — no crash is the assertion
    }

    func test_did_select_with_out_of_bounds_is_no_op() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(), cellType: TestConfigCell.self) }
        }

        // When — out of bounds section, should not crash
        tv.presenter?.tableView(tv, didSelectRowAt: IndexPath(row: 0, section: 2))

        // Then — no crash is the assertion
    }
}
