//
//  RowOperationsTests.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 17.06.2024.
//

import XCTest
@testable import SSTableViewPresenter
import UIKit

@MainActor
final class RowOperationsTests: XCTestCase {
    // MARK: - Append Row

    func test_append_row_to_section() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(59), cellType: TestConfigCell.self) }
        }
        let newRow = makeCellInfo(from: TestConfig(id: "815", title: "Korea"))

        // When
        tv.ss.appendRow(newRow, toSection: 0)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 60)
    }

    func test_append_row_to_invalid_section() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(63), cellType: TestConfigCell.self) }
        }
        let newRow = makeCellInfo(from: TestConfig(id: "301", title: "Manse"))

        // When
        tv.ss.appendRow(newRow, toSection: 119)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 63, "Should be unchanged")
    }

    func test_append_rows_to_section() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
        }
        let newRows = makeCellInfos(from: makeSampleConfigs(19))

        // When
        tv.ss.appendRows(contentsOf: newRows, toSection: 0)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 20)
    }

    func test_append_row_by_section_identifier() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Apple") { builder.cells(makeSampleConfigs(7), cellType: TestConfigCell.self) }
            builder.section("Banana") { builder.cells(makeSampleConfigs(9), cellType: TestConfigCell.self) }
        }
        let newRow = makeCellInfo(from: TestConfig(id: "1713", title: "Google"))

        // When
        tv.ss.appendRow(newRow, sectionIdentifier: "Apple")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 8, "Apple section should grow")
        XCTAssertEqual(tv.ss.getViewModel()?[1].count, 9, "Banana section unchanged")
    }

    func test_append_rows_by_section_identifier() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Conan") { builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self) }
        }
        let rows = makeCellInfos(from: makeSampleConfigs(5))

        // When
        tv.ss.appendRows(contentsOf: rows, sectionIdentifier: "Conan")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 7)
    }

    func test_append_row_by_section_identifier_not_found_is_no_op() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Game") { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }
        let row = makeCellInfo(from: TestConfig(id: "book0001", title: "One Piece"))

        // When
        tv.ss.appendRow(row, sectionIdentifier: "Book")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 3)
    }

    func test_append_row_to_last_section() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(9), cellType: TestConfigCell.self) }
            builder.section { builder.cells(makeSampleConfigs(16), cellType: TestConfigCell.self) }
        }
        let newRow = makeCellInfo(from: TestConfig(id: "1818", title: "TestConfig"))

        // When
        tv.ss.appendRowToLastSection(newRow)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 9, "Section 0 unchanged")
        XCTAssertEqual(tv.ss.getViewModel()?[1].count, 17, "Section 1 should grow")
    }

    func test_append_row_to_last_section_with_empty_view_model_is_no_op() {
        // Given
        let tv = makeTableView()
        tv.ss.setViewModel(with: SSTableViewModel(sections: []))
        let row = makeCellInfo(from: TestConfig(id: "1990", title: "TestRow"))

        // When
        tv.ss.appendRowToLastSection(row)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 0, "Should remain empty")
    }

    // MARK: - Insert Row

    func test_insert_row() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(), cellType: TestConfigCell.self) }
        }
        let newRow = makeCellInfo(from: TestConfig(id: "2024", title: "TestRow"))

        // When
        tv.ss.insertRow(newRow, at: IndexPath(row: 1, section: 0))

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 9)
    }

    func test_insert_row_out_of_bounds() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(), cellType: TestConfigCell.self) }
        }
        let newRow = makeCellInfo(from: TestConfig(id: "2143", title: "InvalidRow"))

        // When
        tv.ss.insertRow(newRow, at: IndexPath(row: 11, section: 0))

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 8, "Out of bounds insert should be a no-op")
    }

    func test_insert_multiple_rows() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(), cellType: TestConfigCell.self) }
        }
        let newRows = makeCellInfos(from: makeSampleConfigs(11))

        // When
        tv.ss.insertRows(newRows, at: IndexPath(row: 1, section: 0))

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 19)
    }

    func test_insert_row_at_exact_end_index() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self) }
        }
        let row = makeCellInfo(from: TestConfig(id: "2323", title: "TestRow"))

        // When — insert at endIndex (== count) should succeed
        tv.ss.insertRow(row, at: IndexPath(row: 5, section: 0))

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 6)
    }

    func test_insert_row_by_identifier() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("AccountConfig") { builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self) }
        }
        let row = makeCellInfo(from: TestConfig(id: "3434", title: "TestRow"))

        // When
        tv.ss.insertRow(row, atRow: 2, sectionIdentifier: "AccountConfig")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 6)
    }

    func test_insert_rows_by_identifier() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("SubscriptionConfig") { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }
        let rows = makeCellInfos(from: makeSampleConfigs(4))

        // When
        tv.ss.insertRows(rows, atRow: 1, sectionIdentifier: "SubscriptionConfig")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 7)
    }

    func test_insert_row_by_identifier_at_end() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("DeveloperConfig") { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }
        let row = makeCellInfo(from: TestConfig(id: "4989", title: "Debug"))

        // When
        tv.ss.insertRow(row, atRow: 3, sectionIdentifier: "DeveloperConfig")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 4)
    }

    func test_insert_row_by_identifier_out_of_bounds_is_no_op() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("DeviceConfig") { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }
        let row = makeCellInfo(from: TestConfig(id: "-30000", title: "InvalidConfig"))

        // When
        tv.ss.insertRow(row, atRow: 90, sectionIdentifier: "DeviceConfig")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 3)
    }

    func test_insert_row_by_identifier_not_found_is_no_op() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("ConfigList") { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }
        let row = makeCellInfo(from: TestConfig(id: "-1111", title: "Typo"))

        // When
        tv.ss.insertRow(row, atRow: 0, sectionIdentifier: "KonfigList")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 3)
    }

    // MARK: - Replace Row

    func test_replace_row() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(), cellType: TestConfigCell.self) }
        }
        let updated = makeCellInfo(from: TestConfig(id: "8080", title: "I am protocol"))

        // When
        tv.ss.replaceRow(updated, at: IndexPath(row: 1, section: 0))

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 8, "Count should remain the same")
    }

    func test_replace_row_by_section_identifier() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Game") { builder.cells(makeSampleConfigs(9), cellType: TestConfigCell.self) }
        }
        let updated = makeCellInfo(from: TestConfig(id: "1024", title: "2^10"))

        // When
        tv.ss.replaceRow(updated, atRow: 0, sectionIdentifier: "Game")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 9, "Count should remain the same")
    }

    func test_replace_row_by_identifier_not_found_is_no_op() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Animation") { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }
        let replacement = makeCellInfo(from: TestConfig(id: "2009", title: "Beethoven Virus"))

        // When
        tv.ss.replaceRow(replacement, atRow: 0, sectionIdentifier: "Drama")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 3, "Should be unchanged")
    }

    // MARK: - Remove Row

    func test_remove_row() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(63), cellType: TestConfigCell.self) }
        }

        // When
        tv.ss.removeRow(at: IndexPath(row: 1, section: 0))

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 62)
    }

    func test_remove_row_out_of_bounds() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(71), cellType: TestConfigCell.self) }
        }

        // When
        tv.ss.removeRow(at: IndexPath(row: 74, section: 0))

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 71, "Should be unchanged")
    }

    func test_remove_multiple_rows() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(11), cellType: TestConfigCell.self) }
        }

        // When
        tv.ss.removeRows(at: [
            IndexPath(row: 0, section: 0),
            IndexPath(row: 2, section: 0),
            IndexPath(row: 4, section: 0)
        ])

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 8)
    }

    func test_remove_rows_multi_section_correct_order() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(11), cellType: TestConfigCell.self) }
            builder.section { builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self) }
        }

        // When
        tv.ss.removeRows(at: [
            IndexPath(row: 1, section: 0),
            IndexPath(row: 3, section: 0),
            IndexPath(row: 0, section: 1),
            IndexPath(row: 2, section: 1)
        ])

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 9, "Section 0: 11 - 2 = 9")
        XCTAssertEqual(tv.ss.getViewModel()?[1].count, 3, "Section 1: 5 - 2 = 3")
    }

    func test_remove_all_rows_in_section() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
            builder.section { builder.cells(makeSampleConfigs(7), cellType: TestConfigCell.self) }
        }

        // When
        tv.ss.removeAllRows(inSection: 1)

        // Then — section still exists, but empty
        XCTAssertEqual(tv.ss.getViewModel()?.count, 2)
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 3)
        XCTAssertEqual(tv.ss.getViewModel()?[1].count, 0)
    }

    func test_remove_row_by_row_and_identifier() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Favorites") { builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self) }
        }

        // When
        tv.ss.removeRow(atRow: 0, sectionIdentifier: "Favorites")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 4)
    }

    func test_remove_all_rows_by_section_identifier() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Cart") { builder.cells(makeSampleConfigs(4), cellType: TestConfigCell.self) }
            builder.section("Todo") { builder.cells(makeSampleConfigs(6), cellType: TestConfigCell.self) }
        }

        // When
        tv.ss.removeAllRows(sectionIdentifier: "Todo")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 4)
        XCTAssertEqual(tv.ss.getViewModel()?[1].count, 0)
    }

    func test_remove_row_by_section_identifier_non_existent_is_no_op() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Keyboard") { builder.cells(makeSampleConfigs(4), cellType: TestConfigCell.self) }
        }

        // When
        tv.ss.removeRow(atRow: 0, sectionIdentifier: "TrackPad")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 4, "Should be unchanged")
    }

    // MARK: - Move Row

    func test_move_row_within_same_section() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self) }
        }

        // When — move row 0 -> 3
        tv.ss.moveRow(from: IndexPath(row: 0, section: 0), to: IndexPath(row: 3, section: 0))

        // Then — count unchanged
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 5)
    }

    func test_move_row_across_sections() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(4), cellType: TestConfigCell.self) }
            builder.section { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }

        // When
        tv.ss.moveRow(from: IndexPath(row: 0, section: 0), to: IndexPath(row: 1, section: 1))

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 3, "Section 0 shrinks")
        XCTAssertEqual(tv.ss.getViewModel()?[1].count, 4, "Section 1 grows")
    }

    func test_move_row_out_of_bounds_source_is_no_op() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }

        // When
        tv.ss.moveRow(from: IndexPath(row: 99, section: 0), to: IndexPath(row: 0, section: 0))

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 3)
    }

    func test_move_row_destination_clamped_to_end() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(4), cellType: TestConfigCell.self) }
            builder.section { builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self) }
        }

        // When — destination row exceeds count -> clamped to end
        tv.ss.moveRow(from: IndexPath(row: 0, section: 0), to: IndexPath(row: 19, section: 1))

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?[0].count, 3)
        XCTAssertEqual(tv.ss.getViewModel()?[1].count, 3)
    }

    // MARK: - Lookup

    func test_row_count_in_section() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(7), cellType: TestConfigCell.self) }
            builder.section { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }

        // Then
        XCTAssertEqual(tv.ss.rowCount(inSection: 0), 7)
        XCTAssertEqual(tv.ss.rowCount(inSection: 1), 3)
        XCTAssertEqual(tv.ss.rowCount(inSection: 2), 0)
    }

    func test_row_count_by_section_identifier() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Starcraft") { builder.cells(makeSampleConfigs(4), cellType: TestConfigCell.self) }
            builder.section("Warcraft") { builder.cells(makeSampleConfigs(12), cellType: TestConfigCell.self) }
        }

        // Then
        XCTAssertEqual(tv.ss.rowCount(sectionIdentifier: "Starcraft"), 4)
        XCTAssertEqual(tv.ss.rowCount(sectionIdentifier: "Warcraft"), 12)
        XCTAssertEqual(tv.ss.rowCount(sectionIdentifier: "LOL"), 0)
    }

    func test_row_at_index_path() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self) }
        }

        // Then
        XCTAssertNotNil(tv.ss.row(at: IndexPath(row: 0, section: 0)))
        XCTAssertNotNil(tv.ss.row(at: IndexPath(row: 4, section: 0)))
        XCTAssertNil(tv.ss.row(at: IndexPath(row: 5, section: 0)))
        XCTAssertNil(tv.ss.row(at: IndexPath(row: 0, section: 1)))
    }

    func test_row_by_row_and_identifier() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Pokemon") { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }

        // Then
        XCTAssertNotNil(tv.ss.row(atRow: 0, sectionIdentifier: "Pokemon"))
        XCTAssertNotNil(tv.ss.row(atRow: 2, sectionIdentifier: "Pokemon"))
        XCTAssertNil(tv.ss.row(atRow: 3, sectionIdentifier: "Pokemon"))
        XCTAssertNil(tv.ss.row(atRow: 0, sectionIdentifier: "Digimon"))
    }

    func test_row_count_on_empty_presenter() {
        // Given
        let tv = makeTableView()

        // Then
        XCTAssertEqual(tv.ss.rowCount(inSection: 0), 0)
        XCTAssertEqual(tv.ss.rowCount(sectionIdentifier: "zxcv"), 0)
        XCTAssertNil(tv.ss.row(at: IndexPath(row: 0, section: 0)))
    }
}
