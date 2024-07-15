//
//  SectionInfoTests.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 17.06.2024.
//

import XCTest
@testable import SSTableViewPresenter
import UIKit

@MainActor
final class SectionInfoTests: XCTestCase {
    // MARK: - Default Init

    func test_section_info_default_init() {
        // When
        let section = SSTableViewModel.SectionInfo()

        // Then
        XCTAssertTrue(section.isEmpty)
        XCTAssertNil(section.identifier)
        XCTAssertNil(section.headerInfo())
        XCTAssertNil(section.footerInfo())
        XCTAssertFalse(section.isCollapsed)
    }

    // MARK: - Cell Access

    func test_section_info_cell_info_access() {
        // Given
        let cellInfos = makeCellInfos(from: makeSampleConfigs(63))
        let section = SSTableViewModel.SectionInfo(rows: cellInfos)

        // Then
        XCTAssertEqual(section.count, 63)
        XCTAssertNotNil(section.cellInfo(at: 0))
        XCTAssertNotNil(section.cellInfo(at: 2))
        XCTAssertNil(section.cellInfo(at: 64), "Out of bounds should return nil")
    }

    // MARK: - Append

    func test_section_info_append_cell_info() {
        // Given
        var section = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(1)))
        let newConfig = TestConfig(id: "1235", title: "NewConfig")

        // When
        section.appendCellInfo(newConfig, cellType: TestConfigCell.self)

        // Then
        XCTAssertEqual(section.count, 2)
    }

    // MARK: - Insert

    func test_section_info_insert_cell_info() {
        // Given
        var section = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(2)))
        let inserted = TestConfig(id: "1233", title: "PersonalizedConfig")

        // When
        section.insertCellInfo(inserted, cellType: TestConfigCell.self, at: 1)

        // Then
        XCTAssertEqual(section.count, 3)
    }

    func test_section_info_insert_cell_info_out_of_range() {
        // Given
        var section = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(11)))
        let config = TestConfig(id: "1243", title: "InvalidConfig")

        // When
        section.insertCellInfo(config, cellType: TestConfigCell.self, at: 19)

        // Then
        XCTAssertEqual(section.count, 11, "Out of range insert should be a no-op")
    }

    // MARK: - Update

    func test_section_info_update_cell_info() {
        // Given
        var section = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(30)))
        let updated = TestConfig(id: "1130", title: "UpdatedConfig")

        // When
        section.updateCellInfo(updated, cellType: TestConfigCell.self, at: 0)

        // Then
        XCTAssertEqual(section.count, 30, "Count should remain the same")
    }

    func test_section_info_update_cell_info_out_of_bounds() {
        // Given
        var section = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(11)))
        let config = TestConfig(id: "1231", title: "InvalidConfig")

        // When
        section.updateCellInfo(config, cellType: TestConfigCell.self, at: 19)

        // Then
        XCTAssertEqual(section.count, 11, "Out of bounds update should be a no-op")
    }

    // MARK: - Upsert

    func test_section_info_upsert_updates_existing() {
        // Given
        var section = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(11)))
        let upserted = TestConfig(id: "1331", title: "UpsertTest1")

        // When
        section.upsertCellInfo(upserted, cellType: TestConfigCell.self, at: 0)

        // Then
        XCTAssertEqual(section.count, 11, "Should update in place")
    }

    func test_section_info_upsert_appends_at_end() {
        // Given
        var section = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(58)))
        let upserted = TestConfig(id: "1442", title: "UpsertTest2")

        // When
        section.upsertCellInfo(upserted, cellType: TestConfigCell.self, at: 58)

        // Then
        XCTAssertEqual(section.count, 59, "Should append at endIndex")
    }

    func test_section_info_upsert_out_of_range() {
        // Given
        var section = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(63)))
        let config = TestConfig(id: "1660", title: "InvalidConfigItem")

        // When
        section.upsertCellInfo(config, cellType: TestConfigCell.self, at: 64)

        // Then
        XCTAssertEqual(section.count, 63, "Out of range upsert should be a no-op")
    }

    // MARK: - Header / Footer

    func test_section_info_set_header() {
        // Given
        var section = SSTableViewModel.SectionInfo()
        XCTAssertNil(section.headerInfo())

        // When
        section.setHeaderInfo(TestHeaderData(title: "Header"), viewType: TestHeaderView.self)

        // Then
        XCTAssertNotNil(section.headerInfo())
    }

    func test_section_info_set_footer() {
        // Given
        var section = SSTableViewModel.SectionInfo()
        XCTAssertNil(section.footerInfo())

        // When
        section.setFooterInfo(TestFooterData(text: "Footer"), viewType: TestFooterView.self)

        // Then
        XCTAssertNotNil(section.footerInfo())
    }

    // MARK: - Operators

    func test_section_info_plus_operator() {
        // Given
        let section1 = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(30)))
        let section2 = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(44)))

        // When
        let combined = section1 + section2

        // Then
        XCTAssertEqual(combined.count, 74)
    }

    func test_section_info_plus_equal_operator() {
        // Given
        var section1 = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(8)))
        let section2 = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(11)))

        // When
        section1 += section2

        // Then
        XCTAssertEqual(section1.count, 19)
    }

    func test_section_info_plus_cell_info_operator() {
        // Given
        let section = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(8)))
        let cellInfo = makeCellInfo(from: TestConfig(id: "1130", title: "MyItem"))

        // When
        let result = section + cellInfo

        // Then
        XCTAssertEqual(result.count, 9)
    }

    func test_section_info_plus_cell_info_array_operator() {
        // Given
        let section = SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(3)))
        let newCells = makeCellInfos(from: makeSampleConfigs(10))

        // When
        let result = section + newCells

        // Then
        XCTAssertEqual(result.count, 13)
    }

    // MARK: - Hashable

    func test_section_info_hashable_uses_uuid() {
        // Given — two SectionInfos with same data but different UUIDs
        let rows = makeCellInfos(from: makeSampleConfigs(3))
        let section1 = SSTableViewModel.SectionInfo(rows: rows, identifier: "SameSection")
        let section2 = SSTableViewModel.SectionInfo(rows: rows, identifier: "SameSection")

        // Then
        XCTAssertNotEqual(section1, section2, "Different SectionInfo instances should have different UUIDs")
        XCTAssertEqual(section1, section1, "Same instance should be equal")
    }
}
