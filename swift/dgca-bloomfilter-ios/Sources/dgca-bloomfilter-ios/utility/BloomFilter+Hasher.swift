//
//  File.swift
//  
//
//  Created by Paul Ballmann on 26.01.22.
//

import Foundation
import CommonCrypto

extension BloomFilter {
	/**
	 Takes either a string or a byte array and hashes it with the given hashFunction
	 */
	public class func hash(_ string: String?, _ bytes: [UInt8]?, hashFunction: HashFunctions, seed: Int) throws -> Int {
		// set the length of hash function first
		let length: Int
		var messageData: Data = Data()
		var digestData: Data
		
		switch hashFunction {
		case .SHA512:
			length = Int(CC_SHA256_DIGEST_LENGTH)
		case .MD5:
			length = Int(CC_MD5_DIGEST_LENGTH)
		
		}
		
		var stringSource: String = "";
		
		if string != nil {
			stringSource = string! + String(seed)
		}
		
		if bytes != nil {
			// concat with bigEndian
			let indexArray = withUnsafeBytes(of: seed.bigEndian, Array.init)
			var concatBytes = bytes!;
			concatBytes.append(contentsOf: indexArray)
			if let s = String(data: Data(concatBytes), encoding: .utf8) {
				stringSource = s
			}
		}
		if stringSource == "" { throw FilterError.unknownError }
		if let s = stringSource.data(using: .utf8) {
			messageData = s
		}
		
		digestData = Data(count: length)
		
		_ = digestData.withUnsafeMutableBytes ({ digestBytes -> UInt8 in
			messageData.withUnsafeBytes { messageBytes -> UInt8 in
				if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
					let messageLength = CC_LONG(messageData.count)
					switch hashFunction {
					case .SHA512:
						CC_SHA256(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
					case .MD5:
						CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
					}
				}
				return 0
			}
		})
		
		return 1;
	}
}

public enum HashFunctions {
	case SHA512
	case MD5
}
