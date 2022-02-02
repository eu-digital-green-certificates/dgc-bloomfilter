//
//  BloomFilter.swift
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
	
	// private var byteSize: Int
	private var probRate: Float = 0.0
    private var version: UInt8 = 1

	private var numberOfHashes: UInt8
	private var numBits: UInt32
	
	private var currentElementAmount: UInt16 = 0
	private var definedElementAmount: UInt16
    private var usedHashFunction: UInt8 = 0

	// CONST
    private let NUM_BYTES : UInt16 = UInt16(MemoryLayout<UInt16>.size)  // On 32-Bit -> Int32 (4 Bytes), On 64-Bit -> Int64 (8 Bytes)
	private let NUM_BITS: UInt16 = 8     // number of bits to use for one byte
    private let NUM_FORMAT: UInt16 = UInt16((MemoryLayout<UInt32>.size * 8))

	public init(memorySize: UInt16, hashesNumber: UInt8, elementsNumber: UInt16) throws {
        guard memorySize > 0 && hashesNumber > 0 && elementsNumber > 0 else { throw FilterError.invalidParameters }
        guard hashesNumber < Int32.max else { throw FilterError.tooManyHashRounds }

        self.numberOfHashes = hashesNumber
        
        let size: UInt16 = (memorySize / NUM_BYTES) + (memorySize % NUM_BYTES)
		self.numBits = UInt32(size * NUM_FORMAT)

        self.probRate = BloomFilter.calcProbValue(numBits: numBits, numberOfElements: elementsNumber, numberOfHashes: hashesNumber)
		self.definedElementAmount = elementsNumber
        self.array = Array(repeating: 0, count: Int(size))
	}
	
	public init(elementsNumber: UInt16, probabilityRate: Float) throws {
        guard elementsNumber > 0 && probabilityRate > 0.0 else { throw FilterError.invalidParameters }

        self.probRate = probabilityRate
        self.definedElementAmount = elementsNumber
        
        let bitsNumber = UInt32(BloomFilter.calcMValue(n: elementsNumber, p: probabilityRate))
		let byteAmount: UInt16 = UInt16(bitsNumber / UInt32(NUM_BITS + 1))
        let size: UInt16 = UInt16((byteAmount / NUM_BYTES) + (byteAmount % NUM_BYTES))
		guard size > 0 else { throw FilterError.invalidSize }
        
        self.numBits = UInt32(size * NUM_FORMAT)
        
        let hashesNumber = BloomFilter.calcKValue(m: numBits, n: elementsNumber)
		guard hashesNumber < Int32.max else { throw FilterError.tooManyHashRounds }
        self.numberOfHashes = hashesNumber
        
        self.array = Array(repeating: 0, count: Int(size))
	}
	
    public func add(element: Data) {
		for i in 0..<self.numberOfHashes {
            let bytesIdx = BloomFilter.calcIndex(element: element, index: UInt8(i), numberOfBits: self.numBits).asMagnitudeBytes()
            
            let data = Data(bytesIdx)
            var index = UInt32(littleEndian: data.withUnsafeBytes { $0.load(as: UInt32.self) })
            
            let bytePos = index / UInt32(NUM_FORMAT)
			index -= bytePos * UInt32(NUM_FORMAT)
            let pattern = Int32.min >>> (index-1)
            self.array[Int(bytePos)] = array[Int(bytePos)] | pattern
		}
		currentElementAmount += 1
		if currentElementAmount >= definedElementAmount {
			//Logger necessary, no exception
		}
	}
	
	public func mightContain(element: Data) -> Bool {
		for i in 0..<self.numberOfHashes {
            let bytesIdx = BloomFilter.calcIndex(element: element, index: UInt8(i), numberOfBits: self.numBits).asMagnitudeBytes()
            
            let data = Data(bytesIdx)
            var index = UInt32(littleEndian: data.withUnsafeBytes { $0.load(as: UInt32.self) })
            
            let bytePos = index / UInt32(NUM_FORMAT)
            index -= bytePos * UInt32(NUM_FORMAT)
            let pattern = Int32.min >>> (index - 1)

            guard (array[Int(bytePos)] & pattern) == pattern else { return false }
		}
		return true
	}
    
    public func getData() -> [Int32] {
        return array
    }

	public static func calcIndex(element: Data, index: UInt8, numberOfBits: UInt32) -> BInt {
        let hash = BloomFilter.hash(data:element, hashFunction: HashFunctions.SHA256, seed: index)
        let hashInt = BigInt.BInt.init(signed: Array(hash))
        let nBytes = withUnsafeBytes(of: numberOfBits.bigEndian, Array.init)
        return hashInt.mod(BInt(signed:nBytes))
	}
	
	public func readFrom(stream: Data) {
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
        
        numBits = UInt32(UInt16(stream.count) * NUM_FORMAT)
	}
}

infix operator >>> : BitwiseShiftPrecedence

func >>> (lhs: Int32, rhs: UInt32) -> Int32 {
    return Int32(bitPattern: UInt32(bitPattern: lhs) >> UInt32(rhs))
}

public extension BloomFilter  {
    
    static func calcProbValue(numBits: UInt32, numberOfElements n: UInt16, numberOfHashes k: UInt8) -> Float {
        return Float(pow(1.0 - exp(Float(-Int8(k)) / (Float)(numBits / 8) / Float(n)), Float(k)))
    }
    
    static func calcMValue(n: UInt16, p: Float) -> UInt32 {
        return UInt32(ceil((Float(n) * log(p)) / log(1.0 / pow(2.0, log(2.0)))))
    }
    
    static func calcKValue(m: UInt32, n: UInt16) -> UInt8 {
        return UInt8(max(1, round(Float(m) / Float(n) * log(2.0))))
    }
}
