//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by LOVINPEACE on 21/05/26.
//

import UIKit
import Social
import SwiftUI

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the main view controller background clear initially
        self.view.backgroundColor = .clear
        
        // Load the shared text and URL from the extension context
        loadSharedContent { [weak self] sharedText, sharedURL in
            DispatchQueue.main.async {
                self?.setupSwiftUIView(sharedText: sharedText, sharedURL: sharedURL)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Traverse all superviews of the view and set their backgrounds to clear
        // to remove any native gray sheet borders or wrapper background colors
        var currentView: UIView? = self.view
        while currentView != nil {
            currentView?.backgroundColor = .clear
            currentView = currentView?.superview
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Animate the background dimming for a premium bottom-sheet backdrop feel
        UIView.animate(withDuration: 0.3) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        }
    }
    
    private func loadSharedContent(completion: @escaping (String?, URL?) -> Void) {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            completion(nil, nil)
            return
        }
        
        var text: String? = nil
        var url: URL? = nil
        let group = DispatchGroup()
        
        for item in inputItems {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                // 1. Load URL if present
                if provider.hasItemConformingToTypeIdentifier("public.url") {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: "public.url", options: nil) { item, error in
                        if let sharedURL = item as? URL {
                            url = sharedURL
                        } else if let urlString = item as? String, let sharedURL = URL(string: urlString) {
                            url = sharedURL
                        }
                        group.leave()
                    }
                }
                
                // 2. Load plain text if present
                if provider.hasItemConformingToTypeIdentifier("public.plain-text") {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { item, error in
                        if let sharedText = item as? String {
                            text = sharedText
                        }
                        group.leave()
                    }
                }
            }
        }
        
        // Wait for all async loads to finish
        group.notify(queue: .main) {
            completion(text, url)
        }
    }
    
    private func setupSwiftUIView(sharedText: String?, sharedURL: URL?) {
        let shareView = ShareView(
            sharedText: sharedText,
            sharedURL: sharedURL,
            onDismiss: { [weak self] in
                self?.dismissExtension()
            }
        )
        
        let hostingController = UIHostingController(rootView: shareView)
        hostingController.view.backgroundColor = .clear
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
    
    private func dismissExtension() {
        // Animate background back to clear before dismissing extension context
        UIView.animate(withDuration: 0.2, animations: {
            self.view.backgroundColor = .clear
        }) { _ in
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
