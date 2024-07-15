//
//  PrefetchTests.swift
//  SSTableViewPresenter
//
//  Created by SunSoo Jeon on 18.06.2024.
//

import XCTest
@testable import SSTableViewPresenter
import UIKit

@MainActor
final class PrefetchTests: XCTestCase {
    // MARK: - Prefetch / Cancel Prefetch

    func test_prefetch_and_cancel_prefetch_callbacks_receive_expected_rows() {
        // Given
        let tv = makeTableView()
        tv.ss.setupPresenter()

        let configs = makeSampleConfigs(5)
        _ = tv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(configs, cellType: TestConfigCell.self)
            }
        }

        var prefetchedIds: [String] = []
        var cancelledIds: [String] = []

        tv.ss.onPrefetch { rows in
            prefetchedIds.append(contentsOf: rows.compactMap { ($0.state as? TestConfig)?.id })
        }
        tv.ss.onCancelPrefetch { rows in
            cancelledIds.append(contentsOf: rows.compactMap { ($0.state as? TestConfig)?.id })
        }

        // When — trigger prefetch for first 3 rows
        let prefetcher = tv.prefetchDataSource
        prefetcher?.tableView(tv, prefetchRowsAt: [
            IndexPath(row: 0, section: 0),
            IndexPath(row: 1, section: 0),
            IndexPath(row: 2, section: 0)
        ])
        // And then cancel two of them
        prefetcher?.tableView?(tv, cancelPrefetchingForRowsAt: [
            IndexPath(row: 1, section: 0),
            IndexPath(row: 2, section: 0)
        ])

        // Then
        XCTAssertEqual(prefetchedIds.count, 3)
        XCTAssertEqual(cancelledIds.count, 2)
    }
}
