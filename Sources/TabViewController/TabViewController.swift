//
//  TabViewController.swift
//  TabmanNavigationView
//
//  Created by Merrick Sapsford on 19/09/2020.
//

import UIKit
import SwiftUI
import Tabman
import Pageboy

extension Notification.Name {
    public static let FORCE_REFRESH_TAB = Notification.Name("FORCE_REFRESH_TAB")
}

extension Array where Element: Hashable {
    func same(as other: [Element]) -> Bool {
        return Set(self) == Set(other)
    }
}

public class TopLineBarIndicator: TMLineBarIndicator {
    public override var displayMode: TMBarIndicator.DisplayMode {
        .top
    }
}

extension TMBar {
    public typealias TopLineButtonBar = TMBarView<TMHorizontalBarLayout, TMLabelBarButton, TopLineBarIndicator>
}

public protocol TabElement<Element> {
    associatedtype Element: Equatable, Hashable
    
    var element: Element { get set }
    var title: String { get }
}

public class TabViewController<Element: TabElement, ContentView: View>: TabmanViewController, @preconcurrency PageboyViewControllerDataSource, @preconcurrency TMBarDataSource where Element: Hashable {
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Properties
    var bar = TMBar.TopLineButtonBar()
    
    var elements: [Element] = []
    var builder: (Element) -> ContentView
    var tint = UIColor(Color.accentColor)
    
    var currentPage: PageboyViewController.Page = .first
    
    // MARK: Lifecycle
    
    init(builder: @escaping (Element) -> ContentView) {
        self.builder = builder
        
        super.init(nibName: nil, bundle: nil)
    }
    
    func update(elements newElements: [Element]) {
        guard !self.elements.same(as: newElements) else
        {
            return
        }
        self.elements = newElements
        self.reloadData()
    }
    
    func refresh() {
        self._refreshBar()
    }
    
    func update(tint: UIColor) {
        self.tint = tint
    }
    
    private func _refreshBar() {
        self.bar.buttons.customize {
            $0.isEnabled = true
            $0.tintAdjustmentMode = .normal
            $0.tintColor = self.tint.withAlphaComponent(0.4)
            $0.selectedTintColor = self.tint
        }
        self.bar.indicator.tintAdjustmentMode = .normal
        self.bar.indicator.tintColor = self.tint
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        
        // Customize bar properties including layout and other styling.
        self.bar.layout.contentInset = UIEdgeInsets(top: 0.0, left: 16.0, bottom: 4.0, right: 16.0)
        self.bar.layout.interButtonSpacing = 24.0
        self.bar.indicator.weight = .light
        self.bar.indicator.cornerStyle = .eliptical
        self.bar.fadesContentEdges = true
        self.bar.spacing = 16.0
        
        // Set tint colors for the bar buttons and indicator.
        self.bar.buttons.customize {
            $0.tintColor = self.tint.withAlphaComponent(0.4)
            $0.selectedTintColor = self.tint
            $0.adjustsFontForContentSizeCategory = true
        }
        self.bar.indicator.tintColor = self.tint
        
        // Add bar to the view - as a .systemBar() to add UIKit style system background views.
        self.addBar(self.bar.systemBar(), dataSource: self, at: .bottom)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self._forceRefresh), name: Notification.Name.FORCE_REFRESH_TAB, object: nil)
    }
    
    deinit {
        // Remove observer when view controller is deallocated
        NotificationCenter.default.removeObserver(self, name: Notification.Name.FORCE_REFRESH_TAB, object: nil)
    }
    
    @objc private func _forceRefresh() {
        self.reloadData()
    }
    
    private func makeContentViewController(index: Int) -> UIViewController {
        let element = self.elements[index]
        let contentView = self.builder(element)
        //let viewController = UIHostingController(rootView: TabContentView(page: index))
        let viewController = UIHostingController(rootView: contentView)
        let navigationController = UINavigationController(rootViewController: viewController)
        //navigationController.navigationBar.prefersLargeTitles = false
        navigationController.isNavigationBarHidden = true
        return navigationController
    }
    
    // MARK: PageboyViewControllerDataSource
    
    public func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return self.elements.count
    }
    
    public func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        return self.makeContentViewController(index: index)
    }
    
    public func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return self.currentPage
    }
    
    public override func scrollToPage(_ page: PageboyViewController.Page, animated: Bool, completion: PageboyViewController.PageScrollCompletion? = nil) -> Bool {
        self.currentPage = page
        return super.scrollToPage(page, animated: animated, completion: completion)
    }
    
    // MARK: TMBarDataSource
    
    public func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        let element = self.elements[index]
        return TMBarItem(title: element.title) // Item to display for a specific index in the bar.
    }
}

public struct TabContainer<Element: TabElement, ContentView: View>: UIViewControllerRepresentable where Element: Hashable {
    @Binding private var elements: [Element]
    
    private let controller: TabViewController<Element, ContentView>
   
    public init(elements: Binding<[Element]>, builder: @escaping (Element) -> ContentView) {
        self._elements = elements
        
        self.controller = TabViewController<Element, ContentView>(builder: builder)
    }
    
    public func makeUIViewController(context: Context) -> TabViewController<Element, ContentView> {
        return self.controller
    }
    
    public func updateUIViewController(_ controller: TabViewController<Element, ContentView>, context: Context) {
        controller.update(elements: self.elements)
        controller.refresh()
    }
    
    public typealias UIViewControllerType = TabViewController<Element, ContentView>
}

extension TabContainer {
    public func bar(tint: UIColor) -> Self {
        self.controller.update(tint: tint)
        return self
    }
}
