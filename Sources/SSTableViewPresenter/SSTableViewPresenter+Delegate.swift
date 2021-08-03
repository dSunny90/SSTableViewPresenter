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
        guard let rowSize = viewModel?[indexPath.section][indexPath.row].size(constrainedTo: tableView.bounds.size)
        else { return tableView.rowHeight }

        return rowSize.height
    }

    public func tableView(_ tableView: UITableView,
                          heightForHeaderInSection section: Int) -> CGFloat {
        guard let headerSize = viewModel?[section].header?.size(constrainedTo: tableView.bounds.size)
        else { return tableView.sectionHeaderHeight }

        return headerSize.height
    }

    public func tableView(_ tableView: UITableView,
                          heightForFooterInSection section: Int) -> CGFloat {
        guard let footerSize = viewModel?[section].footer?.size(constrainedTo: tableView.bounds.size)
        else { return tableView.sectionFooterHeight }

        return footerSize.height
    }

    public func tableView(_ tableView: UITableView,
                          viewForHeaderInSection section: Int) -> UIView? {
        guard let header = viewModel?[section].header,
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
           let aView = view as? (UIView & EventSendingProvider)
        {
            actionHandler.attach(to: aView)
        }

        return view
    }

    public func tableView(_ tableView: UITableView,
                          viewForFooterInSection section: Int) -> UIView? {
        guard let footer = viewModel?[section].footer,
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
           let aView = view as? (UIView & EventSendingProvider)
        {
            actionHandler.attach(to: aView)
        }

        return view
    }

    public func tableView(_ tableView: UITableView,
                          willDisplay cell: UITableViewCell,
                          forRowAt indexPath: IndexPath) {
        guard let row = viewModel?[indexPath.section][indexPath.row] else { return }

        row.willDisplay(to: cell)
    }

    public func tableView(_ tableView: UITableView,
                          willDisplayHeaderView view: UIView,
                          forSection section: Int) {
        guard let header = viewModel?[section].header else { return }

        header.willDisplay(to: view)
    }

    public func tableView(_ tableView: UITableView,
                          willDisplayFooterView view: UIView,
                          forSection section: Int) {
        guard let footer = viewModel?[section].footer else { return }

        footer.willDisplay(to: view)
    }

    public func tableView(_ tableView: UITableView,
                          didEndDisplaying cell: UITableViewCell,
                          forRowAt indexPath: IndexPath) {
        guard let row = viewModel?[indexPath.section][indexPath.row] else { return }

        row.didEndDisplaying(to: cell)
    }

    public func tableView(_ tableView: UITableView,
                          didEndDisplayingHeaderView view: UIView,
                          forSection section: Int) {
        guard let header = viewModel?[section].header else { return }

        header.didEndDisplaying(to: view)
    }

    public func tableView(_ tableView: UITableView,
                          didEndDisplayingFooterView view: UIView,
                          forSection section: Int) {
        guard let footer = viewModel?[section].footer else { return }

        footer.didEndDisplaying(to: view)
    }

    public func tableView(_ tableView: UITableView,
                          didHighlightRowAt indexPath: IndexPath) {
        guard let row = viewModel?[indexPath.section][indexPath.row],
              let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section))
        else { return }

        row.didHighlight(to: cell)
    }

    public func tableView(_ tableView: UITableView,
                          didUnhighlightRowAt indexPath: IndexPath) {
        guard let row = viewModel?[indexPath.section][indexPath.row],
              let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section))
        else { return }

        row.didUnhighlight(to: cell)
    }

    public func tableView(_ tableView: UITableView,
                          didSelectRowAt indexPath: IndexPath) {
        guard let row = viewModel?[indexPath.section][indexPath.row],
              let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section))
        else { return }

        row.didSelect(to: cell)
    }

    public func tableView(_ tableView: UITableView,
                          didDeselectRowAt indexPath: IndexPath) {
        guard let row = viewModel?[indexPath.section][indexPath.row],
              let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section))
        else { return }

        row.didDeselect(to: cell)
    }
}
