//
//  Utility.swift
//  QuickSpeechMemo
//
//  Created by Naoki Nishiya on 10/22/16.
//  Copyright © 2016 Naoki Nishiyama. All rights reserved.
//

import UIKit

extension NSObject {
    var className: String {
        return type(of: self).className
    }
    
    class var className: String {
        return String(describing: self)
    }
}

extension String {
    var count: Int {
        return characters.count
    }
}

extension Collection {
    subscript (safe index: Index) -> Iterator.Element? {
        return startIndex..<endIndex ~= index ? self[index] : nil
    }
}

extension Date {
    func format(_ dateFormat: String = "yyyy/MM/dd HH:mm:ss") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: self)
    }
}

extension UIApplication {
    static var rootViewController: UIViewController? {
        return shared.delegate?.window??.rootViewController
    }
    
    static func topViewController(_ vc: UIViewController? = rootViewController) -> UIViewController? {
        if let nc = vc as? UINavigationController {
            return topViewController(nc.visibleViewController)
        } else if let tc = vc as? UITabBarController {
            return topViewController(tc.selectedViewController)
        } else if let pc = vc?.presentedViewController {
            return topViewController(pc)
        }
        
        return vc
    }
}

protocol StoryboardInitializable {}

extension StoryboardInitializable where Self: UIViewController {
    
    /// インスタンス生成
    ///
    /// - parameter storyboardName: storyboard name
    ///
    /// - returns: インスタンス
    ///
    /// StoryBoardでIdintifierにクラス名を設定
    static func instantiate(storyboardName: String) -> Self {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: self.className) as! Self
    }
}

protocol NibInitializable {}

extension NibInitializable where Self: UIViewController {
    
    /// インスタンス生成
    ///
    /// - parameter nibName: xib name
    ///
    /// - returns: インスタンス
    ///
    /// Xibファイル名をクラス名と同じにする
    static func instatinate(nibName: String? = nil) -> Self {
        let name = nibName ?? self.className
        let xib = UINib(nibName: name, bundle: nil)
        return xib.instantiate(withOwner: nil, options: nil)[0] as! Self
    }
}

struct Device {
    
    struct Screen {
        static var size: CGSize {
            return UIScreen.main.bounds.size
        }
    }
    
}

@IBDesignable
class DesignableView: UIView {
    @IBInspectable var borderColor: UIColor = UIColor.clear
    @IBInspectable var borderWidth: CGFloat = 0
    @IBInspectable var cornerRadius: CGFloat = 0
    
    override func draw(_ rect: CGRect) {
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
        layer.cornerRadius = cornerRadius
        clipsToBounds = cornerRadius > 0
        
        super.draw(rect)
    }
}

@IBDesignable
class DesignableButton: UIButton {
    @IBInspectable var borderColor: UIColor = .clear
    @IBInspectable var borderWidth: CGFloat = 0
    @IBInspectable var cornerRadius: CGFloat = 0
    
    @IBInspectable var defaultTitleColor: UIColor = .darkText
    @IBInspectable var defaultBackColor: UIColor = .white
    
    @IBInspectable var highlightTitleColor: UIColor = .darkText
    @IBInspectable var highlightBackColor: UIColor = .lightGray
    @IBInspectable var highlightBorderColor: UIColor = .clear
    
    @IBInspectable var disableTitleColor: UIColor = .lightText
    @IBInspectable var disableBackColor: UIColor = .white
    @IBInspectable var disableBorderColor: UIColor = .clear
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? highlightBackColor : defaultBackColor
            layer.borderColor = isHighlighted ? highlightBorderColor.cgColor : borderColor.cgColor
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? defaultBackColor : disableBackColor
            layer.borderColor = isEnabled ? borderColor.cgColor : disableBorderColor.cgColor
        }
    }
    
    override func draw(_ rect: CGRect) {
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
        layer.cornerRadius = cornerRadius
        clipsToBounds = cornerRadius > 0
        
        setTitleColor(defaultTitleColor, for: .normal)
        setTitleColor(highlightTitleColor, for: .highlighted)
        setTitleColor(disableTitleColor, for: .disabled)
        
        backgroundColor = defaultBackColor
        
        super.draw(rect)
    }
}

struct Regex {
    
    struct Match {
        var wholeString = ""
        var groups = [String]()
        
        init(wholeString: String, groups: [String]) {
            self.wholeString = wholeString
            self.groups = groups
        }
        
        init(text: NSString, result res: NSTextCheckingResult) {
            let components = (0..<res.numberOfRanges).map { text.substring(with: res.rangeAt($0)) }
            self.wholeString = components[0]
            self.groups = components.dropFirst().map { $0 }
        }
    }
    
    fileprivate let regex: NSRegularExpression
    
    
    /// initializer
    ///
    /// - parameter pattern: 正規表現パターン
    /// - parameter options: 正規表現オプション
    ///
    /// - throws: error
    ///
    /// - returns: Regexオブジェクト
    ///
    /// ```
    /// let regex = try! Regex("([0-9]+?)月([0-9]+?)日")
    /// ```
    init(_ pattern: String, options: NSRegularExpression.Options = []) throws {
        do {
            self.regex = try NSRegularExpression(pattern: pattern, options: options)
        }
    }
    
    
    /// 一度だけマッチ
    ///
    /// - parameter string:  検索文字列
    /// - parameter range:   範囲
    /// - parameter options: 正規表現オプション
    ///
    /// - returns: Matchオブジェクト
    ///
    /// ```
    /// let target = "10月3日12月25日1月1日"
    /// if let match = regex.firstMatch(target) {
    ///     print(match.wholeString) // マッチしたすべての範囲
    ///     print(match.groups) // ()で囲まれた中身
    /// }
    /// ```
    func firstMatch(_ string: String, range: NSRange? = nil, options: NSRegularExpression.MatchingOptions = []) -> Match? {
        let targetRange = range ?? string.wholeNSRange()
        let nsstring = string as NSString
        if let res = self.regex.firstMatch(in: string, options: options, range: targetRange) {
            return Regex.Match(text: nsstring, result: res)
        } else {
            return nil
        }
    }
    
    
    /// すべてのマッチ
    ///
    /// - parameter string:  検索文字列
    /// - parameter range:   範囲
    /// - parameter options: 正規表現オプション
    ///
    /// - returns: Matchオブジェクト
    ///
    /// ```
    /// let target = "10月3日12月25日1月1日"
    /// for match in regex.matches(target) {
    ///     print(match.wholeString, match.groups)
    /// }
    /// ```
    func matches(_ string: String, range: NSRange? = nil, options: NSRegularExpression.MatchingOptions = []) -> [Match] {
        let targetRange = range ?? string.wholeNSRange()
        let nsstring = string as NSString
        return self.regex.matches(in: string, options: options, range: targetRange).map { res in
            return Regex.Match(text: nsstring, result: res)
        }
    }
}

extension String {
    fileprivate func wholeRange() -> Range<String.Index> {
        return Range(uncheckedBounds: (self.startIndex, self.endIndex))
    }
    
    fileprivate func wholeNSRange() -> NSRange {
        return NSRange(location: 0, length: self.characters.count)
    }
    
    func replace(_ regex: Regex, template: String, range: NSRange? = nil, options: NSRegularExpression.MatchingOptions = []) -> String {
        let targetRange = range ?? self.wholeNSRange()
        return regex.regex.stringByReplacingMatches(in: self, options: options, range: targetRange, withTemplate: template)
    }
}
