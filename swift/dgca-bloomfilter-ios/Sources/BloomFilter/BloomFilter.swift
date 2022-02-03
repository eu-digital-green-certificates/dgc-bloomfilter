//
//  BloomFilter.swift
//
//
//  Created by Paul Ballmann on 20.01.22.
//

import Foundation
import BigInt

public class BloomFilter {
    private var array: [Int32] = []                  // each element has 4 bytes: MemoryLayout<Int32>.size == 4 Bytes;
    
    /**
     n -> number of items in the filter   (n = ceil(m / (-k / log(1 - exp(log(p) / k)))))
     p -> probabilty of false positives   (p = pow(1 - exp(-k / (m / n)), k))
     m -> number of bits in filter           (m = ceil((n * log(p)) / log(1 / pow(2, log(2))));)
     k -> number of hash functions      (k = round((m / n) * log(2));)
     */
    
    // private var byteSize: Int
    private var probRate: Double = 0.0
    private var version: UInt16 = 1

    private var numberOfHashes: UInt8 = 0
    private var numBits: UInt32 = 0
    
    private var addedElementsCount: Int = 0
    private var declaredElementsCount: Int = 0
    private var usedHashFunction: UInt8 = 0

    // CONST
    private let NUM_BYTES = MemoryLayout<UInt32>.size  // On 32-Bit -> Int32 (4 Bytes), On 64-Bit -> Int64 (8 Bytes)
    private let NUM_BITS = 8                           // number of bits to use for one byte
    private let NUM_FORMAT = MemoryLayout<UInt32>.size * 8

    public init() {
        self.array = []
    }
    
    public init(memorySize: Int, hashesNumber: UInt8, elementsNumber: Int) throws {
        guard memorySize > 0 && hashesNumber > 0 && elementsNumber > 0 else { throw FilterError.invalidParameters }

        self.numberOfHashes = hashesNumber

        let size = (memorySize / NUM_BYTES) + (memorySize % NUM_BYTES)
        self.numBits = UInt32(size * NUM_FORMAT)

        self.probRate = BloomFilter.calcProbValue(numBits: numBits, numberOfElements: elementsNumber, numberOfHashes: hashesNumber)
        self.declaredElementsCount = elementsNumber
        self.array = Array(repeating: 0, count: Int(size))
    }
    
    public init(elementsNumber: Int, probabilityRate: Double) throws {
        guard elementsNumber > 0 && probabilityRate > 0.0 else { throw FilterError.invalidParameters }
        
        self.probRate = probabilityRate
        self.declaredElementsCount = elementsNumber
        
        let bitsNumber = BloomFilter.calcMValue(n: elementsNumber, p: probabilityRate)
        let byteAmount = (bitsNumber / NUM_BITS) + 1
        let size = (byteAmount / NUM_BYTES) + (byteAmount % NUM_BYTES)
        guard size > 0 else { throw FilterError.invalidSize }

        self.numBits = UInt32(size * NUM_FORMAT)

        let hashesNumber = BloomFilter.calcKValue(m: numBits, n: elementsNumber)
        self.numberOfHashes = hashesNumber

        self.array = Array(repeating: 0, count: size)
    }
    
    public func add(element: Data) {
        for hashIndex in 0..<self.numberOfHashes {
            let bytesIdx = BloomFilter.calcIndex(element: element, index: hashIndex, numberOfBits: numBits).asMagnitudeBytes()
            
            let data = Data(bytesIdx)
            var index = UInt32(littleEndian: data.withUnsafeBytes { $0.pointee })
            
            let bytePos = index / UInt32(NUM_FORMAT)
            index -= bytePos * UInt32(NUM_FORMAT)
            let pattern = index == 0 ? Int32.min : Int32.min >>> (index-1)
            self.array[Int(bytePos)] = array[Int(bytePos)] | pattern
        }
        addedElementsCount += 1
        if addedElementsCount >= declaredElementsCount {
            //Logger necessary, no exception
        }
    }
    
    public func mightContain(element: Data) -> Bool {
        for hashIndex in 0..<self.numberOfHashes {
            let bytesIdx = BloomFilter.calcIndex(element: element, index: hashIndex, numberOfBits: numBits).asMagnitudeBytes()
            
            let data = Data(bytesIdx)
            var index = UInt32(littleEndian: data.withUnsafeBytes {$0.pointee })
            
            let bytePos = index / UInt32(NUM_FORMAT)
            index -= bytePos * UInt32(NUM_FORMAT)
            let pattern = index == 0 ? Int32.min : Int32.min >>> (index-1)

            guard (array[Int(bytePos)] & pattern) == pattern else { return false }
        }
        return true
    }
    
    public func getData() -> [Int32] {
        return array
    }

    public static func calcIndex(element: Data, index: UInt8, numberOfBits: UInt32) -> BInt {
        let hash = BloomFilter.hash(data:element, hashFunction: HashFunctions.SHA256, seed: index)
        let hashInt = BInt(signed: Array(hash))
        let nBytes = withUnsafeBytes(of: numberOfBits.bigEndian, Array.init)
        let dividedValue = BInt(signed:nBytes)
        let result = hashInt.mod(dividedValue)
        return result
    }
    
    public func readFrom(data: Data) throws {
        self.version = data[0..<2].reversed().withUnsafeBytes {$0.load(as: UInt16.self)}
        self.numberOfHashes = data[2..<3].withUnsafeBytes {$0.load(as: UInt8.self)}
        self.usedHashFunction = data[3..<4].withUnsafeBytes {$0.load(as: UInt8.self)}
        self.probRate = data[4..<12].reversed().withUnsafeBytes {$0.load(as: Double.self)}
        let declaredAmount = data[12..<16].reversed().withUnsafeBytes {$0.load(as: UInt32.self)}
        self.declaredElementsCount =  Int(declaredAmount)

        let currentAmount = data[16..<20].reversed().withUnsafeBytes {$0.load(as: UInt32.self)}
        self.addedElementsCount = Int(currentAmount)
        let elementsCount = data[20..<24].reversed().withUnsafeBytes {$0.load(as: UInt32.self)}
        array.removeAll()
        
        var startIndex = 24
        for _ in 0..<elementsCount {
            guard startIndex+4 <= data.count else { break }
            
            let newElement = data[startIndex..<startIndex+4].reversed().withUnsafeBytes {$0.load(as: Int32.self)}
            array.append(newElement)
            startIndex += 4
        }
        
        numBits =  UInt32(array.count * 4 * Int(NUM_FORMAT))
    }
    
    public func writeToData() throws -> Data  {
        var data = Data(count: 24 + array.count * 4)
        data[0..<2] = Data(version.bytes.reversed())
        data[2..<4] = Data([usedHashFunction, numberOfHashes])
        data[4..<12] = Data(probRate.bytes.reversed())
        data[12..<16] = Data(Int32(declaredElementsCount).bytes.reversed())
        data[16..<20] =  Data(Int32(addedElementsCount).bytes.reversed())
        let dataLen = Int32(array.count)
        data[20..<24] = Data(dataLen.bytes.reversed())
        
        var startIndex = 24
        for ind in 0..<array.count {
            data[startIndex..<startIndex+4] = Data(Int32(array[ind]).bytes.reversed())
            startIndex += 4
        }
        return data
    }
}


infix operator >>> : BitwiseShiftPrecedence

func >>> (lhs: Int32, rhs: UInt32) -> Int32 {
    return Int32(bitPattern: UInt32(bitPattern: lhs) >> UInt32(rhs))
}

public extension BloomFilter  {
    
    static func calcProbValue(numBits: UInt32, numberOfElements n: Int, numberOfHashes k: UInt8) -> Double {
        return Double(pow(1.0 - exp(Float(-Int8(k)) / (Float)(numBits / 8) / Float(n)), Float(k)))
    }
    
    static func calcMValue(n: Int, p: Double) -> Int {
        return Int(ceil((Double(n) * log(p)) / log(1 / pow(2, log(2)))))
    }
    
    static func calcKValue(m: UInt32, n: Int) -> UInt8 {
        return UInt8(max(1, round(Float(m) / Float(n) * log(2))))
    }
}
