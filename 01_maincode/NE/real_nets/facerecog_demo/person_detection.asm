///////////////////////////////////////////////////////////////////////////////
///////////////////// Copy MD Frame: Start ////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

// Copy The 32x32 Frame into NE Shared SRAM
//
// NOTE: Face Detect will need to use CP_B to fetch McB,
//       but the motion detected frame will be manually
//       loaded into NE SRAM by the M0. Therefore,
//       Person Detect's start() address should be #1,#2
//       so we start out with "ncx_MOVI r1, #0"
ncx_CP_B	r0, r1, r2 				// Copy 1st MB (r0) to NE_SRAM_ADDR (r1), width in (r2) for stride
ncx_ADDI	r1, r1, #2 				// 2nd MB starts at addr+2 (row takes 16*8*8 = 2 512bit words)
ncx_ADDI	r0, r0, #1 				// 2nd MB index
ncx_CP_B 	r0, r1, r2 			 	// Copy 2nd MB
ncx_MULTI 	r1, r2, #32 		  	// 3rd MB starts at 32*Width + addr of first MB (0x0) in prev row
ncx_ADDI	r0, r0, #40 			// 3rd MB index
ncx_CP_B 	r0, r1, r2 		 		// Copy 3rd MB
ncx_ADDI 	r1, r1, #2 				// 4th MB starts at addr+2

ncx_ADDI  	r0, r0, #1 			  	// 4th MB index
ncx_CP_B 	r0, r1, r2 		 		// Copy 4th MB
ncx_NOOP
ncx_NOOP
ncx_NOOP
ncx_NOOP
ncx_NOOP
ncx_NOOP

ncx_MOVI 	r1, #0 					// Reset to base addr
ncx_MOVI 	r0, #0 					// Repurpose r0 as 0

// Load Huffman Tables & Biases
pe_HUFF {
	max_0_avg_1=0 					// Start with w table
	ia_mem_addr_0=r3 			    // Starting address of w table
	ia_mem_addr_1=r4 			    // Ending address of w table
	resize_factor=255 				// Need from huff
}
pe_HUFF {
	max_0_avg_1=1 					// Load loc table
	ia_mem_addr_0=r5 			    // Starting address of loc table
	ia_mem_addr_1=r6 			    // Ending address of loc table
	resize_factor=255 				// Need from huff
}
pe_BIAS {
	ia_mem_addr_0=r7			    // Starting addr of bias for conv1
	ia_mem_addr_1=r8 			    // Ending addr of bias for conv1
}

// Constants for row/col offsets
ncx_MOVI r2, #7
ncx_MOVI r3, #17
ncx_MOVI r4, #15
ncx_MOVI r5, #25
ncx_MOVI r6, #8
ncx_MOVI r7, #16
ncx_MOVI r8, #24
ncx_MOVI r10, #9
ncx_MOVI r11, #23


// CONV chunk goes from top left across to top right,
// then down to next row left to right, and so on



// Convolution Block 0
pe_MOV {
	process_kernel_size=1 		    // zero pad 1 row of zeros on top
	output_kernel_size=1 			// zero pad 1 column of zeros on left
	ic_size=1 						// 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						// Input size in r9 (32)
	oa_size=10 						// 9x9 with halo +1
	ia_row_start=r0 				// 0
	ia_col_start=r0  				// 0
	ia_row_end=r10 					// 9
	ia_col_end=r10 					// 9
	ia_mem_addr_0=r0 				// Start at 0
	ia_mem_dir_0=1 					// Shared SRAM
	oa_mem_addr=r0  				// Move to addr 0 in local
	oa_mem_dir=0 					// Local mem
	oa_mem_buffer=0 				// buffer 0
}
pe_CONV {
	process_kernel_size=3 		    // 3x3 kernel
	output_kernel_size=1 			// 1x1 output
	stride=1
	shift_width=8
    include_bias=1
	ic_size=8
	start_ic=0
	current_ic=0
	finish_ic=8
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r15 					    // 10x10 convolution region
	oa_size=8 						    // Should result in 8x8x16
	ia_mem_dir_0=0 					  // Input stored in local mem
	ia_mem_buffer_0=0 				// Local mem buffer 0
	oa_mem_dir=0 					    // Store output in local
	oa_mem_buffer=1 				  // Store in local buffer 1
	cwram_addr=r16 					  // Starting addr of conv1 weights
	conv_clear_finished=0 		// Clear buffer first
}
pe_RELU {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=8
	ia_mem_dir_0=0
	ia_mem_buffer_0=1
	oa_mem_dir=0
	oa_mem_buffer=0
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=32
	ia_row_start=r0  				// 0
	ia_col_start=r0  				// 0
	ia_row_end=r6 					// 8
	ia_col_end=r6 					// 8
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 				// buffer 0
	ia_mem_addr_0=r0
	oa_mem_dir=1 					// shared mem
	oa_mem_addr=r18	 			// shared mem addr to store in
}
//--------------------------------------------------------------------------------
pe_MOV {
	process_kernel_size=1 		// zero pad 1 row of zeros on top
	output_kernel_size=0
	ic_size=1 						    // 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r0 				  // 0
	ia_col_start=r2  				  // 7
	ia_row_end=r10 					  // 9
	ia_col_end=r3 					  // 17
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=3 		// 3x3 kernel
	output_kernel_size=1 			// 1x1 output
	stride=1
	shift_width=8
    include_bias=1
	ic_size=8
	start_ic=0
	current_ic=0
	finish_ic=8
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r15 					    // 10x10 convolution region
	oa_size=8 						    // Should result in 8x8x16
	ia_mem_dir_0=0 					  // Input stored in local mem
	ia_mem_buffer_0=0 				// Local mem buffer 0
	oa_mem_dir=0 					    // Store output in local
	oa_mem_buffer=1 				  // Store in local buffer 1
	cwram_addr=r16 					  // Starting addr of conv1 weights
	conv_clear_finished=0 		// Clear buffer first
}
pe_RELU {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=8
	ia_mem_dir_0=0
	ia_mem_buffer_0=1
	oa_mem_dir=0
	oa_mem_buffer=0
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=32
	ia_row_start=r0  				// 0
	ia_col_start=r6  				// 8
	ia_row_end=r6 					// 8
	ia_col_end=r7 					// 16
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 			// buffer 0
	ia_mem_addr_0=r0
	oa_mem_dir=1 					   // shared mem
	oa_mem_addr=r18	 		 // shared mem addr to store in
}
//--------------------------------------------------------------------------------
pe_MOV {
	process_kernel_size=1 		// zero pad 1 row of zeros on top
	output_kernel_size=0
	ic_size=1 						    // 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r0 				  // 0
	ia_col_start=r4  				  // 15
	ia_row_end=r10 					  // 9
	ia_col_end=r5 					  // 25
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=3 		// 3x3 kernel
	output_kernel_size=1 			// 1x1 output
	stride=1
	shift_width=8
	include_bias=1
	ic_size=8
	start_ic=0
	current_ic=0
	finish_ic=8
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r15 					    // 10x10 convolution region
	oa_size=8 						    // Should result in 8x8x16
	ia_mem_dir_0=0 					  // Input stored in local mem
	ia_mem_buffer_0=0 				// Local mem buffer 0
	oa_mem_dir=0 					    // Store output in local
	oa_mem_buffer=1 				  // Store in local buffer 1
	cwram_addr=r16 					  // Starting addr of conv1 weights
	conv_clear_finished=0 		// Clear buffer first
}
pe_RELU {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=8
	ia_mem_dir_0=0
	ia_mem_buffer_0=1
	oa_mem_dir=0
	oa_mem_buffer=0
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=32
	ia_row_start=r0  				// 0
	ia_col_start=r7  				// 16
	ia_row_end=r6 					// 8
	ia_col_end=r8 					// 24
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 			// buffer 0
	ia_mem_addr_0=r0
	oa_mem_dir=1 					   // shared mem
	oa_mem_addr=r18	 		 // shared mem addr to store in
}
//--------------------------------------------------------------------------------
pe_MOV {
	process_kernel_size=0
	output_kernel_size=1     // zero pad 1 col of zeros on left
	ic_size=1 						    // 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r2 				  // 7
	ia_col_start=r0  				  // 0
	ia_row_end=r3 					  // 17
	ia_col_end=r10 					  // 9
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=3 		// 3x3 kernel
	output_kernel_size=1 			// 1x1 output
	stride=1
	shift_width=8
	include_bias=1
	ic_size=8
	start_ic=0
	current_ic=0
	finish_ic=8
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r15 					    // 10x10 convolution region
	oa_size=8 						    // Should result in 8x8x16
	ia_mem_dir_0=0 					  // Input stored in local mem
	ia_mem_buffer_0=0 				// Local mem buffer 0
	oa_mem_dir=0 					    // Store output in local
	oa_mem_buffer=1 				  // Store in local buffer 1
	cwram_addr=r16 					  // Starting addr of conv1 weights
	conv_clear_finished=0 		// Clear buffer first
}
pe_RELU {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=8
	ia_mem_dir_0=0
	ia_mem_buffer_0=1
	oa_mem_dir=0
	oa_mem_buffer=0
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=32
	ia_row_start=r6  				// 8
	ia_col_start=r0  				// 0
	ia_row_end=r7 					// 16
	ia_col_end=r6 					// 8
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 			// buffer 0
	ia_mem_addr_0=r0
	oa_mem_dir=1 					   // shared mem
	oa_mem_addr=r18	 		 // shared mem addr to store in
}
//--------------------------------------------------------------------------------------
pe_MOV {
	process_kernel_size=0
	output_kernel_size=0
	ic_size=1 						    // 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r2 				  // 7
	ia_col_start=r2  				  // 7
	ia_row_end=r3 					  // 17
	ia_col_end=r3 					  // 17
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=3 		// 3x3 kernel
	output_kernel_size=1 			// 1x1 output
	stride=1
	shift_width=8
	include_bias=1
	ic_size=8
	start_ic=0
	current_ic=0
	finish_ic=8
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r15 					    // 10x10 convolution region
	oa_size=8 						    // Should result in 8x8x16
	ia_mem_dir_0=0 					  // Input stored in local mem
	ia_mem_buffer_0=0 				// Local mem buffer 0
	oa_mem_dir=0 					    // Store output in local
	oa_mem_buffer=1 				  // Store in local buffer 1
	cwram_addr=r16 					  // Starting addr of conv1 weights
	conv_clear_finished=0 		// Clear buffer first
}
pe_RELU {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=8
	ia_mem_dir_0=0
	ia_mem_buffer_0=1
	oa_mem_dir=0
	oa_mem_buffer=0
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=32
	ia_row_start=r6  				// 8
	ia_col_start=r6  				// 8
	ia_row_end=r7 					// 16
	ia_col_end=r7 					// 16
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 			// buffer 0
	ia_mem_addr_0=r0
	oa_mem_dir=1 					   // shared mem
	oa_mem_addr=r18	 		 // shared mem addr to store in
}
//--------------------------------------------------------------------------------------
pe_MOV {
	process_kernel_size=0
	output_kernel_size=0
	ic_size=1 						    // 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r2 				  // 7
	ia_col_start=r4  				  // 15
	ia_row_end=r3 					  // 17
	ia_col_end=r5 					  // 25
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=3 		// 3x3 kernel
	output_kernel_size=1 			// 1x1 output
	stride=1
	shift_width=8
	include_bias=1
	ic_size=8
	start_ic=0
	current_ic=0
	finish_ic=8
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r15 					    // 10x10 convolution region
	oa_size=8 						    // Should result in 8x8x16
	ia_mem_dir_0=0 					  // Input stored in local mem
	ia_mem_buffer_0=0 				// Local mem buffer 0
	oa_mem_dir=0 					    // Store output in local
	oa_mem_buffer=1 				  // Store in local buffer 1
	cwram_addr=r16 					  // Starting addr of conv1 weights
	conv_clear_finished=0 		// Clear buffer first
}
pe_RELU {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=8
	ia_mem_dir_0=0
	ia_mem_buffer_0=1
	oa_mem_dir=0
	oa_mem_buffer=0
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=32
	ia_row_start=r6  				// 8
	ia_col_start=r7  				// 16
	ia_row_end=r7 					// 16
	ia_col_end=r8 					// 24
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 			// buffer 0
	ia_mem_addr_0=r0
	oa_mem_dir=1 					   // shared mem
	oa_mem_addr=r18	 		 // shared mem addr to store in
}
//--------------------------------------------------------------------------------------
pe_MOV {
	process_kernel_size=0
	output_kernel_size=1     // zero pad 1 col of zeros on left
	ic_size=1 						    // 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r4 				  // 15
	ia_col_start=r0  				  // 0
	ia_row_end=r5 					  // 25
	ia_col_end=r10 					  // 9
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=3 		// 3x3 kernel
	output_kernel_size=1 			// 1x1 output
	stride=1
	shift_width=8
	include_bias=1
	ic_size=8
	start_ic=0
	current_ic=0
	finish_ic=8
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r15 					    // 10x10 convolution region
	oa_size=8 						    // Should result in 8x8x16
	ia_mem_dir_0=0 					  // Input stored in local mem
	ia_mem_buffer_0=0 				// Local mem buffer 0
	oa_mem_dir=0 					    // Store output in local
	oa_mem_buffer=1 				  // Store in local buffer 1
	cwram_addr=r16 					  // Starting addr of conv1 weights
	conv_clear_finished=0 		// Clear buffer first
}
pe_RELU {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=8
	ia_mem_dir_0=0
	ia_mem_buffer_0=1
	oa_mem_dir=0
	oa_mem_buffer=0
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=32
	ia_row_start=r7  				// 16
	ia_col_start=r0  				// 0
	ia_row_end=r8 					// 24
	ia_col_end=r6 					// 8
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 			// buffer 0
	ia_mem_addr_0=r0
	oa_mem_dir=1 					   // shared mem
	oa_mem_addr=r18	 		 // shared mem addr to store in
}
//--------------------------------------------------------------------------------------
pe_MOV {
	process_kernel_size=0
	output_kernel_size=0
	ic_size=1 						    // 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r4 				  // 15
	ia_col_start=r2  				  // 7
	ia_row_end=r5 					  // 25
	ia_col_end=r3 					  // 17
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=3 		// 3x3 kernel
	output_kernel_size=1 			// 1x1 output
	stride=1
	shift_width=8
	include_bias=1
	ic_size=8
	start_ic=0
	current_ic=0
	finish_ic=8
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r15 					    // 10x10 convolution region
	oa_size=8 						    // Should result in 8x8x16
	ia_mem_dir_0=0 					  // Input stored in local mem
	ia_mem_buffer_0=0 				// Local mem buffer 0
	oa_mem_dir=0 					    // Store output in local
	oa_mem_buffer=1 				  // Store in local buffer 1
	cwram_addr=r16 					  // Starting addr of conv1 weights
	conv_clear_finished=0 		// Clear buffer first
}
pe_RELU {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=8
	ia_mem_dir_0=0
	ia_mem_buffer_0=1
	oa_mem_dir=0
	oa_mem_buffer=0
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=32
	ia_row_start=r7  				// 16
	ia_col_start=r6  				// 8
	ia_row_end=r8 					// 24
	ia_col_end=r7 					// 16
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 			// buffer 0
	ia_mem_addr_0=r0
	oa_mem_dir=1 					   // shared mem
	oa_mem_addr=r18	 		 // shared mem addr to store in
}
//--------------------------------------------------------------------------------------
pe_MOV {
	process_kernel_size=0
	output_kernel_size=0
	ic_size=1 						    // 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r4 				  // 15
	ia_col_start=r4  				  // 15
	ia_row_end=r5 					  // 25
	ia_col_end=r5 					  // 25
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=3 		// 3x3 kernel
	output_kernel_size=1 			// 1x1 output
	stride=1
	shift_width=8
	include_bias=1
	ic_size=8
	start_ic=0
	current_ic=0
	finish_ic=8
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r15 					    // 10x10 convolution region
	oa_size=8 						    // Should result in 8x8x16
	ia_mem_dir_0=0 					  // Input stored in local mem
	ia_mem_buffer_0=0 				// Local mem buffer 0
	oa_mem_dir=0 					    // Store output in local
	oa_mem_buffer=1 				  // Store in local buffer 1
	cwram_addr=r16 					  // Starting addr of conv1 weights
	conv_clear_finished=0 		// Clear buffer first
}
pe_RELU {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=8
	ia_mem_dir_0=0
	ia_mem_buffer_0=1
	oa_mem_dir=0
	oa_mem_buffer=0
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=32
	ia_row_start=r7  				// 16
	ia_col_start=r7  				// 16
	ia_row_end=r8 					// 24
	ia_col_end=r8 					// 24
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 			// buffer 0
	ia_mem_addr_0=r0
	oa_mem_dir=1 					   // shared mem
	oa_mem_addr=r18	 		 // shared mem addr to store in
}
//--------------------------------------------------------------------------------------
pe_MOV {
	process_kernel_size=0
	output_kernel_size=1     // zero pad 1 col of zeros on left
	ic_size=1 						    // 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r11 				  // 23
	ia_col_start=r0  				  // 0
	ia_row_end=r9 					  // 32
	ia_col_end=r10 					  // 9
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=3 		// 3x3 kernel
	output_kernel_size=1 			// 1x1 output
	stride=1
	shift_width=8
	include_bias=1
	ic_size=8
	start_ic=0
	current_ic=0
	finish_ic=8
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r15 					    // 10x10 convolution region
	oa_size=8 						    // Should result in 8x8x16
	ia_mem_dir_0=0 					  // Input stored in local mem
	ia_mem_buffer_0=0 				// Local mem buffer 0
	oa_mem_dir=0 					    // Store output in local
	oa_mem_buffer=1 				  // Store in local buffer 1
	cwram_addr=r16 					  // Starting addr of conv1 weights
	conv_clear_finished=0 		// Clear buffer first
}
pe_RELU {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=8
	ia_mem_dir_0=0
	ia_mem_buffer_0=1
	oa_mem_dir=0
	oa_mem_buffer=0
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=32
	ia_row_start=r8  				// 24
	ia_col_start=r0  				// 0
	ia_row_end=r9 					// 32
	ia_col_end=r6 					// 8
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 			// buffer 0
	ia_mem_addr_0=r0
	oa_mem_dir=1 					   // shared mem
	oa_mem_addr=r18	 		 // shared mem addr to store in
}
//--------------------------------------------------------------------------------------
pe_MOV {
	process_kernel_size=0
	output_kernel_size=0
	ic_size=1 						    // 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r11 				  // 23
	ia_col_start=r2  				  // 7
	ia_row_end=r9 					  // 32
	ia_col_end=r3 					  // 17
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=3 		// 3x3 kernel
	output_kernel_size=1 			// 1x1 output
	stride=1
	shift_width=8
	include_bias=1
	ic_size=8
	start_ic=0
	current_ic=0
	finish_ic=8
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r15 					    // 10x10 convolution region
	oa_size=8 						    // Should result in 8x8x16
	ia_mem_dir_0=0 					  // Input stored in local mem
	ia_mem_buffer_0=0 				// Local mem buffer 0
	oa_mem_dir=0 					    // Store output in local
	oa_mem_buffer=1 				  // Store in local buffer 1
	cwram_addr=r16 					  // Starting addr of conv1 weights
	conv_clear_finished=0 		// Clear buffer first
}
pe_RELU {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=8
	ia_mem_dir_0=0
	ia_mem_buffer_0=1
	oa_mem_dir=0
	oa_mem_buffer=0
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=32
	ia_row_start=r8  				// 24
	ia_col_start=r6  				// 8
	ia_row_end=r9 					// 32
	ia_col_end=r7 					// 16
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 			// buffer 0
	ia_mem_addr_0=r0
	oa_mem_dir=1 					   // shared mem
	oa_mem_addr=r18	 		 // shared mem addr to store in
}
//--------------------------------------------------------------------------------------
pe_MOV {
	process_kernel_size=0
	output_kernel_size=0
	ic_size=1 						    // 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r11 				  // 23
	ia_col_start=r4  				  // 15
	ia_row_end=r9 					  // 32
	ia_col_end=r5 					  // 25
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=3 		// 3x3 kernel
	output_kernel_size=1 			// 1x1 output
	stride=1
	shift_width=8
	include_bias=1
	ic_size=8
	start_ic=0
	current_ic=0
	finish_ic=8
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r15 					    // 10x10 convolution region
	oa_size=8 						    // Should result in 8x8x16
	ia_mem_dir_0=0 					  // Input stored in local mem
	ia_mem_buffer_0=0 				// Local mem buffer 0
	oa_mem_dir=0 					    // Store output in local
	oa_mem_buffer=1 				  // Store in local buffer 1
	cwram_addr=r16 					  // Starting addr of conv1 weights
	conv_clear_finished=0 		// Clear buffer first
}
pe_RELU {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=8
	ia_mem_dir_0=0
	ia_mem_buffer_0=1
	oa_mem_dir=0
	oa_mem_buffer=0
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6
	oa_size=32
	ia_row_start=r8  				// 24
	ia_col_start=r7  				// 16
	ia_row_end=r9 					// 32
	ia_col_end=r8 					// 24
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 			// buffer 0
	ia_mem_addr_0=r0
	oa_mem_dir=1 					   // shared mem
	oa_mem_addr=r18	 		 // shared mem addr to store in
}

///////////////////////////////////////////////////////////////////////////////
///////////////////// Conv 1 + Relu: End //////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////// Max Pool 1: Start  //////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

ncx_MOVI r1, #384 					// Start storing at addr 5000


// use a lot of the same parameters from the CONV1
ncx_MOVI r2, #7
ncx_MOVI r3, #17
ncx_MOVI r4, #15
ncx_MOVI r5, #25
ncx_MOVI r6, #8
ncx_MOVI r7, #16
ncx_MOVI r8, #24
ncx_MOVI r10, #9
ncx_MOVI r11, #23

// output MOV options
ncx_MOVI r17, #10
ncx_MOVI r21, #4
ncx_MOVI r22, #12
ncx_MOVI r23, #16

// Pool Block 0
pe_MOV {
	process_kernel_size=1 		    // zero pad 1 row of zeros on top
	output_kernel_size=1 			// zero pad 1 column of zeros on left
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						// Input size in r9 (32)
	oa_size=10 						// 9x9 with halo +1
	ia_row_start=r0 				// 0
	ia_col_start=r0  				// 0
	ia_row_end=r10 					// 9
	ia_col_end=r10 					// 9
	ia_mem_addr_0=r18 				// Start at 0
	ia_mem_dir_0=1 					// Shared SRAM
	oa_mem_addr=r0  				// Move to addr 0 in local
	oa_mem_dir=0 					// Local mem
	oa_mem_buffer=0 				// buffer 0
}
pe_POOL {
	process_kernel_size=3 			// 3x3 pool
	output_kernel_size=1 			// scalar output
	stride=2 						// stride 2
	max_0_avg_1=0 					// max pool
	shift_width=0 					// no shift
	ic_size=16 						// 16 channels
	start_ic=0 						
	current_ic=0
	finish_ic=16
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r17 					// 10x10 size
	oa_size=4 						// 4x4 output
	ia_mem_dir_0=0
	ia_mem_buffer_0=0
	oa_mem_dir=0
	oa_mem_buffer=1 				// Output in buffer 1 				
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r21
	oa_size=16
	ia_row_start=r0 				// 0
	ia_col_start=r0 				// 0
	ia_row_end=r21 					// 4
	ia_col_end=r21 					// 4
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=1 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r1 					// base addr in r1
}
// Pool Block 1
pe_MOV {
	process_kernel_size=1 		// zero pad 1 row of zeros on top
	output_kernel_size=0
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r0 				  // 0
	ia_col_start=r2  				  // 7
	ia_row_end=r10 					  // 9
	ia_col_end=r3 					  // 17
	ia_mem_addr_0=r18 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_POOL {
	process_kernel_size=3 			// 3x3 pool
	output_kernel_size=1 			// scalar output
	stride=2 						// stride 2
	max_0_avg_1=0 					// max pool
	shift_width=0 					// no shift
	ic_size=16 						// 16 channels
	start_ic=0 						
	current_ic=0
	finish_ic=16
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r17 					// 10x10 size
	oa_size=4 						// 4x4 output
	ia_mem_dir_0=0
	ia_mem_buffer_0=0
	oa_mem_dir=0
	oa_mem_buffer=1 				// Output in buffer 1 				
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r21
	oa_size=16
	ia_row_start=r0 				// 0
	ia_col_start=r21 				// 4
	ia_row_end=r21 					// 4
	ia_col_end=r6 					// 8
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=1 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r1 					// base addr in r1
}
// Pool Block 2
pe_MOV {
	process_kernel_size=1 		// zero pad 1 row of zeros on top
	output_kernel_size=0
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r0 				  // 0
	ia_col_start=r4  				  // 15
	ia_row_end=r10 					  // 9
	ia_col_end=r5 					  // 25
	ia_mem_addr_0=r18 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_POOL {
	process_kernel_size=3 			// 3x3 pool
	output_kernel_size=1 			// scalar output
	stride=2 						// stride 2
	max_0_avg_1=0 					// max pool
	shift_width=0 					// no shift
	ic_size=16 						// 16 channels
	start_ic=0 						
	current_ic=0
	finish_ic=16
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r17 					// 10x10 size
	oa_size=4 						// 4x4 output
	ia_mem_dir_0=0
	ia_mem_buffer_0=0
	oa_mem_dir=0
	oa_mem_buffer=1 				// Output in buffer 1 				
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r21
	oa_size=16
	ia_row_start=r0 				// 0
	ia_col_start=r6 				// 8
	ia_row_end=r21 					// 4
	ia_col_end=r22 					// 12
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=1 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r1 					// base addr in r1
}
// Pool Block 3
pe_MOV {
	process_kernel_size=0
	output_kernel_size=1     // zero pad 1 col of zeros on left
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r2 				  // 7
	ia_col_start=r0  				  // 0
	ia_row_end=r3 					  // 17
	ia_col_end=r10 					  // 9
	ia_mem_addr_0=r18 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_POOL {
	process_kernel_size=3 			// 3x3 pool
	output_kernel_size=1 			// scalar output
	stride=2 						// stride 2
	max_0_avg_1=0 					// max pool
	shift_width=0 					// no shift
	ic_size=16 						// 16 channels
	start_ic=0 						
	current_ic=0
	finish_ic=16
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r17 					// 10x10 size
	oa_size=4 						// 4x4 output
	ia_mem_dir_0=0
	ia_mem_buffer_0=0
	oa_mem_dir=0
	oa_mem_buffer=1 				// Output in buffer 1 				
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r21
	oa_size=16
	ia_row_start=r21 				// 4
	ia_col_start=r0 				// 0
	ia_row_end=r6 					// 8
	ia_col_end=r21 					// 4
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=1 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r1 					// base addr in r1
}
// Pool Block 4
pe_MOV {
	process_kernel_size=0
	output_kernel_size=0
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r2 				  // 7
	ia_col_start=r2  				  // 7
	ia_row_end=r3 					  // 17
	ia_col_end=r3 					  // 17
	ia_mem_addr_0=r18 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_POOL {
	process_kernel_size=3 			// 3x3 pool
	output_kernel_size=1 			// scalar output
	stride=2 						// stride 2
	max_0_avg_1=0 					// max pool
	shift_width=0 					// no shift
	ic_size=16 						// 16 channels
	start_ic=0 						
	current_ic=0
	finish_ic=16
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r17 					// 10x10 size
	oa_size=4 						// 4x4 output
	ia_mem_dir_0=0
	ia_mem_buffer_0=0
	oa_mem_dir=0
	oa_mem_buffer=1 				// Output in buffer 1 				
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r21
	oa_size=16
	ia_row_start=r21 				// 4
	ia_col_start=r21 				// 4
	ia_row_end=r6 					// 8
	ia_col_end=r6 					// 8
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=1 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r1 					// base addr in r1
}
// Pool Block 5
pe_MOV {
	process_kernel_size=0
	output_kernel_size=0
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r2 				  // 7
	ia_col_start=r4  				  // 15
	ia_row_end=r3 					  // 17
	ia_col_end=r5 					  // 25
	ia_mem_addr_0=r18 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_POOL {
	process_kernel_size=3 			// 3x3 pool
	output_kernel_size=1 			// scalar output
	stride=2 						// stride 2
	max_0_avg_1=0 					// max pool
	shift_width=0 					// no shift
	ic_size=16 						// 16 channels
	start_ic=0 						
	current_ic=0
	finish_ic=16
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r17 					// 10x10 size
	oa_size=4 						// 4x4 output
	ia_mem_dir_0=0
	ia_mem_buffer_0=0
	oa_mem_dir=0
	oa_mem_buffer=1 				// Output in buffer 1 				
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r21
	oa_size=16
	ia_row_start=r21 				// 4
	ia_col_start=r6 				// 8
	ia_row_end=r6 					// 8
	ia_col_end=r22 					// 12
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=1 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r1 					// base addr in r1
}
// Pool Block 6
pe_MOV {
	process_kernel_size=0
	output_kernel_size=1     // zero pad 1 col of zeros on left
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r4 				  // 15
	ia_col_start=r0  				  // 0
	ia_row_end=r5 					  // 25
	ia_col_end=r10 					  // 9
	ia_mem_addr_0=r18 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_POOL {
	process_kernel_size=3 			// 3x3 pool
	output_kernel_size=1 			// scalar output
	stride=2 						// stride 2
	max_0_avg_1=0 					// max pool
	shift_width=0 					// no shift
	ic_size=16 						// 16 channels
	start_ic=0 						
	current_ic=0
	finish_ic=16
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r17 					// 10x10 size
	oa_size=4 						// 4x4 output
	ia_mem_dir_0=0
	ia_mem_buffer_0=0
	oa_mem_dir=0
	oa_mem_buffer=1 				// Output in buffer 1 				
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r21
	oa_size=16
	ia_row_start=r6 				// 8
	ia_col_start=r0 				// 0
	ia_row_end=r22 					// 12
	ia_col_end=r21 					// 4
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=1 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r1 					// base addr in r1
}
// Pool Block 7
pe_MOV {
	process_kernel_size=0
	output_kernel_size=0
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r4 				  // 15
	ia_col_start=r2  				  // 7
	ia_row_end=r5 					  // 25
	ia_col_end=r3 					  // 17
	ia_mem_addr_0=r18 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_POOL {
	process_kernel_size=3 			// 3x3 pool
	output_kernel_size=1 			// scalar output
	stride=2 						// stride 2
	max_0_avg_1=0 					// max pool
	shift_width=0 					// no shift
	ic_size=16 						// 16 channels
	start_ic=0 						
	current_ic=0
	finish_ic=16
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r17 					// 10x10 size
	oa_size=4 						// 4x4 output
	ia_mem_dir_0=0
	ia_mem_buffer_0=0
	oa_mem_dir=0
	oa_mem_buffer=1 				// Output in buffer 1 				
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r21
	oa_size=16
	ia_row_start=r6 				// 8
	ia_col_start=r21 				// 4
	ia_row_end=r22 					// 12
	ia_col_end=r6 					// 8
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=1 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r1 					// base addr in r1
}
// Pool Block 8
pe_MOV {
	process_kernel_size=0
	output_kernel_size=0
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r4 				  // 15
	ia_col_start=r4  				  // 15
	ia_row_end=r5 					  // 25
	ia_col_end=r5 					  // 25
	ia_mem_addr_0=r18 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_POOL {
	process_kernel_size=3 			// 3x3 pool
	output_kernel_size=1 			// scalar output
	stride=2 						// stride 2
	max_0_avg_1=0 					// max pool
	shift_width=0 					// no shift
	ic_size=16 						// 16 channels
	start_ic=0 						
	current_ic=0
	finish_ic=16
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r17 					// 10x10 size
	oa_size=4 						// 4x4 output
	ia_mem_dir_0=0
	ia_mem_buffer_0=0
	oa_mem_dir=0
	oa_mem_buffer=1 				// Output in buffer 1 				
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r21
	oa_size=16
	ia_row_start=r6 				// 8
	ia_col_start=r6 				// 8
	ia_row_end=r22 					// 12
	ia_col_end=r22 					// 12
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=1 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r1 					// base addr in r1
}
// Pool Block 9
pe_MOV {
	process_kernel_size=0
	output_kernel_size=1     // zero pad 1 col of zeros on left
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r11 				  // 23
	ia_col_start=r0  				  // 0
	ia_row_end=r9 					  // 32
	ia_col_end=r10 					  // 9
	ia_mem_addr_0=r18 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_POOL {
	process_kernel_size=3 			// 3x3 pool
	output_kernel_size=1 			// scalar output
	stride=2 						// stride 2
	max_0_avg_1=0 					// max pool
	shift_width=0 					// no shift
	ic_size=16 						// 16 channels
	start_ic=0 						
	current_ic=0
	finish_ic=16
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r17 					// 10x10 size
	oa_size=4 						// 4x4 output
	ia_mem_dir_0=0
	ia_mem_buffer_0=0
	oa_mem_dir=0
	oa_mem_buffer=1 				// Output in buffer 1 				
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r21
	oa_size=16
	ia_row_start=r22 				// 12
	ia_col_start=r0 				// 0
	ia_row_end=r23 					// 16
	ia_col_end=r21 					// 4
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=1 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r1 					// base addr in r1
}
// Pool Block 10
pe_MOV {
	process_kernel_size=0
	output_kernel_size=0
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r11 				  // 23
	ia_col_start=r2  				  // 7
	ia_row_end=r9 					  // 32
	ia_col_end=r3 					  // 17
	ia_mem_addr_0=r18 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_POOL {
	process_kernel_size=3 			// 3x3 pool
	output_kernel_size=1 			// scalar output
	stride=2 						// stride 2
	max_0_avg_1=0 					// max pool
	shift_width=0 					// no shift
	ic_size=16 						// 16 channels
	start_ic=0 						
	current_ic=0
	finish_ic=16
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r17 					// 10x10 size
	oa_size=4 						// 4x4 output
	ia_mem_dir_0=0
	ia_mem_buffer_0=0
	oa_mem_dir=0
	oa_mem_buffer=1 				// Output in buffer 1 				
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r21
	oa_size=16
	ia_row_start=r22 				// 12
	ia_col_start=r21 				// 4
	ia_row_end=r23 					// 16
	ia_col_end=r6 					// 8
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=1 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r1 					// base addr in r1
}
// Pool Block 11
pe_MOV {
	process_kernel_size=0
	output_kernel_size=0
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r11 				  // 23
	ia_col_start=r4  				  // 15
	ia_row_end=r9 					  // 32
	ia_col_end=r5 					  // 25
	ia_mem_addr_0=r18 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_POOL {
	process_kernel_size=3 			// 3x3 pool
	output_kernel_size=1 			// scalar output
	stride=2 						// stride 2
	max_0_avg_1=0 					// max pool
	shift_width=0 					// no shift
	ic_size=16 						// 16 channels
	start_ic=0 						
	current_ic=0
	finish_ic=16
	oc_size=16
	start_oc=0
	current_oc=0
	finish_oc=16
	ia_size=r17 					// 10x10 size
	oa_size=4 						// 4x4 output
	ia_mem_dir_0=0
	ia_mem_buffer_0=0
	oa_mem_dir=0
	oa_mem_buffer=1 				// Output in buffer 1 				
}
pe_MOV {
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r21
	oa_size=16
	ia_row_start=r22 				// 12
	ia_col_start=r6 				// 8
	ia_row_end=r23 					// 16
	ia_col_end=r22 					// 12
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=1 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r1 					// base addr in r1
}

///////////////////////////////////////////////////////////////////////////////
///////////////////// Max Pool 1: End  ////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////// Conv 2 + Relu: Start  ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


// new mem addresses
ncx_MOVI r3, #8192
ncx_MOVI r4, #8210
ncx_MOVI r5, #8210
ncx_MOVI r6, #8216
ncx_MOVI r7, #9216
ncx_MOVI r8, #9218
ncx_MOVI r16, #10240

// Need to update weight and bias addresses, maybe some registers
pe_HUFF {
	max_0_avg_1=0 					// Start with w table
	ia_mem_addr_0=r3 			// Starting address of w table
	ia_mem_addr_1=r4 			// Ending address of w table 
	resize_factor=255 				// Need from huff
}
pe_HUFF {
	max_0_avg_1=1 					// Load loc table
	ia_mem_addr_0=r5 			// Starting address of loc table
	ia_mem_addr_1=r6 			// Ending address of loc table
	resize_factor=255 				// Need from huff
}
pe_BIAS {
	ia_mem_addr_0=r7			// Starting addr of bias for conv1
	ia_mem_addr_1=r8 			// Ending addr of bias for conv1
	resize_factor=255
}

ncx_MOVI r18, #448 				// Next addr to store output
ncx_MOVI r2, #7
ncx_MOVI r3, #8
ncx_MOVI r4, #9
ncx_MOVI r5, #10
ncx_MOVI r6, #16

// Convolution Block 0
pe_MOV {
	process_kernel_size=1 		// zero pad 1 row of zeros on top
	output_kernel_size=1 			// zero pad 1 column of zeros on left
	ic_size=16 						    // 16 channel input
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6 						    // Input size in r6 (16)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r0 				  // 0
	ia_col_start=r0  				  // 0
	ia_row_end=r4 					  // 9
	ia_col_end=r4 					  // 9
	ia_mem_addr_0=r1 				  // Start at r1
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=3 		// 3x3 kernel
	output_kernel_size=1 			// 1x1 output
	stride=1
	shift_width=8
	include_bias=1
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	oc_size=32
	start_oc=0
	current_oc=0
	finish_oc=32
	ia_size=r5 					    // 10x10 convolution region
	oa_size=8 						    // Should result in 8x8x32
	ia_mem_dir_0=0 					  // Input stored in local mem
	ia_mem_buffer_0=0 				// Local mem buffer 0
	oa_mem_dir=0 					    // Store output in local
	oa_mem_buffer=1 				  // Store in local buffer 1
	cwram_addr=r16 					  // Starting addr of conv1 weights
	conv_clear_finished=0 		// Clear buffer first
}
pe_RELU {
	ic_size=32
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r3
	oa_size=8
	ia_mem_dir_0=0
	ia_mem_buffer_0=1
	oa_mem_dir=0
	oa_mem_buffer=0
}
pe_MOV {
	ic_size=32
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r3                      // 8
	oa_size=16
	ia_row_start=r0  				// 0
	ia_col_start=r0  				// 0
	ia_row_end=r3 					// 8
	ia_col_end=r3 					// 8
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 				// buffer 0
	ia_mem_addr_0=r0
	oa_mem_dir=1 					// shared mem
	oa_mem_addr=r18	 			// shared mem addr to store in
}
// Convolution Block 1
pe_MOV {
	process_kernel_size=1 		// zero pad 1 row of zeros on top
	output_kernel_size=0 			
	ic_size=16 						    // 16 channel input
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6 						    // Input size in r6 (16)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r0 				  // 0
	ia_col_start=r2  				  // 7
	ia_row_end=r4 					  // 9
	ia_col_end=r6 					  // 16
	ia_mem_addr_0=r1 				  // Start at r1
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=3 		// 3x3 kernel
	output_kernel_size=1 			// 1x1 output
	stride=1
	shift_width=8
	include_bias=1
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	oc_size=32
	start_oc=0
	current_oc=0
	finish_oc=32
	ia_size=r5 					    // 10x10 convolution region
	oa_size=8 						    // Should result in 8x8x32
	ia_mem_dir_0=0 					  // Input stored in local mem
	ia_mem_buffer_0=0 				// Local mem buffer 0
	oa_mem_dir=0 					    // Store output in local
	oa_mem_buffer=1 				  // Store in local buffer 1
	cwram_addr=r16 					  // Starting addr of conv1 weights
	conv_clear_finished=0 		// Clear buffer first
}
pe_RELU {
	ic_size=32
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r3
	oa_size=8
	ia_mem_dir_0=0
	ia_mem_buffer_0=1
	oa_mem_dir=0
	oa_mem_buffer=0
}
pe_MOV {
	ic_size=32
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r3
	oa_size=16
	ia_row_start=r0  				// 0
	ia_col_start=r3  				// 8
	ia_row_end=r3 					// 8
	ia_col_end=r6 					// 16
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 				// buffer 0
	ia_mem_addr_0=r0
	oa_mem_dir=1 					// shared mem
	oa_mem_addr=r18	 			// shared mem addr to store in
}
// Convolution Block 2
pe_MOV {
	process_kernel_size=0 		
	output_kernel_size=1 			// zero pad 1 column of zeros on left
	ic_size=16 						    // 16 channel input
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6 						    // Input size in r6 (16)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r2 				  // 7
	ia_col_start=r0  				  // 0
	ia_row_end=r6 					  // 16
	ia_col_end=r4 					  // 9
	ia_mem_addr_0=r1 				  // Start at r1
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=3 		// 3x3 kernel
	output_kernel_size=1 			// 1x1 output
	stride=1
	shift_width=8
	include_bias=1
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	oc_size=32
	start_oc=0
	current_oc=0
	finish_oc=32
	ia_size=r5 					    // 10x10 convolution region
	oa_size=8 						    // Should result in 8x8x32
	ia_mem_dir_0=0 					  // Input stored in local mem
	ia_mem_buffer_0=0 				// Local mem buffer 0
	oa_mem_dir=0 					    // Store output in local
	oa_mem_buffer=1 				  // Store in local buffer 1
	cwram_addr=r16 					  // Starting addr of conv1 weights
	conv_clear_finished=0 		// Clear buffer first
}
pe_RELU {
	ic_size=32
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r3
	oa_size=8
	ia_mem_dir_0=0
	ia_mem_buffer_0=1
	oa_mem_dir=0
	oa_mem_buffer=0
}
pe_MOV {
	ic_size=32
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r3
	oa_size=16
	ia_row_start=r3  				// 8
	ia_col_start=r0  				// 0
	ia_row_end=r6 					// 16
	ia_col_end=r3 					// 8
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 				// buffer 0
	ia_mem_addr_0=r0
	oa_mem_dir=1 					// shared mem
	oa_mem_addr=r18	 			// shared mem addr to store in
}
// Convolution Block 3
pe_MOV {
	process_kernel_size=0 		
	output_kernel_size=0 			
	ic_size=16 						    // 16 channel input
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r6 						    // Input size in r6 (16)
	oa_size=10 						    // 9x9 with halo +1
	ia_row_start=r2 				  // 7
	ia_col_start=r2  				  // 7
	ia_row_end=r6 					  // 16
	ia_col_end=r6 					  // 16
	ia_mem_addr_0=r1 				  // Start at r1
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=3 		// 3x3 kernel
	output_kernel_size=1 			// 1x1 output
	stride=1
	shift_width=8
	include_bias=1
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	oc_size=32
	start_oc=0
	current_oc=0
	finish_oc=32
	ia_size=r5 					    // 10x10 convolution region
	oa_size=8 						    // Should result in 8x8x32
	ia_mem_dir_0=0 					  // Input stored in local mem
	ia_mem_buffer_0=0 				// Local mem buffer 0
	oa_mem_dir=0 					    // Store output in local
	oa_mem_buffer=1 				  // Store in local buffer 1
	cwram_addr=r16 					  // Starting addr of conv1 weights
	conv_clear_finished=0 		// Clear buffer first
}
pe_RELU {
	ic_size=32
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r3
	oa_size=8
	ia_mem_dir_0=0
	ia_mem_buffer_0=1
	oa_mem_dir=0
	oa_mem_buffer=0
}
pe_MOV {
	ic_size=32
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r3
	oa_size=16
	ia_row_start=r3  				// 8
	ia_col_start=r3  				// 8
	ia_row_end=r6 					// 16
	ia_col_end=r6 					// 10
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 				// buffer 0
	ia_mem_addr_0=r0
	oa_mem_dir=1 					// shared mem
	oa_mem_addr=r18	 			// shared mem addr to store in
}

///////////////////////////////////////////////////////////////////////////////
///////////////////// Conv 2 + Relu: End  /////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////// Max Pool 2: Start  //////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

ncx_MOVI r1, #576

ncx_MOVI r22, #8  // outputs of the whole pool is an 8x8x32
ncx_MOVI r23, #4  // but outputs of individual pooling are 4x4

// POOL needs the same input format as CONV
// ie. 10x10 with filter 3x3 stride 2 -> 4x4

// Pool Block 0
pe_MOV {
	process_kernel_size=1 			// 1 row of zeros before data
	output_kernel_size=1 			// 1 col of zeros before data
	ic_size=32 						// 16 channel input
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r6 						// region size 16
	oa_size=10 						// pool on 10x10 region
	ia_row_start=r0 				// 0
	ia_col_start=r0 				// 0
	ia_row_end=r4 					// 9
	ia_col_end=r4 					// 9
	ia_mem_dir_0=1 					// in shared mem
	ia_mem_addr_0=r18 				// start at addr 1024
	oa_mem_dir=0 					// mov to local mem
	oa_mem_addr=r0 					// addr 0
	oa_mem_buffer=0 				// buffer 0
}
pe_POOL {
	process_kernel_size=3 			// 3x3 pool
	output_kernel_size=1 			// scalar output
	stride=2 						// stride 2
	max_0_avg_1=0 					// max pool
	shift_width=0 					// no shift
	ic_size=32 						// 16 channels
	start_ic=0 						
	current_ic=0
	finish_ic=32
	oc_size=32
	start_oc=0
	current_oc=0
	finish_oc=32
	ia_size=r5 	 					// 10x10 size
	oa_size=4 						// 4x4 output
	ia_mem_dir_0=0
	ia_mem_buffer_0=0
	oa_mem_dir=0
	oa_mem_buffer=1 				// Output in buffer 1 				
}
pe_MOV {
	ic_size=32
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r23                     // 4
	oa_size=8
	ia_row_start=r0 				// 0
	ia_col_start=r0 				// 0
	ia_row_end=r23 					// 4
	ia_col_end=r23 					// 4
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=1 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r1 					// base addr in r1
}
// Pool Block 1
pe_MOV {
	process_kernel_size=1 			// 1 row of zeros before data
	output_kernel_size=0 			
	ic_size=32 						// 16 channel input
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r6 						// region size 16
	oa_size=10 						// pool on 10x10 region
	ia_row_start=r0 				// 0
	ia_col_start=r2 				// 7
	ia_row_end=r4 					// 9
	ia_col_end=r6 					// 16
	ia_mem_dir_0=1 					// in shared mem
	ia_mem_addr_0=r18 				// start at addr 1024
	oa_mem_dir=0 					// mov to local mem
	oa_mem_addr=r0 					// addr 0
	oa_mem_buffer=0 				// buffer 0
}
pe_POOL {
	process_kernel_size=3 			// 3x3 pool
	output_kernel_size=1 			// scalar output
	stride=2 						// stride 2
	max_0_avg_1=0 					// max pool
	shift_width=0 					// no shift
	ic_size=32 						// 16 channels
	start_ic=0 						
	current_ic=0
	finish_ic=32
	oc_size=32
	start_oc=0
	current_oc=0
	finish_oc=32
	ia_size=r5 	 					// 10x10 size
	oa_size=4 						// 4x4 output
	ia_mem_dir_0=0
	ia_mem_buffer_0=0
	oa_mem_dir=0
	oa_mem_buffer=1 				// Output in buffer 1 				
}
pe_MOV {
	ic_size=32
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r23
	oa_size=8
	ia_row_start=r0 				// 0
	ia_col_start=r23 				// 4
	ia_row_end=r23 					// 4
	ia_col_end=r22 					// 8
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=1 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r1 					// base addr in r1
}
// Pool Block 2
pe_MOV {
	process_kernel_size=0 			
	output_kernel_size=1 			// 1 col of zeros before data
	ic_size=32 						// 16 channel input
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r6 						// region size 16
	oa_size=10 						// pool on 10x10 region
	ia_row_start=r2 				// 7
	ia_col_start=r0 				// 0
	ia_row_end=r6 					// 16
	ia_col_end=r4 					// 8
	ia_mem_dir_0=1 					// in shared mem
	ia_mem_addr_0=r18 				// start at addr 1024
	oa_mem_dir=0 					// mov to local mem
	oa_mem_addr=r0 					// addr 0
	oa_mem_buffer=0 				// buffer 0
}
pe_POOL {
	process_kernel_size=3 			// 3x3 pool
	output_kernel_size=1 			// scalar output
	stride=2 						// stride 2
	max_0_avg_1=0 					// max pool
	shift_width=0 					// no shift
	ic_size=32 						// 16 channels
	start_ic=0 						
	current_ic=0
	finish_ic=32
	oc_size=32
	start_oc=0
	current_oc=0
	finish_oc=32
	ia_size=r5 	 					// 10x10 size
	oa_size=4 						// 4x4 output
	ia_mem_dir_0=0
	ia_mem_buffer_0=0
	oa_mem_dir=0
	oa_mem_buffer=1 				// Output in buffer 1 				
}
pe_MOV {
	ic_size=32
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r23
	oa_size=8
	ia_row_start=r23 				// 4
	ia_col_start=r0 				// 0
	ia_row_end=r22 					// 8
	ia_col_end=r23 					// 4
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=1 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r1 					// base addr in r1
}
// Pool Block 3
pe_MOV {
	process_kernel_size=0 			
	output_kernel_size=0 			
	ic_size=32 						// 16 channel input
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r6 						// region size 16
	oa_size=10 						// pool on 10x10 region
	ia_row_start=r2 				// 7
	ia_col_start=r2 				// 7
	ia_row_end=r6 					// 16
	ia_col_end=r6 					// 16
	ia_mem_dir_0=1 					// in shared mem
	ia_mem_addr_0=r18 				// start at addr 1024
	oa_mem_dir=0 					// mov to local mem
	oa_mem_addr=r0 					// addr 0
	oa_mem_buffer=0 				// buffer 0
}
pe_POOL {
	process_kernel_size=3 			// 3x3 pool
	output_kernel_size=1 			// scalar output
	stride=2 						// stride 2
	max_0_avg_1=0 					// max pool
	shift_width=0 					// no shift
	ic_size=32 						// 16 channels
	start_ic=0 						
	current_ic=0
	finish_ic=32
	oc_size=32
	start_oc=0
	current_oc=0
	finish_oc=32
	ia_size=r5 	 			        // 10x10 size
	oa_size=4 						// 4x4 output
	ia_mem_dir_0=0
	ia_mem_buffer_0=0
	oa_mem_dir=0
	oa_mem_buffer=1 				// Output in buffer 1 				
}
pe_MOV {
	ic_size=32
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r23
	oa_size=8
	ia_row_start=r23 				// 4
	ia_col_start=r23 				// 4
	ia_row_end=r22 					// 8
	ia_col_end=r22 					// 8
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=1 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r1 					// base addr in r1
}
///////////////////////////////////////////////////////////////////////////////
///////////////////// Max Pool 2: End  ////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////// Dense Fully Connected 1+2: Start  ///////////////////////
///////////////////////////////////////////////////////////////////////////////

ncx_MOVI r2, #0 					// keep track in local buffer
ncx_MOVI r4, #0 					// keep track of fc columns
ncx_MOVI r5, #0 					// keep track of dfc2
ncx_MOVI r6, #1 					// output of dfc2 size
ncx_MOVI r7, #6144 					// starting addr of dfc2 weights
ncx_MOVI r8, #8 					// increment between dfc2 weights
ncx_MOVI r9, #704 					// where to store output of dfc col 1
ncx_MOVI r10, #0 					// offset into bias
ncx_MOVI r18, #712 					// where to store output of dfc col 2
ncx_MOVI r16, #3584 				// starting addr of fc1 w
pe_BIAS {
	ia_mem_addr_0=r19 				// starting addr of bias
	ia_mem_addr_1=r20 				// ending addr of bias
	resize_factor=255
}
pe_MOV {
	ic_size=32
	start_ic=0
	current_ic=0
	finish_ic=32
	ia_size=r3 						// region size 8
	oa_size=8
	ia_row_start=r0 				// 0
	ia_col_start=r0 				// 0
	ia_row_end=r3 					// 8
	ia_col_end=r3 					// 8
	ia_mem_dir_0=1 					// shared mem
	ia_mem_addr_0=r1 				// addr in r1
	oa_mem_dir=0 					// store to local
	oa_mem_buffer=0 				// buffer 0
	oa_mem_addr=r0 					// store at base
}

// first DFC will wipe output localmem buffer first
pe_DFC {
    max_0_avg_1=1
	shift_width=8
	include_bias=1
	ic_size=32
	start_ic=0
	current_ic=0
	finish_ic=32
	oc_size=8
	start_oc=0
	current_oc=1
	finish_oc=1
	ia_size=r3 						// 8x8x32 in mem
	oa_size=8 						// scalar output
	ia_row_start=r0 				// [actually dest channel]
	ia_col_start=r2 				// [actually dest col]
	ia_mem_addr_1=r10 				// bias offset in word
	ia_mem_dir_0=0 					// in local mem
	ia_mem_buffer_0=0 				// in buffer 0
	oa_mem_dir=0 					// output in local
	oa_mem_buffer=1 				// in buffer 1
	oa_mem_addr=r4 					// start with output at r2
	cwram_addr=r16
	conv_clear_finished=0 			// WIPE OUTPUT FIRST
    conv_clear_addr=0
}

// now we will actually loop
ncx_ADDI r4, r4, #1 				// next fc column
ncx_ADDI r10, r10, #1 				// increment offset of bias
ncx_ADDI r16, r16, #32 				// next addr of fc weights

pe_DFC {
    max_0_avg_1=1
	shift_width=8
	include_bias=1
	ic_size=32
	start_ic=0
	current_ic=0
	finish_ic=32
	oc_size=1
	start_oc=0
	current_oc=1
	finish_oc=1
	ia_size=r3 						// 8x8x32 in mem
	oa_size=1 						// scalar output
	ia_row_start=r0 				// [actually dest channel]
	ia_col_start=r2 				// [actually dest col]
	ia_mem_addr_1=r10 				// bias offset in word
	ia_mem_dir_0=0 					// in local mem
	ia_mem_buffer_0=0 				// in buffer 0
	oa_mem_dir=0 					// output in local
	oa_mem_buffer=1 				// in buffer 1
	oa_mem_addr=r4 					// start with output at r2
	cwram_addr=r16
	conv_clear_finished=1 			// do not clear output
}

ncx_ADDI r4, r4, #1 				// next fc column
ncx_ADDI r10, r10, #1 				// increment offset of bias
ncx_ADDI r16, r16, #32 				// next addr of fc weights
ncx_BLT r4, r3, #134, #0 			// go back to the DFC above 8 times
ncx_MOVI r4, #0
ncx_ADDI r2, r2, #1 				// increment local mem output
ncx_BLT r2, r3, #134, #0            // repeat the above loop another 8 times


// DFC the 8x8x8 (actually 8x8x1) down to a single value
pe_DFC {
    max_0_avg_1=0
	shift_width=8
	include_bias=1
	ic_size=8
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r3 						// 8x8x8 in mem
	oa_size=1 						// scalar output
	ia_row_start=r0 				// 0
	ia_col_start=r0 				// 0
	ia_mem_addr_1=r10 				// bias offset in word
	ia_mem_dir_0=0 					// in local mem
	ia_mem_buffer_0=1 				// in buffer 0
	oa_mem_dir=0 					// output in local
	oa_mem_buffer=0 				// in buffer 1
	oa_mem_addr=r0 					// write 1st word
	cwram_addr=r7                   // fc2 weights
	conv_clear_finished=1 			// do not clear output
}

ncx_ADDI r10, r10, #1
ncx_ADDI r7, r7, #8
ncx_MOVI r1, #1

pe_DFC {
    max_0_avg_1=0
	shift_width=8
	include_bias=1
	ic_size=8
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r3 						// 8x8x8 in mem
	oa_size=1 						// scalar output
	ia_row_start=r0 				// 0
	ia_col_start=r0 				// 0
    ia_mem_addr_1=r10
	ia_mem_dir_0=0 					// in local mem
	ia_mem_buffer_0=1				// in buffer 0
	oa_mem_dir=0 					// output in local
	oa_mem_buffer=0 				// in buffer 1
	oa_mem_addr=r1 					// write 2nd word
	cwram_addr=r7                   // fc2 weights
	conv_clear_finished=1 			// do not clear output
}

// 2x2 "region" to get those two values back to shared mem
ncx_MOVI r12, #2

pe_MOV {
	ic_size=8
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r8
	oa_size=8
	ia_row_start=r0 				// 0
	ia_col_start=r0 				// 0
	ia_row_end=r12 					// 2
	ia_col_end=r12 					// 2
	ia_mem_dir_0=0 					// local mem
	ia_mem_buffer_0=0 				// in buffer 1
	oa_mem_dir=1 					// store in shared
	oa_mem_addr=r0 					// final result at 0 because 512->128 addr translation easy
}



// load results into NCX registers to look pretty
ncx_LDS r5, r0, r0
ncx_LDS r7, r0, r1


// yay
ncx_HALT
