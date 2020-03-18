//
//  ViewController.swift
//  HTMLEditor
//
//  Created by Rob Crabtree on 3/17/20.
//  Copyright © 2020 Certified Organic Software. All rights reserved.
//

import UIKit
import WebKit

// MARK: - Properties

class ViewController: UIViewController {
    
    enum Message: String {
        case textChanged
        case selectionChanged
    }
    
    enum Attribute: String, CaseIterable {
        case bold
        case italic
        case bullet
        case number
        case href
        case heading1
    }
    
    @IBOutlet weak var boldButton: UIButton!
    @IBOutlet weak var italicButton: UIButton!
    @IBOutlet weak var bulletButton: UIButton!
    @IBOutlet weak var numberButton: UIButton!
    @IBOutlet weak var hrefButton: UIButton!
    @IBOutlet weak var headingButton: UIButton!
    @IBOutlet weak var webViewContainerView: UIView!
    @IBOutlet weak var htmlTextView: UITextView!
    @IBOutlet weak var htmlLabel: UILabel!

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
    
    lazy var attributeButtonMap: [Attribute: UIButton] = [:]
}

// MARK: - Life cycle

extension ViewController {
    
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
        
        Attribute.allCases.forEach { attribute in
            
            func associate(attribute: Attribute, button: UIButton, action: Selector) {
                attributeButtonMap[attribute] = button
                button.addTarget(self, action: action, for: .touchUpInside)
            }
            
            switch attribute {
            case .bold:
                associate(attribute: .bold, button: boldButton, action: #selector(onBold(_:)))
            case .bullet:
                associate(attribute: .bullet, button: bulletButton, action: #selector(onBullet(_:)))
            case .heading1:
                associate(attribute: .heading1, button: headingButton, action: #selector(onHeading(_:)))
            case .href:
                associate(attribute: .href, button: hrefButton, action: #selector(onHREF(_:)))
            case .italic:
                associate(attribute: .italic, button: italicButton, action: #selector(onItalic(_:)))
            case .number:
                associate(attribute: .number, button: numberButton, action: #selector(onNumber(_:)))
            }
        }
    }
}

// MARK: - Action methods

extension ViewController {
    
    @IBAction func onClear(_ sender: UIBarButtonItem) {
        clearText()
    }
    
    @objc func onBold(_ sender: UIButton) {
        toggle(attribute: .bold)
    }
    
    @objc func onItalic(_ sender: UIButton) {
        toggle(attribute: .italic)
    }
    
    @objc func onBullet(_ sender: UIButton) {
        toggle(attribute: .bullet)
    }
    
    @objc func onNumber(_ sender: UIButton) {
        toggle(attribute: .number)
    }

    @objc func onHREF(_ sender: UIButton) {
        checkActivated(attribute: .href) { isActivated in
            if isActivated {
                self.toggle(attribute: .href)
            } else {
                self.promptURL { urlString in
                    self.activate(attribute: .href, value: urlString)
                }
            }
        }
    }
    
    @objc func onHeading(_ sender: UIButton) {
        toggle(attribute: .heading1)
    }
}

// MARK: - Message handler

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let message = Message(rawValue: message.name) else { print("crap"); return }
        switch message {
        case .selectionChanged, .textChanged:
            Attribute.allCases.forEach {
                updateButtonColor(for: $0)
            }
            loadHTMLResult()
        }
    }
}

// MARK: - Private methods

extension ViewController {
    
    private func clearText() {
        let js = "document.querySelector('trix-editor').editor.loadHTML('')"
        webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                print("isActivated Error: \(error)")
            }
        }
    }
    
    private func checkActivated(attribute: Attribute, then handle: @escaping (Bool) -> Void) {
        let js = "document.querySelector('trix-editor').editor.attributeIsActive('\(attribute.rawValue)')"
        webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                print("isActivated Error: \(error)")
            } else if let result = result as? Bool {
                handle(result)
            } else {
                print("isActivated oh crap")
            }
        }
    }
    
    private func activate(attribute: Attribute, value: String? = nil) {
        let js: String
        if let value = value {
            js = "document.querySelector('trix-editor').editor.activateAttribute('\(attribute.rawValue)', '\(value)')"
        } else {
            js = "document.querySelector('trix-editor').editor.activateAttribute('\(attribute.rawValue)')"
        }
        webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                print("activate Error: \(error)")
            } else {
                print("result: \(String(describing: result))")
                self.updateButtonColor(for: attribute)
            }
        }
    }
    
    private func deactivate(attribute: Attribute) {
        let js = "document.querySelector('trix-editor').editor.deactivateAttribute('\(attribute.rawValue)')"
        webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                print("deactivate Error: \(error)")
            } else {
                print("result: \(String(describing: result))")
                self.updateButtonColor(for: attribute)
            }
        }
    }
    
    private func toggle(attribute: Attribute) {
        checkActivated(attribute: attribute) { isActivated in
            if isActivated {
                self.deactivate(attribute: attribute)
            } else {
                self.activate(attribute: attribute)
            }
        }
    }
    
    private func updateButtonColor(for attribute: Attribute) {
        guard let button = attributeButtonMap[attribute] else { return }
        checkActivated(attribute: attribute) { isActivated in
            if isActivated {
                button.setTitleColor(.red, for: .normal)
            } else {
                button.setTitleColor(.black, for: .normal)
            }
        }
    }
    
    private func promptURL(then handle: @escaping(String) -> Void) {
        let alert = UIAlertController(title: "Enter URL", message: "Supply a valid URL", preferredStyle: .alert)
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(.init(title: "Ok", style: .default, handler: { _ in
            guard let text = alert.textFields?[0].text, !text.isEmpty else { return }
            handle(text)
        }))
        alert.addTextField { textField in
            textField.placeholder = "URL"
        }
        present(alert, animated: true)
    }
    
    private func loadHTMLResult() {
        webView.evaluateJavaScript("document.getElementById('thedata').value") { (result, error) in
            if let error = error {
                print("Error: \(error)")
            } else if let result = result as? String {
                self.htmlTextView.text = result
                self.htmlLabel.isHidden = !result.isEmpty
            } else {
                print("oh crap")
            }
        }
    }
}
