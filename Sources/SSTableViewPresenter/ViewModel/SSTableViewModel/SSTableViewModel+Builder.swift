//
//  SSTableViewModel+Builder.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 29.07.2021.
//

import UIKit

extension SSTableViewModel {
    // MARK: - SSTableViewModel.Builder

    /// A builder for constructing `SSTableViewModel` by composing sections,
    /// headers/footers, and cells. Use this to declaratively assemble the data
    /// that will be presented in a `UITableView`.
    ///
    /// Example:
    /// ```swift
    /// let builder = SSTableViewModel.Builder()
    /// let model = builder
    ///     .section("main") {
    ///         // Add rows for the "main" section
    ///         // builder.cell(row, cellType: RowCell.self)
    ///     }
    ///     .section("secondary")
    ///     .build()
    /// self.tableView.ss.setViewModel(with: model)
    /// ```
    ///
    /// - Note:
    ///   - This Builder is intended to be used on the main thread only.
    ///   - It is designed specifically to build view models for
    ///     `UITableView` usage.
    ///   - There is no internal synchronization (e.g., `NSLock`);
    ///     concurrent access from multiple threads is not supported
    ///     and behavior is undefined.
    ///   - Do not share a single Builder instance across threads.
    public final class Builder {
        public typealias HeaderFooterViewActionClosure = ((Int, UITableViewHeaderFooterView, String, Any?) -> Void)
        public typealias CellActionClosure = ((IndexPath, UITableViewCell, String, Any?) -> Void)
        public typealias SwipeActionClosure = ((CellInfo) -> CellInfo.SwipeConfiguration)

        private var sections: [SectionInfo] = []

        // Working state for the currently open section
        private var currentRows: [CellInfo] = []
        private var currentHeader: HeaderFooterViewInfo?
        private var currentFooter: HeaderFooterViewInfo?
        private var currentIndexTitle: String?
        private var currentSectionID: String = UUID().uuidString
        private var hasOpenSection: Bool = false

        public init() {}

        /// Starts a new section. If `content` is provided, the section is
        /// automatically closed after executing the block.
        @discardableResult
        public func section(_ id: String? = nil,
                            _ content: (() -> Void)? = nil) -> Self {
            closeCurrentSectionIfNeeded()
            currentSectionID = id ?? UUID().uuidString
            currentRows.removeAll(keepingCapacity: true)
            currentHeader = nil
            currentFooter = nil
            currentIndexTitle = nil
            hasOpenSection = true

            if let content = content {
                content()
                closeCurrentSectionIfNeeded()
            }
            return self
        }

        /// Sets the index title for the currently open section.
        @discardableResult
        public func indexTitle(_ value: String) -> Self {
            ensureSectionIfNeeded()
            currentIndexTitle = value
            return self
        }

        /// Adds a single cell to the current section.
        public func cell<T, V>(
            _ model: T,
            cellType: V.Type,
            actionClosure: CellActionClosure? = nil,
            leadingSwipeActions: SwipeActionClosure? = nil,
            trailingSwipeActions: SwipeActionClosure? = nil
        )
            where V: SSTableViewCellProtocol, V.Input == T
        {
            ensureSectionIfNeeded()
            let cell = CellInfo(BindingStore<T, V>(state: model))
            cell.actionClosure = actionClosure
            cell.leadingSwipeActions = leadingSwipeActions
            cell.trailingSwipeActions = trailingSwipeActions
            currentRows.append(cell)
        }

        /// Adds multiple cells to the current section.
        public func cells<S: Sequence, V>(
            _ models: S,
            cellType: V.Type,
            actionClosure: CellActionClosure? = nil,
            leadingSwipeActions: SwipeActionClosure? = nil,
            trailingSwipeActions: SwipeActionClosure? = nil
        )
            where V: SSTableViewCellProtocol, V.Input == S.Element
        {
            ensureSectionIfNeeded()
            let rows = models.map { model -> CellInfo in
                let cell = CellInfo(BindingStore<S.Element, V>(state: model))
                cell.actionClosure = actionClosure
                cell.leadingSwipeActions = leadingSwipeActions
                cell.trailingSwipeActions = trailingSwipeActions
                return cell
            }
            currentRows.append(contentsOf: rows)
        }

        /// Sets the header of the current section.
        public func header<T, V>(
            _ model: T,
            viewType: V.Type,
            actionClosure: HeaderFooterViewActionClosure? = nil
        )
            where V: SSTableViewHeaderFooterViewProtocol, V.Input == T
        {
            ensureSectionIfNeeded()
            let header = HeaderFooterViewInfo(BindingStore<T, V>(state: model))
            header.actionClosure = actionClosure
            currentHeader = header
        }

        /// Sets the footer of the current section.
        public func footer<T, V>(
            _ model: T,
            viewType: V.Type,
            actionClosure: HeaderFooterViewActionClosure? = nil
        )
            where V: SSTableViewHeaderFooterViewProtocol, V.Input == T
        {
            ensureSectionIfNeeded()
            let footer = HeaderFooterViewInfo(BindingStore<T, V>(state: model))
            footer.actionClosure = actionClosure
            currentFooter = footer
        }

        /// Finalizes and returns the built model.
        public func build(page: Int = 0, hasNext: Bool = false, isIndexTitlesEnabled: Bool = false) -> SSTableViewModel {
            closeCurrentSectionIfNeeded()
            return SSTableViewModel(sections: sections, page: page, hasNext: hasNext, isIndexTitlesEnabled: isIndexTitlesEnabled)
        }

        // MARK: - Private helpers

        private func ensureSectionIfNeeded() {
            if !hasOpenSection {
                // Start an anonymous section implicitly if none is open
                _ = section()
            }
        }

        private func closeCurrentSectionIfNeeded() {
            guard hasOpenSection else { return }
            var section = SectionInfo(
                rows: currentRows,
                header: currentHeader,
                footer: currentFooter,
                identifier: currentSectionID
            )
            section.indexTitle = currentIndexTitle
            sections.append(section)
            // Reset working state
            currentRows.removeAll(keepingCapacity: true)
            currentHeader = nil
            currentFooter = nil
            currentSectionID = UUID().uuidString
            hasOpenSection = false
        }
    }
}
