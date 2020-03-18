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
    
    @IBOutlet weak var bulletButton: UIButton! {
        didSet {
            bulletButton.addTarget(self, action: #selector(onBullet(_:)), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var numberButton: UIButton! {
        didSet {
            numberButton.addTarget(self, action: #selector(onNumber(_:)), for: .touchUpInside)
        }
    }

    @IBOutlet weak var hrefButton: UIButton! {
        didSet {
            hrefButton.addTarget(self, action: #selector(onHREF(_:)), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var headingButton: UIButton! {
        didSet {
            headingButton.addTarget(self, action: #selector(onHeading(_:)), for: .touchUpInside)
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
    
    lazy var attributeButtonMap: [Attribute: UIButton] = {
        var map: [Attribute: UIButton] = [:]
        Attribute.allCases.forEach {
            switch $0 {
            case .bold:
                map[.bold] = self.boldButton
            case .bullet:
                map[.bullet] = self.bulletButton
            case .heading1:
                map[.heading1] = self.headingButton
            case .href:
                map[.href] = self.hrefButton
            case .italic:
                map[.italic] = self.italicButton
            case .number:
                map[.number] = self.numberButton
            }
        }
        return map
    }()
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
    }
}

// MARK: - Action methods

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
                    self.activateHREF(urlString) {
                        self.updateButtonColor(for: .href)
                    }
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
        }
    }
}

// MARK: - Private methods

extension ViewController {
    
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
    
    private func activate(attribute: Attribute, then handle: @escaping () -> Void) {
        let js = "document.querySelector('trix-editor').editor.activateAttribute('\(attribute.rawValue)')"
        webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                print("activate Error: \(error)")
            } else {
                print("result: \(String(describing: result))")
                handle()
            }
        }
    }
    
    private func activateHREF(_ urlString: String, then handle: @escaping() -> Void) {
        let js = "document.querySelector('trix-editor').editor.activateAttribute('href', '\(urlString)')"
        webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                print("activateHREF Error: \(error)")
            } else {
                print("result: \(String(describing: result))")
                handle()
            }
        }
    }
    
    private func deactivate(attribute: Attribute, then handle: @escaping () -> Void) {
        let js = "document.querySelector('trix-editor').editor.deactivateAttribute('\(attribute.rawValue)')"
        webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                print("deactivate Error: \(error)")
            } else {
                print("result: \(String(describing: result))")
                handle()
            }
        }
    }
    
    private func toggle(attribute: Attribute) {
        checkActivated(attribute: attribute) { isActivated in
            if isActivated {
                self.deactivate(attribute: attribute) {
                    self.updateButtonColor(for: attribute)
                }
            } else {
                self.activate(attribute: attribute) {
                    self.updateButtonColor(for: attribute)
                }
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
}
