//
//  SSTableViewModel.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 28.07.2021.
//

import UIKit

private typealias SectionInfo = SSTableViewModel.SectionInfo

/// A data model that represents the entire content of a table view,
/// used by `SSTableViewPresenter` to render and manage UI states.
///
/// - Note:
///   - The `sections` array holds `SectionInfo` objects, each describing
///     the cells and header/footer views for a section.
public struct SSTableViewModel: RandomAccessCollection, RangeReplaceableCollection {
    // MARK: - RandomAccessCollection

    public typealias Index = Int
    public typealias Element = SectionInfo

    public var startIndex: Int { sections.startIndex }
    public var endIndex: Int { sections.endIndex }

    // MARK: - Core Contents

    /// The current sections to be displayed in the table view.
    internal var sections: [SectionInfo] = []

    /// Returns the currently selected rows.
    public var selectedRows: [SSTableViewModel.CellInfo] {
        sections.flatMap { $0.rows.filter { $0.isSelected } }
    }

    /// Whether to display index titles (section index bar) in the table view.
    ///
    /// When `true`, the presenter returns index titles from sections that have
    /// a non-nil `indexTitle` property.
    public var isIndexTitlesEnabled: Bool = false

    // MARK: - Page Map

    /// The current page number for paginated API requests.
    /// Use this when fetching data from a page-based RESTful API
    /// to update your view model.
    public var page: Int = 0

    /// A flag indicating whether there is more data available for pagination.
    /// Set this based on the API response to control whether a next request
    /// should be triggered.
    public var hasNext: Bool = false

    /// Maps page numbers to their original sections.
    /// When non-empty, `sections` is rebuilt as a merged view of all pages
    /// via `rebuildMergedSections()`.
    internal var pageMap: [Int: [SectionInfo]] = [:]

    /// The number of pages currently stored.
    public var pageCount: Int { pageMap.count }

    /// Whether any pages have been stored via `setPage(_:sections:)`.
    public var hasPageData: Bool { !pageMap.isEmpty }

    // MARK: - Init.
    public init(sections: [SectionInfo] = [], page: Int = 0, hasNext: Bool = false, isIndexTitlesEnabled: Bool = false) {
        self.sections = sections
        self.page = page
        self.hasNext = hasNext
        self.isIndexTitlesEnabled = isIndexTitlesEnabled
    }

    public init() {
        self.init(sections: [])
    }

    /// Get a section at the specified index.
    public func sectionInfo(at index: Int) -> SectionInfo? {
        guard sections.indices.contains(index) else { return nil }
        return sections[index]
    }

    // MARK: - Index Titles

    /// Builds a pair of (titles, sections) arrays aligned by position.
    ///
    /// Titles are deduplicated and ordered by first appearance.
    /// Each entry in `sections` is the index of the first section whose
    /// `indexTitle` matches the corresponding title.
    internal func buildIndexTitleMap() -> (titles: [String], sections: [Int]) {
        var seen = Set<String>()
        var titles: [String] = []
        var sectionIndexes: [Int] = []
        for (sectionIndex, section) in sections.enumerated() {
            guard let title = section.indexTitle else { continue }
            if seen.insert(title).inserted {
                titles.append(title)
                sectionIndexes.append(sectionIndex)
            }
        }
        return (titles, sectionIndexes)
    }

    // MARK: - Page Management

    /// Stores sections for a given page and rebuilds the merged sections array.
    ///
    /// If sections for this page already exist, they are replaced entirely.
    /// After storing, `rebuildMergedSections()` is called to update
    /// the flat `sections` array used by the table view.
    ///
    /// - Parameters:
    ///   - page: The page number (zero-based).
    ///   - pageSections: The sections belonging to this page.
    public mutating func setPage(_ page: Int, sections pageSections: [SectionInfo]) {
        pageMap[page] = pageSections
        self.page = page
        rebuildMergedSections()
    }

    /// Returns the sections stored for a specific page, if any.
    public func sections(forPage page: Int) -> [SectionInfo]? {
        pageMap[page]
    }

    /// Removes the sections stored for a specific page and rebuilds
    /// the merged sections.
    public mutating func removePage(_ page: Int) {
        pageMap.removeValue(forKey: page)
        rebuildMergedSections()
    }

    /// Removes all page data and clears the merged sections.
    /// Use this for pull-to-refresh scenarios.
    public mutating func removeAllPages() {
        pageMap.removeAll()
        sections.removeAll()
        page = 0
        hasNext = false
    }

    /// Finds the highest page number that contains a section
    /// with the given identifier.
    ///
    /// Use this to determine which page to request next
    /// for a specific section.
    ///
    /// ```swift
    /// let targetPage = vm.findPage(forSectionIdentifier: "filter") ?? 0
    /// ```
    ///
    /// - Returns: The page number, or `nil` if no page contains
    ///   a section with that identifier.
    public func findPage(forSectionIdentifier id: String) -> Int? {
        pageMap.keys.sorted(by: >).first { page in
            pageMap[page]?.contains(where: { $0.identifier == id }) == true
        }
    }

    /// Rebuilds the flat `sections` array by merging all pages
    /// in ascending page order.
    ///
    /// **Merge rules:**
    /// - Sections with the same non-nil `identifier` across pages
    ///   have their rows concatenated. Headers/footers from later
    ///   pages override earlier ones.
    /// - Sections with nil identifiers are always appended as
    ///   new sections (they never merge).
    internal mutating func rebuildMergedSections() {
        guard !pageMap.isEmpty else { return }

        var merged: [SectionInfo] = []
        var identifierIndex: [String: Int] = [:]

        for pageKey in pageMap.keys.sorted() {
            guard let pageSections = pageMap[pageKey] else { continue }

            for section in pageSections {
                if let id = section.identifier, let idx = identifierIndex[id] {
                    merged[idx].rows.append(contentsOf: section.rows)

                    if let header = section.header {
                        merged[idx].header = header
                    }
                    if let footer = section.footer {
                        merged[idx].footer = footer
                    }
                } else {
                    let newIdx = merged.count
                    merged.append(section)
                    if let id = section.identifier {
                        identifierIndex[id] = newIdx
                    }
                }
            }
        }

        sections = merged
    }

    // MARK: - RandomAccessCollection Methods

    public func index(after i: Int) -> Int {
        sections.index(after: i)
    }

    public func index(before i: Int) -> Int {
        sections.index(before: i)
    }

    // MARK: - RangeReplaceableCollection

    public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C)
        where C: Collection, C.Element == SectionInfo {
            sections.replaceSubrange(subrange, with: newElements)
    }

    // MARK: - RandomAccessCollection Subscripts

    public subscript(index: Int) -> SectionInfo {
        get { sections[index] }
        set { sections[index] = newValue }
    }

    // MARK: - Operators Overloading

    public static func + (lhs: SSTableViewModel, rhs: SSTableViewModel) -> SSTableViewModel {
        SSTableViewModel(sections: lhs.sections + rhs.sections)
    }

    public static func += (lhs: inout SSTableViewModel, rhs: SSTableViewModel) {
        lhs.sections += rhs.sections
    }

    public static func + (lhs: SSTableViewModel, rhs: SectionInfo) -> SSTableViewModel {
        var new = lhs
        new.append(rhs)
        return new
    }

    public static func + (lhs: SSTableViewModel, rhs: [SectionInfo]) -> SSTableViewModel {
        var new = lhs
        new.append(contentsOf: rhs)
        return new
    }
}
