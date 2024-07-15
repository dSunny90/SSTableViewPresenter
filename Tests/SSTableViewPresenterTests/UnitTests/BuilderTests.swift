//
//  BuilderTests.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 18.06.2024.
//

import XCTest
@testable import SSTableViewPresenter
import UIKit

@MainActor
final class BuilderTests: XCTestCase {
    // MARK: - Basic Builder

    func test_build_view_model_creates_correct_structure() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs(7)

        // When
        let result = tv.ss.buildViewModel { builder in
            builder.section("TestSection") {
                builder.cells(configs, cellType: TestConfigCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.count, 1, "Should have 1 section")
        XCTAssertEqual(result[0].count, 7, "Section should have 7 rows")
        XCTAssertEqual(result[0].identifier, "TestSection")
    }

    func test_build_view_model_with_multiple_sections() {
        // Given
        let tv = makeTableView()
        let section0 = makeSampleConfigs(5)
        let section1 = makeSampleConfigs(10)

        // When
        let result = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(section0, cellType: TestConfigCell.self)
            }
            builder.section {
                builder.cells(section1, cellType: TestConfigCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].count, 5)
        XCTAssertEqual(result[1].count, 10)
    }

    func test_build_view_model_single_cell() {
        // Given
        let tv = makeTableView()
        let config = TestConfig(id: "429", title: "TestTitle")

        // When
        let result = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cell(config, cellType: TestConfigCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 1)
    }

    func test_build_view_model_with_header_and_footer() {
        // Given
        let tv = makeTableView()
        let configs = makeSampleConfigs(5)
        let headerData = TestHeaderData(title: "Section Header")
        let footerData = TestFooterData(text: "Section Footer")

        // When
        let result = tv.ss.buildViewModel { builder in
            builder.section {
                builder.header(headerData, viewType: TestHeaderView.self)
                builder.footer(footerData, viewType: TestFooterView.self)
                builder.cells(configs, cellType: TestConfigCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 5)
        XCTAssertNotNil(result[0].headerInfo())
        XCTAssertNotNil(result[0].footerInfo())
    }

    func test_build_view_model_sets_page_and_has_next() {
        // Given
        let tv = makeTableView()

        // When
        let result = tv.ss.buildViewModel(page: 3, hasNext: true) { builder in
            builder.section {
                builder.cells(makeSampleConfigs(1), cellType: TestConfigCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.page, 3)
        XCTAssertTrue(result.hasNext)
    }

    func test_builder_implicit_section_creation() {
        // Given
        let builder = SSTableViewModel.Builder()

        // When
        builder.cell(TestConfig(id: "90", title: "SomeConfigItem 0"), cellType: TestConfigCell.self)
        builder.cell(TestConfig(id: "30", title: "SomeConfigItem 1"), cellType: TestConfigCell.self)
        let model = builder.build()

        // Then
        XCTAssertEqual(model.count, 1, "Should auto-create one implicit section")
        XCTAssertEqual(model[0].count, 2)
    }

    func test_builder_empty_section_is_still_created() {
        // Given
        let builder = SSTableViewModel.Builder()

        // When
        builder.section("EmptySection") { }
        let model = builder.build()

        // Then
        XCTAssertEqual(model.count, 1, "Empty section should still be present")
        XCTAssertEqual(model[0].count, 0)
        XCTAssertEqual(model[0].identifier, "EmptySection")
    }

    func test_builder_chained_sections() {
        // Given
        let builder = SSTableViewModel.Builder()

        // When
        builder
            .section("RemoteConfig") {
                builder.cell(TestConfig(id: "2119", title: "RemoteConfigItem 0"), cellType: TestConfigCell.self)
            }
            .section("LocalConfig") {
                builder.cell(TestConfig(id: "2234", title: "LocalConfigItem 0"), cellType: TestConfigCell.self)
            }
        let model = builder.build()

        // Then
        XCTAssertEqual(model.count, 2)
        XCTAssertEqual(model[0].identifier, "RemoteConfig")
        XCTAssertEqual(model[1].identifier, "LocalConfig")
    }

    func test_builder_no_section_no_rows_produces_empty_model() {
        // Given
        let builder = SSTableViewModel.Builder()

        // When
        let model = builder.build()

        // Then
        XCTAssertTrue(model.isEmpty)
    }

    func test_builder_multiple_cells_then_section_auto_closes() {
        // Given
        let builder = SSTableViewModel.Builder()

        // When
        builder.cell(TestConfig(id: "0001", title: "Account Config Item"), cellType: TestConfigCell.self)
        builder.section("Remote Config") {
            builder.cell(TestConfig(id: "0002", title: "Some Config Item"), cellType: TestConfigCell.self)
        }
        let model = builder.build()

        // Then
        XCTAssertEqual(model.count, 2, "Implicit section + explicit section")
        XCTAssertEqual(model[0].count, 1)
        XCTAssertEqual(model[1].count, 1)
        XCTAssertEqual(model[1].identifier, "Remote Config")
    }

    func test_build_view_model_has_no_page_data() {
        // Given
        let tv = makeTableView()

        // When
        let result = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(10), cellType: TestConfigCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 10)
        XCTAssertFalse(result.hasPageData, "buildViewModel should not use pageMap")
    }

    func test_builder_cell_actionClosure_is_called() {
        // Given
        let tv = makeTableView()
        tv.ss.setupPresenter()

        let configs = makeSampleConfigs(3)
        var received: (indexPath: IndexPath, action: String, input: Any?)?

        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(
                    configs,
                    cellType: TestConfigCell.self,
                    actionClosure: { indexPath, _, action, input in
                        received = (indexPath, action, input)
                    }
                )
            }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        // Dequeue cell through data source to ensure provider sets actionClosure
        let indexPath = IndexPath(row: 1, section: 0)
        guard let cell = tv.dataSource?.tableView(tv, cellForRowAt: indexPath) as? UITableViewCell else {
            XCTFail("Failed to dequeue cell")
            return
        }

        // When — manually invoke the actionClosure on cell
        cell.actionClosure?("tap", nil)

        // Then
        XCTAssertEqual(received?.indexPath, indexPath)
        XCTAssertEqual(received?.action, "tap")
    }

    func test_builder_header_footer_actionClosure_are_called() {
        // Given
        let tv = makeTableView()
        tv.ss.setupPresenter()

        let configs = makeSampleConfigs(1)
        var headerReceived: (section: Int, action: String)?
        var footerReceived: (section: Int, action: String)?

        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.header(TestHeaderData(title: "H"), viewType: TestHeaderView.self) { section, _, action, _ in
                    headerReceived = (section, action)
                }
                builder.footer(TestFooterData(text: "F"), viewType: TestFooterView.self) { section, _, action, _ in
                    footerReceived = (section, action)
                }
                builder.cells(configs, cellType: TestConfigCell.self)
            }
        }
        tv.reloadData()
        tv.layoutIfNeeded()

        let header = tv.headerView(forSection: 0) as? TestHeaderView
        let footer = tv.footerView(forSection: 0) as? TestFooterView

        // When — manually invoke the actionClosure on views
        header?.actionClosure?("headerTap", nil)
        footer?.actionClosure?("footerTap", nil)

        // Then
        XCTAssertEqual(headerReceived?.section, 0)
        XCTAssertEqual(headerReceived?.action, "headerTap")

        XCTAssertEqual(footerReceived?.section, 0)
        XCTAssertEqual(footerReceived?.action, "footerTap")
    }

    // MARK: - ExtendViewModel

    func test_extend_view_model_appends_to_existing_section() {
        // Given
        let tv = makeTableView()

        _ = tv.ss.buildViewModel { builder in
            builder.section("Korea") {
                builder.cells(makeSampleConfigs(4), cellType: TestConfigCell.self)
            }
        }

        // When
        let extended = tv.ss.extendViewModel(page: 1, hasNext: false) { builder in
            builder.section("Korea") {
                builder.cells(makeSampleConfigs(7), cellType: TestConfigCell.self)
            }
        }

        // Then
        XCTAssertEqual(extended.count, 1, "Should still be 1 section")
        XCTAssertEqual(extended[0].count, 11, "Should have 4 + 7 = 11 rows")
        XCTAssertEqual(extended.page, 1)
        XCTAssertFalse(extended.hasNext)
    }

    func test_extend_view_model_adds_new_section() {
        // Given
        let tv = makeTableView()

        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(11), cellType: TestConfigCell.self)
            }
        }

        // When
        let extended = tv.ss.extendViewModel { builder in
            builder.section {
                builder.cells(makeSampleConfigs(19), cellType: TestConfigCell.self)
            }
        }

        // Then
        XCTAssertEqual(extended.count, 2, "Should have 2 sections")
        XCTAssertEqual(extended[0].count, 11)
        XCTAssertEqual(extended[1].count, 19)
    }

    func test_extend_view_model_with_no_existing_view_model() {
        // Given
        let tv = makeTableView()
        XCTAssertNil(tv.ss.getViewModel())

        // When
        let result = tv.ss.extendViewModel { builder in
            builder.section("ZZZ") {
                builder.cells(makeSampleConfigs(23), cellType: TestConfigCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 23)
        XCTAssertEqual(result[0].identifier, "ZZZ")
    }

    func test_extend_view_model_has_no_page_data() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("X") {
                builder.cells(makeSampleConfigs(4), cellType: TestConfigCell.self)
            }
        }

        // When
        let result = tv.ss.extendViewModel(page: 1, hasNext: false) { builder in
            builder.section("X") {
                builder.cells(makeSampleConfigs(7), cellType: TestConfigCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 11)
        XCTAssertFalse(result.hasPageData, "extendViewModel should not use pageMap")
    }

    func test_extend_view_model_replaces_header_and_footer() {
        // Given
        let tv = makeTableView()
        _ = tv.ss.buildViewModel { builder in
            builder.section("Y") {
                builder.header(TestHeaderData(title: "OldHeader"), viewType: TestHeaderView.self)
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }

        // When
        let result = tv.ss.extendViewModel { builder in
            builder.section("Y") {
                builder.header(TestHeaderData(title: "NewHeader"), viewType: TestHeaderView.self)
                builder.footer(TestFooterData(text: "NewFooter"), viewType: TestFooterView.self)
                builder.cells(makeSampleConfigs(2), cellType: TestConfigCell.self)
            }
        }

        // Then
        XCTAssertEqual(result[0].count, 5, "3 + 2 rows")
        XCTAssertNotNil(result[0].headerInfo())
        XCTAssertNotNil(result[0].footerInfo())
    }

    // MARK: - Builder sections() API (Server-Driven)

    func test_builder_sections_api_with_server_state_section_representable() {
        // Given
        struct MockUnit: ServerStateUnitRepresentable {
            let unitType: String
            let unitData: Any?
        }
        struct MockSection: ServerStateSectionRepresentable {
            let sectionId: String?
            let units: [any ServerStateUnitRepresentable]
        }

        let sectionList: [MockSection] = [
            MockSection(sectionId: "remote", units: [
                MockUnit(unitType: "REMOTE", unitData: [TestConfig(id: "0001", title: "Top Banner")])
            ]),
            MockSection(sectionId: "etc", units: [
                MockUnit(unitType: "ETC", unitData: makeSampleConfigs(5))
            ])
        ]

        let builder = SSTableViewModel.Builder()

        // When
        builder.sections(
            sectionList,
            configureUnit: { unit, builder in
                switch unit.unitType {
                case "REMOTE":
                    guard let remoteConfigs = unit.unitData as? [TestConfig] else { return }
                    builder.cells(remoteConfigs, cellType: TestConfigCell.self)
                case "ETC":
                    guard let etcConfigs = unit.unitData as? [TestConfig] else { return }
                    builder.cells(etcConfigs, cellType: TestConfigCell.self)
                default:
                    break
                }
            }
        )
        let model = builder.build()

        // Then
        XCTAssertEqual(model.count, 2)
        XCTAssertEqual(model[0].identifier, "remote")
        XCTAssertEqual(model[0].count, 1)
        XCTAssertEqual(model[1].identifier, "etc")
        XCTAssertEqual(model[1].count, 5)
    }

    func test_builder_sections_api_with_configure_section() {
        // Given
        struct MockUnit: ServerStateUnitRepresentable {
            let unitType: String
            let unitData: Any?
        }
        struct MockSection: ServerStateSectionRepresentable {
            let sectionId: String?
            let units: [any ServerStateUnitRepresentable]
        }

        let sectionList: [MockSection] = [
            MockSection(sectionId: "designSystemTest", units: [
                MockUnit(unitType: "ROW", unitData: makeSampleConfigs(3))
            ])
        ]

        let builder = SSTableViewModel.Builder()

        // When
        builder.sections(
            sectionList,
            configureUnit: { unit, builder in
                guard let rows = unit.unitData as? [TestConfig] else { return }
                builder.cells(rows, cellType: TestConfigCell.self)
            }
        )
        let model = builder.build()

        // Then
        XCTAssertEqual(model.count, 1)
    }

    // MARK: - Index Titles Builder

    func test_build_with_index_titles_enabled() {
        // Given
        let builder = SSTableViewModel.Builder()

        // When
        builder.section {
            builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
        }
        let model = builder.build(isIndexTitlesEnabled: true)

        // Then
        XCTAssertTrue(model.isIndexTitlesEnabled)
    }

    func test_build_with_index_titles_disabled() {
        // Given
        let builder = SSTableViewModel.Builder()

        // When
        builder.section {
            builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
        }
        let model = builder.build(isIndexTitlesEnabled: false)

        // Then
        XCTAssertFalse(model.isIndexTitlesEnabled)
    }
}
