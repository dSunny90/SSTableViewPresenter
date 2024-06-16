//
//  SSTableViewPresenter+DragDrop.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 16.06.2024.
//

import UIKit

extension SSTableViewPresenter: UITableViewDragDelegate {
    public func tableView(_ tableView: UITableView,
                          itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let cellInfo = viewModel?[safe: indexPath.section]?[indexPath.row] else { return [] }

        if let canDrag = canDragRowBlock, !canDrag(cellInfo) {
            return []
        }

        let itemProvider: NSItemProvider = {
            if let cell = tableView.cellForRow(at: indexPath),
               let customItemProvider = dragItemProviderBlock?(cell, cellInfo) {
                customItemProvider
            } else if let json = try? cellInfo.toJSONString() {
                NSItemProvider(object: "\(json)" as NSString)
            } else {
                NSItemProvider(object: "\(indexPath)" as NSString)
            }
        }()
        let dragItem = UIDragItem(itemProvider: itemProvider)

        if let view = dragPreviewProviderBlock?(cellInfo) {
            dragItem.previewProvider = { UIDragPreview(view: view) }
        }
        dragItem.localObject = cellInfo

        return [dragItem]
    }

    public func tableView(_ tableView: UITableView,
                          dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        return dragPreviewParametersBlock?(indexPath)
    }
}

extension SSTableViewPresenter: UITableViewDropDelegate {
    private typealias ReorderSourceContext = (
        indexPath: IndexPath,
        cellInfo: CellInfo,
        dragItem: UIDragItem
    )

    public func tableView(_ tableView: UITableView,
                          dropSessionDidUpdate session: any UIDropSession,
                          withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if session.localDragSession == nil {
            return UITableViewDropProposal(
                operation: .copy,
                intent: .insertAtDestinationIndexPath
            )
        } else {
            return UITableViewDropProposal(
                operation: .move,
                intent: .insertAtDestinationIndexPath
            )
        }
    }

    public func tableView(_ tableView: UITableView,
                          performDropWith coordinator: any UITableViewDropCoordinator) {
        let isLocalReorder =
                coordinator.proposal.operation == .move &&
                coordinator.items.allSatisfy { $0.sourceIndexPath != nil }

        let destination: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destination = indexPath
        } else {
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            destination = IndexPath(row: row, section: section)
        }

        // External copy: load payload and insert new item via handlers
        guard isLocalReorder else {
            handleExternalDrop(coordinator, to: destination, in: tableView)
            return
        }

        let sourceItems: [ReorderSourceContext] = coordinator.items.compactMap {
            guard let source = $0.sourceIndexPath,
                  let item = $0.dragItem.localObject as? CellInfo
            else { return nil }
            return (
                indexPath: source,
                cellInfo: item,
                dragItem: $0.dragItem
            )
        }
        let rows = sourceItems.map {
            (indexPath: $0.indexPath, cellInfo: $0.cellInfo)
        }

        self.willReorderBlock?(rows)

        let insertedIndexPaths = moveCellInfos(rows, to: destination)
        if dataSourceMode == .traditional {
            tableView.performBatchUpdates {
                tableView.deleteRows(at: sourceItems.map(\.indexPath), with: .automatic)
                tableView.insertRows(at: insertedIndexPaths, with: .automatic)
            }
        } else if #available(iOS 13.0, *) {
            applySnapshot(animated: true)
        }

        for (row, indexPath) in zip(sourceItems, insertedIndexPaths) {
            coordinator.drop(row.dragItem, toRowAt: indexPath)
        }

        self.didReorderBlock?(rows, destination)
    }

    private func handleExternalDrop(
        _ coordinator: UITableViewDropCoordinator,
        to destination: IndexPath,
        in tableView: UITableView
    ) {
        guard let externalDropHandler = self.externalDropHandler else { return }

        let ids = acceptedExternalDropTypeIdentifiers
        let dropItems = coordinator.items
        let group = DispatchGroup()

        struct LoadedResult {
            let dragItem: UIDragItem
            let payload: Any
            let typeIdentifier: String?
        }

        var loaded: [LoadedResult] = []
        var errors: [(Error, String?)] = []

        for dropItem in dropItems {
            let provider = dropItem.dragItem.itemProvider
            let typeId = ids.first {
                provider.hasItemConformingToTypeIdentifier($0)
            }

            if !ids.isEmpty, let typeId {
                group.enter()
                provider.loadItem(forTypeIdentifier: typeId) { item, error in
                    defer { group.leave() }
                    if let error {
                        errors.append((error, typeId))
                        return
                    }
                    guard let item else { return }
                    loaded.append(
                        .init(dragItem: dropItem.dragItem,
                              payload: item,
                              typeIdentifier: typeId)
                    )
                }
            } else if provider.canLoadObject(ofClass: NSString.self) {
                group.enter()
                provider.loadObject(ofClass: NSString.self) { object, error in
                    defer { group.leave() }
                    if let error {
                        errors.append((error, "public.utf8-plain-text"))
                        return
                    }
                    guard let str = object as? String else { return }
                    loaded.append(
                        .init(dragItem: dropItem.dragItem,
                              payload: str,
                              typeIdentifier: "public.utf8-plain-text")
                    )
                }
            } else {
                continue
            }
        }

        group.notify(queue: .main) {
            for (error, typeId) in errors {
                if let typeId {
                    print("⚠️ [SSCollectionViewPresenter] External drop load failed for type \(typeId): \(error.localizedDescription).")
                } else {
                    print("⚠️ [SSCollectionViewPresenter] External drop load failed: \(error.localizedDescription).")
                }
            }

            guard !loaded.isEmpty,
                  let count = self.viewModel?[safe: destination.section]?.count else { return }

            let startRow = min(max(0, destination.row), count)

            var cellInfos: [CellInfo] = []
            var finalIndexPaths: [IndexPath] = []

            for (offset, result) in loaded.enumerated() {
                let indexPath = IndexPath(row: startRow + offset,
                                          section: destination.section)
                if let item = externalDropHandler(result.payload, indexPath) {
                    cellInfos.append(item)
                    finalIndexPaths.append(indexPath)
                }
            }

            guard !cellInfos.isEmpty else { return }

            self.insertExternalCells(
                cellInfos,
                startingAt: IndexPath(row: startRow,
                                      section: destination.section),
                in: tableView
            )

            for (i, result) in loaded.enumerated() where i < finalIndexPaths.count {
                coordinator.drop(result.dragItem, toRowAt: finalIndexPaths[i])
            }
        }
    }

    private func moveCellInfos(
        _ pairs: [(indexPath: IndexPath, cellInfo: CellInfo)],
        to destination: IndexPath
    ) -> [IndexPath] {
        guard var newViewModel = self.viewModel, !pairs.isEmpty else { return [] }

        let sortedSourcesDescending = pairs
            .map(\.indexPath)
            .sorted {
                if $0.section != $1.section {
                    return $0.section > $1.section
                }
                return $0.row > $1.row
            }

        let movedItems = pairs
            .sorted {
                if $0.indexPath.section != $1.indexPath.section {
                    return $0.indexPath.section < $1.indexPath.section
                }
                return $0.indexPath.row < $1.indexPath.row
            }
            .map(\.cellInfo)

        for source in sortedSourcesDescending {
            newViewModel[source.section].remove(at: source.row)
        }

        let adjustedDestinationRow: Int
        if destination.section < newViewModel.count {
            adjustedDestinationRow = max(
                0,
                min(destination.row, newViewModel[destination.section].count)
            )
        } else {
            adjustedDestinationRow = 0
        }

        for (offset, item) in movedItems.enumerated() {
            newViewModel[destination.section].insert(
                item,
                at: adjustedDestinationRow + offset
            )
        }

        self.viewModel = newViewModel

        return movedItems.indices.map {
            IndexPath(row: adjustedDestinationRow + $0,
                      section: destination.section)
        }
    }

    private func insertExternalCells(_ cellInfos: [CellInfo],
                                     startingAt indexPath: IndexPath,
                                     in tableView: UITableView) {
        guard !cellInfos.isEmpty,
              var newViewModel = self.viewModel,
              indexPath.section < newViewModel.count else { return }

        let clampedStart = min(
            max(0, indexPath.row), newViewModel[indexPath.section].count
        )

        for (offset, cell) in cellInfos.enumerated() {
            newViewModel[indexPath.section].insert(cell, at: clampedStart + offset)
        }
        self.viewModel = newViewModel

        let indexPaths = cellInfos.indices.map {
            IndexPath(row: clampedStart + $0, section: indexPath.section)
        }

        if self.dataSourceMode == .traditional {
            tableView.performBatchUpdates {
                tableView.insertRows(at: indexPaths, with: .automatic)
            }
        } else if #available(iOS 13.0, *) {
            self.applySnapshot(animated: true)
        }
    }
}
