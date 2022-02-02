//
//  BloomFilter+Hasher.swift
//  
//
//  Created by Paul Ballmann on 26.01.22.
//

import Foundation
import CryptoKit

extension BloomFilter {
	/**
	 Takes either a string or a byte array and hashes it with the given hashFunction
	 */
    public class func hash(data: Data, hashFunction: HashFunctions, seed: UInt8) -> Data {

        let seedBytes = Data(withUnsafeBytes(of: seed.bigEndian, Array.init))
        
        let hashData = NSMutableData(data:data)
        hashData.append(seedBytes)
        
		switch hashFunction {
		case .SHA256:
            return SHA256.digest(input: hashData)
		case .MD5:
			return md5(data: hashData)
		}
	}
}

private func md5(data : NSData) -> Data {
    return Data() //not implemented
}

public enum HashFunctions {
	case SHA256
	case MD5
}
