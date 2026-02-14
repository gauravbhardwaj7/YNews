//
//  ShareSheetManager.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 14/02/26.
//


import UIKit

final class ShareSheetManager {
    
    static let shared = ShareSheetManager()
    
    private init() {}
    func presentShareSheet(
        items: [Any],
        from viewController: UIViewController,
        sourceView: UIView? = nil,
        completion: (() -> Void)? = nil
    ) {
        let activityViewController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        if let popoverController = activityViewController.popoverPresentationController {
            if let sourceView = sourceView {
                popoverController.sourceView = sourceView
                popoverController.sourceRect = sourceView.bounds
            } else {
                popoverController.sourceView = viewController.view
                popoverController.sourceRect = CGRect(
                    x: viewController.view.bounds.midX,
                    y: viewController.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popoverController.permittedArrowDirections = []
            }
        }
        
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            completion?()
        }
        
        viewController.present(activityViewController, animated: true)
    }
    
    func shareArticle(
        _ article: Article,
        from viewController: UIViewController,
        sourceView: UIView? = nil
    ) {
        var itemsToShare: [Any] = []
        

        if let title = article.title {
            itemsToShare.append(title)
        }
        

        if let urlString = article.url, let url = URL(string: urlString) {
            itemsToShare.append(url)
        }
        
        guard !itemsToShare.isEmpty else {
            print("No items to share")
            return
        }
        
        presentShareSheet(
            items: itemsToShare,
            from: viewController,
            sourceView: sourceView
        )
    }
}
