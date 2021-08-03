//
//  UITableViewCell+Presenter.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 28.07.2021.
//

import UIKit

extension UITableViewCell {
    /// A closure invoked when the view sends an action.
    ///
    /// - Parameters:
    ///   - actionName: A string identifying the type of action.
    ///   - input: An optional value passed by the caller for the action.
    public typealias ActionClosure = (String, Any?) -> Void

    private struct AssociatedKeys {
        static var actionClosure: UInt8 = 0
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

    /// The index path of this cell within its table view.
    ///
    /// Traverses the responder chain to locate the parent `UITableView`,
    /// then returns the index path for this cell.
    /// Returns `nil` if the cell is not currently visible or has no parent
    /// table view.
    public var indexPath: IndexPath? {
        var responder: UIResponder? = self
        while let r = responder {
            if let tableView = r as? UITableView {
                return tableView.indexPath(for: self)
            }
            responder = r.next
        }
        return nil
    }
}
