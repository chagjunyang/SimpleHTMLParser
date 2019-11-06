//
//  SimpleHTMLConverter.swift
//  HTMLStringToAttributedString
//
//  Created by cjyang on 01/05/2019.
//  Copyright © 2019 cjyang. All rights reserved.
//

import UIKit

fileprivate typealias StackItem = (SimpleHTMLParserTagName, [NSAttributedString.Key : Any]?)

@objc
public class SimpleHTMLConverter: NSObject, SimpleHTMLParserDelegate {
    var tagToeknStack: Stack!
    var currentAttributedString: [NSAttributedString.Key : Any]!
    var defaultAttributedString: [NSAttributedString.Key : Any]!
    var result: NSMutableAttributedString!
    
    @objc
    public func convertHTMLStringToAttributedString(htmlString: String, baseFont: UIFont, color: UIColor) -> NSAttributedString? {
        self.tagToeknStack = Stack()
        self.currentAttributedString = [NSAttributedString.Key : Any]()
        self.result = NSMutableAttributedString()
        
        currentAttributedString.updateValue(baseFont, forKey: .font)
        currentAttributedString.updateValue(color, forKey: .foregroundColor)
        
        defaultAttributedString = currentAttributedString
        
        let parser = SimpleHTMLParser(htmlString: htmlString, _delegate: self)
        parser.startParsing()
        
        if tagToeknStack.isEmpty() == false {
            throwErrorWithMessageAndExitFlow(exceptionName: "AttributedBuilder", message: "openTag is more than closeTag")
            
            return nil
        }
        
        return self.result
    }

    func startTag(token: SimpleHTMLToken) {
        updateAttributeDict(token: token, attrDict: &currentAttributedString!)
        
        self.tagToeknStack.push(item: (token.tagName, currentAttributedString))
    }
    
    func endTag(token: SimpleHTMLToken) {
        if let topItem = self.tagToeknStack.pop() as? StackItem {
            if topItem.0 == token.tagName {
                if let topItem = self.tagToeknStack.topItem() as? StackItem {
                    self.currentAttributedString = topItem.1
                } else {
                    self.currentAttributedString = defaultAttributedString
                }
            } else {
                throwErrorWithMessageAndExitFlow(exceptionName: "AttributedBuilder", message: "endTag. tagname not matched \(topItem.0) \(token.tagName)")
            }
        } else {
            throwErrorWithMessageAndExitFlow(exceptionName: "AttributedBuilder", message: "closeTag is more than openTag")
        }
    }
    
    func parsedText(_ text: String) {
        result.append(NSAttributedString(string: text, attributes: self.currentAttributedString))
    }
    
    func updateAttributeDict(token: SimpleHTMLToken, attrDict: inout [NSAttributedString.Key : Any]) {
        switch token.tagName {
        case .font:
            for attrItem in token.attributes {
                if attrItem.key == SimpleHTMLParserTagAttrName.color.rawValue {
                    if let color = UIColor.convertHexStringToColor(hexString: attrItem.value, alpha: 1) {
                        attrDict.updateValue(color, forKey: .foregroundColor)
                    }
                } else if attrItem.key == SimpleHTMLParserTagAttrName.size.rawValue {
                    if let font = attrDict[.font] as? UIFont {
                        if let fontSize = NumberFormatter().number(from: attrItem.value) {
                            if let newFont = UIFont(name: font.fontName, size: CGFloat(truncating: fontSize)) {
                                attrDict.updateValue(newFont, forKey: .font)
                            }
                        }
                    }
                } else {
                    throwErrorWithMessageAndExitFlow(exceptionName: "AttributedBuilder", message: "font unkown attr name \(attrItem.key)")
                }
            }
        case .b:
            if let font = attrDict[.font] as? UIFont {
                let boldFont = UIFont.boldSystemFont(ofSize: font.pointSize)
                
                attrDict.updateValue(boldFont, forKey: .font)
            } else {
                throwErrorWithMessageAndExitFlow(exceptionName: "AttributedBuilder", message: "updateAttributedDict > HTMLTag.b > attrDict.Font is nil")
            }
        case .u:
            attrDict.updateValue(NSUnderlineStyle.single.rawValue, forKey: .underlineStyle)
        case .br:
            result.append(NSAttributedString(string: "\n", attributes: attrDict))
        default :
            break
        }
    }
}
