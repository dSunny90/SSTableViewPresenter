# SSTableViewPresenter

🎞️ Super Simple abstraction layer for building `UITableView`-based UIs with minimal boilerplate.

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/) ![Swift](https://img.shields.io/badge/Swift-5.7-orange.svg) ![Platform](https://img.shields.io/badge/platform-iOS%2012-brightgreen) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Motivation

Implementing `UITableView` across various screens often involves repetitive, error-prone tasks — registering cells, configuring data sources and delegates, or adapting raw server responses to data models. As these tasks pile up screen after screen, the codebase becomes tedious to maintain, especially when each screen handles things a little differently.

The core issue is a lack of separation between rendering logic and interaction logic. Each screen ends up owning too much — it knows how to display data, how to respond to events, and how to talk to the rest of the app. To address this, SSTableViewPresenter introduces a presenter layer that takes full ownership of the data source and delegate responsibilities. The screen simply binds to a ViewModel and reacts to it, with no knowledge of how that state was produced.

To enable clean ViewModel binding, I integrated my earlier [`SendingState`](https://github.com/dSunny90/SendingState) into `SSTableViewPresenter`. `SendingState` is the backbone of this approach: the presenter drives the UI entirely through type-safe ViewModel binding, while events emitted by lower-level components (cells) flow upward in a single, unidirectional stream. This keeps UI code focused on rendering and makes interaction logic predictable and easy to test.

## Philosophy

Built with a pragmatic take on Apple's MVC architecture:
- Lightweight business logic can remain in the `UIViewController`.
- For more complex interactions, an `Interactor` can be introduced to separate concerns.
- UI components like `UITableViewCell` can forward user interactions (buttons, gestures, toggles) to an `Interactor` or `UIViewController`.

---

## Key Features

- **Boilerplate-free UITableView setup** — No need to write custom data sources and delegates repeatedly.
- **Diffable & traditional data source support** — Switch modes based on your needs.
- **Automatic cell/header/footer registration** — Uses type-safe identifiers; NIB files are detected automatically.
- **Built-in RESTful API pagination** — Tracks `page` and `hasNext`, with seamless next-page requests.
- **Re-exported dependency** — `SendingState` is re-exported, so you can use `Configurable`, `EventForwardingProvider`, and other types without an extra import.

## How It Works

You provide a `ViewModel` containing:
- A list of `SectionInfo`
- Each section has a list of `CellInfo` (and optional header/footer via `HeaderFooterViewInfo`)

Then, simply bind the ViewModel to the presenter. The presenter handles:
- Drawing the correct section/cell
- Registering cells and header/footer views
- Managing display logic

You **don't** need to manually implement `UITableViewDataSource` anymore.

---

## Usage

### 1. Define Your Model

```swift
struct ListItemData: Decodable {
    let id: String
    let title: String
    let imgUrl: String
}
```

### 2. Create a Custom Cell

Conform to `SSTableViewCellProtocol`, which inherits from `Configurable` (provided by `SendingState`).

```swift
final class ListCell: UITableViewCell, SSTableViewCellProtocol {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imgView: UIImageView!

    static func size(with input: BannerData?, constrainedTo parentSize: CGSize?) -> CGSize? {
        CGSize(width: parentSize?.width ?? 375, height: 40)
    }

    var configurer: (ListCell, ListItemData) -> Void {
        { view, model in
            view.titleLabel.text = model.title
            view.imgView.loadWebImage(model.imgUrl)
        }
    }
}
```

### 3. Set Up in Your ViewController

```swift
final class HomeViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.ss.setupPresenter()

        let items = [
            ListItemData(id: "1", title: "Spring Sale", imgUrl: "https://your.image.url"),
            ListItemData(id: "2", title: "Fall Deals", imgUrl: "https://your.image.url")
        ]

        // Option A: Manual construction
        let sectionInfo = SSTableViewModel.SectionInfo()
        for item in items {
            sectionInfo.appendCellInfo(item, cellType: ListCell.self)
        }
        let viewModel = SSTableViewModel(sections: [sectionInfo])
        tableView.ss.setViewModel(with: viewModel)

        // Option B: Builder pattern
        tableView.ss.buildViewModel { builder in
            builder.section {
                builder.cells(items, cellType: ListCell.self)
            }
        }

        tableView.reloadData()
    }
}
```

---

### Cell Interaction & Event Handling

#### Simple actions with `actionClosure`

For straightforward interactions — a tap, a toggle — attach an `actionClosure` directly in the builder. The closure receives an `action` name and an optional `input` payload.

```swift
// Cell
builder.cells(products, cellType: ProductListCell.self) { indexPath, cell, action, input in
    switch action {
    case "addToCart":
        addToCart(at: indexPath)
    default:
        break
    }
}

// Header / Footer
builder.header(headerData, viewType: SectionHeaderView.self) { section, view, action, input in
    switch action {
    case "more":
        showMore(for: section)
    default:
        break
    }
}
```

#### Complex actions with `EventForwarder` (SendingState)

When a cell or view emits multiple event types, carries typed payloads, or needs to share a single event channel across sections, conform to `EventForwardingProvider` from `SendingState` instead. Observe events at the view-controller level through the presenter's shared event channel.

> For full `EventForwardingProvider` usage, refer to the [`SendingState`](https://github.com/dSunny90/SendingState) documentation.

---

#### Handling delegate events inside cells

Cells can respond to delegate-level events by implementing optional methods from `SSTableViewCellProtocol`:

```swift
final class MyCell: UITableViewCell, SSTableViewCellProtocol {
    // ...

    func didSelect(with input: MyModel?) {
        // Handle selection
    }

    func willDisplay(with input: MyModel?) {
        // Called just before the cell appears
    }

    func didEndDisplaying(with input: MyModel?) {
        // Called after the cell disappears
    }
}
```

Available lifecycle methods:

| Method | Description |
|---|---|
| `willDisplay(with:)` | Called before the view appears |
| `didEndDisplaying(with:)` | Called after the view disappears |
| `didHighlight(with:)` | Called on touch-down |
| `didUnhighlight(with:)` | Called on touch-up |
| `didSelect(with:)` | Called on selection |
| `didDeselect(with:)` | Called on deselection |

> `willDisplay` and `didEndDisplaying` are available on both cells and header/footer views.

---

### Reconfiguring Rows, Headers, and Footers

`reconfigureRow(_:at:)`, `reconfigureHeader(_:at:)`, and `reconfigureFooter(_:at:)` replace the underlying state (model) of a visible view and re-invoke its `configurer` in place — no full reload needed. Use this whenever only the data of an existing view has changed.

```swift
// Update a cell's state
let updated = ProductModel(id: "00000011", title: "Test Product", price: 30)
tableView.ss.reconfigureRow(updated, at: indexPath)

// Update a header / footer
tableView.ss.reconfigureHeader(SectionHeaderData(title: "New Event"), at: 0)
tableView.ss.reconfigureFooter(FooterData(text: "More Events"), at: 0)
```

---

### Collapse & Expand Sections

`toggleSection(_:completion:)` flips the `isCollapsed` flag of the given section and triggers a data source update. The `completion` closure delivers the new collapsed state — use it to push updated state into any header or footer whose appearance depends on it (a chevron, a label, etc.).

```swift
tableView.ss.toggleSection(sectionIndex) { [weak self] collapsed in
    guard let self = self else { return }
    let updated = SectionHeaderData(title: "Products", isExpanded: !collapsed)
    self.tableView.ss.reconfigureHeader(updated, at: sectionIndex)
}
```

#### Triggering from an `actionClosure`

The `section` parameter passed into a header or footer `actionClosure` is the section index itself, so it can be forwarded directly to `toggleSection`:

```swift
builder.header(headerData, viewType: SectionHeaderView.self) { [weak self] section, view, action, input in
    guard let self = self else { return }
    switch action {
    case "toggle":
        guard let state = input as? SectionHeaderData else { return }
        self.tableView.ss.toggleSection(section) { collapsed in            
            let updated = SectionHeaderData(title: state.title, isExpanded: !collapsed)
            self.tableView.ss.reconfigureHeader(updated, at: section)
        }
    default:
        break
    }
}
```

#### Triggering from an `EventForwarder`

When using `EventForwardingProvider`, the handler receives no index by default. The view must embed its own position in the forwarded payload so the handler can pass it to `toggleSection`.

- **Headers / footers** — include `sectionIndex`
- **Cells** — include `indexPath`

```swift
// Action handler (view controller or interactor)
final class TestStoreViewController: UIViewController, ActionHandlingProvider {
    @IBOutlet weak var tableView: UITableView!

    // ...

    func handle(action: TestAction) {
        switch action {
        case .toggle(let sectionIndex):
            tableView.ss.toggleSection(sectionIndex, state) { [weak self] collapsed in
                guard let self = self else { return }
                let newState = SectionHeaderModel(title: state.title, isExpanded: !collapsed)
                self.tableView.ss.reconfigureHeader(newState, at: sectionIndex)
            }
        default:
            break
        }
    }
}
```
---

### Loading Next Page (Pagination)

If your table view should load more data when the user scrolls near the end, use `onNextRequest`:

```swift
tableView.ss.onNextRequest { [weak self] viewModel in
    guard let self = self else { return }
    NetworkingManager.fetchNextPage(current: viewModel.page) { result in
        guard case .success(let response) = result else { return }
        self.tableView.ss.extendViewModel(
            page: response.page,
            hasNext: response.hasNext
        ) { builder in
            builder.section("productList") {
                builder.cells(response.products, cellType: ProductListCell.self)
            }
        }
        self.tableView.reloadData()
    }
}
```

`extendViewModel` merges by section identifier — if a section with the same ID exists, new rows are appended to it. Otherwise, a new section is added.

#### Page-Based Data Management with `loadPage`

For typical RESTful APIs that return paginated responses, `loadPage` lets you store each page's sections independently. The presenter merges all stored pages into a single flat list internally — sections with the same identifier across pages are concatenated, while unnamed sections are simply appended.

`loadPage` accepts either an array of `SectionInfo` or a builder closure:

```swift
// Initial load
tableView.ss.loadPage(0, hasNext: true) { builder in
    builder.section("listItems") {
        builder.cells(banners, cellType: ListCell.self)
    }
    builder.section("productList") {
        builder.cells(products, cellType: ProductListCell.self)
    }
}
tableView.reloadData()
```

Combine it with `onNextRequest` to handle pagination seamlessly:

```swift
tableView.ss.onNextRequest { [weak self] viewModel in
    guard let self = self else { return }
    NetworkingManager.fetchNextPage(current: viewModel.page + 1) { result in
        guard case .success(let response) = result else { return }
        self.tableView.ss.loadPage(response.page, hasNext: response.hasNext) { builder in
            builder.section("productList") {
                builder.cells(response.productList, cellType: ProductListCell.self)
            }
        }
        self.tableView.reloadData()
    }
}
```

Because each page is stored separately, you can replace or remove any individual page without affecting the rest:

```swift
// Replace page 2 with fresh data (e.g. after a row edit)
tableView.ss.loadPage(2, hasNext: true) { builder in
    builder.section("productList") {
        builder.cells(updatedProducts, cellType: ProductListCell.self)
    }
}

// Remove a specific page
tableView.ss.removePage(2)

// Pull-to-refresh: clear everything and start over
var viewModel = tableView.ss.getViewModel()
viewModel?.removeAllPages()
tableView.ss.setViewModel(with: viewModel ?? SSTableViewModel())
```

You can also query page state directly on the view model:

| Property / Method | Description |
|---|---|
| `page` | The most recently loaded page number |
| `hasNext` | Whether more pages are available |
| `pageCount` | Number of stored pages |
| `hasPageData` | `true` if at least one page is stored |
| `sections(forPage:)` | Returns the sections for a specific page |
| `findPage(forSectionIdentifier:)` | Finds the latest page containing a given section ID |

> **Merge rules:** When multiple pages contain sections with the same `identifier`, their rows are merged into one section in page order. Headers and footers from later pages take precedence. Sections without an identifier are never merged — they're always appended as separate sections.

---

### Diffable Data Source

To use the modern diffable data source (iOS 13+), pass `.diffable` when setting up:

```swift
tableView.ss.setupPresenter(dataSourceMode: .diffable)

tableView.ss.buildViewModel { builder in
    builder.section("main") {
        builder.cells(items, cellType: ListCell.self)
    }
}

// Use applySnapshot instead of reloadData
tableView.ss.applySnapshot(animated: true)
```

> When using diffable mode, call `applySnapshot(animated:)` instead of `reloadData()` to apply changes with optional animations.

---

## Installation

SSTableViewPresenter is available via Swift Package Manager.

### Using Xcode:

1. Open your project in Xcode
2. Go to **File > Add Packages...**
3. Enter the URL:
```
https://github.com/dSunny90/SSTableViewPresenter
```
4. Select the version and finish

### Using Package.swift:
```swift
dependencies: [
    .package(url: "https://github.com/dSunny90/SSTableViewPresenter", from: "0.2.2")
]
```
