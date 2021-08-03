//
//  SSTableViewPresenter.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 24.07.2021.
//

import UIKit

/// Simplifies configuring and managing a `UITableView` with a
/// `SSTableViewModel`.
///
/// `SSTableViewPresenter` bridges your view model with the table view,
/// automatically handling data source and delegate methods. It provides an
/// easy way to bind cell and header/footer view data with minimal boilerplate.
public final class SSTableViewPresenter: NSObject {
    typealias SectionInfo = SSTableViewModel.SectionInfo
    typealias CellInfo = SSTableViewModel.CellInfo
    typealias HeaderFooterViewInfo = SSTableViewModel.HeaderFooterViewInfo

    // MARK: - ViewModel

    /// The current view model backing the table view.
    internal var viewModel: SSTableViewModel? {
        didSet {
            guard let viewModel = viewModel, let tableView = tableView else { return }
            for section in viewModel.sections {
                for row in section.rows {
                    tableView.registerCell(row.binderType)
                }
                if let header = section.header {
                    tableView.registerHeaderFooter(header.binderType)
                }
                if let footer = section.footer {
                    tableView.registerHeaderFooter(footer.binderType)
                }
            }
            isLoadingNextPage = false
        }
    }

    // MARK: - Action Handling

    /// The action handler responsible for dispatching actions.
    internal var actionHandler: AnyActionHandlingProvider?

    // MARK: - Pagination

    /// Closure called when the next page of data should be loaded.
    internal var nextRequestBlock: ((SSTableViewModel) -> Void)?

    /// Flag indicating whether a pagination request is in progress.
    internal var isLoadingNextPage: Bool = false

    // MARK: - Prefetching

    /// Closure called when rows should be prefetched.
    internal var prefetchBlock: (([CellInfo]) -> Void)?

    /// Closure called when prefetching should be cancelled.
    internal var cancelPrefetchBlock: (([CellInfo]) -> Void)?

    // MARK: - Table View Reference

    /// The table view being managed by this presenter.
    private weak var tableView: UITableView?

    // MARK: - Initialization

    public init(
        tableView: UITableView,
        actionHandler: ActionHandlingProvider? = nil
    ) {
        self.tableView = tableView
        if let actionHandler = actionHandler {
            self.actionHandler = AnyActionHandlingProvider(actionHandler)
        }
        super.init()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.prefetchDataSource = self
        tableView.registerDefaultCell()
        tableView.registerDefaultHeaderFooterView()
    }

    // MARK: - Section/Row Control

    /// Updates the state of a visible cell without reloading it.
    ///
    /// Applies `newState` directly to the bound cell if it is currently visible.
    /// Has no effect if the cell is not visible or if `newState` does not match
    /// the existing state type.
    ///
    /// - Parameters:
    ///   - newState: The new state to apply to the cell.
    ///   - indexPath: The index path of the cell to update.
    internal func reconfigureRow<T>(_ newState: T, at indexPath: IndexPath) {
        guard let tableView = tableView,
              let viewModel = viewModel,
              indexPath.section < viewModel.count,
              indexPath.row < viewModel[indexPath.section].count else { return }

        let row = viewModel[indexPath.section][indexPath.row]
        guard row.state is T else { return }

        if let cell = tableView.cellForRow(at: indexPath) {
            row.state = newState
            row.apply(to: cell)
        }
    }

    /// Updates the state of a visible section header without reloading it.
    ///
    /// Applies `newState` directly to the header view if it is
    /// currently visible. Has no effect if the header is not visible
    /// or if `newState` does not match the existing state type.
    ///
    /// - Parameters:
    ///   - newState: The new state to apply to the header view.
    ///   - section: The index of the section whose header to update.
    @available(iOS 9.0, *)
    internal func reconfigureHeader<T>(_ newState: T, at section: Int) {
        guard let tableView = tableView,
              let viewModel = viewModel,
              section < viewModel.count else { return }

        guard let header = viewModel[section].header,
              header.state is T else { return }

        if let view = tableView.headerView(forSection: section) {
            header.state = newState
            header.apply(to: view)
        }
    }

    /// Updates the state of a visible section footer without reloading it.
    ///
    /// Applies `newState` directly to the footer view if it is
    /// currently visible. Has no effect if the footer is not visible
    /// or if `newState` does not match the existing state type.
    ///
    /// - Parameters:
    ///   - newState: The new state to apply to the footer view.
    ///   - section: The index of the section whose footer to update.
    @available(iOS 9.0, *)
    internal func reconfigureFooter<T>(_ newState: T, at section: Int) {
        guard let tableView = tableView,
              let viewModel = viewModel,
              section < viewModel.count else { return }

        guard let footer = viewModel[section].footer,
              footer.state is T else { return }

        if let view = tableView.footerView(forSection: section) {
            footer.state = newState
            footer.apply(to: view)
        }
    }

    /// Clears the selection tracking state.
    ///
    /// This only clears the presenter's internal tracking set.
    /// To also visually deselect cells, iterate
    /// `UITableView.indexPathsForSelectedRows` and call
    /// `deselectRow(at:animated:)` on the table view.
    internal func clearSelectedRows() {
        guard let tableView = tableView,
              let viewModel = viewModel else { return }

        // Capture UI-selected index paths before we clear them
        let indexPaths = Set(tableView.indexPathsForSelectedRows ?? [])

        // 1) Visually deselect rows so UITableView updates its state
        //    and the delegate's didDeselect is fired for visible cells
        for indexPath in indexPaths {
            tableView.deselectRow(at: indexPath, animated: false)
        }

        // 2) Ensure model's selection state is cleared for any rows that
        //    remain selected only in the model (e.g., offscreen cells)
        for (section, sectionInfo) in viewModel.sections.enumerated() {
            for (row, cellInfo) in sectionInfo.rows.enumerated()
            where cellInfo.isSelected
            {
                let indexPath = IndexPath(row: row, section: section)
                if let cell = tableView.cellForRow(at: indexPath) {
                    // Forward didDeselect to the binder and clear selection flag
                    cellInfo.didDeselect(to: cell)
                } else {
                    // If the cell is not visible, just clear the selection state
                    cellInfo.isSelected = false
                }
            }
        }

        // Write back the model for consistency
        self.viewModel = viewModel
    }

    /// Toggles the collapsed state of the specified section and animates
    /// the changes.
    ///
    /// Updates `isCollapsed` on the section model before calling
    /// `performBatchUpdates` to keep the data source consistent
    /// during animation.
    ///
    /// - Parameters:
    ///   - section: The index of the section to toggle.
    ///   - completion: A closure called after the animation completes.
    ///                 Receives `true` if the section is now expanded,
    ///                 `false` if collapsed.
    internal func toggleSection(_ section: Int, completion: @escaping ((Bool) -> Void)) {
        guard let tableView = tableView,
              var model = viewModel else { return }

        let wasCollapsed = model[section].isCollapsed
        let indexPaths = (0..<model[section].count).map {
            IndexPath(row: $0, section: section)
        }

        model[section].isCollapsed = !wasCollapsed
        self.viewModel = model

        tableView.performBatchUpdates {
            if wasCollapsed {
                tableView.insertRows(at: indexPaths, with: .automatic)
            } else {
                tableView.deleteRows(at: indexPaths, with: .automatic)
            }
        } completion: { _ in
            completion(!wasCollapsed)
        }
    }

    // MARK: - Pagination

    /// Determines whether the next page should be loaded based on scroll position.
    ///
    /// Checks if the user has scrolled close enough to the end and whether
    /// pagination is available and not already in progress.
    ///
    /// - Returns: `true` if the next page should be requested; otherwise, `false`.
    internal func shouldLoadNextPage() -> Bool {
        guard let tableView = tableView, let viewModel = viewModel,
              viewModel.hasNext, isLoadingNextPage == false
        else { return false }

        return (tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.height * 3)
    }
}
