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
        guard let sectionInfo = viewModel?[safe: section],
              !sectionInfo.isCollapsed else { return 0 }

        return sectionInfo.rows.count
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let viewModel = viewModel
        else { return tableView.dequeueDefaultCell(for: indexPath) }

        guard let row = viewModel[safe: indexPath.section]?[safe: indexPath.row]
        else { return tableView.dequeueDefaultCell(for: indexPath) }

        defer {
            if shouldLoadNextPage() {
                isLoadingNextPage = true
                nextRequestBlock?(viewModel)
            }
        }

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
           let aCell = cell as? (UIView & EventForwardingProvider)
        {
            actionHandler.attach(to: aCell)
        }

        return cell
    }

    public func tableView(_ tableView: UITableView,
                          canEditRowAt indexPath: IndexPath) -> Bool {
        guard let row = viewModel?[safe: indexPath.section]?[safe: indexPath.row] else { return true }

        return row.canEditRow
    }

    public func tableView(_ tableView: UITableView,
                          canMoveRowAt indexPath: IndexPath) -> Bool {
        guard let row = viewModel?[safe: indexPath.section]?[safe: indexPath.row] else { return true }

        return row.canMoveRow
    }

    public func tableView(_ tableView: UITableView,
                          titleForHeaderInSection section: Int) -> String? {
        guard let headerTitle = viewModel?.sections[safe: section]?.headerTitle else { return nil }

        return headerTitle
    }

    public func tableView(_ tableView: UITableView,
                          titleForFooterInSection section: Int) -> String? {
        guard let footerTitle = viewModel?.sections[safe: section]?.footerTitle else { return nil }

        return footerTitle
    }

    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard let viewModel = viewModel, viewModel.isIndexTitlesEnabled else { return nil }
        return cachedIndexTitles.isEmpty ? nil : cachedIndexTitles
    }

    public func tableView(_ tableView: UITableView,
                          sectionForSectionIndexTitle title: String,
                          at index: Int) -> Int {
        guard cachedIndexTitleSections.indices.contains(index) else { return 0 }
        return cachedIndexTitleSections[index]
    }

    public func tableView(_ tableView: UITableView,
                          commit editingStyle: UITableViewCell.EditingStyle,
                          forRowAt indexPath: IndexPath) {
        guard var newViewModel = viewModel else { return }

        switch editingStyle {
        case .delete:
            guard indexPath.section < newViewModel.count,
                  indexPath.row < newViewModel[indexPath.section].count else { return }

            tableView.performBatchUpdates {
                newViewModel[indexPath.section].remove(at: indexPath.row)
                self.viewModel = newViewModel
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        case .insert:
            guard indexPath.section < newViewModel.count,
                  indexPath.row < newViewModel[indexPath.section].count,
                  let newCellInfo = newCellInfoProvider?(indexPath) else { break }

            tableView.performBatchUpdates {
                let newIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
                newViewModel[newIndexPath.section].insert(newCellInfo, at: newIndexPath.row)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        default:
            break
        }
    }

    public func tableView(_ tableView: UITableView,
                          moveRowAt sourceIndexPath: IndexPath,
                          to destinationIndexPath: IndexPath) {
        guard var newViewModel = viewModel else { return }
        guard newViewModel.count > sourceIndexPath.section else { return }
        guard newViewModel.count > destinationIndexPath.section else { return }

        let moving = newViewModel[sourceIndexPath.section].remove(at: sourceIndexPath.row)
        newViewModel[destinationIndexPath.section].rows.insert(moving, at: destinationIndexPath.row)

        self.viewModel = newViewModel
    }
}
