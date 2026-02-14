//
//  Paginator.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 13/02/26.
//

import Foundation
import UIKit

protocol PaginatorDelegate: AnyObject {
    func paginate(to page: Int, for paginator: Paginator)
}

final class Paginator {
    
    var page: Int = 1
    private var isPaginating = false
    
    weak var pagingDelegate: PaginatorDelegate? {
        didSet {
            pagingDelegate?.paginate(to: page, for: self)
        }
    }
    
    init(delegate: PaginatorDelegate) {
        defer { self.pagingDelegate = delegate }
    }
    
    func reset() {
        page = 1
        isPaginating = false
        pagingDelegate?.paginate(to: page, for: self)
    }
    
    func viewingItemAt(indexPath: IndexPath, currentItemCount: Int) {
        
        guard currentItemCount > 0 else { return }
        
        // Trigger when reaching last 3 cells
        if indexPath.row >= currentItemCount - 3 {
            guard !isPaginating else { return }
            
            isPaginating = true
            page += 1
            pagingDelegate?.paginate(to: page, for: self)
        }
    }
    
    func finishedPaginating() {
        isPaginating = false
    }
}

