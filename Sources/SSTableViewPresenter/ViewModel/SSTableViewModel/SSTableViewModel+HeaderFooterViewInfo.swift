//
//  SSTableViewModel+HeaderFooterViewInfo.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 28.07.2021.
//

import UIKit

extension SSTableViewModel {
    // MARK: - SSTableViewModel.HeaderFooterViewInfo
    /// A type-erased container that holds information for headerFooterViews,
    /// used by `SSTableViewPresenter` to configure and render header/footer
    /// views in the table view.
    public final class HeaderFooterViewInfo: AnyBindingStore, @unchecked Sendable {
        /// A closure invoked when the bound view sends an action.
        ///
        /// - Parameters:
        ///   - section: The section index where the view is located.
        ///   - view: The header/footer view that triggered the action.
        ///   - actionName: A string identifying the type of action.
        ///   - input: An optional value passed by the caller for the action.
        public var actionClosure: ((Int, UITableViewHeaderFooterView, String, Any?) -> Void)?

        private let _willDisplayBlock: @MainActor (Any) -> Void
        private let _didEndDisplayingBlock: @MainActor (Any) -> Void

        /// Creates a type-erased wrapper for a header/footer view binding store.
        ///
        /// - Parameter store: The binding store that provides the header/footer
        ///                    view's input state and binder type conforming to
        ///                    `SSTableViewHeaderFooterViewProtocol`.
        public init<State, Binder>(_ store: BindingStore<State, Binder>)
            where Binder: SSTableViewHeaderFooterViewProtocol
        {
            _willDisplayBlock = { binder in
                guard let view = binder as? Binder else { return }
                view.willDisplay(with: store.state)
            }
            _didEndDisplayingBlock = { binder in
                guard let view = binder as? Binder else { return }
                view.didEndDisplaying(with: store.state)
            }
            super.init(store)
        }

        /// Forwards `tableView(_:willDisplayHeaderView:forSection:)`/
        /// `tableView(_:willDisplayFooterView:forSection:)`
        /// to the binder using the stored row.
        @MainActor
        public func willDisplay(to binder: Any) { _willDisplayBlock(binder) }

        /// Forwards `tableView(_:didEndDisplayingHeaderView:forSection:)`/
        /// `tableView(_:didEndDisplayingFooterView:forSection:)`
        /// to the binder using the stored row.
        @MainActor
        public func didEndDisplaying(to binder: Any) { _didEndDisplayingBlock(binder) }
    }
}
