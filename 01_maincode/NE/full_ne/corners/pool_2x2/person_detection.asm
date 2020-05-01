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
ncx_ADD 	r0, r0, #40 			// 3rd MB index
ncx_CP_B 	r0, r1, r2 		 		// Copy 3rd MB
ncx_ADDI 	r1, r1, #2 				// 4th MB starts at addr+2

ncx_ADDI  	r0, r0, #1 			  	// 4th MB index
ncx_CP_B 	r0, r1, r2 		 		// Copy 4th MB
ncx_NOOP    noop
ncx_NOOP    noop
ncx_NOOP    noop
ncx_NOOP    noop
ncx_NOOP    noop
ncx_NOOP    noop

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
ncx_MOVI r2, #6
ncx_MOVI r3, #18
ncx_MOVI r4, #14
ncx_MOVI r5, #26
ncx_MOVI r6, #8
ncx_MOVI r7, #16
ncx_MOVI r8, #24
ncx_MOVI r10, #10
ncx_MOVI r11, #22

// CONV chunk goes from top left across to top right,
// then down to next row left to right, and so on



// Convolution Block 0
pe_MOV {
	process_kernel_size=2 		    // zero pad 2 row of zeros on top
	output_kernel_size=2 			// zero pad 2 column of zeros on left
	ic_size=1 						// 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						// Input size in r9 (32)
	oa_size=12 						// 10x10 with halo +2
	ia_row_start=r0 				// 0
	ia_col_start=r0  				// 0
	ia_row_end=r10 					// 10
	ia_col_end=r10 					// 10
	ia_mem_addr_0=r0 				// Start at 0
	ia_mem_dir_0=1 					// Shared SRAM
	oa_mem_addr=r0  				// Move to addr 0 in local
	oa_mem_dir=0 					// Local mem
	oa_mem_buffer=0 				// buffer 0
}
pe_CONV {
	process_kernel_size=5 		    // 5x5 kernel
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
	ia_size=r15 					    // 12x12 convolution region
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
	process_kernel_size=2 		// zero pad 1 row of zeros on top
	output_kernel_size=0
	ic_size=1 						    // 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=12 						    // 10x10 with halo +2
	ia_row_start=r0 				  // 0
	ia_col_start=r2  				  // 6
	ia_row_end=r10 					  // 10
	ia_col_end=r3 					  // 18
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=5 		// 5x5 kernel
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
	ia_size=r15 					    // 12x12 convolution region
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
	process_kernel_size=2 		// zero pad 2 row of zeros on top
	output_kernel_size=0
	ic_size=1 						    // 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=12 						    // 10x10 with halo +2
	ia_row_start=r0 				  // 0
	ia_col_start=r4  				  // 14
	ia_row_end=r10 					  // 10
	ia_col_end=r5 					  // 26
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=5 		// 3x3 kernel
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
	ia_size=r15 					    // 12x12 convolution region
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
	output_kernel_size=2     // zero pad 1 col of zeros on left
	ic_size=1 						    // 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=12 						    // 10x10 with halo +2
	ia_row_start=r2 				  // 6
	ia_col_start=r0  				  // 0
	ia_row_end=r3 					  // 18
	ia_col_end=r10 					  // 10
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=5 		// 3x3 kernel
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
	ia_size=r15 					    // 12x12 convolution region
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
	oa_size=12 						    // 9x9 with halo +1
	ia_row_start=r2 				  // 6
	ia_col_start=r2  				  // 6
	ia_row_end=r3 					  // 18
	ia_col_end=r3 					  // 18
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=5 		// 3x3 kernel
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
	ia_size=r15 					    // 12x12 convolution region
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
	oa_size=12 						    // 10x10 with halo +2
	ia_row_start=r2 				  // 6
	ia_col_start=r4  				  // 14
	ia_row_end=r3 					  // 18
	ia_col_end=r5 					  // 26
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=5 		// 3x3 kernel
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
	output_kernel_size=2     // zero pad 1 col of zeros on left
	ic_size=1 						    // 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=12 						    // 9x9 with halo +1
	ia_row_start=r4 				  // 14
	ia_col_start=r0  				  // 0
	ia_row_end=r5 					  // 26
	ia_col_end=r10 					  // 10
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=5 		// 3x3 kernel
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
	oa_size=12 						    // 9x9 with halo +1
	ia_row_start=r4 				  // 14
	ia_col_start=r2  				  // 6
	ia_row_end=r5 					  // 26
	ia_col_end=r3 					  // 18
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=5 		// 3x3 kernel
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
	oa_size=12 						    // 9x9 with halo +1
	ia_row_start=r4 				  // 14
	ia_col_start=r4  				  // 14
	ia_row_end=r5 					  // 26
	ia_col_end=r5 					  // 26
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=5 		// 3x3 kernel
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
	output_kernel_size=2     // zero pad 1 col of zeros on left
	ic_size=1 						    // 1 channel input
	start_ic=0
	current_ic=0
	finish_ic=8
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=12 						    // 9x9 with halo +1
	ia_row_start=r11 				  // 22
	ia_col_start=r0  				  // 0
	ia_row_end=r9 					  // 32
	ia_col_end=r10 					  // 10
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=5 		// 3x3 kernel
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
	oa_size=12 						    // 9x9 with halo +1
	ia_row_start=r11 				  // 22
	ia_col_start=r2  				  // 6
	ia_row_end=r9 					  // 32
	ia_col_end=r3 					  // 18
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=5 		// 3x3 kernel
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
	oa_size=12 						    // 9x9 with halo +1
	ia_row_start=r11 				  // 22
	ia_col_start=r4  				  // 14
	ia_row_end=r9 					  // 32
	ia_col_end=r5 					  // 26
	ia_mem_addr_0=r0 				  // Start at 0
	ia_mem_dir_0=1 					  // Shared SRAM
	oa_mem_addr=r0  				  // Move to addr 0 in local
	oa_mem_dir=0 					    // Local mem
	oa_mem_buffer=0 				  // buffer 0
}
pe_CONV {
	process_kernel_size=5 		// 3x3 kernel
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


ncx_MOVI r2, #8
ncx_MOVI r3, #16
ncx_MOVI r4, #16
ncx_MOVI r5, #24
ncx_MOVI r6, #8
ncx_MOVI r7, #16
ncx_MOVI r8, #24
ncx_MOVI r10, #9
ncx_MOVI r11, #24

// output MOV options
ncx_MOVI r17, #8
ncx_MOVI r21, #4
ncx_MOVI r22, #12
ncx_MOVI r23, #16

// Pool Block 0
pe_MOV {
	process_kernel_size=0 		    // zero pad 1 row of zeros on top
	output_kernel_size=0 			// zero pad 1 column of zeros on left
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						// Input size in r9 (32)
	oa_size=8 						// 9x9 with halo +1
	ia_row_start=r0 				// 0
	ia_col_start=r0  				// 0
	ia_row_end=r10 					// 8
	ia_col_end=r10 					// 8
	ia_mem_addr_0=r18 				// Start at 0
	ia_mem_dir_0=1 					// Shared SRAM
	oa_mem_addr=r0  				// Move to addr 0 in local
	oa_mem_dir=0 					// Local mem
	oa_mem_buffer=0 				// buffer 0
}
pe_POOL {
	process_kernel_size=2 			// 3x3 pool
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
	ia_size=r17 					// 8x8 size
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
	process_kernel_size=0 		// zero pad 1 row of zeros on top
	output_kernel_size=0
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=8 						    // 9x9 with halo +1
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
	process_kernel_size=2 			// 3x3 pool
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
	process_kernel_size=0 		// zero pad 1 row of zeros on top
	output_kernel_size=0
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=8 						    // 9x9 with halo +1
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
	process_kernel_size=2 			// 3x3 pool
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
	output_kernel_size=0     // zero pad 1 col of zeros on left
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=8 						    // 9x9 with halo +1
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
	process_kernel_size=2 			// 3x3 pool
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
	oa_size=8 						    // 9x9 with halo +1
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
	process_kernel_size=2 			// 3x3 pool
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
	oa_size=8 						    // 9x9 with halo +1
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
	process_kernel_size=2 			// 3x3 pool
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
	output_kernel_size=0     // zero pad 1 col of zeros on left
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=8 						    // 9x9 with halo +1
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
	process_kernel_size=2 			// 3x3 pool
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
	oa_size=8 						    // 9x9 with halo +1
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
	process_kernel_size=2 			// 3x3 pool
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
	oa_size=8 						    // 9x9 with halo +1
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
	process_kernel_size=2 			// 3x3 pool
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
	output_kernel_size=0     // zero pad 1 col of zeros on left
	ic_size=16
	start_ic=0
	current_ic=0
	finish_ic=16
	ia_size=r9 						    // Input size in r9 (32)
	oa_size=8 						    // 9x9 with halo +1
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
	process_kernel_size=2 			// 3x3 pool
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
	oa_size=8 						    // 9x9 with halo +1
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
	process_kernel_size=2 			// 3x3 pool
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
	oa_size=8 						    // 9x9 with halo +1
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
	process_kernel_size=2 			// 3x3 pool
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



// yay
ncx_HALT
