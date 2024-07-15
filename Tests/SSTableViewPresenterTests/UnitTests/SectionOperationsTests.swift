//
//  SectionOperationsTests.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 23.06.2024.
//

import XCTest
@testable import SSTableViewPresenter
import UIKit

@MainActor
final class SectionOperationsTests: XCTestCase {
    // MARK: - Append

    func test_append_section() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(11), cellType: TestConfigCell.self)
            }
        }
        let newSection = SSTableViewModel.SectionInfo(
            rows: makeCellInfos(from: makeSampleConfigs(23)),
            identifier: "NewSection"
        )

        // When
        tv.ss.appendSection(newSection)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 2)
    }

    func test_append_multiple_sections() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(11), cellType: TestConfigCell.self)
            }
        }
        let sections = [
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(23))),
            SSTableViewModel.SectionInfo(rows: makeCellInfos(from: makeSampleConfigs(67)))
        ]

        // When
        tv.ss.appendSections(contentsOf: sections)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 3)
    }

    func test_append_section_with_no_view_model_is_no_op() {
        // Given
        let tv = makeTableView()
        let section = SSTableViewModel.SectionInfo(rows: [])

        // When
        tv.ss.appendSection(section)

        // Then
        XCTAssertNil(tv.ss.getViewModel())
    }

    // MARK: - Insert

    func test_insert_section_at_beginning() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Hello") {
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }
        let newSection = SSTableViewModel.SectionInfo(
            rows: makeCellInfos(from: makeSampleConfigs(2)),
            identifier: "Swift"
        )

        // When
        tv.ss.insertSection(newSection, at: 0)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 2)
        XCTAssertEqual(tv.ss.getViewModel()?.sections[0].identifier, "Swift")
        XCTAssertEqual(tv.ss.getViewModel()?.sections[1].identifier, "Hello")
    }

    func test_insert_section_at_middle() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("안녕") {
                builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self)
            }
            builder.section("Halo") {
                builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self)
            }
        }
        let newSection = SSTableViewModel.SectionInfo(
            rows: makeCellInfos(from: makeSampleConfigs(2)),
            identifier: "Hello"
        )

        // When
        tv.ss.insertSection(newSection, at: 1)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 3)
        XCTAssertEqual(tv.ss.getViewModel()?.sections[0].identifier, "안녕")
        XCTAssertEqual(tv.ss.getViewModel()?.sections[1].identifier, "Hello")
        XCTAssertEqual(tv.ss.getViewModel()?.sections[2].identifier, "Halo")
    }

    func test_insert_section_out_of_bounds_is_no_op() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self)
            }
        }
        let newSection = SSTableViewModel.SectionInfo(rows: [])

        // When
        tv.ss.insertSection(newSection, at: 99)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 1)
    }

    func test_insert_multiple_sections() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Mango") {
                builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self)
            }
            builder.section("Strawberry") {
                builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self)
            }
        }
        let newSections = [
            SSTableViewModel.SectionInfo(rows: [], identifier: "Apple"),
            SSTableViewModel.SectionInfo(rows: [], identifier: "Banana")
        ]

        // When
        tv.ss.insertSections(newSections, at: 1)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 4)
        XCTAssertEqual(tv.ss.getViewModel()?.sections[1].identifier, "Apple")
        XCTAssertEqual(tv.ss.getViewModel()?.sections[2].identifier, "Banana")
        XCTAssertEqual(tv.ss.getViewModel()?.sections[3].identifier, "Strawberry")
    }

    // MARK: - Remove

    func test_remove_section_at_index() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Climbing") {
                builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self)
            }
            builder.section("Skating") {
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }

        // When
        tv.ss.removeSection(at: 1)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 1)
        XCTAssertEqual(tv.ss.getViewModel()?.sections[0].identifier, "Climbing")
    }

    func test_remove_section_out_of_bounds_is_no_op() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self)
            }
        }

        // When
        tv.ss.removeSection(at: 5)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 1)
    }

    func test_remove_sections_at_multiple_indices() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("I") { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
            builder.section("My") { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
            builder.section("Me") { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
            builder.section("Mine") { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
        }

        // When — remove index 1 and 3
        tv.ss.removeSections(at: IndexSet([1, 3]))

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 2)
        XCTAssertEqual(tv.ss.getViewModel()?.sections[0].identifier, "I")
        XCTAssertEqual(tv.ss.getViewModel()?.sections[1].identifier, "Me")
    }

    func test_remove_section_by_identifier() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("MainConfig") {
                builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self)
            }
            builder.section("DeviceConfig") {
                builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self)
            }
        }

        // When
        tv.ss.removeSection(identifier: "MainConfig")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 1)
        XCTAssertEqual(tv.ss.getViewModel()?.sections[0].identifier, "DeviceConfig")
    }

    func test_remove_section_by_identifier_not_found_is_no_op() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("ProductList") {
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }

        // When
        tv.ss.removeSection(identifier: "asdf")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 1)
    }

    func test_remove_all_sections() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self) }
            builder.section { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }

        // When
        tv.ss.removeAllSections()

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 0)
    }

    // MARK: - Replace

    func test_replace_section_at_index() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Old") {
                builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self)
            }
        }
        let replacement = SSTableViewModel.SectionInfo(
            rows: makeCellInfos(from: makeSampleConfigs(5)),
            identifier: "New"
        )

        // When
        tv.ss.replaceSection(replacement, at: 0)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 1)
        XCTAssertEqual(tv.ss.getViewModel()?.sections[0].identifier, "New")
        XCTAssertEqual(tv.ss.getViewModel()?.sections[0].count, 5)
    }

    func test_replace_section_at_index_out_of_bounds_is_no_op() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Original") {
                builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self)
            }
        }
        let replacement = SSTableViewModel.SectionInfo(rows: [], identifier: "Brood War")

        // When
        tv.ss.replaceSection(replacement, at: 5)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 1)
        XCTAssertEqual(tv.ss.getViewModel()?.sections[0].identifier, "Original")
    }

    func test_replace_section_by_identifier() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("MainConfig") { builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self) }
            builder.section("PhoneConfig") { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }
        let replacement = SSTableViewModel.SectionInfo(
            rows: makeCellInfos(from: makeSampleConfigs(10)),
            identifier: "DeviceConfig"
        )

        // When
        tv.ss.replaceSection(replacement, identifier: "PhoneConfig")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 2)
        XCTAssertEqual(tv.ss.getViewModel()?.sections[1].identifier, "DeviceConfig")
        XCTAssertEqual(tv.ss.getViewModel()?.sections[1].count, 10)
    }

    func test_replace_section_by_identifier_not_found_is_no_op() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("ProductList") { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }
        let replacement = SSTableViewModel.SectionInfo(rows: [], identifier: "Fake")

        // When
        tv.ss.replaceSection(replacement, identifier: "qwer")

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.count, 1)
        XCTAssertEqual(tv.ss.getViewModel()?.sections[0].identifier, "ProductList")
    }

    // MARK: - Move

    func test_move_section_forward() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Chovy") { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
            builder.section("Peyz") { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
            builder.section("Lehends") { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
        }

        // When — move index 0 -> 2
        tv.ss.moveSection(from: 0, to: 2)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.sections[0].identifier, "Peyz")
        XCTAssertEqual(tv.ss.getViewModel()?.sections[1].identifier, "Lehends")
        XCTAssertEqual(tv.ss.getViewModel()?.sections[2].identifier, "Chovy")
    }

    func test_move_section_backward() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Kiin") { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
            builder.section("Canyon") { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
            builder.section("Chovy") { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
        }

        // When — move index 2 -> 0
        tv.ss.moveSection(from: 2, to: 0)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.sections[0].identifier, "Chovy")
        XCTAssertEqual(tv.ss.getViewModel()?.sections[1].identifier, "Kiin")
        XCTAssertEqual(tv.ss.getViewModel()?.sections[2].identifier, "Canyon")
    }

    func test_move_section_same_index_is_no_op() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("AccountConfig") { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
            builder.section("AdConfig") { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
        }

        // When
        tv.ss.moveSection(from: 0, to: 0)

        // Then
        XCTAssertEqual(tv.ss.getViewModel()?.sections[0].identifier, "AccountConfig")
        XCTAssertEqual(tv.ss.getViewModel()?.sections[1].identifier, "AdConfig")
    }

    // MARK: - Lookup

    func test_section_count() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
            builder.section { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
            builder.section { builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self) }
        }

        // Then
        XCTAssertEqual(tv.ss.sectionCount, 3)
    }

    func test_section_count_empty_view_model() {
        // Given
        let tv = makeTableView()

        // Then
        XCTAssertEqual(tv.ss.sectionCount, 0)
    }

    func test_section_at_index() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("2024") {
                builder.cells(makeSampleConfigs(5), cellType: TestConfigCell.self)
            }
        }

        // Then
        XCTAssertEqual(tv.ss.section(at: 0)?.identifier, "2024")
        XCTAssertEqual(tv.ss.section(at: 0)?.count, 5)
        XCTAssertNil(tv.ss.section(at: 123))
    }

    func test_section_by_identifier() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("RemoteConfig") { builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self) }
            builder.section("LocalConfig") { builder.cells(makeSampleConfigs(7), cellType: TestConfigCell.self) }
        }

        // Then
        XCTAssertEqual(tv.ss.section(identifier: "LocalConfig")?.count, 7)
        XCTAssertNil(tv.ss.section(identifier: "qwerasdf"))
    }

    func test_section_index_by_identifier() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("RemoteConfig") { builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self) }
            builder.section("LocalConfig") { builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self) }
        }

        // Then
        XCTAssertEqual(tv.ss.sectionIndex(identifier: "RemoteConfig"), 0)
        XCTAssertEqual(tv.ss.sectionIndex(identifier: "LocalConfig"), 1)
        XCTAssertNil(tv.ss.sectionIndex(identifier: "asdfqwer"))
    }
}
