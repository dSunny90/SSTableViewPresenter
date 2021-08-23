//
//  SendingState+UITableView.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 28.07.2021.
//

import UIKit

@_exported import SendingState

extension SendingState where Base: UITableView {
    public typealias Builder = SSTableViewModel.Builder
    public typealias SectionInfo = SSTableViewModel.SectionInfo
    public typealias CellInfo = SSTableViewModel.CellInfo
    public typealias HeaderFooterViewInfo = SSTableViewModel.HeaderFooterViewInfo

    /// Returns the currently selected rows.
    ///
    /// The presenter automatically tracks selections and deselections via
    /// `tableView(_:didSelectRowAt:)` and `tableView(_:didDeselectRowAt:)`.
    /// When rows are removed from the view model, they are also removed
    /// from this collection.
    internal var selectedRows: [SSTableViewModel.CellInfo] {
        Array(base.presenter?.viewModel?.selectedRows ?? [])
    }

    // MARK: - Configuration

    /// Sets up the presenter for the table view
    ///
    /// - Parameters:
    ///   - actionHandler: Optional handler for user interactions.
    ///   - dataSourceMode: Data mode (`.traditional`, `.diffable`).
    ///                     Default is `.traditional`.
    public func setupPresenter(
        actionHandler: (any ActionHandlingProvider)? = nil,
        dataSourceMode: SSTableViewPresenter.DataSourceMode = .traditional
    ) {
        base.presenter = SSTableViewPresenter(
            tableView: base,
            actionHandler: actionHandler,
            dataSourceMode: dataSourceMode
        )
    }

    // MARK: - View Model

    /// Assigns the view model used by the presenter (sections & rows source).
    ///
    /// - Parameter viewModel: The model containing sections and rows.
    public func setViewModel(with viewModel: SSTableViewModel) {
        base.presenter?.viewModel = viewModel
    }

    /// Gets the current view model used by the presenter.
    ///
    /// - Returns: The current `SSTableViewModel`, if available.
    public func getViewModel() -> SSTableViewModel? {
        return base.presenter?.viewModel
    }

    /// Resets the view model's sections.
    public func resetViewModel() {
        var model = base.presenter?.viewModel ?? SSTableViewModel()
        model.removeAllPages()
        base.presenter?.viewModel = model
    }

    // MARK: - Section/Row Control

    /// Updates the state of a visible cell without reloading it.
    ///
    /// - Parameters:
    ///   - newState: The new state to apply to the cell.
    ///   - indexPath: The index path of the cell to update.
    public func reconfigureRow<T>(_ newState: T, at indexPath: IndexPath) {
        base.presenter?.reconfigureRow(newState, at: indexPath)
    }

    /// Updates the state of a visible section header without reloading it.
    ///
    /// - Parameters:
    ///   - newState: The new state to apply to the header view.
    ///   - section: The index of the section whose header to update.
    @available(iOS 9.0, *)
    public func reconfigureHeader<T>(_ newState: T, at section: Int) {
        base.presenter?.reconfigureHeader(newState, at: section)
    }

    /// Updates the state of a visible section footer without reloading it.
    ///
    /// - Parameters:
    ///   - newState: The new state to apply to the footer view.
    ///   - section: The index of the section whose footer to update.
    @available(iOS 9.0, *)
    public func reconfigureFooter<T>(_ newState: T, at section: Int) {
        base.presenter?.reconfigureFooter(newState, at: section)
    }

    /// Clears the selection tracking state.
    public func clearSelectedRows() {
        base.presenter?.clearSelectedRows()
    }

    /// Toggles the collapsed state of the specified section.
    ///
    /// - Parameters:
    ///   - section: The index of the section to toggle.
    ///   - completion: A closure called after the animation completes.
    ///                 Receives `true` if the section is now expanded,
    ///                 `false` if collapsed.
    public func toggleSection(_ section: Int, completion: @escaping ((Bool) -> Void)) {
        base.presenter?.toggleSection(section, completion: completion)
    }

    /// Builds a new `SSTableViewModel` using a builder pattern and assigns
    /// it to the presenter.
    ///
    /// This method replaces any existing view model. After calling this method,
    /// you must manually refresh the UI by calling `tableView.reloadData()`.
    ///
    /// # Example
    /// ```swift
    /// tableView.ss.buildViewModel { builder in
    ///     builder.section() {
    ///         builder.cell(result.eventBanner, cellType: EventBannerRowCell.self)
    ///     }
    ///     builder.section() {
    ///         builder.cells(result.mainBannerList, cellType: MainBannerRowCell.self)
    ///     }
    ///     builder.section("productList") {
    ///         builder.header(result.productHeaderInfo, viewType: ProductHeaderView.self)
    ///         builder.footer(result.productFooterInfo, viewType: ProductFooterView.self)
    ///         builder.cells(result.productList, cellType: ProductRowCell.self)
    ///     }
    /// }
    ///
    /// // Refresh the UI
    /// tableView.reloadData()
    /// ```
    ///
    /// - Parameters:
    ///   - page: The current page number for pagination. Default is `0`.
    ///   - hasNext: Whether more data is available for pagination.
    ///              Default is `false`.
    ///   - build: A closure that receives a `Builder` instance for constructing
    ///            sections and rows.
    ///
    /// - Returns: The newly built `SSTableViewModel` that was assigned to
    ///            the presenter.
    @discardableResult
    public func buildViewModel(
        page: Int = 0,
        hasNext: Bool = false,
        _ build: (Builder) -> Void
    ) -> SSTableViewModel {
        let builder = Builder()
        build(builder)
        let model = builder.build(page: page, hasNext: hasNext)
        base.presenter?.viewModel = model
        return model
    }

    /// Extends the current view model by appending new sections and rows.
    ///
    /// This method is designed for pagination scenarios where you want to add
    /// content to existing data rather than replacing it entirely.
    ///
    /// **Merge behavior:**
    /// - If a section with the same identifier exists, new rows are appended
    ///   to that section
    /// - Headers and footers are replaced if provided in the new content
    /// - If a section identifier is new, the entire section is appended
    ///
    /// After calling this method, you must manually refresh the UI by calling
    /// `tableView.reloadData()`.
    ///
    /// # Example
    /// ```swift
    /// // Load next page of products
    /// tableView.ss.extendViewModel(
    ///     page: currentPage + 1,
    ///     hasNext: response.hasNext
    /// ) { builder in
    ///     builder.section("productList") {
    ///         builder.cells(response.productList, cellType: ProductRowCell.self)
    ///     }
    /// }
    ///
    /// // Refresh the UI
    /// tableView.reloadData()
    /// ```
    ///
    /// - Parameters:
    ///   - page: The current page number for pagination. Default is `0`.
    ///   - hasNext: Whether more data is available for pagination.
    ///              Default is `false`.
    ///   - build: A closure that receives a `Builder` instance for constructing
    ///            additional sections and rows.
    ///
    /// - Returns: The merged `SSTableViewModel` after appending
    ///            the new content.
    @discardableResult
    public func extendViewModel(
        page: Int = 0,
        hasNext: Bool = false,
        _ build: (Builder) -> Void
    ) -> SSTableViewModel {
        let builder = Builder()
        build(builder)

        var model = base.presenter?.viewModel ?? SSTableViewModel(sections: [])
        model.page = page
        model.hasNext = hasNext

        for section in builder.build().sections {
            if let sectionId = section.identifier,
               let idx = model.firstIndex(where: { $0.identifier == sectionId })
            {
                // Append rows to existing section
                model.sections[idx].rows.append(contentsOf: section.rows)

                // Override header/footer if present
                if let header = section.header {
                    model.sections[idx].header = header
                }
                if let footer = section.footer {
                    model.sections[idx].footer = footer
                }
            } else {
                // Append new section
                model.append(section)
            }
        }

        base.presenter?.viewModel = model
        return model
    }

    // MARK: - Prefetching

    /// Sets a closure to be called when rows should be prefetched.
    ///
    /// Automatically sets the table view's `prefetchDataSource`.
    ///
    /// - Parameter block: A closure that receives the `CellInfo` for rows
    ///                    to prefetch.
    @available(iOS 10.0, *)
    public func onPrefetch(_ block: @escaping ([CellInfo]) -> Void) {
        base.presenter?.prefetchBlock = block
    }

    /// Sets a closure to be called when prefetching should be cancelled.
    ///
    /// - Parameter block: A closure that receives the `CellInfo` for rows
    ///                    whose prefetching should be cancelled.
    @available(iOS 10.0, *)
    public func onCancelPrefetch(_ block: @escaping ([CellInfo]) -> Void) {
        base.presenter?.cancelPrefetchBlock = block
    }

    // MARK: - Snapshot Application (iOS 13+)

    /// Applies the current diffable data source snapshot.
    ///
    /// Only applies when using the `.diffable` data source mode.
    ///
    /// - Parameter animated: Whether to animate the changes. Default is `true`.
    @available(iOS 13.0, *)
    public func applySnapshot(animated: Bool = true) {
        base.presenter?.applySnapshot(animated: animated)
    }

    // MARK: - Row Insertion

    /// Sets a provider used to create a new cell model for row insertion.
    ///
    /// - Parameter block: A closure that receives the target `IndexPath` and
    ///                    returns the `CellInfo` to insert.
    public func setNewCellInfoProvider(_ block: @escaping (IndexPath) -> CellInfo) {
        base.presenter?.newCellInfoProvider = block
    }

    // MARK: - Page-Based Loading

    /// Loads a page of data into the view model's page map and
    /// rebuilds the merged sections.
    ///
    /// This method is designed for server-side pagination where each
    /// page response contains sections that should be merged with
    /// existing pages by identifier.
    ///
    /// **Merge behavior:**
    /// - Sections with the same non-nil identifier across pages have
    ///   their rows concatenated in page order.
    /// - Headers and footers from later pages override earlier ones
    ///   for the same section identifier.
    /// - Sections with unique (or nil) identifiers are appended
    ///   in page order.
    ///
    /// After calling this method, you must manually refresh the UI
    /// by calling `tableView.reloadData()`.
    ///
    /// - Parameters:
    ///   - page: The page number for this batch of data.
    ///   - hasNext: Whether more data is available for pagination.
    ///              Default is `false`.
    ///   - sections: The sections for this page.
    ///
    /// - Returns: The merged `SSTableViewModel` after storing the page.
    @discardableResult
    public func loadPage(
        _ page: Int,
        hasNext: Bool = false,
        sections: [SectionInfo]
    ) -> SSTableViewModel {
        var model = base.presenter?.viewModel ?? SSTableViewModel()
        model.hasNext = hasNext
        model.setPage(page, sections: sections)
        base.presenter?.viewModel = model
        return model
    }

    /// Stores sections for a given page using the builder pattern
    /// and rebuilds the merged sections array.
    ///
    /// This is a convenience overload of `loadPage(_:hasNext:sections:)`
    /// that uses `SSTableViewModel.Builder` for a more declarative syntax.
    ///
    /// After calling this method, you must manually refresh the UI
    /// by calling `tableView.reloadData()`.
    ///
    /// # Example
    /// ```swift
    /// // Initial load
    /// tableView.ss.loadPage(0, hasNext: true) { builder in
    ///     builder.section("banner") {
    ///         builder.cells(bannerList, cellType: BannerRowCell.self)
    ///     }
    ///     builder.section("weekly") {
    ///         builder.cells(productList, cellType: ProductRowCell.self)
    ///     }
    /// }
    /// tableView.reloadData()
    ///
    /// // Next page
    /// tableView.ss.loadPage(1, hasNext: false) { builder in
    ///     builder.section("today") {
    ///         builder.cells(productList, cellType: ProductCell.self)
    ///     }
    /// }
    /// tableView.reloadData()
    /// ```
    ///
    /// - Parameters:
    ///   - page: The page number for this batch of data.
    ///   - hasNext: Whether more data is available for pagination.
    ///              Default is `false`.
    ///   - build: A closure that receives a `Builder` to construct the
    ///            sections for this page.
    ///
    /// - Returns: The merged `SSTableViewModel` after storing the page.
    @discardableResult
    public func loadPage(
        _ page: Int,
        hasNext: Bool = false,
        _ build: (Builder) -> Void
    ) -> SSTableViewModel {
        let builder = Builder()
        build(builder)
        let built = builder.build()
        return loadPage(page, hasNext: hasNext, sections: built.sections)
    }

    /// Removes a specific page from the page map and rebuilds
    /// the merged sections.
    ///
    /// - Parameter page: The page number to remove.
    /// - Returns: The updated `SSTableViewModel` after removal,
    ///            or `nil` if no view model exists.
    @discardableResult
    public func removePage(_ page: Int) -> SSTableViewModel? {
        guard var model = base.presenter?.viewModel else { return nil }
        model.removePage(page)
        base.presenter?.viewModel = model
        return model
    }

    /// Configures the pagination handler for loading the next page.
    ///
    /// The closure is called automatically when the user scrolls near the end
    /// and `viewModel.hasNext` is `true`.
    ///
    /// - Parameter block: A closure that receives the current view model.
    ///                    Use this to fetch additional data from your API.
    public func onNextRequest(_ block: @escaping (SSTableViewModel) -> Void) {
        base.presenter?.nextRequestBlock = block
    }

    // MARK: - Section Operations

    /// Appends a section to the end of the view model.
    ///
    /// No-op if the view model is empty.
    ///
    /// - Parameter section: The section to append.
    public func appendSection(_ section: SectionInfo) {
        guard var viewModel = base.presenter?.viewModel else { return }
        viewModel.append(section)
        base.presenter?.viewModel = viewModel
    }

    /// Appends multiple sections to the end of the view model.
    ///
    /// No-op if the view model is empty.
    ///
    /// - Parameter sections: The sections to append.
    public func appendSections(contentsOf sections: [SectionInfo]) {
        guard var viewModel = base.presenter?.viewModel else { return }
        viewModel.append(contentsOf: sections)
        base.presenter?.viewModel = viewModel
    }

    /// Inserts a section at the specified index.
    ///
    /// No-op if the index is out of bounds (`0...sectionCount`).
    ///
    /// - Parameters:
    ///   - section: The section to insert.
    ///   - index: The position at which to insert the section.
    public func insertSection(_ section: SectionInfo, at index: Int) {
        guard var viewModel = base.presenter?.viewModel,
              (0...viewModel.count).contains(index) else { return }
        viewModel.insert(section, at: index)
        base.presenter?.viewModel = viewModel
    }

    /// Inserts multiple sections starting at the specified index.
    ///
    /// No-op if the index is out of bounds (`0...sectionCount`).
    ///
    /// - Parameters:
    ///   - sections: The sections to insert.
    ///   - index: The starting position for the insertion.
    public func insertSections(_ sections: [SectionInfo], at index: Int) {
        guard var viewModel = base.presenter?.viewModel,
              (0...viewModel.count).contains(index) else { return }
        viewModel.insert(contentsOf: sections, at: index)
        base.presenter?.viewModel = viewModel
    }

    /// Removes the section at the specified index.
    ///
    /// No-op if the index is out of bounds.
    ///
    /// - Parameter index: The index of the section to remove.
    public func removeSection(at index: Int) {
        guard var viewModel = base.presenter?.viewModel,
              viewModel.indices.contains(index) else { return }
        viewModel.remove(at: index)
        base.presenter?.viewModel = viewModel
    }

    /// Removes sections at the specified indices.
    ///
    /// Out-of-bounds indices are silently ignored.
    ///
    /// - Parameter indices: An `IndexSet` of section indices to remove.
    public func removeSections(at indices: IndexSet) {
        guard var viewModel = base.presenter?.viewModel else { return }
        for index in indices.sorted(by: >) {
            guard viewModel.indices.contains(index) else { continue }
            viewModel.remove(at: index)
        }
        base.presenter?.viewModel = viewModel
    }

    /// Removes the first section matching the given identifier.
    ///
    /// No-op if no section with the identifier exists.
    ///
    /// - Parameter identifier: The identifier of the section to remove.
    public func removeSection(identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let index = viewModel.sections.firstIndex(where: { $0.identifier == identifier })
        else { return }
        viewModel.remove(at: index)
        base.presenter?.viewModel = viewModel
    }

    /// Removes all sections from the view model.
    public func removeAllSections() {
        guard var viewModel = base.presenter?.viewModel else { return }
        viewModel.removeAll()
        base.presenter?.viewModel = viewModel
    }

    /// Replaces the section at the specified index with a new section.
    ///
    /// No-op if the index is out of bounds.
    ///
    /// - Parameters:
    ///   - section: The replacement section.
    ///   - index: The index of the section to replace.
    public func replaceSection(_ section: SectionInfo, at index: Int) {
        guard var viewModel = base.presenter?.viewModel,
              viewModel.indices.contains(index) else { return }
        viewModel[index] = section
        base.presenter?.viewModel = viewModel
    }

    /// Replaces the first section matching the given identifier.
    ///
    /// No-op if no section with the identifier exists.
    ///
    /// - Parameters:
    ///   - section: The replacement section.
    ///   - identifier: The identifier of the section to replace.
    public func replaceSection(_ section: SectionInfo, identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let index = viewModel.sections.firstIndex(where: { $0.identifier == identifier })
        else { return }
        viewModel[index] = section
        base.presenter?.viewModel = viewModel
    }

    /// Moves a section from one index to another.
    ///
    /// No-op if either index is out of bounds.
    ///
    /// - Parameters:
    ///   - fromIndex: The current index of the section.
    ///   - toIndex: The destination index for the section.
    public func moveSection(from fromIndex: Int, to toIndex: Int) {
        guard var viewModel = base.presenter?.viewModel,
              viewModel.indices.contains(fromIndex),
              (0...viewModel.count - 1).contains(toIndex),
              fromIndex != toIndex
        else { return }
        let section = viewModel.remove(at: fromIndex)
        viewModel.insert(section, at: toIndex)
        base.presenter?.viewModel = viewModel
    }

    /// Returns the number of sections in the view model.
    public var sectionCount: Int {
        base.presenter?.viewModel?.count ?? 0
    }

    /// Returns the section at the specified index, or `nil` if out of bounds.
    ///
    /// - Parameter index: The index of the section.
    /// - Returns: The `SectionInfo` at the index, or `nil`.
    public func section(at index: Int) -> SectionInfo? {
        base.presenter?.viewModel?.sectionInfo(at: index)
    }

    /// Returns the first section matching the given identifier, or `nil`
    /// if not found.
    ///
    /// - Parameter identifier: The identifier to search for.
    /// - Returns: The matching `SectionInfo`, or `nil`.
    public func section(identifier: String) -> SectionInfo? {
        base.presenter?.viewModel?.sections.first(where: { $0.identifier == identifier })
    }

    /// Returns the index of the first section matching the given identifier,
    /// or `nil` if not found.
    ///
    /// - Parameter identifier: The identifier to search for.
    /// - Returns: The section index, or `nil`.
    public func sectionIndex(identifier: String) -> Int? {
        base.presenter?.viewModel?.sections.firstIndex(where: { $0.identifier == identifier })
    }

    // MARK: - Row Operations

    /// Appends an rows to the section at the specified index.
    ///
    /// No-op if the section index is out of bounds.
    ///
    /// - Parameters:
    ///   - row: The row to append.
    ///   - section: The index of the target section.
    public func appendRow(_ row: CellInfo, toSection section: Int) {
        guard var viewModel = base.presenter?.viewModel,
              viewModel.indices.contains(section) else { return }
        viewModel[section].append(row)
        base.presenter?.viewModel = viewModel
    }

    /// Appends multiple rows to the section at the specified index.
    ///
    /// No-op if the section index is out of bounds.
    ///
    /// - Parameters:
    ///   - rows: The rows to append.
    ///   - section: The index of the target section.
    public func appendRows(contentsOf rows: [CellInfo], toSection section: Int) {
        guard var viewModel = base.presenter?.viewModel,
              viewModel.indices.contains(section) else { return }
        viewModel[section].append(contentsOf: rows)
        base.presenter?.viewModel = viewModel
    }

    /// Appends an row to the first section matching the given identifier.
    ///
    /// No-op if no section with the identifier exists.
    ///
    /// - Parameters:
    ///   - row: The row to append.
    ///   - identifier: The identifier of the target section.
    public func appendRow(_ row: CellInfo, sectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier })
        else { return }
        viewModel.sections[sectionIndex].append(row)
        base.presenter?.viewModel = viewModel
    }

    /// Appends multiple rows to the first section matching the given identifier.
    ///
    /// No-op if no section with the identifier exists.
    ///
    /// - Parameters:
    ///   - rows: The rows to append.
    ///   - identifier: The identifier of the target section.
    public func appendRows(contentsOf rows: [CellInfo], sectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier })
        else { return }
        viewModel.sections[sectionIndex].append(contentsOf: rows)
        base.presenter?.viewModel = viewModel
    }

    /// Appends an row to the last section in the view model.
    ///
    /// No-op if the view model is empty.
    ///
    /// - Parameter row: The row to append.
    public func appendRowToLastSection(_ row: CellInfo) {
        guard var viewModel = base.presenter?.viewModel,
              !viewModel.isEmpty else { return }
        let lastIndex = viewModel.count - 1
        viewModel[lastIndex].append(row)
        base.presenter?.viewModel = viewModel
    }

    /// Appends multiple rows to the last section in the view model.
    ///
    /// No-op if the view model is empty.
    ///
    /// - Parameter rows: The rows to append.
    public func appendRowsToLastSection(contentsOf rows: [CellInfo]) {
        guard var viewModel = base.presenter?.viewModel,
              !viewModel.isEmpty else { return }
        let lastIndex = viewModel.count - 1
        viewModel[lastIndex].append(contentsOf: rows)
        base.presenter?.viewModel = viewModel
    }

    /// Inserts an row at the specified index path.
    ///
    /// No-op if the section or row index is out of bounds.
    ///
    /// - Parameters:
    ///   - row: The row to insert.
    ///   - indexPath: The index path where the row will be inserted.
    public func insertRow(_ row: CellInfo, at indexPath: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.count,
              indexPath.row <= viewModel[indexPath.section].count else { return }
        viewModel[indexPath.section].insert(row, at: indexPath.row)
        base.presenter?.viewModel = viewModel
    }

    /// Inserts multiple rows starting at the specified index path.
    ///
    /// No-op if the section or row index is out of bounds.
    ///
    /// - Parameters:
    ///   - rows: The rows to insert.
    ///   - indexPath: The starting index path for insertion.
    public func insertRows(_ rows: [CellInfo], at indexPath: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.count,
              indexPath.row <= viewModel[indexPath.section].count else { return }
        viewModel[indexPath.section].insert(contentsOf: rows, at: indexPath.row)
        base.presenter?.viewModel = viewModel
    }

    /// Inserts an row at the specified row in the first section matching
    /// the given identifier.
    ///
    /// No-op if no section with the identifier exists or the row is out
    /// of bounds (`0...rowCount`).
    ///
    /// - Parameters:
    ///   - cellInfo: The row to insert.
    ///   - row: The row index for insertion.
    ///   - identifier: The identifier of the target section.
    public func insertRow(
        _ cellInfo: CellInfo,
        atRow row: Int,
        sectionIdentifier identifier: String
    ) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier }),
              (0...viewModel[sectionIndex].count).contains(row)
        else { return }
        viewModel[sectionIndex].insert(cellInfo, at: row)
        base.presenter?.viewModel = viewModel
    }

    /// Inserts multiple rows starting at the specified row in the first
    /// section matching the given identifier.
    ///
    /// No-op if no section with the identifier exists or the row is out
    /// of bounds (`0...rowCount`).
    ///
    /// - Parameters:
    ///   - rows: The rows to insert.
    ///   - row: The starting row index for insertion.
    ///   - identifier: The identifier of the target section.
    public func insertRows(
        _ rows: [CellInfo],
        atRow row: Int,
        sectionIdentifier identifier: String
    ) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier }),
              (0...viewModel[sectionIndex].count).contains(row)
        else { return }
        viewModel[sectionIndex].insert(contentsOf: rows, at: row)
        base.presenter?.viewModel = viewModel
    }

    /// Removes the row at the specified index path.
    ///
    /// No-op if the index path is out of bounds.
    ///
    /// - Parameter indexPath: The index path of the row to remove.
    public func removeRow(at indexPath: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.count,
              indexPath.row < viewModel[indexPath.section].count else { return }
        viewModel[indexPath.section].remove(at: indexPath.row)
        base.presenter?.viewModel = viewModel
    }

    /// Removes rows at the specified index paths.
    ///
    /// Out-of-bounds index paths are silently ignored.
    ///
    /// - Parameter indexPaths: The index paths of the rows to remove.
    public func removeRows(at indexPaths: [IndexPath]) {
        guard var viewModel = base.presenter?.viewModel else { return }
        let sorted = indexPaths.sorted {
            $0.section > $1.section ||
            ($0.section == $1.section && $0.row > $1.row)
        }
        for indexPath in sorted {
            guard indexPath.section < viewModel.count,
                  indexPath.row < viewModel[indexPath.section].count else { continue }
            viewModel[indexPath.section].remove(at: indexPath.row)
        }
        base.presenter?.viewModel = viewModel
    }

    /// Removes all rows in the section at the specified index.
    ///
    /// No-op if the section index is out of bounds.
    /// The section itself remains; only its rows are cleared.
    ///
    /// - Parameter section: The index of the section to clear.
    public func removeAllRows(inSection section: Int) {
        guard var viewModel = base.presenter?.viewModel,
              viewModel.indices.contains(section) else { return }
        viewModel[section].removeAll()
        base.presenter?.viewModel = viewModel
    }

    /// Removes the row at the specified row in the first section matching
    /// the given identifier.
    ///
    /// No-op if no section with the identifier exists or the row is out
    /// of bounds.
    ///
    /// - Parameters:
    ///   - row: The row index of the row to remove.
    ///   - identifier: The identifier of the target section.
    public func removeRow(atRow row: Int, sectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier }),
              row < viewModel[sectionIndex].count
        else { return }
        viewModel[sectionIndex].remove(at: row)
        base.presenter?.viewModel = viewModel
    }

    /// Removes all rows in the first section matching the given identifier.
    ///
    /// No-op if no section with the identifier exists.
    /// The section itself remains; only its rows are cleared.
    ///
    /// - Parameter identifier: The identifier of the section to clear.
    public func removeAllRows(sectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier })
        else { return }
        viewModel[sectionIndex].removeAll()
        base.presenter?.viewModel = viewModel
    }

    /// Replaces the row at the specified index path.
    ///
    /// No-op if the index path is out of bounds.
    ///
    /// - Parameters:
    ///   - row: The replacement row.
    ///   - indexPath: The index path of the row to replace.
    public func replaceRow(_ row: CellInfo, at indexPath: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.count,
              indexPath.row < viewModel[indexPath.section].count else { return }
        viewModel[indexPath.section][indexPath.row] = row
        base.presenter?.viewModel = viewModel
    }

    /// Replaces the row at the specified row in the first section matching
    /// the given identifier.
    ///
    /// No-op if no section with the identifier exists or the row is out
    /// of bounds.
    ///
    /// - Parameters:
    ///   - cellInfo: The replacement row.
    ///   - row: The row index of the row to replace.
    ///   - identifier: The identifier of the target section.
    public func replaceRow(
        _ cellInfo: CellInfo,
        atRow row: Int,
        sectionIdentifier identifier: String
    ) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier }),
              row < viewModel[sectionIndex].count
        else { return }
        viewModel[sectionIndex][row] = cellInfo
        base.presenter?.viewModel = viewModel
    }

    /// Moves an row from one index path to another.
    ///
    /// No-op if the source index path is out of bounds. The destination
    /// row is clamped to the valid range after removal.
    ///
    /// - Parameters:
    ///   - source: The current index path of the row.
    ///   - destination: The destination index path for the row.
    public func moveRow(from source: IndexPath, to destination: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              source.section < viewModel.count,
              source.row < viewModel[source.section].count,
              destination.section < viewModel.count
        else { return }
        let row = viewModel[source.section].remove(at: source.row)
        let clampedRow = min(destination.row, viewModel[destination.section].count)
        viewModel[destination.section].insert(row, at: clampedRow)
        base.presenter?.viewModel = viewModel
    }

    /// Returns the number of rows in the section at the specified index.
    ///
    /// - Parameter section: The index of the section.
    /// - Returns: The row count, or `0` if the section index is out of bounds.
    public func rowCount(inSection section: Int) -> Int {
        base.presenter?.viewModel?.sectionInfo(at: section)?.count ?? 0
    }

    /// Returns the number of rows in the first section matching
    /// the given identifier.
    ///
    /// - Parameter identifier: The identifier of the section.
    /// - Returns: The row count, or `0` if no matching section exists.
    public func rowCount(sectionIdentifier identifier: String) -> Int {
        base.presenter?.viewModel?.sections
            .first(where: { $0.identifier == identifier })?.count ?? 0
    }

    /// Returns the row at the specified index path, or `nil` if out of bounds.
    ///
    /// - Parameter indexPath: The index path of the row.
    /// - Returns: The `CellInfo` at the index path, or `nil`.
    public func row(at indexPath: IndexPath) -> CellInfo? {
        guard let viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.count,
              indexPath.row < viewModel[indexPath.section].count
        else { return nil }
        return viewModel[indexPath.section][indexPath.row]
    }

    /// Returns the row at the specified row in the first section matching
    /// the given identifier, or `nil` if not found.
    ///
    /// - Parameters:
    ///   - row: The row index of the row.
    ///   - identifier: The identifier of the target section.
    /// - Returns: The `CellInfo`, or `nil`.
    public func row(atRow row: Int, sectionIdentifier identifier: String) -> CellInfo? {
        guard let viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier }),
              row < viewModel[sectionIndex].count
        else { return nil }
        return viewModel[sectionIndex][row]
    }
}
