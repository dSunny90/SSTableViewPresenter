//
//  SSTableViewPresenter+Prefetching.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 29.07.2021.
//

import UIKit

// MARK: - UITableViewDataSourcePrefetching

extension SSTableViewPresenter: UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        guard let viewModel = viewModel else { return }

        let rows: [CellInfo] = indexPaths.compactMap {
            guard $0.section < viewModel.count,
                  $0.row < viewModel[$0.section].count else { return nil }
            return viewModel[$0.section][$0.row]
        }
        prefetchBlock?(rows)
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        guard let viewModel = viewModel else { return }

        let rows: [CellInfo] = indexPaths.compactMap {
            guard $0.section < viewModel.count,
                  $0.row < viewModel[$0.section].count else { return nil }
            return viewModel[$0.section][$0.row]
        }

        cancelPrefetchBlock?(rows)
    }
}
