//
//  File.swift
//  
//
//  Created by Paul Ballmann on 20.01.22.
//

import Foundation
import CommonCrypto


public class BloomFilter<T> {
	private var array: [UInt32] // each element has 4 bytes: MemoryLayout<Int32>.size == 4 Bytes;
	
	/**
	 n -> number of items in the filter   (n = ceil(m / (-k / log(1 - exp(log(p) / k)))))
	 p -> probabilty of false positives   (p = pow(1 - exp(-k / (m / n)), k))
	 m -> number of bits in filter           (m = ceil((n * log(p)) / log(1 / pow(2, log(2))));)
	 k -> number of hash functions      (k = round((m / n) * log(2));)
	 */
	
	// private var byteSize: Int;
	private var probRate: Double = 0.0;

	private let DATA_OFFSET: Int = 6;
	
	private var numberOfHashes: Int;
	private var numBits: Int;
	
	private var currentElementAmount: Int = 0;
	private var definedElementAmount: Int;
	
	private var usedHashFunction: UInt8 = 0;
	
	// CONST
	private let NUM_BYTES = MemoryLayout<UInt32>.size; // On 32-Bit -> Int32 (4 Bytes), On 64-Bit -> Int64 (8 Bytes)
	private let NUM_BITS: Int32 = 8; // number of bits to use for one byte
	private let NUM_FORMAT: Int = (MemoryLayout<Int32>.size * 8)
	private var VERSION: Int64 = 7526472295622776147;
	
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
		if self.numberOfHashes > Int32.max {
			throw FilterError.tooManyHashRounds
		}
		self.probRate = BloomFilter<T>.calcProbValue(numBits: numBits, numberOfElements: n, numberOfHashes: k)
		self.definedElementAmount = n
		self.array = Array(repeating: 0, count: size)
	}
	
	public init(numElems n: Int, probRate p: Double) throws {
		if (n == 0 || p == 0) {
			throw FilterError.invalidParameters
		}
		self.numBits = BloomFilter<T>.calcMValue(n: n, p: p)
		
		let bytes: Int = (self.numBits / Int(NUM_BITS)) + 1
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
		self.numberOfHashes = BloomFilter<T>.calcKValue(m: numBits, n: n)
		if self.numberOfHashes > Int32.max {
			throw FilterError.tooManyHashRounds
		}
		self.probRate = p
		self.definedElementAmount = n
		self.array = Array(repeating: 0, count: size)
	}
	
	public func add(element: [UInt8]) throws {
		for i in 0..<self.numberOfHashes {
			var index = try self.calcIndex(element: element, index: i, numberOfBits: self.numBits)
			let bytePos = index / self.NUM_FORMAT
			index -= bytePos * NUM_FORMAT
			let pattern = UInt32.min >> index - 1
			self.array[bytePos] = self.array[bytePos] | pattern;
		}
		currentElementAmount += 1;
		
		if currentElementAmount >= definedElementAmount {
			throw FilterError.filledFilter
		}
	}
	
	public func mightContain(element: [UInt8]) throws -> Bool {
		var result = true
		for i in 0..<self.numberOfHashes {
			var index = try self.calcIndex(element: element, index: i, numberOfBits: self.numBits)
			let bytePos: Int = index / self.NUM_FORMAT
			index -= bytePos * NUM_FORMAT
			let pattern = UInt32.min >> index - 1
			if (self.array[bytePos] & pattern) == pattern {
				result = result && true
			} else {
				result = result && false
				break
			}
		}
		return result;
	}

	private func calcIndex(element: [UInt8], index: Int, numberOfBits: Int) throws -> Int {
		let hashSource = try BloomFilter.hash(nil, element, hashFunction: HashFunctions.SHA512, seed: index)
		return hashSource % numberOfBits
	}
	
	public func readFrom(stream: InputStream) throws {
		let metaLength = 20, dataLengthOffset = 16
		let byteLength = 1, shortLength = 2, doubleLength = 8;
		// read meta data first
		let metaData = try stream.readData(withLength: metaLength)

		// get the data length from the metaData
		let dataLength: Int = metaData.subdata(in: Range(dataLengthOffset...metaLength)).withUnsafeBytes {
			$0.load(as: Int.self)
		}
		// now read all data from stream that is array
		let dataStream = try stream.readData(withLength: metaLength + dataLength)
		
		let arrayData = dataStream.subdata(in: Range(metaLength...dataLength)).withUnsafeBytes {
			$0.load(as: [UInt32].self)
		}
		// get all data we need from metaData and from arrayData
		let rangePtr: ClosedRange<Int> = (0...shortLength)
		
		let version = metaData.subdata(in: Range(rangePtr)).withUnsafeBytes {
			$0.load(as: Int64.self)
		}
		
		let usedHashFunction = metaData.subdata(in: Range(rangePtr)).withUnsafeBytes {
			$0.load(as: UInt8.self)
		}
		
		let numberOfHashes = metaData.subdata(in: Range(rangePtr.shiftRange(by: byteLength))).withUnsafeBytes {
			$0.load(as: Int.self)
		}
		
		let probRate = metaData.subdata(in: Range(rangePtr.shiftRange(by: doubleLength))).withUnsafeBytes {
			$0.load(as: Double.self)
		}
		
		let definedElementAmount = metaData.subdata(in: Range(rangePtr.shiftRange(by: doubleLength))).withUnsafeBytes {
			$0.load(as: Int.self)
		}
		
		let currentElementAmount = metaData.subdata(in: Range(rangePtr.shiftRange(by: doubleLength))).withUnsafeBytes {
			$0.load(as: Int.self)
		}
		// done reading all data needed
		self.VERSION = version
		self.usedHashFunction = usedHashFunction
		self.numberOfHashes = numberOfHashes
		self.probRate = probRate
		self.definedElementAmount = definedElementAmount
		self.currentElementAmount = currentElementAmount
		// self.array = arrayData
		self.array = Array(repeating: 0, count: dataLength)
		for index in 0..<dataLength {
			self.array[index] = arrayData[index]
		}
		// data stored. done.
		
	}
	
}

extension ClosedRange where Bound == Int {
	public func shiftRange(by offset: Int) -> ClosedRange<Int> {
		let lowerBound = self.upperBound
		let upperBound = self.upperBound + offset
		return (lowerBound...upperBound)
	}
}


/// REGION: Utility
extension BloomFilter {
	/*
	public func calcNValue(m: Int, k: Int, p: Double) -> Int {
		let x = log(1 - exp(log(p) / Float(k)))
		let f = Double(m / (-k / Int(x)))
		return Int(ceil(f))
	}
	 */
	
	public class func calcProbValue(numBits: Int, numberOfElements n: Int, numberOfHashes k: Int) -> Double {
		return Double(pow(1 - exp(Float(-k) / (Float)(numBits / 8) / Float(n)), Float(k)))
	}
	
	public class func calcMValue(n: Int, p: Double) -> Int {
		return Int(ceil((Double(n) * log(p)) / log(1 / pow(2, log(2)))))
	}
	
	public class func calcKValue(m: Int, n: Int) -> Int {
		return Int(max(1, round(Float(m) / Float(n) * log(2))))
	}
}
/// ENDREGION
