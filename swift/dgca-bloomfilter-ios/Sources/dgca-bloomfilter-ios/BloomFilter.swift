//
//  File.swift
//  
//
//  Created by Paul Ballmann on 20.01.22.
//

import Foundation
import CryptoKit
import CommonCrypto

public class BloomFilter<T> {
	private var array: [Int32] // each element has 4 bytes: MemoryLayout<Int32>.size == 4 Bytes;
	
	/**
	 n -> number of items in the filter   (n = ceil(m / (-k / log(1 - exp(log(p) / k)))))
	 p -> probabilty of false positives   (p = pow(1 - exp(-k / (m / n)), k))
	 m -> number of bits in filter           (m = ceil((n * log(p)) / log(1 / pow(2, log(2))));)
	 k -> number of hash functions      (k = round((m / n) * log(2));)
	 */
	
	// private var byteSize: Int;
	private var probRate: Float;

	private let DATA_OFFSET: Int = 6;
	
	private var numberOfHashes: Int;
	private var numBits: Int;
	
	// CONST
	private let NUM_BYTES = MemoryLayout<Int32>.size; // On 32-Bit -> Int32 (4 Bytes), On 64-Bit -> Int64 (8 Bytes)
	private let NUM_BITS: Int = 8; // number of bits to use for one byte
	private let NUM_FORMAT = (MemoryLayout<Int32>.size * 8)

	
	public init(size m: Int, nHash k: Int, numElems n: Int) throws {
		if (m <= 0 || k <= 0 || n <= 0) {
			throw FilterError.invalidParameters
		}
		let size: Int = (m / NUM_BYTES) + (m % NUM_BYTES)
		// check if memory has enough free heap
		let memSize = Int(MemoryHelper().heapMemory()!)
		if (memSize <= (size * NUM_BYTES)) {
			throw FilterError.notEnoughMemory
		}
		self.numBits = size * NUM_FORMAT
		self.numberOfHashes = k
		self.probRate = pow(1 - exp(Float(-k) / (Float)(self.numBits / NUM_BITS) / Float(n)), Float(k))
		self.array = Array(repeating: 0, count: size)
	}
	
	public init(numElems n: Int, probRate p: Float) throws {
		if (n == 0 || p == 0) {
			throw FilterError.invalidParameters
		}
		self.numBits = Int(ceil((Float(n) * log(p)) / log(1 / pow(2, log(2)))))
		
		let bytes: Int = (self.numBits / NUM_BITS) + 1
		let size: Int = (bytes / NUM_BYTES) + (bytes % NUM_BYTES)
		self.numBits = size * NUM_FORMAT
		if (size <= 0) {
			throw FilterError.invalidSize
		}
		
		let memSize = Int(MemoryHelper().heapMemory()!)
		if (memSize <= (size * NUM_BYTES)) {
			throw FilterError.notEnoughMemory
		}
		
		// self.numberOfHashes = Int(max(1, round(Float(self.numBits) / Float(n) * log(2))Float(self.numBits))
		self.numberOfHashes = Int(max(1, round(Float(self.numBits) / Float(n) * log(2))))
		/// TODO: Too many hashes error
		self.probRate = p
		self.array = Array(repeating: 0, count: size)
	}
	
	public class func add(element: [UInt8]) {
		
	}
	
	public class func mightContain() -> Bool {
		return false;
	}
	
	public class func hash(bytes: [UInt8]) throws -> String {
		if let data = String(bytes: bytes, encoding: .utf8) {
			let hashed = data.sha1(seed: 1);
			
		} else {
			throw FilterError.invalidEncoding
		}
		return "hash"
	}
	
}

extension String {
	func sha1(seed s: Int32) -> String {
		let toHash = self + String(s)
		let data = Data(toHash.utf8)
		
		var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
		data.withUnsafeBytes {
			_ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
		}
		let hexBytes = digest.map { String(format: "%02hhx", $0) }
		return hexBytes.joined()
	}
}

/// REGION: Utility
extension BloomFilter {
	class func calcNValue(m: Int, k: Int, p: Float) -> Int {
		let x = log(1 - exp(log(p) / Float(k)))
		let f = Double(m / (-k / Int(x)))
		return Int(ceil(f))
	}
	
	class func calcProbValue(byteCount m: Int, numberOfElements n: Int, numberOfHashes k: Int) -> Float {
		let f = Double(-k / (m / n))
		let x = exp(f)
		return Float(pow(1 - x, Double(k)))
	}
	
	class func calcMValue(n: Int, p: Float) -> Int {
		// m = ceil((n * log(p)) / log(1 / pow(2, log(2))));)
		let x = (Float(n) * log(p))
		return Int(ceil(x / log(1 / pow(2, log(2)))))
	}
	
	class func calcKValue(m: Int, n: Int) -> Int {
		// k = round((m / n) * log(2))
		return Int(round(Float((m / n)) * log(2)))
	}
}
/// ENDREGION
