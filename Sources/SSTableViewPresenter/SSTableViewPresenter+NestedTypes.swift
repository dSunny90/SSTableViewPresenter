//
//  SSTableViewPresenter+NestedTypes.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 19.08.2021.
//

import UIKit

// MARK: - Nested Types

extension SSTableViewPresenter {
    /// Defines the data source implementation mode.
    public enum DataSourceMode {
        /// Classic data source using delegate callbacks.
        case traditional

        /// Modern diffable data source (iOS 13+).
        case diffable
    }

    // MARK: - DiffableSupportCore

    /// The internal core that manages all diffable data source operations for
    /// ``SSTableViewPresenter``.
    ///
    /// ## Responsibilities
    /// - Creates and owns the `UITableViewDiffableDataSource`
    /// - Builds, stores, and applies `NSDiffableDataSourceSnapshot` instances
    ///
    /// ## Lifecycle
    /// 1. Instantiated in ``SSTableViewPresenter/init`` when
    ///    ``DataSourceMode/diffable`` is selected.
    /// 2. ``configureDiffableDataSource(in:anyActionHandler:)`` sets up the
    ///    data source and its providers.
    /// 3. On every view model update, ``updateSnapshot(with:)`` followed by
    ///    ``applySnapshot(animated:)`` pushes the changes to the table view.
    ///
    /// ## Thread Safety
    /// All APIs must be called on the main thread.
    /// `UITableViewDiffableDataSource.apply` uses the main queue internally,
    /// but snapshot construction is performed synchronously.
    @available(iOS 13.0, *)
    @MainActor
    internal class DiffableSupportCore {
        /// The `UITableViewDiffableDataSource` instance.
        ///
        /// Created during ``configureDiffableDataSource(in:anyActionHandler:)``
        /// and owns the cell provider closures.
        /// `nil` until initial configuration is complete.
        private var dataSource: UITableViewDiffableDataSource<SectionInfo, CellInfo>?

        /// The current `NSDiffableDataSourceSnapshot` managed by this core.
        ///
        /// Rebuilt from the view model each time ``updateSnapshot(with:)``
        /// is called, then applied to the data source via
        /// ``applySnapshot(animated:)``.
        private var snapshot: NSDiffableDataSourceSnapshot<SectionInfo, CellInfo>?

        /// Creates the diffable data source and attaches it to the table view.
        ///
        /// Called once from
        /// ``SSTableViewPresenter/configureDataSource()``
        /// when the data source mode is ``DataSourceMode/diffable``.
        ///
        /// ## Cell Provider Behavior
        /// 1. Uses `CellInfo.binderType` name as the reuse identifier
        ///    to dequeue the cell.
        /// 2. Calls `CellInfo.apply(to:)` to bind data to the cell.
        /// 3. Attaches `actionHandler` if the cell conforms to
        ///    `EventForwardingProvider`.
        /// 4. Evaluates `shouldLoadNextPage()` to trigger pagination
        ///    when needed.
        ///
        /// - Parameters:
        ///   - tableView: The table view to bind the data source to.
        ///   - actionHandler: Optional handler for forwarding cell events.
        internal func configureDiffableDataSource(
            in tableView: UITableView,
            anyActionHandler actionHandler: AnyActionHandlingProvider? = nil
        ) {
            let aDataSource = UITableViewDiffableDataSource<SectionInfo, CellInfo>(tableView: tableView) { tv, indexPath, row in
                defer {
                    if tv.presenter?.shouldLoadNextPage() ?? false {
                        if let viewModel = tv.presenter?.viewModel {
                            tv.presenter?.isLoadingNextPage = true
                            tv.presenter?.nextRequestBlock?(viewModel)
                        }
                    }
                }

                let id = String(describing: row.binderType)
                let cell = tv.dequeueReusableCell(withIdentifier: id, for: indexPath)
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
            self.dataSource = aDataSource
        }

        /// Builds a new snapshot from the given view model and stores it
        /// internally.
        ///
        /// This method **does not** apply the snapshot to the data source.
        /// Call ``applySnapshot(animated:)`` separately to push the changes.
        ///
        /// Automatically invoked from
        /// ``SSTableViewPresenter/viewModel``'s `didSet`, so external
        /// callers typically do not need to call this directly.
        ///
        /// - Parameter viewModel: The view model whose sections and rows
        ///   will be converted into a snapshot.
        internal func updateSnapshot(with viewModel: SSTableViewModel) {
            var snapshot = NSDiffableDataSourceSnapshot<SectionInfo, CellInfo>()
            for section in viewModel.sections {
                snapshot.appendSections([section])
                snapshot.appendItems(section.rows, toSection: section)
            }
            self.snapshot = snapshot
        }

        /// Applies the stored snapshot to the data source.
        ///
        /// No-op if ``updateSnapshot(with:)`` has not been called yet
        /// (i.e., `snapshot` is `nil`).
        ///
        /// When `animated` is `true`, UIKit automatically animates
        /// insertions, deletions, and moves.
        /// Pass `false` for the initial data load to avoid unnecessary
        /// animation.
        ///
        /// - Parameter animated: Whether to animate the diff-based
        ///   changes.
        internal func applySnapshot(animated: Bool) {
            guard let snapshot = snapshot else { return }
            dataSource?.apply(snapshot, animatingDifferences: animated)
        }

        // MARK: - iOS 15+ Reconfigure Items

        /// Reconfigures cells for the given row identifiers without reloading.
        ///
        /// This updates cell content without recreating the cell,
        /// providing better performance than `reloadItems`.
        ///
        /// - Parameter identifiers: The cell info identifiers to reconfigure.
        @available(iOS 15.0, *)
        internal func reconfigureItems(_ identifiers: [CellInfo]) {
            guard var currentSnapshot = snapshot else { return }
            currentSnapshot.reconfigureItems(identifiers)
            self.snapshot = currentSnapshot
            dataSource?.apply(currentSnapshot, animatingDifferences: false)
        }

        // MARK: - iOS 15+ Apply Snapshot Using Reload Data

        /// Applies the current snapshot without diffing, using a full reload.
        ///
        /// Use this for initial data loads or large batch updates where
        /// animation is not needed.
        @available(iOS 15.0, *)
        internal func applySnapshotUsingReloadData() {
            guard let snapshot = snapshot else { return }
            dataSource?.applySnapshotUsingReloadData(snapshot)
        }
    }
}
