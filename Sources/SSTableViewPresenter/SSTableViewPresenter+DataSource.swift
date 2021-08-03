//
//  SSTableViewPresenter+DataSource.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 29.07.2021.
//

import UIKit

// MARK: - UITableViewDataSource

extension SSTableViewPresenter: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        guard let viewModel = viewModel else { return 0 }

        if viewModel.sections.isEmpty, viewModel.hasNext {
            isLoadingNextPage = true
            nextRequestBlock?(viewModel)
        }
        return viewModel.sections.count
    }

    public func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = viewModel?[section],
              !sectionInfo.isCollapsed else { return 0 }

        return sectionInfo.rows.count
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let viewModel = viewModel
        else { return tableView.dequeueDefaultCell(for: indexPath) }

        defer {
            if shouldLoadNextPage() {
                isLoadingNextPage = true
                nextRequestBlock?(viewModel)
            }
        }

        let row = viewModel[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: row.binderType),
            for: indexPath
        )

        row.apply(to: cell)

        if let actionClosure = row.actionClosure {
            cell.actionClosure = { [weak cell] actionName, input in
                guard let cell = cell else { return }
                actionClosure(indexPath, cell, actionName, input)
            }
        } else {
            cell.actionClosure = nil
        }

        if let actionHandler = actionHandler,
           let aCell = cell as? (UIView & EventSendingProvider)
        {
            actionHandler.attach(to: aCell)
        }

        return cell
    }
}
