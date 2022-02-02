//	TestDataLoader.swift
//  
//
//  Created by Paul Ballmann on 01.02.22.
//

import Foundation
import dgca_bloomfilter_ios

class TestDataLoader {
	var testData: TestData?
	var testDataName = "filter-test"
	
	public init() throws {
		do {
			let testData = try self.readTestData()
			self.testData = testData
		} catch {
			throw error
		}
	}
	
	private func readTestData() throws -> TestData {
		guard let rawData = readLocalTestFile(withName: self.testDataName) else {
			throw UnitTestErrors.cannotLoadTestData
		}
		
		guard let testData = parseTestData(json: rawData) else {
			throw UnitTestErrors.cannotParseTestData
		}
		
		return testData
	}
	
	private func readLocalTestFile(withName name: String) -> Data? {
		do {
			if let pathToFile = Bundle.module.url(forResource: name, withExtension: "json") {
				let data = try Data(contentsOf: pathToFile)
				return data
			}
		} catch {
			print("error: \(error)")
		}
		return nil
	}
	
	private func parseTestData(json: Data) -> TestData? {
		let decoder = JSONDecoder()
		do {
			let testData = try decoder.decode([TestData].self, from: json)
			print(testData.count)
			// return testData
		} catch {
			print(error)
		}
		return nil
	}
}

enum UnitTestErrors: Error {
	case cannotLoadTestData
	case cannotParseTestData
	case unknown
}

class TestDataArr: Codable {
	let data: [TestData]
	
	public init(data: [TestData]) {
		self.data = data
	}
}
