//
//  SSTableViewPresenterTests.swift
//  SSTableViewPresenterTests
//
//  Created by SunSoo Jeon on 24.07.2021.
//

import XCTest
@testable import SSTableViewPresenter

import UIKit

class SSTableViewPresenterTests: XCTestCase {
    func test_presenter() {
        let tv = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        tv.ss.setupPresenter()
        XCTAssertNotNil(tv.presenter, "Presenter should be attached after setupPresenter()")

        let models = (0..<5).map { TestModel(id: "\($0)", title: "Model \($0)") }
        let rows = models.map { SSTableViewModel.CellInfo(BindingStore<TestModel, TestCell>(state: $0)) }
        let header = SSTableViewModel.HeaderFooterViewInfo(BindingStore<TestModel, TestHeaderFooterView>(state: TestModel(id: "11", title: "Header 11")))
        let footer = SSTableViewModel.HeaderFooterViewInfo(BindingStore<TestModel, TestHeaderFooterView>(state: TestModel(id: "22", title: "Footer 22")))
        let section = SSTableViewModel.SectionInfo(rows: rows, header: header, footer: footer)
        let viewModel = SSTableViewModel(sections: [section])

        tv.ss.setViewModel(with: viewModel)

        let retrieved = tv.ss.getViewModel()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.count, 1, "Should have 1 section")
        XCTAssertEqual(retrieved?[0].count, 5, "Section should have 5 rows (default)")

        tv.reloadData()

        let cellCount = tv.dataSource?.tableView(tv, numberOfRowsInSection: 0)
        XCTAssertEqual(cellCount, 5)

        guard let cell = tv.dataSource?.tableView(tv, cellForRowAt: IndexPath(row: 2, section: 0)) as? TestCell else {
            XCTFail("Failed to dequeue TestCell")
            return
        }

        XCTAssertEqual(cell.titleLabel.text, "Model 2")

        guard let headerView = tv.delegate?.tableView?(tv, viewForHeaderInSection: 0) as? TestHeaderFooterView
        else {
            XCTFail("Failed to dequeue TestHeaderFooterView")
            return
        }

        XCTAssertEqual(headerView.titleLabel.text, "Header 11")

        guard let footerView = tv.delegate?.tableView?(tv, viewForFooterInSection: 0) as? TestHeaderFooterView
        else {
            XCTFail("Failed to dequeue TestHeaderFooterView")
            return
        }

        XCTAssertEqual(footerView.titleLabel.text, "Footer 22")
    }
}

final class TestHeaderFooterView: UITableViewHeaderFooterView, SSTableViewHeaderFooterViewProtocol {
    let titleLabel = UILabel()

    var configurer: (TestHeaderFooterView, TestModel) -> Void {
        { view, model in
            view.titleLabel.text = model.title
        }
    }
}

final class TestCell: UITableViewCell, SSTableViewCellProtocol {
    let titleLabel = UILabel()

    var configurer: (TestCell, TestModel) -> Void {
        { view, model in
            view.titleLabel.text = model.title
        }
    }
}

struct TestModel {
    let id: String
    let title: String
}
