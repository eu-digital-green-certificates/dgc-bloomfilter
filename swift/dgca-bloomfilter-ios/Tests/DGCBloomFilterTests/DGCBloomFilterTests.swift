import XCTest
@testable
import DGCBloomFilter

final class DGCBloomFilterTests: XCTestCase {
	var testDataLoader: TestDataLoader!
	
	func testReadTestData() throws {
		self.testDataLoader = try TestDataLoader()
	}
	
	func readTestData() throws -> [TestData] {
		self.testDataLoader = try TestDataLoader()
		guard let dataSets = self.testDataLoader.testData else { throw TestError.unknown }
		return dataSets
	}
	
	func testWithTestData() throws {
		let dataSets = try self.readTestData()
		for (index, element) in dataSets.enumerated() {
			print("TEST (\(index)) START")
			// guard let data = element.data else { throw FilterError.unknownError }
			let filter = BloomFilter(elementsNumber: element.data.count, probabilityRate: element.p)!
			for addIndex in 0..<element.data.count {
				if element.written[addIndex] == 1 {
					guard let elemToAdd = element.data[addIndex].data(using: .utf8) else { throw FilterError.unknownError }
					filter.add(element: elemToAdd)
				}
			}
			// get base64 string of filter after all elems have been added
			//guard let dataFromArray = arrayToData(intArray: filter.getData()) else { throw FilterError.unknownError } /// Seems to be broken!
            let base64String = Data(("["+filter.getData().map{String($0)}.joined(separator: ", ")+"]").utf8).base64EncodedString()
        
			print("Swift Filter: \(base64String) vs. Java: \(element.filter)")
            XCTAssert(base64String.elementsEqual(element.filter), "BASE64COMPARE NOT EQUAL")
			var exists: [Int32] = [Int32](repeating: 0, count: element.data.count)
			//var exists: [Int32] = [Int32(element.data.count)]
			for x in 0..<element.data.count {
				let mightContain = filter.mightContain(element: element.data[x].data(using: .utf8)!) ? 1 : 0
				exists[x] = Int32(mightContain)
				print("Filter reported element \(element.data[x]) \(mightContain == 1 ? "exists" : "not exist") at index \(x)")
			}
			// compare written and exist arrays
			let base64Exist = arrayToData(intArray: exists)!.base64EncodedString()
			let base64Written = array2ToData(intArray: element.written)!.base64EncodedString()
			XCTAssert(base64Exist.elementsEqual(base64Written), "WRITTEN NOT EQUAL EXISTS")
			print("TEST (\(index)) END")
		}
	}
	
	func stringArrayToData(stringArray: [String]) -> Data? {
	  return try? JSONSerialization.data(withJSONObject: stringArray, options: [])
	}
	
	func arrayToData(intArray: [Int32]) -> Data? {
		return try? JSONSerialization.data(withJSONObject: intArray, options: [])
	}
    
	func array2ToData(intArray: [Int]) -> Data? {
		return try? JSONSerialization.data(withJSONObject: intArray, options: [])
	}
	
    func testRunBasicBloom() throws {
        let impl = BloomFilter(memorySize: 1, hashesNumber: 1, elementsNumber: 1)!
        impl.add(element: Data([0, 5, 33, 44]))
        XCTAssert(!impl.mightContain(element:Data( [0, 5, 88, 44])))
        XCTAssert(impl.mightContain(element:Data( [0, 5, 33, 44])))
        XCTAssert(impl.getData().count == 1)
        XCTAssert(impl.getData()[0] == (Int32.min >>> 26))
    }
    
    func testBigInteger() throws {
        var val = BloomFilter.calcIndex(element: Data([11]), index: 1, numberOfBits: 100).asInt()
        XCTAssert(val == 75)
        val = BloomFilter.calcIndex(element: Data([1]), index: 1, numberOfBits: 1).asInt()
        XCTAssert( val == 0)
    }
    
    func testHash() throws {
        let hash = BloomFilter.hash(data: Data([11]), hashFunction: HashFunctions.SHA256, seed: 1)
        XCTAssert(hash.base64EncodedString() == "G2lkA9iYJ1bCNq+8WwnA9U3QaC7lNKddxLcKXV7Quo8=" )
    }
    
    func testRandom() throws {
        let filter = BloomFilter(elementsNumber: 62, probabilityRate:0.01)!
        
        filter.add(element: Data([16, 43, 72, 132, 157, 34, 143, 179, 78, 151, 143, 30, 166, 231, 218, 70, 76, 109, 164, 229, 241, 65, 36, 143, 3, 141, 252, 207, 175, 255, 69, 131, 234, 53, 207, 65, 31, 65, 18, 60, 200, 239, 16, 5, 245, 5, 253, 207, 4, 208, 122, 31, 219, 143, 54, 221, 173, 142, 62, 57, 125, 120, 230, 106 ]))
    }
	
	func float() {
		let fVal: Float = 0.000001
		let dVal: Double = 0.000001
		print(dVal.bytes.reversed())
		print(dVal.bytes)
		print(fVal.bytes.reversed())
		print(fVal.bytes)
		let bigEndianValue = fVal.bytes.withUnsafeBufferPointer {
			$0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0.pointee }
		}
		let bitPattern = UInt32(bigEndian: bigEndianValue)
		let fValBigEndian = Float(bitPattern: bitPattern)
		// print(fValBigEndian.bytes)
	}
	
	/**
	
	 */
	func testByteStream() throws {
		let probRate: Float = 0.000000001
		let numberOfElements = 500
		let base64String = "AAEeADCJcF8AAAH0AAAABQAAAqIAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAEABAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAIAAAAAAEAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAQAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAgAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACCAAAAAAAAAAAAAAAAAAQAAAACAAAAAAAAAAAAAEAAAgAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAABAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAACAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACCAIAAAAAAAAAAEAAAAAAAAAAABAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAEAAAQAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAQAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAEAAAAAAAAAACEAAAAAAAAAAAAAAACAAAAAAAAAACAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAACAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAACAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAgAAAAAAAgAAAAAAgAAACAAAAAQAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgCAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAggAAAAAgAQAAAAAAAAAAAQAAAAAAAAAAAEAAAAAAAAAAAAQAAAAAAAAAAAAAAAAKAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAEAAAAgAAAAAAAAIAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAACAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAEAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAEAAAAAAAAAAAAgIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAADAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAIAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQIAAAAAAABAAAAAAAIAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAgAAAAAAQgAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAgABAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="
		let filterData = Data(base64Encoded: base64String)
		print(filterData)
		XCTAssert(filterData != nil)
		let filter = BloomFilter()
		try filter.readFrom(data: filterData!)
		XCTAssert(filter.getData().count != 0)
		//XCTAssert(filter.probRate == probRate)
		print("prate = \(filter.probRate == probRate)")
		XCTAssert(filter.getData().count == 674)
		XCTAssert(filter.currentElementAmount == 5)
		XCTAssert(filter.definedElementAmount == numberOfElements)
        print("mightContain = \(try filter.mightContain(element: Data([5, 3, 2, 7])))")
		XCTAssert(try filter.mightContain(element: Data([5, 3, 2, 7])))		
	}
	
	
	
}

private enum TestError: Error {
	case unknown
}
