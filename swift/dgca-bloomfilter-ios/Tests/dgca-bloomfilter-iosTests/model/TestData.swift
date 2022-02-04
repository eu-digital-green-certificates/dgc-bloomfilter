//
//  TestData.swift
//  
//
//  Created by Paul Ballmann on 31.01.22.
//

import Foundation

struct TestData: Codable {
	let p: Double;
	let filter: String;
	let data: [String];
	let exists: String;
	let k: Int;
	let written: [Int];
}
