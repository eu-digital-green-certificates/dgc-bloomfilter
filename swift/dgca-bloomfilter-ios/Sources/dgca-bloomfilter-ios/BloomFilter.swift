//
//  File.swift
//  
//
//  Created by Paul Ballmann on 20.01.22.
//

import Foundation
import BigInt
public class BloomFilter {
	private var array: [Int32] // each element has 4 bytes: MemoryLayout<Int32>.size == 4 Bytes;
	
	/**
	 n -> number of items in the filter   (n = ceil(m / (-k / log(1 - exp(log(p) / k)))))
	 p -> probabilty of false positives   (p = pow(1 - exp(-k / (m / n)), k))
	 m -> number of bits in filter           (m = ceil((n * log(p)) / log(1 / pow(2, log(2))));)
	 k -> number of hash functions      (k = round((m / n) * log(2));)
	 */
	
	// private var byteSize: Int;
	private var probRate: Float = 0.0

	private let DATA_OFFSET: UInt = 6

	private var numberOfHashes: UInt8
	private var numBits: UInt32
	
	private var currentElementAmount: UInt16 = 0
	private var definedElementAmount: UInt16
	
	private var usedHashFunction: UInt8 = 0
	
	// CONST
    private let NUM_BYTES : UInt16 = UInt16(MemoryLayout<UInt16>.size) // On 32-Bit -> Int32 (4 Bytes), On 64-Bit -> Int64 (8 Bytes)
	private let NUM_BITS: UInt16 = 8 // number of bits to use for one byte
    private let NUM_FORMAT: UInt16 = UInt16((MemoryLayout<UInt32>.size * 8))
	private var VERSION: Int64 = 7526472295622776147
    private var version: UInt8 = 1
	
	public init(size m: UInt16, nHash k: UInt8, numElems n: UInt16) throws {
		if (m <= 0 || k <= 0 || n <= 0) {
			throw FilterError.invalidParameters
		}
		let size: UInt16 = (m / NUM_BYTES) + (m % NUM_BYTES)
		// check if memory has enough free heap
		let memSize = Int(MemoryHelper().heapMemory()!)
		if (memSize <= (size * NUM_BYTES)) {
			throw FilterError.notEnoughMemory
		}
		self.numBits = UInt32(size * NUM_FORMAT)
		self.numberOfHashes = k
		if self.numberOfHashes > Int32.max {
			throw FilterError.tooManyHashRounds
		}
        self.probRate = BloomFilter.calcProbValue(numBits: numBits, numberOfElements: n, numberOfHashes: k)
		self.definedElementAmount = n
        self.array = Array(repeating: 0, count: Int(size))
	}
	
	public init(numElems n: UInt16, probRate p: Float) throws {
		if (n == 0 || p == 0) {
			throw FilterError.invalidParameters
		}
        self.numBits = UInt32(BloomFilter.calcMValue(n: n, p: p))
		
		let bytes: UInt16 = UInt16(self.numBits / UInt32(NUM_BITS + 1))
        let size: UInt16 = UInt16((bytes / NUM_BYTES) + (bytes % NUM_BYTES))
		self.numBits = UInt32(size * NUM_FORMAT)
		if (size <= 0) {
			throw FilterError.invalidSize
		}
		
		let memSize = Int(MemoryHelper().heapMemory()!)
		if (memSize <= (size * NUM_BYTES)) {
			throw FilterError.notEnoughMemory
		}
		
		// self.numberOfHashes = Int(max(1, round(Float(self.numBits) / Float(n) * log(2))Float(self.numBits))
        self.numberOfHashes = BloomFilter.calcKValue(m: numBits, n: n)
		if self.numberOfHashes > Int32.max {
			throw FilterError.tooManyHashRounds
		}
		self.probRate = p
		self.definedElementAmount = n
        self.array = Array(repeating: 0, count: Int(size))
	}
	
    public func add(element: Data) throws {
		for i in 0..<self.numberOfHashes {
			let bytesIdx = try BloomFilter.calcIndex(element: element, index: UInt8(i), numberOfBits: self.numBits).asMagnitudeBytes()
            
            let data = Data(_: bytesIdx)
            var index = UInt32(littleEndian: data.withUnsafeBytes { $0.pointee })
            
            let bytePos = index / UInt32(self.NUM_FORMAT)
			index -= bytePos * UInt32(NUM_FORMAT)
            let pattern = Int32.min >>> (index-1)
            self.array[Int(bytePos)] = self.array[Int(bytePos)] | pattern;
		}
		currentElementAmount += 1;
		
		if currentElementAmount >= definedElementAmount {
			//Logger necessary, no exception
			print("BloomFilter full.")
		}
	}
	
	public func mightContain(element: Data) throws -> Bool {
		var result = true
		for i in 0..<self.numberOfHashes {
			let bytesIdx = try BloomFilter.calcIndex(element: element, index: UInt8(i), numberOfBits: self.numBits).asMagnitudeBytes()
            
            let data = Data(_: bytesIdx)
            var index = UInt32(littleEndian: data.withUnsafeBytes { $0.pointee })
            
            let bytePos = index / UInt32(self.NUM_FORMAT)
            index -= bytePos * UInt32(NUM_FORMAT)
            let pattern = Int32.min >>> (index - 1)
            if (self.array[Int(bytePos)] & pattern) == pattern {
				result = result && true
			} else {
				result = result && false
				break
			}
		}
		return result;
	}
    
    public func getData()-> [Int32]
    {
        return array;
    }

	public static func calcIndex(element: Data, index: UInt8, numberOfBits: UInt32) throws -> BInt {
        let hash = try BloomFilter.hash(data:element, hashFunction: HashFunctions.SHA256, seed: index)
        let hashInt = BigInt.BInt.init(signed: Array(hash))
        let nBytes = withUnsafeBytes(of: numberOfBits.bigEndian, Array.init)
        return hashInt.mod(BInt(signed:nBytes));
	}
	
	public func readFrom(stream: Data) throws {
        version = stream.withUnsafeBytes {$0.load(as: UInt8.self)}
        numberOfHashes = stream.withUnsafeBytes {$0.load(as: UInt8.self)}
        usedHashFunction = stream.withUnsafeBytes {$0.load(as: UInt8.self)}
        probRate = stream.withUnsafeBytes {$0.load(as: Float.self)}
        definedElementAmount = UInt16(stream.withUnsafeBytes {$0.load(as: UInt32.self)})
        currentElementAmount = UInt16(stream.withUnsafeBytes {$0.load(as: UInt32.self)})
        let datalength = stream.withUnsafeBytes {$0.load(as: UInt32.self)}
        array.removeAll()
        
        for _ in 0...datalength {
            let newElement = stream.withUnsafeBytes {$0.load(as: Int32.self)}
            array.append(newElement)
        }
        
        numBits = UInt32( UInt16(stream.count) * NUM_FORMAT);
	}
}

infix operator >>> : BitwiseShiftPrecedence

func >>> (lhs: Int32, rhs: UInt32) -> Int32 {
    return Int32(bitPattern: UInt32(bitPattern: lhs) >> UInt32(rhs))
}

public extension BloomFilter  {
    
    class func calcProbValue(numBits: UInt32, numberOfElements n: UInt16, numberOfHashes k: UInt8) -> Float {
        return Float(pow(1 - exp(Float(-Int8(k)) / (Float)(numBits / 8) / Float(n)), Float(k)))
    }
    
    class func calcMValue(n: UInt16, p: Float) -> UInt32 {
        return UInt32(ceil((Float(n) * log(p)) / log(1 / pow(2, log(2)))))
    }
    
    class func calcKValue(m: UInt32, n: UInt16) -> UInt8 {
        return UInt8(max(1, round(Float(m) / Float(n) * log(2))))
    }
    
}