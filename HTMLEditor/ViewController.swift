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
    
    func isActive(attribute: String, completion: @escaping (Bool) -> Void) {
        let js = "document.querySelector('trix-editor').editor.attributeIsActive('\(attribute)')"
        webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                print("isActive Error: \(error)")
            } else if let result = result as? Bool {
                print("isActive Result: \(result)")
                completion(result)
            } else {
                print("isActive oh crap")
            }
        }
    }
    
    func activate(attribute: String, completion: @escaping (Bool) -> Void) {
        let js = "document.querySelector('trix-editor').editor.activateAttribute('\(attribute)')"
        webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                print("activate Error: \(error)")
            } else if let result = result as? Bool {
                print("activate Result: \(result)")
                completion(result)
            } else {
                print("activate oh crap")
            }
        }
    }
    
    func deactivate(attribute: String, completion: @escaping (Bool) -> Void) {
        let js = "document.querySelector('trix-editor').editor.deactivateAttribute('\(attribute)')"
        webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                print("deactivate Error: \(error)")
            } else if let result = result as? Bool {
                print("deactivate Result: \(result)")
                completion(result)
            } else {
                print("deactivate oh crap")
            }
        }
    }
    
    func toggle(attribute: String, for button: UIButton) {
        isActive(attribute: attribute) { active in
            if active {
                self.deactivate(attribute: attribute) { _ in
                    self.update(attributeButton: button, attribute: attribute)
                }
            } else {
                self.activate(attribute: attribute) { _ in
                    self.update(attributeButton: button, attribute: attribute)
                }
            }
        }
    }
    
    func update(attributeButton: UIButton, attribute: String) {
        isActive(attribute: attribute) { active in
            self.update(attributeButton: attributeButton, isActive: active)
        }
    }
    
    func update(attributeButton: UIButton, isActive: Bool) {
        if isActive {
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
