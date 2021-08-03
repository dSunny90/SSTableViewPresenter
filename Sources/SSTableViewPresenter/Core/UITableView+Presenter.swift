//
//  UITableView+Presenter.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 28.07.2021.
//

import UIKit

extension UITableView {
    private struct AssociatedKeys {
        static var registeredCellIdentifiers: UInt8 = 0
        static var registeredHeaderFooterIdentifiers: UInt8 = 0
        static var presenter: UInt8 = 0
    }

    public var registeredCellIdentifiers: Set<String> {
        get {
            if let obj = objc_getAssociatedObject(self, &AssociatedKeys.registeredCellIdentifiers) as? Set<String> {
                return obj
            }
            let obj = Set<String>(minimumCapacity: 200)
            objc_setAssociatedObject(self, &AssociatedKeys.registeredCellIdentifiers, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return obj
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.registeredCellIdentifiers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public var registeredHeaderFooterIdentifiers: Set<String> {
        get {
            if let obj = objc_getAssociatedObject(self, &AssociatedKeys.registeredHeaderFooterIdentifiers) as? Set<String> {
                return obj
            }
            let obj = Set<String>(minimumCapacity: 200)
            objc_setAssociatedObject(self, &AssociatedKeys.registeredHeaderFooterIdentifiers, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return obj
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.registeredHeaderFooterIdentifiers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    internal var presenter: SSTableViewPresenter? {
        get {
            if let obj = objc_getAssociatedObject(self, &AssociatedKeys.presenter) as? SSTableViewPresenter {
                return obj
            } else {
                return nil
            }
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.presenter, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public func registerDefaultCell() {
        register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
    }

    public func registerDefaultHeaderFooterView() {
        register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: String(describing: UITableViewHeaderFooterView.self))
    }

    public func registerHeaderFooter(_ classType: Any.Type, reuseIdentifier: String? = nil, bundle: Bundle? = nil) {
        guard let headerFooterType = classType as? UITableViewHeaderFooterView.Type else { return }

        let identifier: String
        if let reuseIdentifier = reuseIdentifier {
            identifier = reuseIdentifier
        } else {
            identifier = String(describing: headerFooterType)
        }

        guard registeredHeaderFooterIdentifiers.contains(identifier) == false else { return }

        registeredHeaderFooterIdentifiers.insert(identifier)
        if isNibFileExists(identifier, bundle: bundle) {
            let nib = UINib(nibName: identifier, bundle: bundle)
            register(nib, forHeaderFooterViewReuseIdentifier: identifier)
        } else {
            register(headerFooterType, forHeaderFooterViewReuseIdentifier: identifier)
        }
    }

    public func registerCell(_ classType: Any.Type, reusableIdentifier: String? = nil, for bundle: Bundle? = nil) {
        guard let cellType = classType as? UITableViewCell.Type else { return }

        let identifier: String
        if let reusableIdentifier = reusableIdentifier {
            identifier = reusableIdentifier
        } else {
            identifier = String(describing: cellType)
        }

        guard registeredCellIdentifiers.contains(identifier) == false else { return }

        registeredCellIdentifiers.insert(identifier)
        if isNibFileExists(identifier, bundle: bundle) {
            let nib = UINib(nibName: identifier, bundle: bundle)
            register(nib, forCellReuseIdentifier: identifier)
        } else {
            register(cellType, forCellReuseIdentifier: identifier)
        }
    }

    public func dequeueDefaultCell(for indexPath: IndexPath) -> UITableViewCell {
        return dequeueReusableCell(
            withIdentifier: String(describing: UITableViewCell.self),
            for: indexPath
        )
    }

    /// Checks whether a `.nib` file with the given name exists in the specified bundle.
    /// Falls back to `Bundle.main` when `bundle` is `nil`.
    ///
    /// - Parameters:
    ///   - nibName: The nib file name without extension.
    ///   - bundle:  The bundle to search in (defaults to main bundle).
    /// - Returns: `true` if the nib file exists on disk; otherwise `false`.
    /// - Note: This only checks for presence; it does not load the nib.
    ///         If you’re using Swift Package resources, consider `Bundle.module`.
    private func isNibFileExists(_ nibName: String, bundle: Bundle? = nil) -> Bool {
        // Resolve bundle (explicit or main)
        let aBundle = bundle ?? .main

        // Lookup the path for "<nibName>.nib" and verify it exists
        if let path = aBundle.path(forResource: nibName, ofType: "nib") {
            return FileManager.default.fileExists(atPath: path)
        }
        return false
     }
}
