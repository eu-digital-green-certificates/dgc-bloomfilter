//
//  MemoryHelper.swift
//  
//
//  Created by Paul Ballmann on 24.01.22.
//

import Foundation

public class MemoryHelper {
	/**
	 Returns the amount of bytes used by the app.
	 Not byte precise
	 */
	func heapMemory() -> UInt64 {
		let TASK_VM_INFO_COUNT = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
		let TASK_VM_INFO_REV1_COUNT = mach_msg_type_number_t(MemoryLayout.offset(of: \task_vm_info_data_t.min_address)! / MemoryLayout<integer_t>.size)
		var info = task_vm_info_data_t()
		var count = TASK_VM_INFO_COUNT
		let kr = withUnsafeMutablePointer(to: &info) { infoPtr in
			infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
				task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
			}
		}
        guard kr == KERN_SUCCESS, TASK_VM_INFO_COUNT >= TASK_VM_INFO_REV1_COUNT else { return 0 }

		return UInt64(info.phys_footprint)
	}
}
