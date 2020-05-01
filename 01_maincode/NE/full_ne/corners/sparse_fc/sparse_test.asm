////////////////////////////////////////////////////
//      128x1 -> 1024x1 Sparse FC Test            //
////////////////////////////////////////////////////
// input image (1x1x[c]) is in shared addr r1     //
// sparse weights are in 512-world address r2     //
////////////////////////////////////////////////////


ncx_MOVI r0, #0
ncx_MOVI r8, #8

// r1 is input data address
// r2 is weight address (512b)

ncx_MOVI r4, #REPLACEME_IASIZE     // SFC input size (1x1x[c])


// Convolution Block 0
pe_MOV {
	process_kernel_size=0 		    // zero pad 1 row of zeros on top
	output_kernel_size=0 			// zero pad 1 column of zeros on left
	ic_size=REPLACEME_MOVIC
	start_ic=0
	current_ic=0
	finish_ic=REPLACEME_MOVIC
	ia_size=r8 						// Input size in r8 (8)
	oa_size=8 						// 8
	ia_row_start=r0 				// 0
	ia_col_start=r0  				// 0
	ia_row_end=r8 					// 8
	ia_col_end=r8 					// 8
	ia_mem_addr_0=r0 				// Start at 0
	ia_mem_dir_0=1 					// Shared SRAM
	oa_mem_addr=r0  				// Move to addr 0 in local
	oa_mem_dir=0 					// Local mem
	oa_mem_buffer=0 				// buffer 0
}


// Sparse FC
pe_FC {
   include_bias=0
   ic_size=REPLACEME_ICHAN
   oc_size=REPLACEME_OCHAN
   shift_width=5
   ia_size=r4
   oa_size=REPLACEME_OASIZE
   ia_mem_buffer_0=0
   oa_mem_buffer=1
   cwram_addr=r2
}


ncx_HALT 
