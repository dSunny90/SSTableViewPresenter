//
//  SSTableViewPresenter+Delegate.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 29.07.2021.
//

import UIKit

// MARK: - UITableViewDelegate

extension SSTableViewPresenter: UITableViewDelegate {
    public func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let rowSize = viewModel?[safe: indexPath.section]?[safe: indexPath.row]?.size(constrainedTo: tableView.bounds.size)
        else { return tableView.rowHeight }

        return rowSize.height
    }

    public func tableView(_ tableView: UITableView,
                          heightForHeaderInSection section: Int) -> CGFloat {
        guard let headerSize = viewModel?[safe: section]?.header?.size(constrainedTo: tableView.bounds.size)
        else { return tableView.sectionHeaderHeight }

        return headerSize.height
    }

    public func tableView(_ tableView: UITableView,
                          heightForFooterInSection section: Int) -> CGFloat {
        guard let footerSize = viewModel?[safe: section]?.footer?.size(constrainedTo: tableView.bounds.size)
        else { return tableView.sectionFooterHeight }

        return footerSize.height
    }

    public func tableView(_ tableView: UITableView,
                          viewForHeaderInSection section: Int) -> UIView? {
        guard let header = viewModel?[safe: section]?.header,
              let view = tableView.dequeueReusableHeaderFooterView(
                  withIdentifier: String(describing: header.binderType)
              ) else { return nil }

        header.apply(to: view)

        if let actionClosure = header.actionClosure {
            view.actionClosure = { [weak view] actionName, input in
                guard let view = view else { return }
                actionClosure(section, view, actionName, input)
            }
        } else {
            view.actionClosure = nil
        }

        if let actionHandler = actionHandler,
           let aView = view as? (UIView & EventForwardingProvider)
        {
            actionHandler.attach(to: aView)
        }

        return view
    }

    public func tableView(_ tableView: UITableView,
                          viewForFooterInSection section: Int) -> UIView? {
        guard let footer = viewModel?[safe: section]?.footer,
              let view = tableView.dequeueReusableHeaderFooterView(
                  withIdentifier: String(describing: footer.binderType)
              ) else { return nil }

        footer.apply(to: view)

        if let actionClosure = footer.actionClosure {
            view.actionClosure = { [weak view] actionName, input in
                guard let view = view else { return }
                actionClosure(section, view, actionName, input)
            }
        } else {
            view.actionClosure = nil
        }

        if let actionHandler = actionHandler,
           let aView = view as? (UIView & EventForwardingProvider)
        {
            actionHandler.attach(to: aView)
        }

        return view
    }

    public func tableView(_ tableView: UITableView,
                          willDisplay cell: UITableViewCell,
                          forRowAt indexPath: IndexPath) {
        guard let row = viewModel?[safe: indexPath.section]?[safe: indexPath.row] else { return }

        row.willDisplay(to: cell)
    }

    public func tableView(_ tableView: UITableView,
                          willDisplayHeaderView view: UIView,
                          forSection section: Int) {
        guard let header = viewModel?[safe: section]?.header else { return }

        header.willDisplay(to: view)
    }

    public func tableView(_ tableView: UITableView,
                          willDisplayFooterView view: UIView,
                          forSection section: Int) {
        guard let footer = viewModel?[safe: section]?.footer else { return }

        footer.willDisplay(to: view)
    }

    public func tableView(_ tableView: UITableView,
                          didEndDisplaying cell: UITableViewCell,
                          forRowAt indexPath: IndexPath) {
        guard let row = viewModel?[safe: indexPath.section]?[safe: indexPath.row] else { return }

        row.didEndDisplaying(to: cell)
    }

    public func tableView(_ tableView: UITableView,
                          didEndDisplayingHeaderView view: UIView,
                          forSection section: Int) {
        guard let header = viewModel?[safe: section]?.header else { return }

        header.didEndDisplaying(to: view)
    }

    public func tableView(_ tableView: UITableView,
                          didEndDisplayingFooterView view: UIView,
                          forSection section: Int) {
        guard let footer = viewModel?[safe: section]?.footer else { return }

        footer.didEndDisplaying(to: view)
    }

    public func tableView(_ tableView: UITableView,
                          shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let row = viewModel?[safe: indexPath.section]?[safe: indexPath.row],
              let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section))
        else { return true }

        return row.shouldHighlight(to: cell)
    }

    public func tableView(_ tableView: UITableView,
                          didHighlightRowAt indexPath: IndexPath) {
        guard let row = viewModel?[safe: indexPath.section]?[safe: indexPath.row],
              let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section))
        else { return }

        row.didHighlight(to: cell)
    }

    public func tableView(_ tableView: UITableView,
                          didUnhighlightRowAt indexPath: IndexPath) {
        guard let row = viewModel?[safe: indexPath.section]?[safe: indexPath.row],
              let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section))
        else { return }

        row.didUnhighlight(to: cell)
    }

    public func tableView(_ tableView: UITableView,
                          willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let row = viewModel?[safe: indexPath.section]?[safe: indexPath.row],
              let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section))
        else { return indexPath }

        return row.willSelect(to: cell) ? indexPath : nil
    }

    public func tableView(_ tableView: UITableView,
                          didSelectRowAt indexPath: IndexPath) {
        guard let row = viewModel?[safe: indexPath.section]?[safe: indexPath.row],
              let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section))
        else { return }

        row.didSelect(to: cell)
    }

    public func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let row = viewModel?[safe: indexPath.section]?[safe: indexPath.row],
              let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section))
        else { return indexPath }

        return row.willDeselect(to: cell) ? indexPath : nil
    }

    public func tableView(_ tableView: UITableView,
                          didDeselectRowAt indexPath: IndexPath) {
        guard let row = viewModel?[safe: indexPath.section]?[safe: indexPath.row],
              let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section))
        else { return }

        row.didDeselect(to: cell)
    }

    @available(iOS 16.0, *)
    public func tableView(_ tableView: UITableView,
                          canPerformPrimaryActionForRowAt indexPath: IndexPath) -> Bool {
        guard let block = performPrimaryActionBlock,
              let row = viewModel?[safe: indexPath.section]?[safe: indexPath.row] else { return false }
        return block(indexPath, row) != nil
    }

    @available(iOS 16.0, *)
    public func tableView(_ tableView: UITableView, performPrimaryActionForRowAt indexPath: IndexPath) {
        guard let block = performPrimaryActionBlock,
              let row = viewModel?[safe: indexPath.section]?[safe: indexPath.row] else { return }
        block(indexPath, row)?()
    }

    public func tableView(_ tableView: UITableView,
                          leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let row = viewModel?[safe: indexPath.section]?[safe: indexPath.row],
              let swipeConfig = row.leadingSwipeActions?(row)
        else { return nil }

        let contextualActions = swipeConfig.actions.map { action in
            let element = UIContextualAction(style: action.style, title: action.title) { [weak self] _, _, completion in
                guard let self = self else { completion(false); return }

                let result = action.handler(row)

                switch result {
                case .delete:
                    if var newViewModel = self.viewModel {
                        newViewModel[indexPath.section].remove(at: indexPath.row)
                        self.viewModel = newViewModel
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                case .update(let newCellInfo):
                    if var newViewModel = self.viewModel {
                        newViewModel[indexPath.section][indexPath.row] = newCellInfo
                        self.viewModel = newViewModel
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }
                case .reload:
                    tableView.reloadData()
                case .none:
                    break
                }

                completion(true)
            }

            if let bgColor = action.backgroundColor {
                element.backgroundColor = bgColor
            }
            if let image = action.image {
                element.image = image
            }
            return element
        }
        let config = UISwipeActionsConfiguration(actions: contextualActions)
        config.performsFirstActionWithFullSwipe = swipeConfig.performsFirstActionWithFullSwipe
        return config
    }

    public func tableView(_ tableView: UITableView,
                          trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let row = viewModel?[safe: indexPath.section]?[safe: indexPath.row],
              let swipeConfig = row.trailingSwipeActions?(row)
        else { return nil }

        let contextualActions = swipeConfig.actions.map { action in
            let element = UIContextualAction(style: action.style, title: action.title) { [weak self] _, _, completion in
                guard let self = self else { completion(false); return }

                let result = action.handler(row)

                switch result {
                case .delete:
                    if var newViewModel = self.viewModel {
                        newViewModel[indexPath.section].remove(at: indexPath.row)
                        self.viewModel = newViewModel
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                case .update(let newCellInfo):
                    if var newViewModel = self.viewModel {
                        newViewModel[indexPath.section][indexPath.row] = newCellInfo
                        self.viewModel = newViewModel
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }
                case .reload:
                    tableView.reloadData()
                case .none:
                    break
                }

                completion(true)
            }

            if let bgColor = action.backgroundColor {
                element.backgroundColor = bgColor
            }
            if let image = action.image {
                element.image = image
            }
            return element
        }
        let config = UISwipeActionsConfiguration(actions: contextualActions)
        config.performsFirstActionWithFullSwipe = swipeConfig.performsFirstActionWithFullSwipe
        return config
    }

}
