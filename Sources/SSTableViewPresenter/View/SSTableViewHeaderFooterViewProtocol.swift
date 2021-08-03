//
//  SSTableViewHeaderFooterViewProtocol.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 28.07.2021.
//

import UIKit

/// A protocol for configurable UI units to respond to interaction events.
///
/// Enables handling of selection, highlighting, and display lifecycle events.
/// All methods are guaranteed to be called on the main thread.
public protocol InteractiveHeaderFooterView: Configurable {
    /// Called when the view is about to appear.
    func willDisplay(with input: Input?)

    /// Called when the view is no longer visible.
    func didEndDisplaying(with input: Input?)
}

extension InteractiveHeaderFooterView {
    public func willDisplay(with input: Input?) {}
    public func didEndDisplaying(with input: Input?) {}
}

/// A convenience protocol that combines `UITableViewHeaderFooterView` with
/// `InteractiveHeaderFooterView`.
///
/// Adopt this protocol for header/footer views that are configured using
/// `Configurable` and respond to display lifecycle events such as
/// `willDisplay` and `didEndDisplaying`.
public protocol SSTableViewHeaderFooterViewProtocol: UITableViewHeaderFooterView, InteractiveHeaderFooterView {}
