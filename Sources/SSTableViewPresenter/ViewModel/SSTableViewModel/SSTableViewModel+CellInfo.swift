//
//  SSTableViewModel+CellInfo.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 28.07.2021.
//

import UIKit

extension SSTableViewModel {
    // MARK: - SSTableViewModel.CellInfo
    /// A type-erased container that holds information for a single cell,
    /// used by `SSTableViewPresenter` to configure and render cells
    /// in the table view.
    public final class CellInfo: AnyBindingStore {
        /// Swipe action shown on leading/trailing side of a row.
        public struct SwipeAction {
            /// Visual style (.normal / .destructive).
            let style: UIContextualAction.Style
            /// Button title (nil = icon-only if you set an image elsewhere).
            let title: String?
            /// Optional background color override.
            let backgroundColor: UIColor?
            /// Optional image override.
            let image: UIImage?
            /// Called when the action is triggered; return how the row should update.
            let handler: (CellInfo) -> SwipeActionResult

            public init(style: UIContextualAction.Style,
                        title: String? = nil,
                        backgroundColor: UIColor? = nil,
                        image: UIImage? = nil,
                        handler: @escaping (CellInfo) -> SwipeActionResult) {
                self.style = style
                self.title = title
                self.backgroundColor = backgroundColor
                self.image = image
                self.handler = handler
            }
        }

        /// Configuration for swipe actions in table view cells
        public struct SwipeConfiguration {
            /// Array of swipe actions to display
            let actions: [SwipeAction]
            /// Whether a full swipe performs the first action automatically
            let performsFirstActionWithFullSwipe: Bool

            public init(actions: [SwipeAction], performsFirstActionWithFullSwipe: Bool = true) {
                self.actions = actions
                self.performsFirstActionWithFullSwipe = performsFirstActionWithFullSwipe
            }
        }

        /// Outcome of a swipe action.
        public enum SwipeActionResult {
            /// Remove the row from the data source.
            case delete
            /// Replace the row with an updated `CellInfo`.
            case update(CellInfo)
            /// Reload the row in place (no identity change).
            case reload
            /// No UI/model change.
            case none
        }

        /// Whether the cell is currently highlighted (touch-down state)
        public var isHighlighted: Bool = false

        /// Whether the cell is currently selected
        public var isSelected: Bool = false

        /// A closure invoked when the bound cell sends an action.
        ///
        /// - Parameters:
        ///   - indexPath: The index path where the cell is located.
        ///   - cell: The table view cell that triggered the action.
        ///   - actionName: A string identifying the type of action.
        ///   - input: An optional value passed by the caller for the action.
        public var actionClosure: ((IndexPath, UITableViewCell, String, Any?) -> Void)?

        /// Closure that returns leading swipe configuration for a cell
        public var leadingSwipeActions: ((CellInfo) -> SwipeConfiguration)?

        /// Closure that returns trailing swipe configuration for a cell
        public var trailingSwipeActions: ((CellInfo) -> SwipeConfiguration)?

        private let _didHighlightBlock: (Any) -> Void
        private let _didUnhighlightBlock: (Any) -> Void
        private let _didSelectBlock: (Any) -> Void
        private let _didDeselectBlock: (Any) -> Void
        private let _willDisplayBlock: (Any) -> Void
        private let _didEndDisplayingBlock: (Any) -> Void

        /// Creates a type-erased wrapper for a cell binding store.
        ///
        /// - Parameter store: The binding store that provides
        ///                    the cell's input state and binder type
        ///                    conforming to `SSTableViewCellProtocol`.
        public init<State, Binder>(_ store: BindingStore<State, Binder>)
        where Binder: SSTableViewCellProtocol
        {
            _didHighlightBlock = { binder in
                guard let cell = binder as? Binder else { return }
                cell.didHighlight(with: store.state)
            }
            _didUnhighlightBlock = { binder in
                guard let cell = binder as? Binder else { return }
                cell.didUnhighlight(with: store.state)
            }
            _didSelectBlock = { binder in
                guard let cell = binder as? Binder else { return }
                cell.didSelect(with: store.state)
            }
            _didDeselectBlock = { binder in
                guard let cell = binder as? Binder else { return }
                cell.didDeselect(with: store.state)
            }
            _willDisplayBlock = { binder in
                guard let cell = binder as? Binder else { return }
                cell.willDisplay(with: store.state)
            }
            _didEndDisplayingBlock = { binder in
                guard let cell = binder as? Binder else { return }
                cell.didEndDisplaying(with: store.state)
            }
            super.init(store)
        }

        /// Forwards `tableView(_:didHighlightRowAt:)`
        /// to the binder using the stored row.
        public func didHighlight(to binder: Any) {
            _didHighlightBlock(binder)
            isHighlighted = true
        }

        /// Forwards `tableView(_:didUnhighlightRowAt:)`
        /// to the binder using the stored row.
        public func didUnhighlight(to binder: Any) {
            _didUnhighlightBlock(binder)
            isHighlighted = false
        }

        /// Forwards `tableView(_:didSelectRowAt:)`
        /// to the binder using the stored row.
        public func didSelect(to binder: Any) {
            isSelected = true
            _didSelectBlock(binder)
        }

        /// Forwards `tableView(_:didDeselectRowAt:)`
        /// to the binder using the stored row.
        public func didDeselect(to binder: Any) {
            isSelected = false
            _didDeselectBlock(binder)
        }

        /// Forwards `tableView(_:willDisplay:forRowAt:)`
        /// to the binder using the stored row.
        public func willDisplay(to binder: Any) {
            _willDisplayBlock(binder)
        }

        /// Forwards `tableView(_:didEndDisplaying:forRowAt:)`
        /// to the binder using the stored row.
        public func didEndDisplaying(to binder: Any) {
            _didEndDisplayingBlock(binder)
        }
    }
}
