//
//  SSTableViewModel+SectionInfo.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 28.07.2021.
//

import UIKit

extension SSTableViewModel {
    // MARK: - SSTableViewModel.SectionInfo
    /// A view model structure used by `SSTableViewPresenter` to configure
    /// and render each section of the table view.
    public struct SectionInfo: RandomAccessCollection, RangeReplaceableCollection, Hashable, Sendable {
        public typealias HeaderFooterViewInfo = SSTableViewModel.HeaderFooterViewInfo

        private let uuid: UUID = UUID()

        // MARK: - Core Contents

        internal var identifier: String?

        internal var rows: [CellInfo]
        internal var header: HeaderFooterViewInfo?
        internal var footer: HeaderFooterViewInfo?
        internal var headerTitle: String?
        internal var footerTitle: String?

        /// A Boolean value indicating whether the section is collapsed.
        ///
        /// When `true`, the section's rows are hidden from the table view.
        /// Set this value before calling `performBatchUpdates` to ensure the
        /// data source reflects the updated state during the animation.
        public var isCollapsed: Bool = false

        /// An optional index title string for this section.
        ///
        /// When set, this value is used by `sectionIndexTitles(for:)` to build
        /// the section index bar on the right side of the table view.
        /// Only effective when `SSTableViewModel.isIndexTitlesEnabled` is `true`
        public var indexTitle: String?

        // MARK: - RandomAccessCollection

        public typealias Index = Int
        public typealias Element = CellInfo

        public var startIndex: Int { rows.startIndex }
        public var endIndex: Int { rows.endIndex }

        // MARK: - Init.
        public init(
            rows: [CellInfo] = [],
            header: HeaderFooterViewInfo? = nil,
            footer: HeaderFooterViewInfo? = nil,
            headerTitle: String? = nil,
            footerTitle: String? = nil,
            indexTitle: String? = nil,
            identifier: String? = nil
        ) {
            self.rows = rows
            self.header = header
            self.footer = footer
            self.headerTitle = headerTitle
            self.footerTitle = footerTitle
            self.indexTitle = indexTitle
            self.identifier = identifier
        }

        public init() {
            self.init(rows: [])
        }

        /// Get a cell info at the specified index.
        public func cellInfo(at index: Int) -> CellInfo? {
            guard let cellInfo = rows[safe: index] else { return nil }
            return cellInfo
        }

        /// Get a header info at the specified index.
        public func headerInfo() -> HeaderFooterViewInfo? { header }

        /// Get a footer info at the specified index.
        public func footerInfo() -> HeaderFooterViewInfo? { footer }

        // MARK: - RandomAccessCollection Methods

        public func index(after i: Int) -> Int {
            rows.index(after: i)
        }

        public func index(before i: Int) -> Int {
            rows.index(before: i)
        }

        // MARK: - RangeReplaceableCollection

        public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C)
            where C: Collection, C.Element == CellInfo
        {
            rows.replaceSubrange(subrange, with: newElements)
        }

        // MARK: - RandomAccessCollection Subscripts

        public subscript(index: Int) -> CellInfo {
            get { rows[index] }
            set { rows[index] = newValue }
        }

        // MARK: - Hashable

        public func hash(into hasher: inout Hasher) {
            hasher.combine(uuid)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.uuid == rhs.uuid
        }

        // MARK: - Operators Overloading
        public static func + (lhs: SectionInfo, rhs: SectionInfo) -> SectionInfo {
            SectionInfo(rows: lhs.rows + rhs.rows)
        }

        public static func += (lhs: inout SectionInfo, rhs: SectionInfo) {
            lhs.rows += rhs.rows
        }

        public static func + (lhs: SectionInfo, rhs: CellInfo) -> SectionInfo {
            var new = lhs
            new.append(rhs)
            return new
        }

        public static func + (lhs: SectionInfo, rhs: [CellInfo]) -> SectionInfo {
            var new = lhs
            new.append(contentsOf: rhs)
            return new
        }
    }
}

public extension SSTableViewModel.SectionInfo {
    // MARK: - Cell/Header/Footer Operations

    /// Appends a cell info to the end of the section.
    ///
    /// - Parameters:
    ///   - model: The data model to bind to the cell.
    ///   - cellType: The cell view type conforming to `SSTableViewCellProtocol`.
    mutating func appendCellInfo<T, V>(_ model: T, cellType: V.Type)
        where V: SSTableViewCellProtocol, V.Input == T
    {
        append(Element(BindingStore<T, V>(state: model)))
    }

    /// Inserts a cell info at the specified index.
    ///
    /// - Parameters:
    ///   - model: The data model to bind to the cell.
    ///   - cellType: The cell view type conforming to `SSTableViewCellProtocol`.
    ///   - index: Target index within `startIndex...endIndex`.
    ///
    /// - Note: No-op if `index` is outside `startIndex...endIndex`.
    mutating func insertCellInfo<T, V>(_ model: T, cellType: V.Type, at index: Int)
        where V: SSTableViewCellProtocol, V.Input == T
    {
        guard (startIndex...endIndex).contains(index) else { return }
        rows.insert(Element(BindingStore<T, V>(state: model)), at: index)

    }

    /// Updates an existing cell info at the specified index.
    ///
    /// - Parameters:
    ///   - model: The data model to bind to the cell.
    ///   - cellType: The cell view type conforming to `SSTableViewCellProtocol`.
    ///   - index: The index of the cell to update.
    mutating func updateCellInfo<T, V>(
        _ model: T,
        cellType: V.Type,
        at index: Int
    ) where V: SSTableViewCellProtocol, V.Input == T {
        guard rows.indices.contains(index) else { return }
        rows[index] = Element(BindingStore<T, V>(state: model))
    }

    /// Upserts a cell info at the specified index.
    ///
    /// - Behavior:
    ///   - If `index` is within current indices, updates the cell.
    ///   - If `index` equals `endIndex`, appends the cell.
    ///   - Otherwise, performs no operation.
    ///
    /// - Parameters:
    ///   - model: The data model to bind to the cell.
    ///   - cellType: The cell view type conforming to `SSTableViewCellProtocol`.
    ///   - index: Target index for update or insertion.
    mutating func upsertCellInfo<T, V>(
        _ model: T,
        cellType: V.Type,
        at index: Int
    ) where V: SSTableViewCellProtocol, V.Input == T {
        if rows.indices.contains(index) {
            updateCellInfo(model, cellType: cellType, at: index)
        } else if index == endIndex {
            appendCellInfo(model, cellType: V.self)
        } else {
            return
        }
    }

    /// Sets the section's header reusable view information.
    ///
    /// - Parameters:
    ///   - model: The data model to provide to the header view.
    ///   - viewType: The header view type conforming to `SSTableViewHeaderFooterViewProtocol`.
    mutating func setHeaderInfo<T, V>(_ model: T, viewType: V.Type)
        where V: SSTableViewHeaderFooterViewProtocol, V.Input == T
    {
        header = HeaderFooterViewInfo(BindingStore<T, V>(state: model))
    }

    /// Sets the section's footer reusable view information.
    ///
    /// - Parameters:
    ///   - model: The data model to provide to the footer view.
    ///   - viewType: The footer view type conforming to `SSTableViewHeaderFooterViewProtocol`.
    mutating func setFooterInfo<T, V>(_ model: T, viewType: V.Type)
        where V: SSTableViewHeaderFooterViewProtocol, V.Input == T
    {
        footer = HeaderFooterViewInfo(BindingStore<T, V>(state: model))
    }
}
