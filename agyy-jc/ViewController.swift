//
//  ViewController.swift
//  agyy-jc
//
//  Created by NB Connor on 26/01/2019.
//  Copyright © 2019 NB Connor. All rights reserved.
//


import UIKit
import WebKit


//UIColor扩展
extension UIColor {
    //使用rgb方式生成自定义颜色
    convenience init(_ r : CGFloat, _ g : CGFloat, _ b : CGFloat) {
        let red = r / 255.0
        let green = g / 255.0
        let blue = b / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }

    //使用rgba方式生成自定义颜色
    convenience init(_ r : CGFloat, _ g : CGFloat, _ b : CGFloat, _ a : CGFloat) {
        let red = r / 255.0
        let green = g / 255.0
        let blue = b / 255.0
        self.init(red: red, green: green, blue: blue, alpha: a)
    }
}

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    // 当前页面中的webview对象
    var webView: WKWebView!
    // app版本信息
    var appVersion = "NB/Hybrid-iOS=0.1.1"
    // 默认user-agent
    var defaultUA = "Mozilla/5.0 (iPhone; CPU iPhone OS 12_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/16B91"
    // 与H5的自定义通信协议
    var SCHEME_PROTOCOL = "nbapp"
    // 运营：获取网站domain的接口地址
    var DOMAIN_API_URL = "https://pull.agvipp8.com/portal/findappdomain"
    // UAT：获取网站domain的接口地址
//    var DOMAIN_API_URL = "http://pull.nbbets.com/portal/findappdomain"
    // 前端id
    var FRONT_ID = "102001011JIaThBA";
    
    // d获取当前可用的域名并加载页面
    func getDomain() {
        let url = DOMAIN_API_URL + "?frontId=" + FRONT_ID
        let session = URLSession(configuration: .default)
        let urlRequest = URLRequest(url: URL(string: url)!)
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            do {
                let result = try JSONSerialization.jsonObject(with: data!, options: []) as! NSDictionary
                if result.value(forKey: "code") as! Int == 200 {
                    let data = result.value(forKey: "data") as! NSDictionary
                    let portalUrlResult = data.value(forKey: "appDomain") as! String
                    let portalUrls = portalUrlResult.components(separatedBy: ",")
                    
                    DispatchQueue.main.async {
                        self.webView.load(URLRequest(url: URL(string: portalUrls[0])!))
                    }
                    
                    return
                }
            } catch let error {
                print("net error: \(error)")
            }
            
            let alert = UIAlertController(title: "提示", message: "当前网络连接不稳定，请稍后再试", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default, handler: {
                Action in
                exit(0)
            }))
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        task.resume()
    }
    
    // 获取启动图
    func launchImage() -> UIImage {
        var lunchImage : UIImage!
        let viewOrientation = "Portrait"
        let viewSize = UIScreen.main.bounds.size
        
        let imagesInfoArray = Bundle.main.infoDictionary!["UILaunchImages"]
        for dict : Dictionary <String, String> in imagesInfoArray as! Array {
            let imageSize = NSCoder.cgSize(for: dict["UILaunchImageSize"]!)
            if imageSize.equalTo(viewSize) && viewOrientation == dict["UILaunchImageOrientation"]!
                as String {
                lunchImage = UIImage(named: dict["UILaunchImageName"]!)
            }
        }
        
        return lunchImage
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let webConfiguration = WKWebViewConfiguration()
        
        self.webView = WKWebView(frame: .zero, configuration: webConfiguration)
        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
        
        self.webView.customUserAgent = defaultUA + " " + appVersion
        
        self.webView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        
        self.webView.alpha = 0
        
        self.view.addSubview(self.webView)
        
        self.getDomain()
        print("did appear")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("did load")
        self.view.backgroundColor = UIColor(patternImage: launchImage())
    }
    
    func getDictionaryFromJSONString(jsonString:String) -> NSDictionary {
        let jsonData:Data = jsonString.data(using: .utf8, allowLossyConversion: false)!
        let dict = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        
        if dict != nil {
            return dict as! NSDictionary
        }
        return NSDictionary()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        let url = navigationAction.request.url!
        if url.scheme?.lowercased() == SCHEME_PROTOCOL {
            let method = url.host!
            print(url)
            if method.isEmpty {
                return
            }
            
            var dataString: String = url.absoluteString.replacingOccurrences(
                of: SCHEME_PROTOCOL + "://" + method + "?data=",
                with: ""
                ).removingPercentEncoding!
            
            if dataString.isEmpty {
                dataString = "{}"
            }
            
            let data = self.getDictionaryFromJSONString(jsonString: dataString)
            
            switch (method) {
            case "openInBrowser":
                self.openInBrowser(data: data)
                break
            case "setTheme":
                self.setTheme(data: data)
                break
            default:
                break
            }
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("load finish")
        self.webView.alpha = 1
    }
    
    func openInBrowser(data: NSDictionary) {
        let openaddress = data.value(forKey: "url") as! String
        let openUrl = URL(string: openaddress)
        print(openUrl as Any)
        
        if (openUrl != nil) {
            UIApplication.shared.openURL(openUrl!)
        }
    }
    
    func setTheme(data: NSDictionary) {
        let theme:Int = data.value(forKey: "theme") as! Int
        self.setNeedsStatusBarAppearanceUpdate()
        if theme == 0 {
            self.view.backgroundColor = UIColor(0xff, 0xff, 0xff)
            self.webView.backgroundColor = UIColor(0xff, 0xff, 0xff)
        } else {
            self.view.backgroundColor = UIColor(0x28, 0x27, 0x2d)
            self.webView.backgroundColor = UIColor(0x28, 0x27, 0x2d)
        }
    }
}
