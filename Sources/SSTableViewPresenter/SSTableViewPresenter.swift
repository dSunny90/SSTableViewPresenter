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

    // MARK: - Configuration

    /// The data source mode (diffable or classic).
    internal let dataSourceMode: DataSourceMode

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

            if #available(iOS 13.0, *) {
                if dataSourceMode == .diffable {
                    diffableSupportCore?.updateSnapshot(with: viewModel)
                }
            }

            if viewModel.isIndexTitlesEnabled {
                let map = viewModel.buildIndexTitleMap()
                cachedIndexTitles = map.titles
                cachedIndexTitleSections = map.sections
            } else {
                cachedIndexTitles.removeAll()
                cachedIndexTitleSections.removeAll()
            }
        }
    }

    // MARK: - Action Handling

    /// The action handler responsible for dispatching actions.
    internal var actionHandler: AnyActionHandlingProvider?

    // MARK: - Primary Action (iOS 16+)

    /// Asked on each primary-action tap. Returns a non-nil closure to run
    /// when the action should proceed, or `nil` to veto the action for that
    /// cell. `nil` (no block set) vetoes by default.
    internal var performPrimaryActionBlock: ((IndexPath, CellInfo) -> (() -> Void)?)?

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

    // MARK: - Index Title Cache

    /// Cached index title map, rebuilt whenever the view model changes.
    internal var cachedIndexTitles: [String] = []
    internal var cachedIndexTitleSections: [Int] = []

    // MARK: - Diffable Data Source Support

    @available(iOS 13.0, *)
    private var diffableSupportCore: DiffableSupportCore? {
        get {
            _diffableSupportCore as? DiffableSupportCore
        }
        set {
            _diffableSupportCore = newValue
        }
    }

    private var _diffableSupportCore: Any?

    // MARK: - Row Insertion
    internal var newCellInfoProvider: ((IndexPath) -> CellInfo)?

    // MARK: - Reorder

    /// Whether drag & drop reordering is enabled.
    internal var isReorderEnabled: Bool = false

    /// Determines if a specific row can be dragged. Defaults to `true` if nil.
    internal var canDragRowBlock: ((CellInfo) -> Bool)?

    /// Called with the rows about to move, before the data source is updated.
    internal var willReorderBlock: (([(indexPath: IndexPath, cellInfo: CellInfo)]) -> Void)?

    /// Called after the data source is updated with the moved rows and destination.
    internal var didReorderBlock: (([(indexPath: IndexPath, cellInfo: CellInfo)], IndexPath) -> Void)?

    /// Provides custom `UIDragPreviewParameters` for a dragged row.
    internal var dragPreviewParametersBlock: ((IndexPath) -> UIDragPreviewParameters?)?

    /// Provides a custom preview view for a dragged row. Returns nil for default.
    internal var dragPreviewProviderBlock: ((CellInfo) -> UIView?)?

    // MARK: - External Drag & Drop Handlers (iPad)

    /// Whether external drag & drop is enabled.
    ///
    /// When enabled, rows can be dragged out to or dropped in from
    /// other apps on iPad.
    internal var isExternalDragDropEnabled: Bool = false

    /// Optional provider to build an NSItemProvider
    /// for a given cell & cell info when a drag begins.
    internal var dragItemProviderBlock: ((UITableViewCell, CellInfo) -> NSItemProvider?)?

    /// UTType identifiers accepted for external drops.
    /// Only drop sessions advertising a matching type are forwarded to
    /// `externalDropHandler`.
    internal var acceptedExternalDropTypeIdentifiers: [String] = []

    /// Converts an externally dropped value into a `CellInfo` at the
    /// destination index path. Return `nil` to reject the drop.
    internal var externalDropHandler: ((Any?, IndexPath) -> CellInfo?)?

    // MARK: - Table View Reference

    /// The table view being managed by this presenter.
    private weak var tableView: UITableView?

    // MARK: - Initialization

    public init(
        tableView: UITableView,
        actionHandler: (any ActionHandlingProvider)? = nil,
        dataSourceMode: DataSourceMode = .traditional
    ) {
        self.tableView = tableView
        if let actionHandler = actionHandler {
            self.actionHandler = AnyActionHandlingProvider(actionHandler)
        }
        self.dataSourceMode = dataSourceMode
        super.init()
        configureDataSource()
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
              let row = viewModel?[safe: indexPath.section]?[safe: indexPath.row],
              row.state is T else { return }

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
    internal func reconfigureHeader<T>(_ newState: T, at section: Int) {
        guard let tableView = tableView,
              let header = viewModel?[safe: section]?.header,
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
    internal func reconfigureFooter<T>(_ newState: T, at section: Int) {
        guard let tableView = tableView,
              let footer = viewModel?[safe: section]?.footer,
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

    // MARK: - Configuration

    /// Configures the data source for the table view.
    ///
    /// Sets up either traditional data source callbacks or a diffable data source
    /// based on the specified mode.
    private func configureDataSource() {
        guard let tableView = tableView else { return }
        switch dataSourceMode {
        case .traditional:
            tableView.dataSource = self
        case .diffable:
            if #available(iOS 13.0, *) {
                self.diffableSupportCore = DiffableSupportCore()
                self.diffableSupportCore?.configureDiffableDataSource(
                    in: tableView,
                    anyActionHandler: actionHandler
                )
            } else {
                assertionFailure("Diffable is not supported below iOS 13.")
            }
        }
    }

    // MARK: - Drag&Drop Configuration

    /// Configures drag & drop on the table view.
    ///
    /// When either `isReorderEnabled` or `isExternalDragDropEnabled` is
    /// `true`, sets `dragInteractionEnabled = true` and assigns the
    /// presenter as both `dragDelegate` and `dropDelegate`.
    internal func configureDragDrop() {
        guard let tableView = tableView else { return }
        if isReorderEnabled || isExternalDragDropEnabled {
            tableView.dragInteractionEnabled = true
            tableView.dragDelegate = self
            tableView.dropDelegate = self
        } else {
            tableView.dragInteractionEnabled = false
            tableView.dragDelegate = nil
            tableView.dropDelegate = nil
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

    // MARK: - Presentation

    /// Applies the current snapshot to the diffable data source.
    ///
    /// Only applies when using the `.diffable` data source mode. Has no effect
    /// in traditional mode.
    ///
    /// - Parameter animated: Whether to animate the changes.
    @available(iOS 13.0, *)
    internal func applySnapshot(animated: Bool) {
        guard dataSourceMode == .diffable else { return }
        diffableSupportCore?.applySnapshot(animated: animated)
    }

    // MARK: - iOS 15+ Features

    /// Reconfigures cells without reloading them.
    @available(iOS 15.0, *)
    internal func reconfigureItems(_ identifiers: [CellInfo]) {
        guard dataSourceMode == .diffable else { return }
        diffableSupportCore?.reconfigureItems(identifiers)
    }

    /// Applies the snapshot using a full reload without diffing.
    @available(iOS 15.0, *)
    internal func applySnapshotUsingReloadData() {
        guard dataSourceMode == .diffable else { return }
        diffableSupportCore?.applySnapshotUsingReloadData()
    }
}
