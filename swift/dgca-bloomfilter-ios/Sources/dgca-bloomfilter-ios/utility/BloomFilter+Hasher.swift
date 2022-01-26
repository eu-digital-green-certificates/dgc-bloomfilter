//
//  File.swift
//  
//
//  Created by Paul Ballmann on 26.01.22.
//

import Foundation
import CryptoKit
import CommonCrypto

extension BloomFilter {
	/**
	 Takes either a string or a byte array and hashes it with the given hashFunction
	 */
	func hash(string: String?, bytes: [UInt8]?, hashFunction: HashFunctions) -> Data {
		// set the length of hash function first
		let length: Int
		let messageData, var digestData: Data
		
		switch hashFunction {
		case .SHA512:
			length = CC_SHA256_DIGEST_LENGTH
		case .MD5:
			length = CC_MD5_DIGEST_LENGTH
		default:
			throw FilterError.unsupportedCryptoFunction
		}
		
		let stringSource: String;
		
		if string != null {
			guard stringSource = string else {
				throw FilterError.unknownError
			}
		}
		
		if bytes != null {
			guard stringSource = String(data: bytes, encoding: .utf8) else {
				throw FilterError.invalidEncoding
			}
		}
		
		guard stringSource != null else {
			throw FilterError.unknownError
		}
		
		messageData = stringSource.data(using: .utf8)
		digestData = Data(count: length)
		
		_ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
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
		}
		return digestData
	}
}

enum HashFunctions {
	case SHA512
	case MD5
}
