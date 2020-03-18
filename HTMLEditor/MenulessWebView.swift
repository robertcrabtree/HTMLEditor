//
//  MenuLessWebView.swift
//  HTMLEditor
//
//  Created by Rob Crabtree on 3/17/20.
//  Copyright © 2020 Certified Organic Software. All rights reserved.
//

import WebKit

class MenulessWebView: WKWebView {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
}
