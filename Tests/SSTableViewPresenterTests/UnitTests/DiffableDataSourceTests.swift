//
//  DiffableDataSourceTests.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 18.06.2024.
//

import XCTest
@testable import SSTableViewPresenter
import UIKit

@MainActor
final class DiffableDataSourceTests: XCTestCase {
    // MARK: - Setup with Diffable Mode

    func test_setup_with_diffable_mode_creates_presenter() {
        // Given
        let tv = makeTableView(dataSourceMode: .diffable)

        // Then
        XCTAssertNotNil(tv.presenter)
    }

    func test_diffable_mode_does_not_set_traditional_data_source() {
        // Given
        let tv = makeTableView(dataSourceMode: .diffable)

        // Then — diffable data source owns the data source, not the presenter
        XCTAssertFalse(tv.dataSource === tv.presenter,
                       "In diffable mode, presenter should not be the dataSource")
    }

    func test_traditional_mode_sets_presenter_as_data_source() {
        // Given
        let tv = makeTableView()

        // Then
        XCTAssertTrue(tv.dataSource === tv.presenter)
    }

    // MARK: - Snapshot Application

    func test_apply_snapshot_with_diffable_mode() {
        // Given
        let tv = makeTableView(dataSourceMode: .diffable)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self)
            }
        }

        // When
        tv.ss.applySnapshot(animated: false)

        // Then
        let vm = tv.ss.getViewModel()
        XCTAssertNotNil(vm)
        XCTAssertEqual(vm?.count, 1)
        XCTAssertEqual(vm?[0].count, 5)
    }

    func test_apply_snapshot_animated() {
        // Given
        let tv = makeTableView(dataSourceMode: .diffable)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }

        // When — should not crash
        tv.ss.applySnapshot(animated: true)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 1)
    }

    func test_apply_snapshot_in_traditional_mode_is_no_op() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }

        // When — should not crash, just no-op
        tv.ss.applySnapshot(animated: false)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 1)
    }

    // MARK: - Multiple Sections

    func test_apply_snapshot_with_multiple_sections() {
        // Given
        let tv = makeTableView(dataSourceMode: .diffable)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self)
            }
            builder.section {
                builder.cells(makeSampleConfigs(4), cellType: TestConfigCell.self)
            }
            builder.section {
                builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self)
            }
        }

        // When
        tv.ss.applySnapshot(animated: false)

        // Then
        let vm = tv.ss.getViewModel()
        XCTAssertEqual(vm?.count, 3)
        XCTAssertEqual(vm?[0].count, 2)
        XCTAssertEqual(vm?[1].count, 4)
        XCTAssertEqual(vm?[2].count, 1)
    }

    // MARK: - Snapshot Update After ViewModel Change

    func test_snapshot_updates_when_viewmodel_changes() {
        // Given
        let tv = makeTableView(dataSourceMode: .diffable)
        _ = tv.ss.buildViewModel { builder in
            builder.section("Test") {
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }
        tv.ss.applySnapshot(animated: false)
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 3)

        // When — replace with new viewmodel
        _ = tv.ss.buildViewModel { builder in
            builder.section("Test") {
                builder.cells(makeSampleConfigs(7), cellType: TestConfigCell.self)
            }
        }
        tv.ss.applySnapshot(animated: false)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 7)
    }

    // MARK: - Empty Snapshot

    func test_apply_snapshot_with_empty_viewmodel() {
        // Given
        let tv = makeTableView(dataSourceMode: .diffable)
        _ = tv.ss.buildViewModel { _ in }

        // When — should not crash
        tv.ss.applySnapshot(animated: false)

        // Then
        XCTAssertTrue(tv.ss.getViewModel()?.isEmpty ?? true)
    }

    // MARK: - Diffable with Headers and Footers

    func test_diffable_snapshot_with_headers_and_footers() {
        // Given
        let tv = makeTableView(dataSourceMode: .diffable)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                // UITableView headers and footers setup if supported by SSTableViewPresenter
                builder.header(TestHeaderData(title: "TestHeader"), viewType: TestHeaderView.self)
                builder.footer(TestFooterData(text: "TestFooter"), viewType: TestFooterView.self)
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }

        // When
        tv.ss.applySnapshot(animated: false)

        // Then
        let vm = tv.ss.getViewModel()
        XCTAssertNotNil(vm?[0].header)
        XCTAssertNotNil(vm?[0].footer)
    }

    // MARK: - Reconfigure Items (iOS 15+)

    @available(iOS 15.0, *)
    func test_reconfigure_items_at_index_paths() {
        // Given
        let tv = makeTableView(dataSourceMode: .diffable)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self)
            }
        }
        tv.ss.applySnapshot(animated: false)

        // When — should not crash
        tv.ss.reconfigureItems(at: [IndexPath(row: 0, section: 0), IndexPath(row: 2, section: 0)])

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 5)
    }

    @available(iOS 15.0, *)
    func test_reconfigure_items_with_out_of_bounds_index_paths() {
        // Given
        let tv = makeTableView(dataSourceMode: .diffable)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(18), cellType: TestConfigCell.self)
            }
        }
        tv.ss.applySnapshot(animated: false)

        // When — out of bounds index paths should be safely skipped
        tv.ss.reconfigureItems(at: [IndexPath(row: 19, section: 0)])

        // Then — no crash
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 18)
    }

    @available(iOS 15.0, *)
    func test_reconfigure_visible_rows() {
        // Given
        let tv = makeTableView(dataSourceMode: .diffable)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }
        tv.ss.applySnapshot(animated: false)
        tv.layoutIfNeeded()

        // When — should not crash
        tv.ss.reconfigureVisibleRows()

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 3)
    }

    @available(iOS 15.0, *)
    func test_reconfigure_items_in_traditional_mode_is_no_op() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }
        tv.reloadData()

        // When — should be no-op, not crash
        tv.ss.reconfigureItems(at: [IndexPath(row: 0, section: 0)])

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 3)
    }

    // MARK: - Apply Snapshot Using Reload Data (iOS 15+)

    @available(iOS 15.0, *)
    func test_apply_snapshot_using_reload_data() {
        // Given
        let tv = makeTableView(dataSourceMode: .diffable)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(4), cellType: TestConfigCell.self)
            }
        }

        // When
        tv.ss.applySnapshotUsingReloadData()

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 4)
    }

    @available(iOS 15.0, *)
    func test_apply_snapshot_using_reload_data_in_traditional_mode_is_no_op() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }

        // When — should be no-op, not crash
        tv.ss.applySnapshotUsingReloadData()

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 3)
    }

    // MARK: - Diffable with Pagination

    func test_diffable_with_build_and_extend_viewmodel() {
        // Given
        let tv = makeTableView(dataSourceMode: .diffable)
        _ = tv.ss.buildViewModel(page: 0, hasNext: true) { builder in
            builder.section("RemoteConfig") {
                builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self)
            }
        }
        tv.ss.applySnapshot(animated: false)
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 5)

        // When — extend with next page
        _ = tv.ss.extendViewModel(page: 1, hasNext: false) { builder in
            builder.section("RemoteConfig") {
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }
        tv.ss.applySnapshot(animated: false)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 8)
        XCTAssertFalse(tv.ss.getViewModel()?.hasNext ?? true)
    }

    // MARK: - Reconfigure Items by Identifiers (iOS 15+)

    @available(iOS 15.0, *)
    func test_reconfigure_items_by_identifiers() {
        // Given
        let tv = makeTableView(dataSourceMode: .diffable)
        _ = tv.ss.buildViewModel { builder in
            builder.section("Test1") {
                builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self)
            }
        }
        tv.ss.applySnapshot(animated: false)

        // When — reconfigure by non-matching identifiers should be safe
        tv.ss.reconfigureItems(identifiers: ["Test2"])

        // Then — no crash
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 5)
    }

    // MARK: - Reset ViewModel in Diffable Mode

    func test_reset_viewmodel_in_diffable_mode() {
        // Given
        let tv = makeTableView(dataSourceMode: .diffable)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self)
            }
        }
        tv.ss.applySnapshot(animated: false)
        XCTAssertEqual(tv.ss.getViewModel()?.count, 1)

        // When
        tv.ss.resetViewModel()
        tv.ss.applySnapshot(animated: false)

        // Then
        XCTAssertTrue(tv.ss.getViewModel()?.isEmpty ?? false)
    }
}
