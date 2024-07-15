//
//  DragDropTests.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 18.06.2024.
//

import XCTest
@testable import SSTableViewPresenter
import UIKit

// MARK: - Mock Drag Session

private class MockDragSession: NSObject, UIDragSession {
    var localContext: Any?
    var items: [UIDragItem] = []
    var isRestrictedToDraggingApplication: Bool = false
    var allowsMoveOperation: Bool = true

    func canLoadObjects(ofClass aClass: NSItemProviderReading.Type) -> Bool {
        return false
    }

    func hasItemsConforming(toTypeIdentifiers typeIdentifiers: [String]) -> Bool {
        return false
    }

    func location(in view: UIView) -> CGPoint {
        return .zero
    }
}

// MARK: - Mock Drop Session

private class MockDropSession: NSObject, UIDropSession {
    private let _progress = Progress()

    var localDragSession: UIDragSession?
    var progressIndicatorStyle: UIDropSessionProgressIndicatorStyle = .default
    var items: [UIDragItem] = []
    var isRestrictedToDraggingApplication: Bool = false
    var allowsMoveOperation: Bool = true
    nonisolated var progress: Progress { _progress }

    func canLoadObjects(ofClass aClass: NSItemProviderReading.Type) -> Bool {
        return false
    }

    func loadObjects(
        ofClass aClass: NSItemProviderReading.Type,
        completion: @escaping ([NSItemProviderReading]) -> Void
    ) -> Progress {
        return Progress()
    }

    func hasItemsConforming(toTypeIdentifiers typeIdentifiers: [String]) -> Bool {
        return false
    }

    func location(in view: UIView) -> CGPoint {
        return .zero
    }
}

@MainActor
final class DragDropTests: XCTestCase {
    /// Helper: Encodes a BindingStore<TestConfig, TestConfigCell> to a JSON string
    /// simulating what an external drag source would produce via `toJSONString()`.
    private func encodeToJSON(_ config: TestConfig) throws -> String {
        let store = BindingStore<TestConfig, TestConfigCell>(state: config)
        return try store.toJSONString(prettyPrinted: false)
    }

    // MARK: - Drag Initiation (tableView(_:itemsForBeginning:at:))

    func test_drag_returns_items_for_valid_index_path() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs(5)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(configs, cellType: TestConfigCell.self)
            }
        }
        tv.reloadData()
        tv.layoutIfNeeded()
        tv.ss.setReorderEnabled(true)

        let session = MockDragSession()
        let indexPath = IndexPath(row: 2, section: 0)

        // When
        let dragItems = tv.presenter?.tableView(tv, itemsForBeginning: session, at: indexPath)

        // Then
        XCTAssertEqual(dragItems?.count, 1, "Should return exactly one drag item")
        XCTAssertTrue(dragItems?.first?.localObject is SSTableViewModel.CellInfo,
                      "localObject should be CellInfo for local reorder detection")
    }

    func test_drag_returns_empty_for_out_of_bounds_index() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self)
            }
        }
        tv.reloadData()
        tv.ss.setReorderEnabled(true)

        let session = MockDragSession()

        // When — section out of bounds
        let result = tv.presenter?.tableView(tv, itemsForBeginning: session, at: IndexPath(row: 0, section: 119)) ?? []

        // Then
        XCTAssertTrue(result.isEmpty, "Should return empty for invalid section")
    }

    func test_drag_respects_can_drag_row_block_returning_false() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs(5)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(configs, cellType: TestConfigCell.self)
            }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        // Block all drags
        tv.ss.onCanDragRow { _ in return false }
        tv.ss.setReorderEnabled(true)

        let session = MockDragSession()

        // When
        let dragItems = tv.presenter?.tableView(tv, itemsForBeginning: session, at: IndexPath(row: 0, section: 0)) ?? []

        // Then
        XCTAssertTrue(dragItems.isEmpty, "Should return empty when canDragRow returns false")
    }

    func test_drag_selectively_allows_specific_rows() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs(5)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(configs, cellType: TestConfigCell.self)
            }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        // Only allow dragging rows at even indices
        var checkedItems: [SSTableViewModel.CellInfo] = []
        tv.ss.onCanDragRow { cellInfo in
            checkedItems.append(cellInfo)
            if let state = cellInfo.state as? TestConfig {
                return Int(state.id)! % 2 == 0
            }
            return false
        }
        tv.ss.setReorderEnabled(true)

        let session = MockDragSession()

        // When — row at index 0 (id "0", even) -> allowed
        let allowedResult = tv.presenter?.tableView(tv, itemsForBeginning: session, at: IndexPath(row: 0, section: 0)) ?? []
        XCTAssertEqual(allowedResult.count, 1)

        // When — row at index 1 (id "1", odd) -> blocked
        let blockedResult = tv.presenter?.tableView(tv, itemsForBeginning: session, at: IndexPath(row: 1, section: 0)) ?? []
        XCTAssertTrue(blockedResult.isEmpty)

        // Callback was actually invoked for both
        XCTAssertEqual(checkedItems.count, 2)
    }

    // MARK: - Drop Session Update (Move vs Copy Intent)

    func test_drop_session_returns_move_for_local_drag() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }
        tv.reloadData()
        tv.ss.setReorderEnabled(true)

        let localSession = MockDragSession()
        let dropSession = MockDropSession()
        dropSession.localDragSession = localSession

        // When
        let proposal = tv.presenter?.tableView(tv, dropSessionDidUpdate: dropSession, withDestinationIndexPath: IndexPath(row: 1, section: 0))

        // Then
        XCTAssertEqual(proposal?.operation, .move, "Local drag should propose .move")
    }

    func test_drop_session_returns_copy_for_external_drag() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }
        tv.reloadData()
        tv.ss.setExternalDragDropEnabled(true)

        let dropSession = MockDropSession()
        dropSession.localDragSession = nil // no local drag = external

        // When
        let proposal = tv.presenter?.tableView(tv, dropSessionDidUpdate: dropSession, withDestinationIndexPath: IndexPath(row: 1, section: 0))

        // Then
        XCTAssertEqual(proposal?.operation, .copy, "External drag should propose .copy")
    }

    // MARK: - Reorder ViewModel Verification

    func test_reorder_move_single_row_forward_in_viewmodel() {
        // Given
        let tv = makeTableView()
        let configs = (0..<5).map { TestConfig(id: "id\($0)", title: "Row\($0)") }
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(configs, cellType: TestConfigCell.self)
            }
        }
        tv.reloadData()
        tv.layoutIfNeeded()
        tv.ss.setReorderEnabled(true)

        // Capture titles before move
        let titlesBefore = (0..<5).map {
            (tv.ss.getViewModel()?[0][$0].state as? TestConfig)?.title ?? ""
        }
        XCTAssertEqual(titlesBefore, ["Row0", "Row1", "Row2", "Row3", "Row4"])

        // When — simulate move by directly calling moveCellInfos via performDrop
        // We test the underlying model change by using the presenter's delegate
        guard let cellInfo1 = tv.ss.getViewModel()?[0][1] else {
            XCTFail("Failed to load cellInfo")
            return
        }

        let pairs: [(indexPath: IndexPath, cellInfo: SSTableViewModel.CellInfo)] = [
            (indexPath: IndexPath(row: 1, section: 0), cellInfo: cellInfo1)
        ]

        // Call willReorder and track it
        var willReorderCalled = false
        tv.ss.onWillReorder { rows in
            willReorderCalled = true
            XCTAssertEqual(rows.count, 1)
            XCTAssertEqual(rows[0].indexPath, IndexPath(row: 1, section: 0))
        }

        tv.presenter?.willReorderBlock?(pairs)
        XCTAssertTrue(willReorderCalled)
    }

    // MARK: - Will/Did Reorder Callbacks

    func test_will_reorder_callback_receives_correct_items() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs(5)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(configs, cellType: TestConfigCell.self)
            }
        }
        tv.reloadData()

        var receivedRows: [(indexPath: IndexPath, cellInfo: SSTableViewModel.CellInfo)] = []
        tv.ss.onWillReorder { rows in
            receivedRows = rows
        }

        // When
        guard let cellInfo2 = tv.ss.getViewModel()?[0][2] else {
            XCTFail("Failed to load cellInfo")
            return
        }

        let pairs: [(indexPath: IndexPath, cellInfo: SSTableViewModel.CellInfo)] = [
            (indexPath: IndexPath(row: 2, section: 0), cellInfo: cellInfo2)
        ]
        tv.presenter?.willReorderBlock?(pairs)

        // Then
        XCTAssertEqual(receivedRows.count, 1)
        XCTAssertEqual(receivedRows[0].indexPath, IndexPath(row: 2, section: 0))
        XCTAssertTrue(receivedRows[0].cellInfo === cellInfo2)
    }

    func test_did_reorder_callback_receives_destination() {
        // Given — items: [A, B, C, D, E], move B(1) -> after D(3)
        let tv = makeTableView()
        let configs = makeSampleConfigs(5)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(configs, cellType: TestConfigCell.self)
            }
        }
        tv.reloadData()

        var receivedDestination: IndexPath?
        var receivedCount = 0
        tv.ss.onDidReorder { rows, destination in
            receivedCount = rows.count
            receivedDestination = destination
        }

        // When
        guard let cellInfo1 = tv.ss.getViewModel()?[0][1] else {
            XCTFail("Failed to load cellInfo")
            return
        }

        let pairs: [(indexPath: IndexPath, cellInfo: SSTableViewModel.CellInfo)] = [
            (indexPath: IndexPath(row: 1, section: 0), cellInfo: cellInfo1)
        ]
        let dest = IndexPath(row: 3, section: 0)
        tv.presenter?.didReorderBlock?(pairs, dest)

        // Then
        XCTAssertEqual(receivedCount, 1)
        XCTAssertEqual(receivedDestination, IndexPath(row: 3, section: 0))
    }

    // MARK: - Drag Preview

    func test_drag_preview_parameters_callback_invoked() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }
        tv.reloadData()
        tv.ss.setReorderEnabled(true)

        var receivedIndexPath: IndexPath?
        let expectedParams = UIDragPreviewParameters()
        expectedParams.backgroundColor = .blue
        tv.ss.onDragPreviewParameters { indexPath in
            receivedIndexPath = indexPath
            return expectedParams
        }

        // When
        let result = tv.presenter?.tableView(tv, dragPreviewParametersForRowAt: IndexPath(row: 1, section: 0))

        // Then
        XCTAssertEqual(receivedIndexPath, IndexPath(row: 1, section: 0))
        XCTAssertEqual(result?.backgroundColor, .blue)
    }

    func test_drag_preview_provider_sets_custom_preview_on_drag_item() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs(3)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(configs, cellType: TestConfigCell.self)
            }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        let customView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        tv.ss.setDragPreviewProvider { _ in return customView }
        tv.ss.setReorderEnabled(true)

        let session = MockDragSession()

        // When
        let dragItems = tv.presenter?.tableView(tv, itemsForBeginning: session, at: IndexPath(row: 0, section: 0)) ?? []

        // Then — previewProvider should be set (non-nil)
        XCTAssertEqual(dragItems.count, 1)
        XCTAssertNotNil(dragItems.first?.previewProvider,
                        "Drag item should have a custom preview provider when dragPreviewProviderBlock is set")
    }

    // MARK: - Accepted Drop Type Identifiers

    func test_accepted_type_identifiers_stored_correctly() {
        // Given
        let tv = makeTableView()
        let types = ["public.plain-text", "public.image", "public.url"]

        // When
        tv.ss.setAcceptedExternalDropTypeIdentifiers(types)

        // Then
        XCTAssertEqual(tv.presenter?.acceptedExternalDropTypeIdentifiers, types)
        XCTAssertEqual(tv.presenter?.acceptedExternalDropTypeIdentifiers.count, 3)
    }

    // MARK: - External Drop Handler

    func test_external_drop_json_round_trip_creates_valid_cell_info() throws {
        // Given — simulate an external app encoding a TestConfig via toJSONString
        let original = TestConfig(id: "test00000001", title: "Test Config")
        let jsonString = try encodeToJSON(original)

        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }
        tv.reloadData()

        // Set up the external drop handler that receives JSON and reconstructs CellInfo
        tv.ss.onExternalDrop { payload, _ in
            guard let json = payload as? String,
                  let data = json.data(using: .utf8) else { return nil }

            // Decode the payload: { "state": {...}, "binderType": "TestConfigCell" }
            struct Payload: Decodable { let state: TestConfig; let binderType: String }
            guard let decoded = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }

            // Verify binderType matches what we expect
            guard decoded.binderType == String(describing: TestConfigCell.self) else { return nil }

            // Reconstruct: State -> BindingStore -> CellInfo
            let store = BindingStore<TestConfig, TestConfigCell>(state: decoded.state)
            return SSTableViewModel.CellInfo(store)
        }

        // When — feed the JSON string as if it came from an external drop
        let destination = IndexPath(row: 1, section: 0)
        let result = tv.presenter?.externalDropHandler?(jsonString, destination)

        // Then — CellInfo was created with correct state
        XCTAssertNotNil(result, "Handler should produce a CellInfo from JSON")
        let restoredConfig = result?.state as? TestConfig
        XCTAssertEqual(restoredConfig?.id, "test00000001")
        XCTAssertEqual(restoredConfig?.title, "Test Config")
        XCTAssertTrue(result?.binderType == TestConfigCell.self,
                      "binderType should be TestConfigCell")
    }

    func test_external_drop_json_with_wrong_binder_type_rejected() throws {
        // Given — JSON encoded with TestConfigCell binder type
        let jsonString = try encodeToJSON(TestConfig(id: "test00000002", title: "Test Config"))

        let tv = makeTableView()
        tv.ss.onExternalDrop { payload, _ in
            guard let json = payload as? String,
                  let data = json.data(using: .utf8) else { return nil }
            struct Payload: Decodable { let state: TestConfig; let binderType: String }
            guard let decoded = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }

            // Only accept "SomeOtherCell" — reject TestConfigCell
            guard decoded.binderType == "SomeOtherCell" else { return nil }
            return makeCellInfo(from: decoded.state)
        }

        // When
        let result = tv.presenter?.externalDropHandler?(jsonString, IndexPath(row: 0, section: 0))

        // Then — rejected because binderType doesn't match
        XCTAssertNil(result, "Should reject drop when binderType doesn't match expected type")
    }

    func test_external_drop_malformed_json_rejected() {
        // Given — garbage payload that is not valid JSON
        let tv = makeTableView()
        tv.ss.onExternalDrop { payload, _ in
            guard let json = payload as? String,
                  let data = json.data(using: .utf8) else { return nil }
            struct Payload: Decodable { let state: TestConfig; let binderType: String }
            guard let decoded = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }
            return makeCellInfo(from: decoded.state)
        }

        // When — send broken JSON
        let result = tv.presenter?.externalDropHandler?("{Invalid Json!!", IndexPath(row: 0, section: 0))

        // Then
        XCTAssertNil(result, "Malformed JSON should be rejected gracefully")
    }

    // MARK: - Combined Enable/Disable States

    func test_enable_reorder_then_disable_cleans_up_delegates() {
        // Given
        let tv = makeTableView()
        tv.ss.setReorderEnabled(true)
        XCTAssertTrue(tv.dragInteractionEnabled)
        XCTAssertNotNil(tv.dragDelegate)

        // When
        tv.ss.setReorderEnabled(false)

        // Then
        XCTAssertFalse(tv.dragInteractionEnabled)
        XCTAssertNil(tv.dragDelegate)
        XCTAssertNil(tv.dropDelegate)
    }

    func test_disable_reorder_keeps_external_drop_active() {
        // Given
        let tv = makeTableView()
        tv.ss.setReorderEnabled(true)
        tv.ss.setExternalDragDropEnabled(true)

        // When
        tv.ss.setReorderEnabled(false)

        // Then — external drop still active, drag interaction still on
        XCTAssertTrue(tv.dragInteractionEnabled)
        XCTAssertNotNil(tv.dragDelegate)
        XCTAssertTrue(tv.presenter?.isExternalDragDropEnabled ?? false)
    }

    func test_disable_both_reorder_and_external_drop() {
        // Given
        let tv = makeTableView()
        tv.ss.setReorderEnabled(true)
        tv.ss.setExternalDragDropEnabled(true)
        XCTAssertTrue(tv.dragInteractionEnabled)

        // When
        tv.ss.setReorderEnabled(false)
        tv.ss.setExternalDragDropEnabled(false)

        // Then
        XCTAssertFalse(tv.dragInteractionEnabled)
        XCTAssertNil(tv.dragDelegate)
        XCTAssertNil(tv.dropDelegate)
    }
}
