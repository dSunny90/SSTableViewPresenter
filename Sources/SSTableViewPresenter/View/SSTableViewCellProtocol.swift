//
//  SSTableViewCellProtocol.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 28.07.2021.
//

import UIKit

/// A protocol for configurable UI units to respond to interaction events.
///
/// Enables handling of selection, highlighting, and display lifecycle events.
/// All methods are guaranteed to be called on the main thread.
public protocol InteractiveTableViewCell: InteractiveHeaderFooterView {
    /// Returns whether the view should be highlighted.
    func shouldHighlight(with input: Input?) -> Bool

    /// Called when the view is highlighted (e.g., during touch-down).
    func didHighlight(with input: Input?)

    /// Called when the view is no longer highlighted (e.g., touch-up).
    func didUnhighlight(with input: Input?)

    /// Returns whether the view should allow selection.
    ///
    /// Return `false` to prevent the selection from being applied.
    func willSelect(with input: Input?) -> Bool

    /// Called when the view is selected.
    func didSelect(with input: Input?)

    /// Returns whether the view should allow deselection.
    ///
    /// Return `false` to prevent the deselection from being applied.
    func willDeselect(with input: Input?) -> Bool

    /// Called when the view is deselected.
    func didDeselect(with input: Input?)
}

extension InteractiveTableViewCell {
    public func shouldHighlight(with input: Input?) -> Bool { return true }
    public func didHighlight(with input: Input?) {}
    public func didUnhighlight(with input: Input?) {}
    public func willSelect(with input: Input?) -> Bool { return true }
    public func didSelect(with input: Input?) {}
    public func willDeselect(with input: Input?) -> Bool { return true }
    public func didDeselect(with input: Input?) {}
}

/// A convenience protocol that combines `UITableViewCell` with
/// `InteractiveTableViewCell`.
///
/// Adopt this protocol for table view cells that are configured using
/// `Configurable` and respond to interaction and display lifecycle events
/// (e.g. selection, highlight, willDisplay).
public protocol SSTableViewCellProtocol: UITableViewCell, InteractiveTableViewCell {}
