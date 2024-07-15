//
//  UITableViewHeaderFooterView+Presenter.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 28.07.2021.
//

import UIKit

extension UITableViewHeaderFooterView {
    /// A closure invoked when the view sends an action.
    ///
    /// - Parameters:
    ///   - actionName: A string identifying the type of action.
    ///   - input: An optional value passed by the caller for the action.
    public typealias ActionClosure = (String, Any?) -> Void

    private struct AssociatedKeys {
        nonisolated(unsafe) static var actionClosure: UInt8 = 0
    }

    /// The closure to handle actions sent from this view.
    ///
    /// Assign this closure to respond to actions triggered within the view
    /// without subclassing or adding a delegate.
    public var actionClosure: ActionClosure? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.actionClosure) as? ActionClosure
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.actionClosure, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    /// The section index of this view within its table view.
    ///
    /// Traverses the responder chain to locate the parent `UITableView`,
    /// then matches this view against visible header and footer views.
    /// Returns `nil` if the view is not currently visible or has no parent
    /// table view.
    public var sectionIndex: Int? {
        var responder: UIResponder? = self
        while let r = responder {
            guard let tableView = r as? UITableView else {
                responder = r.next
                continue
            }
            for section in 0..<tableView.numberOfSections {
                if tableView.headerView(forSection: section) === self {
                    return section
                }
                if tableView.footerView(forSection: section) === self {
                    return section
                }
            }
            return nil
        }
        return nil
    }
}
