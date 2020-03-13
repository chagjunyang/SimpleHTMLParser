//
//  UTF8StreamReader.swift
//  HTMLStringToAttributedString
//
//  Created by cjyang on 01/05/2019.
//  Copyright © 2019 cjyang. All rights reserved.
//

import UIKit

fileprivate enum ByteKind {
    case head(length: Int8)
    case body
    case invalid
    
    public init(byte: UInt8) {
        if byte & 0b1000_0000 == 0b0000_0000 {
            self = .head(length: 1)
        } else if byte & 0b1100_0000 == 0b1000_0000 {
            self = .body
        } else if byte & 0b1110_0000 == 0b1100_0000 {
            self = .head(length: 2)
        } else if byte & 0b1111_0000 == 0b1110_0000 {
            self = .head(length: 3)
        } else if byte & 0b1111_1000 == 0b1111_0000 {
            self = .head(length: 4)
        } else {
            self = .invalid
        }
    }
}

class UTF8StreamReader {
    var inputStream: InputStream!
    var bufferSize = 128
    let buffer: UnsafeMutablePointer<UInt8>
    var bufferArray: [UInt8] = [UInt8]()
    var bufferOffset: Int = 0
    
    init(data: Data) {
        buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        inputStream = InputStream(data: data)
        inputStream.open()
    }
    
    deinit {
        clearStream()
    }
    
    func clearStream() {
        buffer.deallocate()
        inputStream.close()
    }
    
    func nextString() -> String? {
        var result: String?
        
        if let headByte = readByteFromBufferArray() {
            let headByteKind = ByteKind(byte: headByte)

            if case .head(let length) = headByteKind {
                switch length {
                case 1:
                    result = String(Character(Unicode.Scalar(headByte)))
                case 2, 3, 4:
                    var value: [UInt8] = [UInt8]()
                    value.append(headByte)

                    for _ in 0..<(length - 1) {
                        if let bodyByte = readByteFromBufferArray() {
                            if case .body = ByteKind(byte: bodyByte) {
                                value.append(bodyByte)
                            }
                        }
                    }

                    if let string = String(bytes: value, encoding: .utf8) {
                        result = string
                    }
                default:
                    return nil
                }
            }
        }
        
        return result
    }
    
    func readByteFromBufferArray() -> UInt8? {
        var result: UInt8?
        
        if bufferOffset < bufferArray.count {
            result = bufferArray[bufferOffset]
            
            bufferOffset += 1
        } else {
            if readStreamToBufferArray() {
                result = bufferArray[bufferOffset]
                
                bufferOffset += 1
            }
        }
        
        return result
    }
    
    func readStreamToBufferArray() -> Bool {
        var result = false
        
        if inputStream.hasBytesAvailable {
            let readCount = inputStream.read(buffer, maxLength: bufferSize)
            
            bufferArray = Array(UnsafeBufferPointer(start: buffer, count: readCount))
            bufferOffset = 0
            
            result = true
        }
        
        return result
    }
}
