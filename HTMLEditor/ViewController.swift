//
//  ViewController.swift
//  HTMLEditor
//
//  Created by Rob Crabtree on 3/17/20.
//  Copyright © 2020 Certified Organic Software. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    
    enum Message: String {
        case textChanged
        case selectionChanged
    }
    
    @IBOutlet weak var printButton: UIButton! {
        didSet {
            printButton.addTarget(self, action: #selector(onPrintHTML(_:)), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var boldButton: UIButton! {
        didSet {
            boldButton.addTarget(self, action: #selector(onBold(_:)), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var italicButton: UIButton! {
        didSet {
            italicButton.addTarget(self, action: #selector(onItalic(_:)), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var webViewContainerView: UIView!
    
    lazy var webView: WKWebView = {
        let controller = WKUserContentController()
        controller.add(self, name: Message.textChanged.rawValue)
        controller.add(self, name: Message.selectionChanged.rawValue)
        let config = WKWebViewConfiguration()
        config.userContentController = controller
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webViewContainerView.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: webViewContainerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: webViewContainerView.trailingAnchor),
            webView.topAnchor.constraint(equalTo: webViewContainerView.topAnchor),
            webView.bottomAnchor.constraint(equalTo: webViewContainerView.bottomAnchor),
        ])
        
        let htmlFile = Bundle.main.path(forResource: "index", ofType: "html")!
        let html = try! String(contentsOfFile: htmlFile, encoding: .utf8)
        webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
    }
}

extension ViewController {
    @objc func onPrintHTML(_ sender: UIButton) {
        webView.evaluateJavaScript("document.getElementById('thedata').value") { (result, error) in
            if let error = error {
                print("Error: \(error)")
            } else if let result = result {
                print("Result: \(result)")
            } else {
                print("oh crap")
            }
        }
    }
    
    @objc func onBold(_ sender: UIButton) {
        toggle(attribute: "bold", for: boldButton)
    }
    
    @objc func onItalic(_ sender: UIButton) {
        toggle(attribute: "italic", for: italicButton)
    }
    
    func checkActivated(attribute: String, then handle: @escaping (Bool) -> Void) {
        let js = "document.querySelector('trix-editor').editor.attributeIsActive('\(attribute)')"
        webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                print("isActivated Error: \(error)")
            } else if let result = result as? Bool {
                print("isActivated Result: \(result)")
                handle(result)
            } else {
                print("isActivated oh crap")
            }
        }
    }
    
    func activate(attribute: String, then handle: @escaping (Bool) -> Void) {
        let js = "document.querySelector('trix-editor').editor.activateAttribute('\(attribute)')"
        webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                print("activate Error: \(error)")
            } else if let result = result as? Bool {
                print("activate Result: \(result)")
                handle(result)
            } else {
                print("activate oh crap")
            }
        }
    }
    
    func deactivate(attribute: String, then handle: @escaping (Bool) -> Void) {
        let js = "document.querySelector('trix-editor').editor.deactivateAttribute('\(attribute)')"
        webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                print("deactivate Error: \(error)")
            } else if let result = result as? Bool {
                print("deactivate Result: \(result)")
                handle(result)
            } else {
                print("deactivate oh crap")
            }
        }
    }
    
    func toggle(attribute: String, for attributeButton: UIButton) {
        checkActivated(attribute: attribute) { isActivated in
            if isActivated {
                self.deactivate(attribute: attribute) { _ in
                    self.update(attributeButton: attributeButton, attribute: attribute)
                }
            } else {
                self.activate(attribute: attribute) { _ in
                    self.update(attributeButton: attributeButton, attribute: attribute)
                }
            }
        }
    }
    
    func update(attributeButton: UIButton, attribute: String) {
        checkActivated(attribute: attribute) { isActivated in
            self.update(attributeButton: attributeButton, isActivated: isActivated)
        }
    }
    
    func update(attributeButton: UIButton, isActivated: Bool) {
        if isActivated {
            attributeButton.setTitleColor(.red, for: .normal)
        } else {
            attributeButton.setTitleColor(.black, for: .normal)
        }
    }
}

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let message = Message(rawValue: message.name) else { print("crap"); return }
        switch message {
        case .selectionChanged, .textChanged:
            update(attributeButton: boldButton, attribute: "bold")
            update(attributeButton: italicButton, attribute: "italic")
        }
    }
}
