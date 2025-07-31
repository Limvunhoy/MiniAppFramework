import UIKit
import WebKit

public class JSBridge: NSObject, WKUIDelegate,WKScriptMessageHandler, UIScrollViewDelegate, WKNavigationDelegate {
    
    public weak var delegate: JSBridgeDelegate?
    var webView:WKWebView!
    
    public init(webView: WKWebView) {
        super.init()
        self.webView = webView
        self.setupWebView()
    }
    
    private func setupWebView() {
        let source =
        """
            function captureLog(msg) { window.webkit.messageHandlers.logHandler.postMessage(msg); }
            window.console.error = captureLog;
        """
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        self.webView.configuration.userContentController.addUserScript(script)
        self.webView.configuration.userContentController.add(self, name: "jsbridge")
        self.webView.configuration.userContentController.add(self, name: "logHandler")
        self.webView.configuration.applicationNameForUserAgent = "JSBridge/1.0 (iPhone)"
        
        
        DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
            guard let self = self else { return }
            self.webView.evaluateJavaScript("navigator.userAgent") { (result, error) in
                if let userAgent = result as? String {
                    let customSuffix = " JSBridge/1.0 (iPhone)"
                    let newCustomUserAgent = userAgent + customSuffix
                    self.webView.customUserAgent = newCustomUserAgent
                } else if let error = error {
                    debugPrint("Error getting User-Agent via JavaScript: \(error.localizedDescription)")
                }
            }
        }
        
        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
        if #available(iOS 14.0, *) {
            self.webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else if #available(iOS 16.4, *) {
            self.webView.isInspectable = true
        }
        self.webView.scrollView.delegate = self
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if (message.name == "logHandler") {
            debugPrint("ErrorLog ==> ",message.body)
            return
        }
        
        if message.name != "jsbridge" { return }
        
        guard let dict = message.body as? [String: Any] else { return }
        
        let data = convertToDictionary(text: dict["data"] as? String ?? "")
        let event = dict["event"] as? String ?? ""
        let id = dict["id"] as? Int ?? 0
        
        self.jsEventHandler(id: id, event: event, data: data!)
    }
    
    func jsEventHandler(id:Int,event:String,data:[String: Any]) {
        var res = """
                {}
            """
        if (event == JSBridgeEventEnum.ping.rawValue) {
            let timeStamp = Int64(Date().timeIntervalSince1970 * 1000)
            res = """
                {"\(event)":\(timeStamp)}
            """
            self.dispatchEvent(id: id, event: event, res: res)
            
        } else if (event == JSBridgeEventEnum.getProfile.rawValue) {
            self.delegate?.getProfile( completion: { user in
                self.dispatchEvent(id: id, event: event, res: user?.toJSONString() ?? "")
            })
            
        } else if (event == JSBridgeEventEnum.getConfig.rawValue) {
            self.delegate?.getConfig(completion: { config in
                self.dispatchEvent(id: id, event: event, res: config?.toJSONString() ?? "")
            })
            
        } else if (event == JSBridgeEventEnum.doPayment.rawValue) {
            self.delegate?.doPayment(args: data)
            self.dispatchEvent(id: id, event: event, res: "{}")
            
        } else if (event == JSBridgeEventEnum.getDefaultAccount.rawValue) {
            self.delegate?.getDefaultAccount(completion: { acc in
                self.dispatchEvent(id: id, event: event, res: acc?.toJSONString() ?? "")
            })
            
        } else if (event == JSBridgeEventEnum.closeApp.rawValue) {
            self.delegate?.closeApp(args: data)
            self.dispatchEvent(id: id, event: event, res: res)
            
        } else if (event == JSBridgeEventEnum.setBarTitle.rawValue) {
            self.delegate?.setBarTitle(barItem: data)
            
        } else if (event == JSBridgeEventEnum.uploadFile.rawValue) {
            self.delegate?.uploadFile(args: data, completion: {file in
                self.dispatchEvent(id: id, event: event, res: file?.toJSONString() ?? "")
            })
            
        } else if (event == JSBridgeEventEnum.openMap.rawValue) {
            self.delegate?.openMap(args:data)
            self.dispatchEvent(id: id, event: event, res: res)
            
        } else if (event == JSBridgeEventEnum.share.rawValue) {
            self.delegate?.share(args:data)
            self.dispatchEvent(id: id, event: event, res: res)
            
        } else if (event == JSBridgeEventEnum.backToHome.rawValue) {
            self.delegate?.backToHomePage()
            self.dispatchEvent(id: id, event: event, res: res)
            
        } else if (event == JSBridgeEventEnum.addCalendar.rawValue) {
            self.delegate?.addCalendar(args: data)
            self.dispatchEvent(id: id, event: event, res: res)
            
        } else if (event == JSBridgeEventEnum.requestCurrentLocation.rawValue) {
            self.delegate?.requestCurrentLocation()
            
        } else if (event == JSBridgeEventEnum.download.rawValue) {
            self.delegate?.download(args: data, completion: { status in
                self.dispatchEvent(id: id, event: event, res: status?.toJSONString() ?? "")
            })
            
        } else if (event == JSBridgeEventEnum.openApp.rawValue) {
            self.delegate?.openApp(args: data)
            self.dispatchEvent(id: id, event: event, res: res)
            
        } else if (event == JSBridgeEventEnum.getNID.rawValue) {
            self.delegate?.getNID(completion: { nid in
                self.dispatchEvent(id: id, event: event, res: nid?.toJSONString() ?? "")
            })
            
        } else if (event == JSBridgeEventEnum.logError.rawValue) {
            self.delegate?.logError(completion: { error in
                self.dispatchEvent(id: id, event: event, res: error?.toJSONString() ?? "")
            })
            
        } else if (event == JSBridgeEventEnum.load.rawValue) {
            self.delegate?.onLoad(completion: { load in
                self.dispatchEvent(id: id, event: event, res: load?.toJSONString() ?? "")
            })
            
        } else if (event == JSBridgeEventEnum.viewAppInfo.rawValue) {
            self.delegate?.onViewAppInfo()
            self.dispatchEvent(id: id, event: event, res: res)
            
        } else if (event == JSBridgeEventEnum.unknown.rawValue) {
            let timeStamp = Int64(Date().timeIntervalSince1970 * 1000)
            res = """
                    {"\(event)":\(timeStamp)}
                """
            self.dispatchEvent(id: id, event: event, res: res)
            
        } else if (event == JSBridgeEventEnum.closePayment.rawValue) {
            self.delegate?.closePayment()
            
        } else {
            self.delegate?.onEventCallback(type: event, data: data, completion:{ res in
                self.dispatchEvent(id: id, event: event, res: res?.toJSONString() ?? "")
            })
        }
    }
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    public func dispatchEvent(id:Int,event:String,res:String,action:String = "") {
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("try { JSBridge.native.callback(\(id), '\(event)', `\(res)`,`\(action)`) } catch (e) { console.error(JSON.stringify(e)) }")
        }
    }
    public func dispatchEvent(id:Int,event:String,res:[String : Any],action:String = "") {
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("try { JSBridge.native.callback(\(id), '\(event)', `\(res.toJSONString() ?? "")`,`\(action)`) } catch (e) { console.error(JSON.stringify(e)) }")
        }
    }
    public func bridgeAvailable(completion: @escaping (Bool) -> Void)  {
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("typeof JSBridge === 'object'") { (result, error) in
                let resultBool = result as? Int ?? 0
                completion(resultBool == 1)
            }
        }
    }
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
            }
        }
        return nil
    }
    
    func convertBase64StringToImage (imageBase64String:String) -> UIImage? {
        if let url = URL(string: imageBase64String), let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }
}
