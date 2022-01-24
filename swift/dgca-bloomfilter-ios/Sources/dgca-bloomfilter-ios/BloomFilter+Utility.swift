//
//  File.swift
//  
//
//  Created by Paul Ballmann on 24.01.22.
//

import Foundation

extension BloomFilter {
	var width = 0.0;
	
	class func calcXValue(m: Int, n: Int) -> Int {
		// k = round((m / n) * log(2))
		return Int(round(Float((m / n)) * log(2)))
	}
}
