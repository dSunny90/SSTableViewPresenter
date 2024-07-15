//
//  TestFixtures.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 24.04.2021.
//

import XCTest
@testable import SSTableViewPresenter
import UIKit

// MARK: - Test Models

struct TestConfig: Codable, Sendable {
    let id: String
    let title: String
}

struct TestHeaderData: Sendable {
    let title: String
}

struct TestFooterData: Sendable {
    let text: String
}

// MARK: - Test Cells

final class TestConfigCell: UITableViewCell, SSTableViewCellProtocol {
    let titleLabel = UILabel()
    var didSelectCalled = false
    var didDeselectCalled = false
    var didHighlightCalled = false
    var didUnhighlightCalled = false
    var willDisplayCalled = false
    var didEndDisplayingCalled = false

    static func size(with input: TestConfig?, constrainedTo parentSize: CGSize?) -> CGSize? {
        return CGSize(width: 375, height: 44)
    }

    var configurer: (TestConfigCell, TestConfig) -> Void {
        { view, model in
            view.titleLabel.text = model.title
        }
    }

    func didSelect(with input: TestConfig?) {
        didSelectCalled = true
    }

    func didDeselect(with input: TestConfig?) {
        didDeselectCalled = true
    }

    func didHighlight(with input: TestConfig?) {
        didHighlightCalled = true
    }

    func didUnhighlight(with input: TestConfig?) {
        didUnhighlightCalled = true
    }

    func willDisplay(with input: TestConfig?) {
        willDisplayCalled = true
    }

    func didEndDisplaying(with input: TestConfig?) {
        didEndDisplayingCalled = true
    }
}

// MARK: - Test Supplementary Views

final class TestHeaderView: UITableViewHeaderFooterView, SSTableViewHeaderFooterViewProtocol {
    let titleLabel = UILabel()
    var willDisplayCalled = false
    var didEndDisplayingCalled = false

    static func size(with input: TestHeaderData?, constrainedTo parentSize: CGSize?) -> CGSize? {
        return CGSize(width: parentSize?.width ?? 375, height: 50)
    }

    var configurer: (TestHeaderView, TestHeaderData) -> Void {
        { view, model in
            view.titleLabel.text = model.title
        }
    }

    func willDisplay(with input: TestHeaderData?) {
        willDisplayCalled = true
    }

    func didEndDisplaying(with input: TestHeaderData?) {
        didEndDisplayingCalled = true
    }
}

final class TestFooterView: UITableViewHeaderFooterView, SSTableViewHeaderFooterViewProtocol {
    let titleLabel = UILabel()
    var willDisplayCalled = false
    var didEndDisplayingCalled = false

    static func size(with input: TestFooterData?, constrainedTo parentSize: CGSize?) -> CGSize? {
        return CGSize(width: parentSize?.width ?? 375, height: 30)
    }

    var configurer: (TestFooterView, TestFooterData) -> Void {
        { view, model in
            view.titleLabel.text = model.text
        }
    }

    func willDisplay(with input: TestFooterData?) {
        willDisplayCalled = true
    }

    func didEndDisplaying(with input: TestFooterData?) {
        didEndDisplayingCalled = true
    }
}

// MARK: - Helpers

@MainActor
func makeTableView(
    frame: CGRect = CGRect(x: 0, y: 0, width: 375, height: 667),
    dataSourceMode: SSTableViewPresenter.DataSourceMode = .traditional
) -> UITableView {
    let tv = UITableView(frame: frame)
    tv.ss.setupPresenter(dataSourceMode: dataSourceMode)
    return tv
}

@MainActor
func makeSampleConfigs(_ count: Int = 8) -> [TestConfig] {
    (0..<count).map { TestConfig(id: "\($0)", title: "Config \($0)") }
}

@MainActor
func makeCellInfo(from config: TestConfig) -> SSTableViewModel.CellInfo {
    .init(BindingStore<TestConfig, TestConfigCell>(state: config))
}

@MainActor
func makeCellInfos(from configs: [TestConfig]) -> [SSTableViewModel.CellInfo] {
    configs.map { makeCellInfo(from: $0) }
}
