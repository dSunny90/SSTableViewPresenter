//
//  SectionControlTests.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 23.06.2024.
//

import XCTest
@testable import SSTableViewPresenter
import UIKit

@MainActor
final class SectionControlTests: XCTestCase {
    // MARK: - Reconfigure Item/Header/Footer

    func test_reconfigure_row_updates_visible_cell() {
        // Given
        let tv = makeTableView()
        tv.ss.setupPresenter()

        let configs = makeSampleConfigs(3)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(configs, cellType: TestConfigCell.self)
            }
        }

        tv.reloadData()
        tv.layoutIfNeeded()

        let indexPath = IndexPath(row: 1, section: 0)
        let cell = tv.cellForRow(at: indexPath) as? TestConfigCell
        XCTAssertEqual(cell?.titleLabel.text, configs[1].title)

        // When — reconfigure with updated state
        let updated = TestConfig(id: configs[1].id, title: "Updated Config")
        tv.ss.reconfigureRow(updated, at: indexPath)

        // Then — cell should reflect new title
        XCTAssertEqual(cell?.titleLabel.text, "Updated Config")
    }

    func test_reconfigure_header_and_footer_update_visible_views() {
        // Given
        let tv = makeTableView()
        tv.ss.setupPresenter()

        let configs = makeSampleConfigs(1)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.header(TestHeaderData(title: "Header-Old"), viewType: TestHeaderView.self)
                builder.footer(TestFooterData(text: "Footer-Old"), viewType: TestFooterView.self)
                builder.cells(configs, cellType: TestConfigCell.self)
            }
        }

        tv.reloadData()
        tv.layoutIfNeeded()

        let header = tv.headerView(forSection: 0) as? TestHeaderView
        let footer = tv.footerView(forSection: 0) as? TestFooterView
        XCTAssertEqual(header?.titleLabel.text, "Header-Old")
        XCTAssertEqual(footer?.titleLabel.text, "Footer-Old")

        // When
        tv.ss.reconfigureHeader(TestHeaderData(title: "Header-New"), at: 0)
        tv.ss.reconfigureFooter(TestFooterData(text: "Footer-New"), at: 0)

        // Then
        XCTAssertEqual(header?.titleLabel.text, "Header-New")
        XCTAssertEqual(footer?.titleLabel.text, "Footer-New")
    }

    // MARK: - toggleSection

    func test_toggleSection_call_manually_and_reconfigure_header() {
        // Given
        let tv = makeTableView()
        tv.ss.setupPresenter()

        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.header(TestHeaderData(title: "expanded"), viewType: TestHeaderView.self)
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }

        tv.reloadData()
        tv.layoutIfNeeded()

        // Initially not collapsed
        XCTAssertEqual(tv.ss.getViewModel()?[0].isCollapsed, false)

        // When
        tv.ss.toggleSection(0) { collapsed in
            // Then
            XCTAssertEqual(tv.ss.getViewModel()?[0].isCollapsed, true)

            let title = collapsed ? "collapsed" : "expanded"

            let newState = TestHeaderData(title: title)
            tv.ss.reconfigureHeader(newState, at: 0)

            let aHeader = tv.headerView(forSection: 0) as? TestHeaderView
            XCTAssertEqual(aHeader?.ss.state()?.title, title)
        }
    }

    func test_toggleSection_in_action_closure_and_reconfigure_header() {
        // Given
        let tv = makeTableView()
        tv.ss.setupPresenter()

        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.header(TestHeaderData(title: "expanded"), viewType: TestHeaderView.self) { section, _, _, _ in
                    tv.ss.toggleSection(0) { collapsed in
                        // Then
                        XCTAssertEqual(tv.ss.getViewModel()?[0].isCollapsed, true)

                        let title = collapsed ? "collapsed" : "expanded"

                        let newState = TestHeaderData(title: title)
                        tv.ss.reconfigureHeader(newState, at: section)

                        let aHeader = tv.headerView(forSection: 0) as? TestHeaderView
                        XCTAssertEqual(aHeader?.ss.state()?.title, title)
                    }
                }
                builder.cells(makeSampleConfigs(3), cellType: TestConfigCell.self)
            }
        }

        tv.reloadData()
        tv.layoutIfNeeded()

        // Initially not collapsed
        XCTAssertEqual(tv.ss.getViewModel()?[0].isCollapsed, false)

        // When
        let header = tv.headerView(forSection: 0) as? TestHeaderView
        header?.actionClosure?("toggle", nil)

        // Then - toggleSection in completion closure
    }
}
