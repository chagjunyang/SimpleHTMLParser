//
//  SimpleHTMLParser.swift
//  HTMLStringToAttributedString
//
//  Created by cjyang on 15/05/2019.
//  Copyright © 2019 cjyang. All rights reserved.
//

import UIKit

fileprivate typealias StackItem = (SimpleHTMLParserTagName, [NSAttributedString.Key : Any]?)

enum SimpleHTMLParserTagState {
    case open
    case close
    case selfClose
}

enum SimpleHTMLParserTagName: String {
    case unknown
    case font
    case br
    case b
    case u
}

enum SimpleHTMLParserTagAttrName: String {
    case color
    case size
}

class SimpleHTMLToken {
    var tagName: SimpleHTMLParserTagName
    var attributes: [String : String]
    
    init() {
        tagName = .unknown
        attributes = [String : String]()
    }
    
    func clearToken() {
        tagName = .unknown
        attributes.removeAll()
    }
}

protocol SimpleHTMLParserDelegate: class {
    func startTag(token: SimpleHTMLToken)
    func endTag(token: SimpleHTMLToken)
    func parsedText(_ text: String)
}

enum SimpleHTMLParserStateV2 {
    case collectText
    case collectStartingTagName
    case collectCloseTagName
    case collectTagNameFontF
    case collectTagNameFontO
    case collectTagNameFontN
    case collectTagNameFontT
    case collectTagNameB
    case collectTagNameBR
    case collectTagNameU
    case selfCloseTag
    case collectAttrKey
    case startCollectingAttrValue
    case collectAttrValue
    case confirmMoreAttribute
}

extension SimpleHTMLParserStateV2 {
    static let stateToTransitionTableMapper =
        [SimpleHTMLParserStateV2.collectText : SimpleHTMLParserStateTransitionTable.collectText,
         SimpleHTMLParserStateV2.collectStartingTagName : SimpleHTMLParserStateTransitionTable.collectStartingTagName,
         SimpleHTMLParserStateV2.collectCloseTagName : SimpleHTMLParserStateTransitionTable.collectCloseTagName,
         SimpleHTMLParserStateV2.collectTagNameFontF : SimpleHTMLParserStateTransitionTable.collectTagNameFontF,
         SimpleHTMLParserStateV2.collectTagNameFontO : SimpleHTMLParserStateTransitionTable.collectTagNameFontO,
         SimpleHTMLParserStateV2.collectTagNameFontN : SimpleHTMLParserStateTransitionTable.collectTagNameFontN,
         SimpleHTMLParserStateV2.collectTagNameFontT : SimpleHTMLParserStateTransitionTable.collectTagNameFontT,
         SimpleHTMLParserStateV2.collectTagNameB : SimpleHTMLParserStateTransitionTable.collectTagNameB,
         SimpleHTMLParserStateV2.collectTagNameBR : SimpleHTMLParserStateTransitionTable.collectTagNameBR,
         SimpleHTMLParserStateV2.collectTagNameU : SimpleHTMLParserStateTransitionTable.collectTagNameU,
         SimpleHTMLParserStateV2.selfCloseTag : SimpleHTMLParserStateTransitionTable.selfCloseTag,
         SimpleHTMLParserStateV2.collectAttrKey : SimpleHTMLParserStateTransitionTable.collectAttrKey,
         SimpleHTMLParserStateV2.startCollectingAttrValue : SimpleHTMLParserStateTransitionTable.startCollectingAttrValue,
         SimpleHTMLParserStateV2.collectAttrValue : SimpleHTMLParserStateTransitionTable.collectAttrValue,
         SimpleHTMLParserStateV2.confirmMoreAttribute : SimpleHTMLParserStateTransitionTable.confirmMoreAttribute]
    
    func transitionTable() -> [String : SimpleHTMLParserStateV2]? {
        return SimpleHTMLParserStateV2.stateToTransitionTableMapper[self]
    }
}

class SimpleHTMLParserStateTransitionTable {
    typealias TableType = [String : SimpleHTMLParserStateV2]
    
    static let collectText: TableType = ["<" : SimpleHTMLParserStateV2.collectStartingTagName]
    
    static let collectStartingTagName: TableType = ["/" : SimpleHTMLParserStateV2.collectCloseTagName,
                                                    "f" : SimpleHTMLParserStateV2.collectTagNameFontF,
                                                    "F" : SimpleHTMLParserStateV2.collectTagNameFontF,
                                                    "b" : SimpleHTMLParserStateV2.collectTagNameB,
                                                    "B" : SimpleHTMLParserStateV2.collectTagNameB,
                                                    "u" : SimpleHTMLParserStateV2.collectTagNameU,
                                                    "U" : SimpleHTMLParserStateV2.collectTagNameU,
                                                    " " : SimpleHTMLParserStateV2.collectStartingTagName]
    
    static let collectCloseTagName: TableType = ["f" : SimpleHTMLParserStateV2.collectTagNameFontF,
                                                 "F" : SimpleHTMLParserStateV2.collectTagNameFontF,
                                                 "b" : SimpleHTMLParserStateV2.collectTagNameB,
                                                 "B" : SimpleHTMLParserStateV2.collectTagNameB,
                                                 "u" : SimpleHTMLParserStateV2.collectTagNameU,
                                                 "U" : SimpleHTMLParserStateV2.collectTagNameU,
                                                 " " : SimpleHTMLParserStateV2.collectCloseTagName]
    
    static let collectTagNameFontF: TableType = ["o" : SimpleHTMLParserStateV2.collectTagNameFontO,
                                                 "O" : SimpleHTMLParserStateV2.collectTagNameFontO]
    
    static let collectTagNameFontO: TableType = ["n" : SimpleHTMLParserStateV2.collectTagNameFontN,
                                                 "N" : SimpleHTMLParserStateV2.collectTagNameFontN]
    
    static let collectTagNameFontN: TableType = ["t" : SimpleHTMLParserStateV2.collectTagNameFontT,
                                                 "T" : SimpleHTMLParserStateV2.collectTagNameFontT]
    
    static let collectTagNameFontT: TableType = ["/" : SimpleHTMLParserStateV2.selfCloseTag,
                                                 ">" : SimpleHTMLParserStateV2.collectText,
                                                 " " : SimpleHTMLParserStateV2.collectAttrKey]
    
    static let collectTagNameB: TableType = ["r" : SimpleHTMLParserStateV2.collectTagNameBR,
                                             "R" : SimpleHTMLParserStateV2.collectTagNameBR,
                                             "/" : SimpleHTMLParserStateV2.selfCloseTag,
                                             ">" : SimpleHTMLParserStateV2.collectText,
                                             " " : SimpleHTMLParserStateV2.collectTagNameB]
    
    static let collectTagNameBR: TableType = ["/" : SimpleHTMLParserStateV2.selfCloseTag,
                                              ">" : SimpleHTMLParserStateV2.collectText,
                                              " " : SimpleHTMLParserStateV2.collectTagNameBR]
    
    static let collectTagNameU: TableType = ["/" : SimpleHTMLParserStateV2.selfCloseTag,
                                             ">" : SimpleHTMLParserStateV2.collectText,
                                             " " : SimpleHTMLParserStateV2.collectTagNameU]
    
    static let selfCloseTag: TableType = [">" : SimpleHTMLParserStateV2.collectText,
                                          " " : SimpleHTMLParserStateV2.selfCloseTag]
    
    static let collectAttrKey: TableType = ["=" : SimpleHTMLParserStateV2.startCollectingAttrValue,
                                            " " : SimpleHTMLParserStateV2.collectAttrKey]
    
    static let startCollectingAttrValue: TableType = ["'" : SimpleHTMLParserStateV2.collectAttrValue,
                                                      "\"" : SimpleHTMLParserStateV2.collectAttrValue,
                                                      " " : SimpleHTMLParserStateV2.startCollectingAttrValue]
    
    static let collectAttrValue: TableType = ["#" : SimpleHTMLParserStateV2.collectAttrValue,
                                              " " : SimpleHTMLParserStateV2.collectAttrValue,
                                              "\\" : SimpleHTMLParserStateV2.collectAttrValue,
                                              "'" : SimpleHTMLParserStateV2.confirmMoreAttribute,
                                              "\"" : SimpleHTMLParserStateV2.confirmMoreAttribute]
    
    static let confirmMoreAttribute: TableType = [" " : SimpleHTMLParserStateV2.collectAttrKey,
                                                  "/" : SimpleHTMLParserStateV2.selfCloseTag,
                                                  "\\" : SimpleHTMLParserStateV2.confirmMoreAttribute,
                                                  ">" : SimpleHTMLParserStateV2.collectText]
}

class SimpleHTMLParser {
    var token: SimpleHTMLToken = SimpleHTMLToken()
    var tagState: SimpleHTMLParserTagState = .open
    var streamReader: UTF8StreamReader!
    
    var text: String = ""
    var attrName: String = ""
    var attrValue: String = ""
    
    weak var delegate: SimpleHTMLParserDelegate?

    init(htmlString: String, _delegate: SimpleHTMLParserDelegate) {
        if let data = htmlString.data(using: .utf8) {
            streamReader = UTF8StreamReader(data: data)
            
            delegate = _delegate
        } else {
            throwErrorWithMessageAndExitFlow(exceptionName: "SimpleHTMLParser", message: "[init] convert htmlString to Data fail")
        }
    }
    
    func startParsing() {
        var currentState = SimpleHTMLParserStateV2.collectText
        var nextString = streamReader.nextString()
        
        while nextString != nil {
            guard let _nextString = nextString else {
                break;
            }
            
            let transitionTable = currentState.transitionTable()
            
            switch currentState {
            case .collectText:
                if let nextState = transitionTable?[_nextString] {
                    if text.count > 0 {
                        delegate?.parsedText(text)
                        text = ""
                    }
                    
                    currentState = nextState
                } else {
                    text.append(_nextString)
                }
            case .collectStartingTagName:
                tagState = .open
                
                if let nextState = transitionTable?[_nextString] {
                    currentState = nextState
                } else {
                    throwErrorWithMessageAndExitFlow(exceptionName: "CollectStartingTagName", message: "unkown tag name input character " + _nextString)
                }
            case .collectCloseTagName:
                tagState = .close
                
                if let nextState = transitionTable?[_nextString] {
                    currentState = nextState
                } else {
                    throwErrorWithMessageAndExitFlow(exceptionName: "CollectCloseTagName", message: "unkown tag name input character " + _nextString)
                }
            case .collectTagNameFontF:
                if let nextState = transitionTable?[_nextString] {
                    currentState = nextState
                } else {
                    throwErrorWithMessageAndExitFlow(exceptionName: "CollectTagNameFontF", message: "unkown tag name input character " + _nextString)
                }
            case .collectTagNameFontO:
                if let nextState = transitionTable?[_nextString] {
                    currentState = nextState
                } else {
                    throwErrorWithMessageAndExitFlow(exceptionName: "CollectTagNameFontO", message: "unkown tag name input character " + _nextString)
                }
            case .collectTagNameFontN:
                if let nextState = transitionTable?[_nextString] {
                    currentState = nextState
                } else {
                    throwErrorWithMessageAndExitFlow(exceptionName: "CollectTagNameFontN", message: "unkown tag name input character " + _nextString)
                }
            case .collectTagNameFontT:
                token.tagName = .font
                
                if let nextState = transitionTable?[_nextString] {
                    if nextState == .collectText {
                        endTagAction()
                    }
                    
                    currentState = nextState
                } else {
                    throwErrorWithMessageAndExitFlow(exceptionName: "CollectTagNameFontT", message: "unkown tag name input character " + _nextString)
                }
            case .collectTagNameB:
                token.tagName = .b
                
                if let nextState = transitionTable?[_nextString] {
                    if nextState == .collectText {
                        endTagAction()
                    }
                    
                    currentState = nextState
                } else {
                    throwErrorWithMessageAndExitFlow(exceptionName: "CollectTagNameB", message: "unkown tag name input character " + _nextString)
                }
            case .collectTagNameBR:
                token.tagName = .br
                
                if let nextState = transitionTable?[_nextString] {
                    if nextState == .collectText {
                        tagState = .selfClose
                        
                        endTagAction()
                    }
                    
                    currentState = nextState
                } else {
                    throwErrorWithMessageAndExitFlow(exceptionName: "CollectTagNameBR", message: "unkown tag name input character " + _nextString)
                }
            case .collectTagNameU:
                token.tagName = .u
                
                if let nextState = transitionTable?[_nextString] {
                    if nextState == .collectText {
                        endTagAction()
                    }
                    
                    currentState = nextState
                } else {
                    throwErrorWithMessageAndExitFlow(exceptionName: "CollectTagNameU", message: "unkown tag name input character " + _nextString)
                }
            case .selfCloseTag:
                tagState = .selfClose
                
                if let nextState = transitionTable?[_nextString] {
                    if nextState == .collectText {
                        endTagAction()
                    }
                    
                    currentState = nextState
                } else {
                    throwErrorWithMessageAndExitFlow(exceptionName: "SelfCloseTag", message: "unkown tag name input character " + _nextString)
                }
            case .collectAttrKey:
                if let nextState = transitionTable?[_nextString] {
                    currentState = nextState
                } else {
                    attrName.append(_nextString)
                }
            case .startCollectingAttrValue:
                if let nextState = transitionTable?[_nextString] {
                    currentState = nextState
                } else {
                    throwErrorWithMessageAndExitFlow(exceptionName: "StartCollectingAttrValue", message: "unkown tag name input character " + _nextString)
                }
            case .collectAttrValue:
                if let nextState = transitionTable?[_nextString] {
                    if nextState == .confirmMoreAttribute {
                        token.attributes.updateValue(attrValue.lowercased(), forKey: attrName.lowercased())
                        attrValue = ""
                        attrName = ""
                    }
                    
                    currentState = nextState
                } else {
                    attrValue.append(_nextString)
                }
            case .confirmMoreAttribute:
                if let nextState = transitionTable?[_nextString] {
                    if nextState == .collectText {
                        endTagAction()
                    }
                    
                    currentState = nextState
                } else {
                    throwErrorWithMessageAndExitFlow(exceptionName: "confirmMoreAttribute", message: "unkown tag name input character " + _nextString)
                }

            }
            
            nextString = streamReader.nextString()
        }
        
        if text.count > 0 {
            delegate?.parsedText(text)
            text = ""
        }
        
        if currentState == .collectText{
            if attrValue.isEmpty == false || attrName.isEmpty == false {
                throwErrorWithMessageAndExitFlow(exceptionName: "SimpleParser", message: "attribute value is not empty")
            }
        } else {
            throwErrorWithMessageAndExitFlow(exceptionName: "SimpleParser", message: "end state is not collectTextState")
        }
    }
    
    func endTagAction() {
        switch tagState {
        case .open:
            delegate?.startTag(token: token)
            token.clearToken()
        case .close:
            delegate?.endTag(token: token)
            token.clearToken()
        case .selfClose:
            delegate?.startTag(token: token)
            delegate?.endTag(token: token)
            token.clearToken()
        }
    }
}

