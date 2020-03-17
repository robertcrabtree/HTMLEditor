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
    
    lazy var buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.spacing = 10
        stack.distribution = .equalSpacing
        return stack
    }()
    
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
    
    let doneButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Done", for: .normal)
        button.addTarget(self, action: #selector(onDone(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var boldButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Bold", for: .normal)
        button.addTarget(self, action: #selector(onBold(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var italicButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Italic", for: .normal)
        button.addTarget(self, action: #selector(onItalic(_:)), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(buttonStack)
        view.addSubview(webView)
        view.addSubview(doneButton)
        
        buttonStack.addArrangedSubview(boldButton)
        buttonStack.addArrangedSubview(italicButton)

        NSLayoutConstraint.activate([
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            webView.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 20),
            webView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -20),
            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
        
        let htmlFile = Bundle.main.path(forResource: "index", ofType: "html")!
        let html = try! String(contentsOfFile: htmlFile, encoding: .utf8)
        webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)

    }
}

extension ViewController {
    @objc func onDone(_ sender: UIButton) {
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
        isActive(attribute: "bold") { active in
            if active {
                self.deactivate(attribute: "bold") { _ in
                    self.boldButton.setTitle("Bold", for: .normal)
                }
            } else {
                self.activate(attribute: "bold") { _ in
                    self.boldButton.setTitle("Bold(X)", for: .normal)
                }
            }
        }
    }
    
    @objc func onItalic(_ sender: UIButton) {
        isActive(attribute: "italic") { active in
            if active {
                self.deactivate(attribute: "italic") { _ in
                    self.italicButton.setTitle("Italic", for: .normal)
                }
            } else {
                self.activate(attribute: "italic") { _ in
                    self.italicButton.setTitle("Italic(X)", for: .normal)
                }
            }
        }
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
}

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let message = Message(rawValue: message.name) else { print("crap"); return }
        switch message {
        case .selectionChanged, .textChanged:
            isActive(attribute: "bold") { active in
                if active {
                    self.boldButton.setTitle("Bold(X)", for: .normal)
                } else {
                    self.boldButton.setTitle("Bold", for: .normal)
                }
            }
            isActive(attribute: "italic") { active in
                if active {
                    self.italicButton.setTitle("Italic(X)", for: .normal)
                } else {
                    self.italicButton.setTitle("Italic", for: .normal)
                }
            }
        }
    }
}
