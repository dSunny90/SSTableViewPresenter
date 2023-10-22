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
    /// # Example
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
        public typealias SectionRepresentable = ServerStateSectionRepresentable
        public typealias UnitRepresentable = ServerStateUnitRepresentable

        private var sections: [SectionInfo] = []

        // Working state for the currently open section
        private var currentRows: [CellInfo] = []
        private var currentHeader: HeaderFooterViewInfo?
        private var currentFooter: HeaderFooterViewInfo?
        private var currentIndexTitle: String?
        private var currentSectionID: String = UUID().uuidString
        private var hasOpenSection: Bool = false

        public init() {}

        /// Starts a new section.
        ///
        /// Any previously open section is closed before the new one begins.
        /// If `content` is provided, the block is executed and the section is
        /// closed automatically upon completion.
        ///
        /// - Parameters:
        ///   - id: An optional identifier for the section. Defaults to a
        ///         randomly generated UUID string.
        ///   - content: An optional block for adding rows to this section.
        ///              The section closes automatically after the block returns.
        /// - Returns: The builder, for chaining.
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

        /// Adds multiple sections, with optional per-section and per-unit
        /// configuration.
        ///
        /// Each section is opened in order. `configureSection` runs first,
        /// allowing layout properties such as inset and spacings to be set
        /// before units are added via `configureUnit`.
        ///
        /// When the server and client share a contract that guarantees
        /// section and row ordering, the list can be passed directly
        /// without manual iteration.
        ///
        /// - Parameters:
        ///   - sectionList: The sections to add.
        ///   - configureSection: An optional closure called once per section
        ///                       before its units are added. Receives the
        ///                       section and the builder.
        ///   - configureUnit: A closure called once per unit within each
        ///                    section. Receives the unit and the builder.
        /// - Returns: The builder, for chaining.
        ///
        /// # Example
        /// ```swift
        /// tableView.ss.buildViewModel { builder in
        ///     builder.sections(
        ///         result.sectionList,
        ///         configureSection: { section, builder in
        ///             builder.indexTitle(section.sectionTitle)
        ///         },
        ///         configureUnit: { unit, builder in
        ///             switch unit.unitType {
        ///             case "SS_TOP_BANNER":
        ///                 guard let banrList = unit.unitData as? [BannerModel] else { return }
        ///                 builder.cell(banrList, cellType: TopBannerTableViewCell.self)
        ///             case "SS_PRODUCT_LIST":
        ///                 guard let productList = unit.unitData as? [ProductModel] else { return }
        ///                 builder.cells(productList, cellType: ProductListCell.self)
        ///             case "SS_MY_FAVORITES":
        ///                 guard let myFavorites = unit.unitData as? MyFavoritesModel else { return }
        ///                 if let titleInfo = myFavorites.titleInfo {
        ///                     builder.header(titleInfo, viewType: MyFavoriteTableHeaderView.self)
        ///                 }
        ///                 builder.cells(myFavorites.productList, cellType: ProductListCell.self)
        ///             default:
        ///                 break
        ///             }
        ///         }
        ///     )
        /// }
        /// tableView.reloadData()
        /// ```
        @discardableResult
        public func sections(
            _ sectionList: [any SectionRepresentable],
            configureSection: ((_ section: any SectionRepresentable, _ builder: Builder) -> Void)? = nil,
            configureUnit: @escaping (_ unit: any UnitRepresentable, _ builder: Builder) -> Void
        ) -> Self {
            for section in sectionList {
                self.section(section.sectionId) {
                    configureSection?(section, self)
                    for unit in section.units {
                        configureUnit(unit, self)
                    }
                }
            }
            return self
        }

        /// Sets the index title for the currently open section.
        ///
        /// - Parameter value: The title displayed in the table view section index.
        /// - Returns: The builder, for chaining.
        @discardableResult
        public func indexTitle(_ value: String) -> Self {
            ensureSectionIfNeeded()
            currentIndexTitle = value
            return self
        }

        /// Adds a single cell to the current section.
        ///
        /// - Parameters:
        ///   - model: The model to bind to the cell.
        ///   - cellType: The cell type that renders `model`.
        ///   - actionClosure: A closure invoked when the cell sends an action.
        ///                    Receives the index path, the cell, an action name,
        ///                    and an optional input value.
        ///   - leadingSwipeActions: A closure that returns the leading swipe
        ///                          configuration for the created cell.
        ///   - trailingSwipeActions: A closure that returns the trailing swipe
        ///                           configuration for the created cell.
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
        ///
        /// - Parameters:
        ///   - models: A sequence of models to bind, one cell per element.
        ///   - cellType: The cell type that renders each element.
        ///   - actionClosure: A closure invoked when the cell sends an action.
        ///                    Receives the index path, the cell, an action name,
        ///                    and an optional input value.
        ///   - leadingSwipeActions: A closure that returns the leading swipe
        ///                          configuration for the created cell.
        ///   - trailingSwipeActions: A closure that returns the trailing swipe
        ///                           configuration for the created cell.
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

        /// Sets the header view for the currently open section.
        ///
        /// - Parameters:
        ///   - model: The model to bind to the header view.
        ///   - viewType: The reusable view type that renders `model`.
        ///   - actionClosure: A closure invoked when the header view sends
        ///                    an action. Receives the section index, the view,
        ///                    an action name, and an optional input value.
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

        /// Sets the footer view for the currently open section.
        ///
        /// - Parameters:
        ///   - model: The model to bind to the footer view.
        ///   - viewType: The reusable view type that renders `model`.
        ///   - actionClosure: A closure invoked when the footer view sends
        ///                    an action. Receives the section index, the view,
        ///                    an action name, and an optional input value.
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

        /// Finalizes all open sections and returns the built view model.
        ///
        /// - Parameters:
        ///   - page: The current page index. Defaults to `0`.
        ///   - hasNext: Whether more pages are available. Defaults to `false`.
        ///   - isIndexTitlesEnabled: Whether to display index titles.
        ///                           Defaults to `false`.
        /// - Returns: A fully constructed `SSTableViewModel`.
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
