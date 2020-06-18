///////////////////////////////////////////////////////////////////////////////
//// if you're doing Face Detection,
//// copy The 32x32 Frame into NE Shared SRAM

l1:ncx_MOV   r8,  r1            // save r1 value for later
ncx_CP_B  r10, r1,  r7       // Copy 1st MB (r10) to NE_SRAM_ADDR (r1), width in (r7) for stride
ncx_ADDI  r1,  r1,  #2       // 2nd MB starts at addr+2 (row takes 16*8*8 = 2 512bit words)
ncx_ADDI  r10, r10, #1       // 2nd MB index
ncx_CP_B  r10, r1,  r7       // Copy 2nd MB
ncx_MULTI r1,  r7,  #32      // 3rd MB starts at 32*Width + addr of first MB (0x0) in prev row
ncx_ADDI  r10, r10, #39      // 3rd MB index is +40-1
ncx_CP_B  r10, r1,  r7       // Copy 3rd MB
l2:ncx_ADDI  r1,  r1,  #2       // 4th MB starts at addr+2
ncx_ADDI  r10, r10, #1       // 4th MB index
ncx_CP_B  r10, r1,  r7       // Copy 4th MB
ncx_MOV   r1,  r8            // restore r1 to its original value



///////////////////////////////////////////////////////////////////////////////
//// if you're running Person Detection,
//// start here at address 2
//// i.e.: ne_start(2) instead of ne_start(0)


// Load Huffman Tables & Biases
l3:pe_HUFF {
    w_0_loc_1=0              // Start with w table
    table_start_addr=r13     // Starting address of w table
    table_end_addr=r14       // Ending address of w table
    last_word_valid_mask=255 // all should be valid!
}
l4:pe_HUFF {
    w_0_loc_1=1              // Load loc table
    table_start_addr=r14     // Starting address of loc table
    table_end_addr=r15       // Ending address of loc table
    last_word_valid_mask=255 // all should be valid!
}
l5:pe_BIAS {
    start_addr=r5            // Starting addr of bias for conv1
    end_addr=r6              // Ending addr of bias for conv1
}

//------------------------------------------------
// set conv1 constants and describe the
// current register values for easier reading

l6:ncx_MOVI r0,  #0
//       r1                  // r1 is input image
//       r2                  // r2 is 1st intermediate region
ncx_MOVI r3,  #17
//       r4                  // r4 is 2nd intermediate region
ncx_MOVI r5,  #25            // was conv1 bias start
ncx_MOVI r6,  #8             // was conv1 bias end
ncx_MOVI r7,  #16            // potentially was CP_B region width
ncx_MOVI r8,  #24
ncx_MOVI r9,  #32
ncx_MOVI r10, #9             // potentially was CP_B top-left McB index
ncx_MOVI r11, #23
//       r12                 // r12 is conv1 weights
l7:ncx_MOVI r13, #10            // was conv1 w table start
ncx_MOVI r14, #7             // was conv1 w table end / loc table start
ncx_MOVI r15, #15            // was conv1 loc table end
//       r16                 // r16 is conv2 weights
//       r17                 // r17 is conv2 w table
//       r18                 // r18 is conv2 loc table
//       r19                 // r19 is conv2 bias (will assume +2 for bias end addr)
//       r20                 // r20 is fc1 weights
//       r21                 // r21 is fc2 weights
//       r22                 // r22 is fc1 bias (will assume +5 for bias end addr)
//       r23                 // r23 is conv2 loc table end
//
//----------------------------------------





// Convolution Block 0
l8:pe_MOV {
    top_pad_rows=1          // zero pad 1 row of zeros on top
    left_pad_cols=1         // zero pad 1 column of zeros on left
    ic_size=1               // 1 channel input
    start_ic=0
    current_ic=0
    finish_ic=8
    ia_size=r9              // Input size in r9 (32)
    oa_size=10              // 9x9 with halo +1
    ia_row_start=r0         // 0
    ia_col_start=r0         // 0
    ia_row_end=r10          // 9
    ia_col_end=r10          // 9
    ia_mem_addr_0=r1        // Starting input image addr
    ia_mem_dir_0=shared     // Shared SRAM
    oa_mem_addr=r0          // Move to addr 0 in local
    oa_mem_dir=local        // Local mem
    oa_mem_buffer=0         // buffer 0
}
l9:pe_CONV {
    process_kernel_size=3   // 3x3 kernel
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
    ia_size=r13             // 10x10 convolution region
    oa_size=8               // Should result in 8x8x16
    ia_mem_dir_0=local      // Input stored in local mem
    ia_mem_buffer_0=0       // Local mem buffer 0
    oa_mem_dir=local        // Store output in local
    oa_mem_buffer=1         // Store in local buffer 1
    cwram_addr=r12          // Starting addr of conv1 weights
    skip_localmem_clear=0   // Clear buffer first
}
l10:pe_RELU {
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
l11:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r6
    oa_size=32
    ia_row_start=r0         // 0
    ia_col_start=r0         // 0
    ia_row_end=r6           // 8
    ia_col_end=r6           // 8
    ia_mem_dir_0=local      // local mem
    ia_mem_buffer_0=0       // buffer 0
    ia_mem_addr_0=r0
    oa_mem_dir=shared       // shared mem
    oa_mem_addr=r2          // shared mem addr to store in
}
//--------------------------------------------------------------------------------
l12:pe_MOV {
    top_pad_rows=1          // zero pad 1 row of zeros on top
    ic_size=1               // 1 channel input
    start_ic=0
    current_ic=0
    finish_ic=8
    ia_size=r9              // Input size in r9 (32)
    oa_size=10              // 9x9 with halo +1
    ia_row_start=r0         // 0
    ia_col_start=r14        // 7
    ia_row_end=r10          // 9
    ia_col_end=r3           // 17
    ia_mem_addr_0=r1        // Start at 0
    ia_mem_dir_0=shared     // Shared SRAM
    oa_mem_addr=r0          // Move to addr 0 in local
    oa_mem_dir=local        // Local mem
    oa_mem_buffer=0         // buffer 0
}
l13:pe_CONV {
    process_kernel_size=3   // 3x3 kernel
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
    ia_size=r13             // 10x10 convolution region
    oa_size=8               // Should result in 8x8x16
    ia_mem_dir_0=local      // Input stored in local mem
    ia_mem_buffer_0=0       // Local mem buffer 0
    oa_mem_dir=local        // Store output in local
    oa_mem_buffer=1         // Store in local buffer 1
    cwram_addr=r12          // Starting addr of conv1 weights
    skip_localmem_clear=0   // Clear buffer first
}
l14:pe_RELU {
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
l15:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r6
    oa_size=32
    ia_row_start=r0         // 0
    ia_col_start=r6         // 8
    ia_row_end=r6           // 8
    ia_col_end=r7           // 16
    ia_mem_dir_0=local      // local mem
    ia_mem_buffer_0=0       // buffer 0
    ia_mem_addr_0=r0
    oa_mem_dir=shared       // shared mem
    oa_mem_addr=r2          // shared mem addr to store in
}



//--------------------------------------------------------------------------------
l16:pe_MOV {
    top_pad_rows=1          // zero pad 1 row of zeros on top
    ic_size=1               // 1 channel input
    start_ic=0
    current_ic=0
    finish_ic=8
    ia_size=r9              // Input size in r9 (32)
    oa_size=10              // 9x9 with halo +1
    ia_row_start=r0         // 0
    ia_col_start=r15        // 15
    ia_row_end=r10          // 9
    ia_col_end=r5           // 25
    ia_mem_addr_0=r1        // Start at 0
    ia_mem_dir_0=shared     // Shared SRAM
    oa_mem_addr=r0          // Move to addr 0 in local
    oa_mem_dir=local        // Local mem
    oa_mem_buffer=0         // buffer 0
}
l17:pe_CONV {
    process_kernel_size=3   // 3x3 kernel
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
    ia_size=r13             // 10x10 convolution region
    oa_size=8               // Should result in 8x8x16
    ia_mem_dir_0=local      // Input stored in local mem
    ia_mem_buffer_0=0       // Local mem buffer 0
    oa_mem_dir=local        // Store output in local
    oa_mem_buffer=1         // Store in local buffer 1
    cwram_addr=r12          // Starting addr of conv1 weights
    skip_localmem_clear=0   // Clear buffer first
}
l18:pe_RELU {
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
l19:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r6
    oa_size=32
    ia_row_start=r0         // 0
    ia_col_start=r7         // 16
    ia_row_end=r6           // 8
    ia_col_end=r8           // 24
    ia_mem_dir_0=local      // local mem
    ia_mem_buffer_0=0       // buffer 0
    ia_mem_addr_0=r0
    oa_mem_dir=shared       // shared mem
    oa_mem_addr=r2          // shared mem addr to store in
}



//--------------------------------------------------------------------------------
l20:pe_MOV {
    left_pad_cols=1          // zero pad 1 col of zeros on left
    ic_size=1                // 1 channel input
    start_ic=0
    current_ic=0
    finish_ic=8
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r14         // 7
    ia_col_start=r0          // 0
    ia_row_end=r3            // 17
    ia_col_end=r10           // 9
    ia_mem_addr_0=r1         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l21:pe_CONV {
    process_kernel_size=3    // 3x3 kernel
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
    ia_size=r13              // 10x10 convolution region
    oa_size=8                // Should result in 8x8x16
    ia_mem_dir_0=local       // Input stored in local mem
    ia_mem_buffer_0=0        // Local mem buffer 0
    oa_mem_dir=local         // Store output in local
    oa_mem_buffer=1          // Store in local buffer 1
    cwram_addr=r12           // Starting addr of conv1 weights
    skip_localmem_clear=0    // Clear buffer first
}
l22:pe_RELU {
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
l23:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r6
    oa_size=32
    ia_row_start=r6          // 8
    ia_col_start=r0          // 0
    ia_row_end=r7            // 16
    ia_col_end=r6            // 8
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=0        // buffer 0
    ia_mem_addr_0=r0
    oa_mem_dir=shared        // shared mem
    oa_mem_addr=r2           // shared mem addr to store in
}



//--------------------------------------------------------------------------------------
l24:pe_MOV {
    ic_size=1                // 1 channel input
    start_ic=0
    current_ic=0
    finish_ic=8
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r14         // 7
    ia_col_start=r14         // 7
    ia_row_end=r3            // 17
    ia_col_end=r3            // 17
    ia_mem_addr_0=r1         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l25:pe_CONV {
    process_kernel_size=3    // 3x3 kernel
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
    ia_size=r13              // 10x10 convolution region
    oa_size=8                // Should result in 8x8x16
    ia_mem_dir_0=local       // Input stored in local mem
    ia_mem_buffer_0=0        // Local mem buffer 0
    oa_mem_dir=local         // Store output in local
    oa_mem_buffer=1          // Store in local buffer 1
    cwram_addr=r12           // Starting addr of conv1 weights
    skip_localmem_clear=0    // Clear buffer first
}
l26:pe_RELU {
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
l27:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r6
    oa_size=32
    ia_row_start=r6          // 8
    ia_col_start=r6          // 8
    ia_row_end=r7            // 16
    ia_col_end=r7            // 16
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=0        // buffer 0
    ia_mem_addr_0=r0
    oa_mem_dir=shared        // shared mem
    oa_mem_addr=r2           // shared mem addr to store in
}



//--------------------------------------------------------------------------------------
l28:pe_MOV {
    ic_size=1                // 1 channel input
    start_ic=0
    current_ic=0
    finish_ic=8
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r14         // 7
    ia_col_start=r15         // 15
    ia_row_end=r3            // 17
    ia_col_end=r5            // 25
    ia_mem_addr_0=r1         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l29:pe_CONV {
    process_kernel_size=3    // 3x3 kernel
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
    ia_size=r13              // 10x10 convolution region
    oa_size=8                // Should result in 8x8x16
    ia_mem_dir_0=local       // Input stored in local mem
    ia_mem_buffer_0=0        // Local mem buffer 0
    oa_mem_dir=local         // Store output in local
    oa_mem_buffer=1          // Store in local buffer 1
    cwram_addr=r12           // Starting addr of conv1 weights
    skip_localmem_clear=0    // Clear buffer first
}
l30:pe_RELU {
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
l31:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r6
    oa_size=32
    ia_row_start=r6          // 8
    ia_col_start=r7          // 16
    ia_row_end=r7            // 16
    ia_col_end=r8            // 24
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=0        // buffer 0
    ia_mem_addr_0=r0
    oa_mem_dir=shared        // shared mem
    oa_mem_addr=r2           // shared mem addr to store in
}



//--------------------------------------------------------------------------------------
l32:pe_MOV {
    left_pad_cols=1          // zero pad 1 col of zeros on left
    ic_size=1                // 1 channel input
    start_ic=0
    current_ic=0
    finish_ic=8
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r15         // 15
    ia_col_start=r0          // 0
    ia_row_end=r5            // 25
    ia_col_end=r10           // 9
    ia_mem_addr_0=r1         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l33:pe_CONV {
    process_kernel_size=3    // 3x3 kernel
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
    ia_size=r13              // 10x10 convolution region
    oa_size=8                // Should result in 8x8x16
    ia_mem_dir_0=local       // Input stored in local mem
    ia_mem_buffer_0=0        // Local mem buffer 0
    oa_mem_dir=local         // Store output in local
    oa_mem_buffer=1          // Store in local buffer 1
    cwram_addr=r12           // Starting addr of conv1 weights
    skip_localmem_clear=0    // Clear buffer first
}
l34:pe_RELU {
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
l35:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r6
    oa_size=32
    ia_row_start=r7          // 16
    ia_col_start=r0          // 0
    ia_row_end=r8            // 24
    ia_col_end=r6            // 8
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=0        // buffer 0
    ia_mem_addr_0=r0
    oa_mem_dir=shared        // shared mem
    oa_mem_addr=r2           // shared mem addr to store in
}



//--------------------------------------------------------------------------------------
l36:pe_MOV {
    ic_size=1                // 1 channel input
    start_ic=0
    current_ic=0
    finish_ic=8
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r15         // 15
    ia_col_start=r14         // 7
    ia_row_end=r5            // 25
    ia_col_end=r3            // 17
    ia_mem_addr_0=r1         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l37:pe_CONV {
    process_kernel_size=3    // 3x3 kernel
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
    ia_size=r13              // 10x10 convolution region
    oa_size=8                // Should result in 8x8x16
    ia_mem_dir_0=local       // Input stored in local mem
    ia_mem_buffer_0=0        // Local mem buffer 0
    oa_mem_dir=local         // Store output in local
    oa_mem_buffer=1          // Store in local buffer 1
    cwram_addr=r12           // Starting addr of conv1 weights
    skip_localmem_clear=0    // Clear buffer first
}
l38:pe_RELU {
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
l39:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r6
    oa_size=32
    ia_row_start=r7          // 16
    ia_col_start=r6          // 8
    ia_row_end=r8            // 24
    ia_col_end=r7            // 16
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=0        // buffer 0
    ia_mem_addr_0=r0
    oa_mem_dir=shared        // shared mem
    oa_mem_addr=r2           // shared mem addr to store in
}



//--------------------------------------------------------------------------------------
l40:pe_MOV {
    ic_size=1                // 1 channel input
    start_ic=0
    current_ic=0
    finish_ic=8
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r15         // 15
    ia_col_start=r15         // 15
    ia_row_end=r5            // 25
    ia_col_end=r5            // 25
    ia_mem_addr_0=r1         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l41:pe_CONV {
    process_kernel_size=3    // 3x3 kernel
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
    ia_size=r13              // 10x10 convolution region
    oa_size=8                // Should result in 8x8x16
    ia_mem_dir_0=local       // Input stored in local mem
    ia_mem_buffer_0=0        // Local mem buffer 0
    oa_mem_dir=local         // Store output in local
    oa_mem_buffer=1          // Store in local buffer 1
    cwram_addr=r12           // Starting addr of conv1 weights
    skip_localmem_clear=0    // Clear buffer first
}
l42:pe_RELU {
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
l43:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r6
    oa_size=32
    ia_row_start=r7          // 16
    ia_col_start=r7          // 16
    ia_row_end=r8            // 24
    ia_col_end=r8            // 24
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=0        // buffer 0
    ia_mem_addr_0=r0
    oa_mem_dir=shared        // shared mem
    oa_mem_addr=r2           // shared mem addr to store in
}



//--------------------------------------------------------------------------------------
l44:pe_MOV {
    left_pad_cols=1          // zero pad 1 col of zeros on left
    ic_size=1                // 1 channel input
    start_ic=0
    current_ic=0
    finish_ic=8
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r11         // 23
    ia_col_start=r0          // 0
    ia_row_end=r9            // 32
    ia_col_end=r10           // 9
    ia_mem_addr_0=r1         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l45:pe_CONV {
    process_kernel_size=3    // 3x3 kernel
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
    ia_size=r13              // 10x10 convolution region
    oa_size=8                // Should result in 8x8x16
    ia_mem_dir_0=local       // Input stored in local mem
    ia_mem_buffer_0=0        // Local mem buffer 0
    oa_mem_dir=local         // Store output in local
    oa_mem_buffer=1          // Store in local buffer 1
    cwram_addr=r12           // Starting addr of conv1 weights
    skip_localmem_clear=0    // Clear buffer first
}
l46:pe_RELU {
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
l47:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r6
    oa_size=32
    ia_row_start=r8          // 24
    ia_col_start=r0          // 0
    ia_row_end=r9            // 32
    ia_col_end=r6            // 8
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=0        // buffer 0
    ia_mem_addr_0=r0
    oa_mem_dir=shared        // shared mem
    oa_mem_addr=r2           // shared mem addr to store in
}



//--------------------------------------------------------------------------------------
l48:pe_MOV {
    ic_size=1                // 1 channel input
    start_ic=0
    current_ic=0
    finish_ic=8
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r11         // 23
    ia_col_start=r14         // 7
    ia_row_end=r9            // 32
    ia_col_end=r3            // 17
    ia_mem_addr_0=r1         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l49:pe_CONV {
    process_kernel_size=3    // 3x3 kernel
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
    ia_size=r13              // 10x10 convolution region
    oa_size=8                // Should result in 8x8x16
    ia_mem_dir_0=local       // Input stored in local mem
    ia_mem_buffer_0=0        // Local mem buffer 0
    oa_mem_dir=local         // Store output in local
    oa_mem_buffer=1          // Store in local buffer 1
    cwram_addr=r12           // Starting addr of conv1 weights
    skip_localmem_clear=0    // Clear buffer first
}
l50:pe_RELU {
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
l51:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r6
    oa_size=32
    ia_row_start=r8          // 24
    ia_col_start=r6          // 8
    ia_row_end=r9            // 32
    ia_col_end=r7            // 16
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=0        // buffer 0
    ia_mem_addr_0=r0
    oa_mem_dir=shared        // shared mem
    oa_mem_addr=r2           // shared mem addr to store in
}



//--------------------------------------------------------------------------------------
l52:pe_MOV {
    ic_size=1                // 1 channel input
    start_ic=0
    current_ic=0
    finish_ic=8
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r11         // 23
    ia_col_start=r15         // 15
    ia_row_end=r9            // 32
    ia_col_end=r5            // 25
    ia_mem_addr_0=r1         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l53:pe_CONV {
    process_kernel_size=3    // 3x3 kernel
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
    ia_size=r13              // 10x10 convolution region
    oa_size=8                // Should result in 8x8x16
    ia_mem_dir_0=local       // Input stored in local mem
    ia_mem_buffer_0=0        // Local mem buffer 0
    oa_mem_dir=local         // Store output in local
    oa_mem_buffer=1          // Store in local buffer 1
    cwram_addr=r12           // Starting addr of conv1 weights
    skip_localmem_clear=0    // Clear buffer first
}
l54:pe_RELU {
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
l55:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r6
    oa_size=32
    ia_row_start=r8          // 24
    ia_col_start=r7          // 16
    ia_row_end=r9            // 32
    ia_col_end=r8            // 24
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=0        // buffer 0
    ia_mem_addr_0=r0
    oa_mem_dir=shared        // shared mem
    oa_mem_addr=r2           // shared mem addr to store in
}

///////////////////////////////////////////////////////////////////////////////
///////////////////// Conv 1 + Relu: End //////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////// Max Pool 1: Start  //////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

l56:ncx_MOVI r7,  #7
ncx_MOVI r12, #10
ncx_MOVI r13, #4
ncx_MOVI r14, #12
ncx_MOVI r15, #16

// need something to hold #15 and it cant be r4
ncx_MOVI r8, #15


// Pool Block 0
//--------------------------------------------------------------------------------------
l57:pe_MOV {
    top_pad_rows=1           // zero pad 1 row of zeros on top
    left_pad_cols=1          // zero pad 1 column of zeros on left
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r0          // 0
    ia_col_start=r0          // 0
    ia_row_end=r10           // 9
    ia_col_end=r10           // 9
    ia_mem_addr_0=r2         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l58:pe_POOL {
    process_kernel_size=3    // 3x3 pool
    stride=2                 // stride 2
    max_0_avg_1=0            // max pool
    shift_width=0            // no shift
    ic_size=16               // 16 channels
    start_ic=0                      
    current_ic=0
    finish_ic=16
    oc_size=16
    start_oc=0
    current_oc=0
    finish_oc=16
    ia_size=r12              // 10x10 size (8x8+halo)
    oa_size=4                // 4x4 output (actual)
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    oa_mem_dir=0
    oa_mem_buffer=1          // Output in buffer 1               
}
l59:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r13
    oa_size=16
    ia_row_start=r0          // 0
    ia_col_start=r0          // 0
    ia_row_end=r13           // 4
    ia_col_end=r13           // 4
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}
// Pool Block 1
//--------------------------------------------------------------------------------------
l60:pe_MOV {
    top_pad_rows=1           // zero pad 1 row of zeros on top
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r0          // 0
    ia_col_start=r7          // 7
    ia_row_end=r10           // 9
    ia_col_end=r3            // 17
    ia_mem_addr_0=r2         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l61:pe_POOL {
    process_kernel_size=3    // 3x3 pool
    stride=2                 // stride 2
    max_0_avg_1=0            // max pool
    shift_width=0            // no shift
    ic_size=16               // 16 channels
    start_ic=0                      
    current_ic=0
    finish_ic=16
    oc_size=16
    start_oc=0
    current_oc=0
    finish_oc=16
    ia_size=r12              // 10x10 size
    oa_size=4                // 4x4 output
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    oa_mem_dir=0
    oa_mem_buffer=1          // Output in buffer 1               
}
l62:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r13
    oa_size=16
    ia_row_start=r0          // 0
    ia_col_start=r13         // 4
    ia_row_end=r13           // 4
    ia_col_end=r6            // 8
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}
// Pool Block 2
//--------------------------------------------------------------------------------------
l63:pe_MOV {
    top_pad_rows=1           // zero pad 1 row of zeros on top
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r0          // 0
    ia_col_start=r8          // 15
    ia_row_end=r10           // 9
    ia_col_end=r5            // 25
    ia_mem_addr_0=r2         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l64:pe_POOL {
    process_kernel_size=3    // 3x3 pool
    stride=2                 // stride 2
    max_0_avg_1=0            // max pool
    shift_width=0            // no shift
    ic_size=16               // 16 channels
    start_ic=0                      
    current_ic=0
    finish_ic=16
    oc_size=16
    start_oc=0
    current_oc=0
    finish_oc=16
    ia_size=r12              // 10x10 size
    oa_size=4                // 4x4 output
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    oa_mem_dir=0
    oa_mem_buffer=1          // Output in buffer 1               
}
l65:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r13
    oa_size=16
    ia_row_start=r0          // 0
    ia_col_start=r6          // 8
    ia_row_end=r13           // 4
    ia_col_end=r14           // 12
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}
// Pool Block 3
//--------------------------------------------------------------------------------------
l66:pe_MOV {
    left_pad_cols=1          // zero pad 1 col of zeros on left
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r7          // 7
    ia_col_start=r0          // 0
    ia_row_end=r3            // 17
    ia_col_end=r10           // 9
    ia_mem_addr_0=r2         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l67:pe_POOL {
    process_kernel_size=3    // 3x3 pool
    stride=2                 // stride 2
    max_0_avg_1=0            // max pool
    shift_width=0            // no shift
    ic_size=16               // 16 channels
    start_ic=0                      
    current_ic=0
    finish_ic=16
    oc_size=16
    start_oc=0
    current_oc=0
    finish_oc=16
    ia_size=r12              // 10x10 size
    oa_size=4                // 4x4 output
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    oa_mem_dir=0
    oa_mem_buffer=1          // Output in buffer 1               
}
l68:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r13
    oa_size=16
    ia_row_start=r13         // 4
    ia_col_start=r0          // 0
    ia_row_end=r6            // 8
    ia_col_end=r13           // 4
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}
// Pool Block 4
//--------------------------------------------------------------------------------------
l69:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r7          // 7
    ia_col_start=r7          // 7
    ia_row_end=r3            // 17
    ia_col_end=r3            // 17
    ia_mem_addr_0=r2         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l70:pe_POOL {
    process_kernel_size=3    // 3x3 pool
    stride=2                 // stride 2
    max_0_avg_1=0            // max pool
    shift_width=0            // no shift
    ic_size=16               // 16 channels
    start_ic=0                      
    current_ic=0
    finish_ic=16
    oc_size=16
    start_oc=0
    current_oc=0
    finish_oc=16
    ia_size=r12              // 10x10 size
    oa_size=4                // 4x4 output
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    oa_mem_dir=0
    oa_mem_buffer=1          // Output in buffer 1               
}
l71:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r13
    oa_size=16
    ia_row_start=r13         // 4
    ia_col_start=r13         // 4
    ia_row_end=r6            // 8
    ia_col_end=r6            // 8
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}
// Pool Block 5
//--------------------------------------------------------------------------------------
l72:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r7          // 7
    ia_col_start=r8          // 15
    ia_row_end=r3            // 17
    ia_col_end=r5            // 25
    ia_mem_addr_0=r2         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l73:pe_POOL {
    process_kernel_size=3    // 3x3 pool
    stride=2                 // stride 2
    max_0_avg_1=0            // max pool
    shift_width=0            // no shift
    ic_size=16               // 16 channels
    start_ic=0                      
    current_ic=0
    finish_ic=16
    oc_size=16
    start_oc=0
    current_oc=0
    finish_oc=16
    ia_size=r12              // 10x10 size
    oa_size=4                // 4x4 output
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    oa_mem_dir=0
    oa_mem_buffer=1          // Output in buffer 1               
}
l74:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r13
    oa_size=16
    ia_row_start=r13         // 4
    ia_col_start=r6          // 8
    ia_row_end=r6            // 8
    ia_col_end=r14           // 12
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}
// Pool Block 6
//--------------------------------------------------------------------------------------
l75:pe_MOV {
    left_pad_cols=1          // zero pad 1 col of zeros on left
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r8          // 15
    ia_col_start=r0          // 0
    ia_row_end=r5            // 25
    ia_col_end=r10           // 9
    ia_mem_addr_0=r2         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l76:pe_POOL {
    process_kernel_size=3    // 3x3 pool
    stride=2                 // stride 2
    max_0_avg_1=0            // max pool
    shift_width=0            // no shift
    ic_size=16               // 16 channels
    start_ic=0                      
    current_ic=0
    finish_ic=16
    oc_size=16
    start_oc=0
    current_oc=0
    finish_oc=16
    ia_size=r12              // 10x10 size
    oa_size=4                // 4x4 output
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    oa_mem_dir=0
    oa_mem_buffer=1          // Output in buffer 1               
}
l77:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r13
    oa_size=16
    ia_row_start=r6          // 8
    ia_col_start=r0          // 0
    ia_row_end=r14           // 12
    ia_col_end=r13           // 4
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}

l77a:ncx_BEQ r0, r0, $l78       // ISP37 specific
ldummy:pe_MOV { 
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r13
    oa_size=16
    ia_row_start=r6          // 8
    ia_col_start=r0          // 0
    ia_row_end=r14           // 12
    ia_col_end=r13           // 4
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}
// Pool Block 7
//--------------------------------------------------------------------------------------
l78:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r8          // 15
    ia_col_start=r7          // 7
    ia_row_end=r5            // 25
    ia_col_end=r3            // 17
    ia_mem_addr_0=r2         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l79:pe_POOL {
    process_kernel_size=3    // 3x3 pool
    stride=2                 // stride 2
    max_0_avg_1=0            // max pool
    shift_width=0            // no shift
    ic_size=16               // 16 channels
    start_ic=0               
    current_ic=0
    finish_ic=16
    oc_size=16
    start_oc=0
    current_oc=0
    finish_oc=16
    ia_size=r12              // 10x10 size
    oa_size=4                // 4x4 output
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    oa_mem_dir=0
    oa_mem_buffer=1          // Output in buffer 1               
}
l80:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r13
    oa_size=16
    ia_row_start=r6          // 8
    ia_col_start=r13         // 4
    ia_row_end=r14           // 12
    ia_col_end=r6            // 8
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}
// Pool Block 8
//--------------------------------------------------------------------------------------
l81:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r8          // 15
    ia_col_start=r8          // 15
    ia_row_end=r5            // 25
    ia_col_end=r5            // 25
    ia_mem_addr_0=r2         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l82:pe_POOL {
    process_kernel_size=3    // 3x3 pool
    stride=2                 // stride 2
    max_0_avg_1=0            // max pool
    shift_width=0            // no shift
    ic_size=16               // 16 channels
    start_ic=0               
    current_ic=0
    finish_ic=16
    oc_size=16
    start_oc=0
    current_oc=0
    finish_oc=16
    ia_size=r12              // 10x10 size
    oa_size=4                // 4x4 output
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    oa_mem_dir=0
    oa_mem_buffer=1          // Output in buffer 1               
}
l83:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r13
    oa_size=16
    ia_row_start=r6          // 8
    ia_col_start=r6          // 8
    ia_row_end=r14           // 12
    ia_col_end=r14           // 12
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}
// Pool Block 9
//--------------------------------------------------------------------------------------
l84:pe_MOV {
    left_pad_cols=1          // zero pad 1 col of zeros on left
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r11         // 23
    ia_col_start=r0          // 0
    ia_row_end=r9            // 32
    ia_col_end=r10           // 9
    ia_mem_addr_0=r2         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l85:pe_POOL {
    process_kernel_size=3    // 3x3 pool
    stride=2                 // stride 2
    max_0_avg_1=0            // max pool
    shift_width=0            // no shift
    ic_size=16               // 16 channels
    start_ic=0               
    current_ic=0
    finish_ic=16
    oc_size=16
    start_oc=0
    current_oc=0
    finish_oc=16
    ia_size=r12              // 10x10 size
    oa_size=4                // 4x4 output
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    oa_mem_dir=0
    oa_mem_buffer=1          // Output in buffer 1               
}
l86:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r13
    oa_size=16
    ia_row_start=r14         // 12
    ia_col_start=r0          // 0
    ia_row_end=r15           // 16
    ia_col_end=r13           // 4
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}
// Pool Block 10
//--------------------------------------------------------------------------------------
l87:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r11         // 23
    ia_col_start=r7          // 7
    ia_row_end=r9            // 32
    ia_col_end=r3            // 17
    ia_mem_addr_0=r2         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l88:pe_POOL {
    process_kernel_size=3    // 3x3 pool
    stride=2                 // stride 2
    max_0_avg_1=0            // max pool
    shift_width=0            // no shift
    ic_size=16               // 16 channels
    start_ic=0               
    current_ic=0
    finish_ic=16
    oc_size=16
    start_oc=0
    current_oc=0
    finish_oc=16
    ia_size=r12              // 10x10 size
    oa_size=4                // 4x4 output
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    oa_mem_dir=0
    oa_mem_buffer=1          // Output in buffer 1               
}
l89:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r13
    oa_size=16
    ia_row_start=r14         // 12
    ia_col_start=r13         // 4
    ia_row_end=r15           // 16
    ia_col_end=r6            // 8
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}
// Pool Block 11
//--------------------------------------------------------------------------------------
l90:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r9               // Input size in r9 (32)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r11         // 23
    ia_col_start=r8          // 15
    ia_row_end=r9            // 32
    ia_col_end=r5            // 25
    ia_mem_addr_0=r2         // Start at 0
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l91:pe_POOL {
    process_kernel_size=3    // 3x3 pool
    stride=2                 // stride 2
    max_0_avg_1=0            // max pool
    shift_width=0            // no shift
    ic_size=16               // 16 channels
    start_ic=0               
    current_ic=0
    finish_ic=16
    oc_size=16
    start_oc=0
    current_oc=0
    finish_oc=16
    ia_size=r12              // 10x10 size
    oa_size=4                // 4x4 output
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    oa_mem_dir=0
    oa_mem_buffer=1          // Output in buffer 1               
}
l92:pe_MOV {
    ic_size=16
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r13
    oa_size=16
    ia_row_start=r14         // 12
    ia_col_start=r6          // 8
    ia_row_end=r15           // 16
    ia_col_end=r14           // 12
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}

///////////////////////////////////////////////////////////////////////////////
///////////////////// Max Pool 1: End  ////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////// Conv 2 + Relu: Start  ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


l93:pe_HUFF {
    w_0_loc_1=0              // Start with w table
    table_start_addr=r17     // Starting address of w table
    table_end_addr=r18       // Ending address of w table 
    last_word_valid_mask=255 // All should be valid!
}
l94:pe_HUFF {
    w_0_loc_1=1              // Load loc table
    table_start_addr=r18     // Starting address of loc table
    table_end_addr=r23       // Ending address of loc table
    last_word_valid_mask=255 // All should be valid!
}

l95:ncx_ADDI r7, r19, #2         // ending addr is start+2 (32 ochan = 16x2 words)
l96:pe_BIAS {
    start_addr=r19           // Starting addr of bias for conv1
    end_addr=r7              // Ending addr of bias for conv1
}

// set constants for this round
l97:ncx_MOVI r7, #7
ncx_MOVI r3, #8
ncx_MOVI r8, #9
ncx_MOVI r5, #10
ncx_MOVI r6, #16

// Convolution Block 0
//--------------------------------------------------------------------------------------
l98:pe_MOV {
    top_pad_rows=1           // zero pad 1 row of zeros on top
    left_pad_cols=1          // zero pad 1 column of zeros on left
    ic_size=16               // 16 channel input
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r6               // Input size in r6 (16)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r0          // 0
    ia_col_start=r0          // 0
    ia_row_end=r8            // 9
    ia_col_end=r8            // 9
    ia_mem_addr_0=r4         // Start at r1
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l99:pe_CONV {
    process_kernel_size=3    // 3x3 kernel
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
    ia_size=r5               // 10x10 convolution region
    oa_size=8                // Should result in 8x8x32
    ia_mem_dir_0=local       // Input stored in local mem
    ia_mem_buffer_0=0        // Local mem buffer 0
    oa_mem_dir=local         // Store output in local
    oa_mem_buffer=1          // Store in local buffer 1
    cwram_addr=r16           // Starting addr of conv2 weights
    skip_localmem_clear=0    // Clear buffer first
}
l100:pe_RELU {
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
l101:pe_MOV {
    ic_size=32
    start_ic=0
    current_ic=0
    finish_ic=32
    ia_size=r3               // 8
    oa_size=16
    ia_row_start=r0          // 0
    ia_col_start=r0          // 0
    ia_row_end=r3            // 8
    ia_col_end=r3            // 8
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=0        // buffer 0
    ia_mem_addr_0=r0
    oa_mem_dir=shared        // shared mem
    oa_mem_addr=r2           // shared mem addr to store in
}
// Convolution Block 1
//--------------------------------------------------------------------------------------
l102:pe_MOV {
    top_pad_rows=1           // zero pad 1 row of zeros on top
    ic_size=16               // 16 channel input
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r6               // Input size in r6 (16)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r0          // 0
    ia_col_start=r7          // 7
    ia_row_end=r8            // 9
    ia_col_end=r6            // 16
    ia_mem_addr_0=r4         // Start at r1
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l103:pe_CONV {
    process_kernel_size=3    // 3x3 kernel
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
    ia_size=r5               // 10x10 convolution region
    oa_size=8                // Should result in 8x8x32
    ia_mem_dir_0=local       // Input stored in local mem
    ia_mem_buffer_0=0        // Local mem buffer 0
    oa_mem_dir=local         // Store output in local
    oa_mem_buffer=1          // Store in local buffer 1
    cwram_addr=r16           // Starting addr of conv2 weights
    skip_localmem_clear=0    // Clear buffer first
}
l104:pe_RELU {
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
l105:pe_MOV {
    ic_size=32
    start_ic=0
    current_ic=0
    finish_ic=32
    ia_size=r3
    oa_size=16
    ia_row_start=r0          // 0
    ia_col_start=r3          // 8
    ia_row_end=r3            // 8
    ia_col_end=r6            // 16
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=0        // buffer 0
    ia_mem_addr_0=r0
    oa_mem_dir=shared        // shared mem
    oa_mem_addr=r2           // shared mem addr to store in
}
// Convolution Block 2
//--------------------------------------------------------------------------------------
l106:pe_MOV {
    left_pad_cols=1          // zero pad 1 column of zeros on left
    ic_size=16               // 16 channel input
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r6               // Input size in r6 (16)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r7          // 7
    ia_col_start=r0          // 0
    ia_row_end=r6            // 16
    ia_col_end=r8            // 9
    ia_mem_addr_0=r4         // Start at r1
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l107:pe_CONV {
    process_kernel_size=3    // 3x3 kernel
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
    ia_size=r5               // 10x10 convolution region
    oa_size=8                // Should result in 8x8x32
    ia_mem_dir_0=local       // Input stored in local mem
    ia_mem_buffer_0=0        // Local mem buffer 0
    oa_mem_dir=local         // Store output in local
    oa_mem_buffer=1          // Store in local buffer 1
    cwram_addr=r16           // Starting addr of conv2 weights
    skip_localmem_clear=0    // Clear buffer first
}
l108:pe_RELU {
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
l109:pe_MOV {
    ic_size=32
    start_ic=0
    current_ic=0
    finish_ic=32
    ia_size=r3
    oa_size=16
    ia_row_start=r3          // 8
    ia_col_start=r0          // 0
    ia_row_end=r6            // 16
    ia_col_end=r3            // 8
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=0        // buffer 0
    ia_mem_addr_0=r0
    oa_mem_dir=shared        // shared mem
    oa_mem_addr=r2           // shared mem addr to store in
}
// Convolution Block 3
//--------------------------------------------------------------------------------------
l110:pe_MOV {
    ic_size=16               // 16 channel input
    start_ic=0
    current_ic=0
    finish_ic=16
    ia_size=r6               // Input size in r6 (16)
    oa_size=10               // 9x9 with halo +1
    ia_row_start=r7          // 7
    ia_col_start=r7          // 7
    ia_row_end=r6            // 16
    ia_col_end=r6            // 16
    ia_mem_addr_0=r4         // Start at r1
    ia_mem_dir_0=shared      // Shared SRAM
    oa_mem_addr=r0           // Move to addr 0 in local
    oa_mem_dir=local         // Local mem
    oa_mem_buffer=0          // buffer 0
}
l111:pe_CONV {
    process_kernel_size=3    // 3x3 kernel
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
    ia_size=r5               // 10x10 convolution region
    oa_size=8                // Should result in 8x8x32
    ia_mem_dir_0=local       // Input stored in local mem
    ia_mem_buffer_0=0        // Local mem buffer 0
    oa_mem_dir=local         // Store output in local
    oa_mem_buffer=1          // Store in local buffer 1
    cwram_addr=r16           // Starting addr of conv2 weights
    skip_localmem_clear=0    // Clear buffer first
}
l112:pe_RELU {
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
l113:pe_MOV {
    ic_size=32
    start_ic=0
    current_ic=0
    finish_ic=32
    ia_size=r3
    oa_size=16
    ia_row_start=r3          // 8
    ia_col_start=r3          // 8
    ia_row_end=r6            // 16
    ia_col_end=r6            // 10
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=0        // buffer 0
    ia_mem_addr_0=r0
    oa_mem_dir=shared        // shared mem
    oa_mem_addr=r2           // shared mem addr to store in
}

///////////////////////////////////////////////////////////////////////////////
///////////////////// Conv 2 + Relu: End  /////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////// Max Pool 2: Start  //////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


// Pool Block 0
//--------------------------------------------------------------------------------------
l114:pe_MOV {
    top_pad_rows=1           // 1 row of zeros before data
    left_pad_cols=1          // 1 col of zeros before data
    ic_size=32               // 16 channel input
    start_ic=0
    current_ic=0
    finish_ic=32
    ia_size=r6               // region size 16
    oa_size=10               // pool on 10x10 region
    ia_row_start=r0          // 0
    ia_col_start=r0          // 0
    ia_row_end=r8            // 9
    ia_col_end=r8            // 9
    ia_mem_dir_0=shared      // in shared mem
    ia_mem_addr_0=r2         // start at addr 1024
    oa_mem_dir=local         // mov to local mem
    oa_mem_addr=r0           // addr 0
    oa_mem_buffer=0          // buffer 0
}
l115:pe_POOL {
    process_kernel_size=3    // 3x3 pool
    stride=2                 // stride 2
    max_0_avg_1=0            // max pool
    shift_width=0            // no shift
    ic_size=32               // 16 channels
    start_ic=0                      
    current_ic=0
    finish_ic=32
    oc_size=32
    start_oc=0
    current_oc=0
    finish_oc=32
    ia_size=r5               // 10x10 size
    oa_size=4                // 4x4 output
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    oa_mem_dir=0
    oa_mem_buffer=1          // Output in buffer 1               
}
l116:pe_MOV {
    ic_size=32
    start_ic=0
    current_ic=0
    finish_ic=32
    ia_size=r13              // 4
    oa_size=8
    ia_row_start=r0          // 0
    ia_col_start=r0          // 0
    ia_row_end=r13           // 4
    ia_col_end=r13           // 4
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}
// Pool Block 1
//--------------------------------------------------------------------------------------
l117:pe_MOV {
    top_pad_rows=1           // 1 row of zeros before data
    ic_size=32               // 16 channel input
    start_ic=0
    current_ic=0
    finish_ic=32
    ia_size=r6               // region size 16
    oa_size=10               // pool on 10x10 region
    ia_row_start=r0          // 0
    ia_col_start=r7          // 7
    ia_row_end=r8            // 9
    ia_col_end=r6            // 16
    ia_mem_dir_0=shared      // in shared mem
    ia_mem_addr_0=r2         // start at addr 1024
    oa_mem_dir=local         // mov to local mem
    oa_mem_addr=r0           // addr 0
    oa_mem_buffer=0          // buffer 0
}
l118:pe_POOL {
    process_kernel_size=3    // 3x3 pool
    stride=2                 // stride 2
    max_0_avg_1=0            // max pool
    shift_width=0            // no shift
    ic_size=32               // 16 channels
    start_ic=0               
    current_ic=0
    finish_ic=32
    oc_size=32
    start_oc=0
    current_oc=0
    finish_oc=32
    ia_size=r5               // 10x10 size
    oa_size=4                // 4x4 output
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    oa_mem_dir=0
    oa_mem_buffer=1          // Output in buffer 1               
}
l119:pe_MOV {
    ic_size=32
    start_ic=0
    current_ic=0
    finish_ic=32
    ia_size=r13
    oa_size=8
    ia_row_start=r0          // 0
    ia_col_start=r13         // 4
    ia_row_end=r13           // 4
    ia_col_end=r3            // 8
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}
// Pool Block 2
//--------------------------------------------------------------------------------------
l120:pe_MOV {
    left_pad_cols=1          // 1 col of zeros before data
    ic_size=32               // 16 channel input
    start_ic=0
    current_ic=0
    finish_ic=32
    ia_size=r6               // region size 16
    oa_size=10               // pool on 10x10 region
    ia_row_start=r7          // 7
    ia_col_start=r0          // 0
    ia_row_end=r6            // 16
    ia_col_end=r8            // 8
    ia_mem_dir_0=shared      // in shared mem
    ia_mem_addr_0=r2         // start at addr 1024
    oa_mem_dir=local         // mov to local mem
    oa_mem_addr=r0           // addr 0
    oa_mem_buffer=0          // buffer 0
}
l121:pe_POOL {
    process_kernel_size=3    // 3x3 pool
    stride=2                 // stride 2
    max_0_avg_1=0            // max pool
    shift_width=0            // no shift
    ic_size=32               // 16 channels
    start_ic=0               
    current_ic=0
    finish_ic=32
    oc_size=32
    start_oc=0
    current_oc=0
    finish_oc=32
    ia_size=r5               // 10x10 size
    oa_size=4                // 4x4 output
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    oa_mem_dir=0
    oa_mem_buffer=1          // Output in buffer 1               
}
l122:pe_MOV {
    ic_size=32
    start_ic=0
    current_ic=0
    finish_ic=32
    ia_size=r13
    oa_size=8
    ia_row_start=r13         // 4
    ia_col_start=r0          // 0
    ia_row_end=r3            // 8
    ia_col_end=r13           // 4
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}
// Pool Block 3
//--------------------------------------------------------------------------------------
l123:pe_MOV {
    ic_size=32               // 16 channel input
    start_ic=0
    current_ic=0
    finish_ic=32
    ia_size=r6               // region size 16
    oa_size=10               // pool on 10x10 region
    ia_row_start=r7          // 7
    ia_col_start=r7          // 7
    ia_row_end=r6            // 16
    ia_col_end=r6            // 16
    ia_mem_dir_0=shared      // in shared mem
    ia_mem_addr_0=r2         // start at addr 1024
    oa_mem_dir=local         // mov to local mem
    oa_mem_addr=r0           // addr 0
    oa_mem_buffer=0          // buffer 0
}
l124:pe_POOL {
    process_kernel_size=3    // 3x3 pool
    stride=2                 // stride 2
    max_0_avg_1=0            // max pool
    shift_width=0            // no shift
    ic_size=32               // 16 channels
    start_ic=0               
    current_ic=0
    finish_ic=32
    oc_size=32
    start_oc=0
    current_oc=0
    finish_oc=32
    ia_size=r5               // 10x10 size
    oa_size=4                // 4x4 output
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    oa_mem_dir=0
    oa_mem_buffer=1          // Output in buffer 1               
}
l125:pe_MOV {
    ic_size=32
    start_ic=0
    current_ic=0
    finish_ic=32
    ia_size=r13
    oa_size=8
    ia_row_start=r13         // 4
    ia_col_start=r13         // 4
    ia_row_end=r3            // 8
    ia_col_end=r3            // 8
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=1        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r4           // base addr in r4
}
///////////////////////////////////////////////////////////////////////////////
///////////////////// Max Pool 2: End  ////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////// Dense Fully Connected 1+2: Start  ///////////////////////
///////////////////////////////////////////////////////////////////////////////

l126:ncx_MOVI r7, #0              // keep track in local buffer
ncx_MOVI r5, #0              // keep track of fc columns
ncx_MOVI r6, #1              // output of dfc2 size
ncx_MOVI r8, #8              // increment between dfc2 weights
ncx_MOVI r10, #0             // offset into bias
ncx_ADDI r18, r22, #5        // bias end is always =start+5
l127:pe_BIAS {
    start_addr=r22           // starting addr of bias
    end_addr=r18             // ending addr of bias
}
l128:pe_MOV {
    ic_size=32
    start_ic=0
    current_ic=0
    finish_ic=32
    ia_size=r3               // region size 8
    oa_size=8
    ia_row_start=r0          // 0
    ia_col_start=r0          // 0
    ia_row_end=r3            // 8
    ia_col_end=r3            // 8
    ia_mem_dir_0=shared      // shared mem
    ia_mem_addr_0=r4         // addr in r1
    oa_mem_dir=local         // store to local
    oa_mem_buffer=0          // buffer 0
    oa_mem_addr=r0           // store at base
}

// first DFC will wipe output localmem buffer first,
// then the following ones all write 1 pixel at a time
// into the same localmem buffer
l129:pe_DFC {
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
    ia_size=r3               // 8x8x32 in mem
    oa_size=1                // scalar output
    insert_chan=r0           // dest channel
    insert_col=r7            // dest col
    insert_row=r5            // dest row
    bias_index=r10           // bias offset in word
    ia_mem_buffer_0=0        // in buffer 0
    oa_mem_buffer=1          // in buffer 1
    cwram_addr=r20
    skip_localmem_clear=0    // WIPE OUTPUT FIRST
}

// now we will actually loop
l130:ncx_ADDI r5, r5, #1          // next fc column
ncx_ADDI r10, r10, #1        // increment offset of bias
ncx_ADDI r20, r20, #32       // next addr of fc weights

dloop: pe_DFC { //l131:
    keep_existing_oa_data=1
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
    ia_size=r3               // 8x8x32 in mem
    oa_size=1                // scalar output
    insert_chan=r0           // dest channel
    insert_col=r7            // dest col
    insert_row=r5            // dest row
    bias_index=r10           // bias offset in word
    ia_mem_dir_0=local       // in local mem
    ia_mem_buffer_0=0        // in buffer 0
    oa_mem_dir=local         // output in local
    oa_mem_buffer=1          // in buffer 1
    cwram_addr=r20
    skip_localmem_clear=1    // do NOT clear output
}

l131a:ncx_BEQ r0, r0, $l132       // ISP37 specific
ldummy2:pe_DFC {
    keep_existing_oa_data=0
    shift_width=8
    include_bias=1
    ic_size=8
    start_ic=0
    current_ic=0
    finish_ic=8
    ia_size=r3               // 8x8x8 in mem
    oa_size=1                // scalar output
    insert_row=r0            // write 1st word
    insert_chan=r0           // 0
    insert_col=r0            // 0
    bias_index=r10           // bias offset in word
    ia_mem_dir_0=local       // in local mem
    ia_mem_buffer_0=1        // in buffer 0
    oa_mem_dir=local         // output in local
    oa_mem_buffer=0          // in buffer 1
    cwram_addr=r21           // fc2 weights
    skip_localmem_clear=1    // do NOT clear output
}

l132:ncx_ADDI r5, r5, #1          // next fc column
ncx_ADDI r10, r10, #1        // increment offset of bias
ncx_ADDI r20, r20, #32       // next addr of fc weights
ncx_BLT r5, r3, $dloop       // go back to the DFC above 8 times
ncx_MOVI r5, #0
ncx_ADDI r7, r7, #1          // increment local mem output
ncx_BLT r7, r3, $dloop       // repeat the above loop another 8 times


// DFC the 1st 8x8x8 (actually 8x8x1) down to a single value
l133:pe_DFC {
    keep_existing_oa_data=0
    shift_width=8
    include_bias=1
    ic_size=8
    start_ic=0
    current_ic=0
    finish_ic=8
    ia_size=r3               // 8x8x8 in mem
    oa_size=1                // scalar output
    insert_row=r0            // write 1st word
    insert_chan=r0           // 0
    insert_col=r0            // 0
    bias_index=r10           // bias offset in word
    ia_mem_dir_0=local       // in local mem
    ia_mem_buffer_0=1        // in buffer 0
    oa_mem_dir=local         // output in local
    oa_mem_buffer=0          // in buffer 1
    cwram_addr=r21           // fc2 weights
    skip_localmem_clear=1    // do NOT clear output
}

// DFC the 2nd 8x8x8 (actually 8x8x1) down to a single value
l134:ncx_ADDI r10, r10, #1
ncx_ADDI r21, r21, #8
ncx_MOVI r1, #1

l135:pe_DFC {
    keep_existing_oa_data=0
    shift_width=8
    include_bias=1
    ic_size=8
    start_ic=0
    current_ic=0
    finish_ic=8
    ia_size=r3               // 8x8x8 in mem
    oa_size=1                // scalar output
    insert_row=r1            // write 2nd word
    insert_chan=r0           // 0
    insert_col=r0            // 0
    bias_index=r10
    ia_mem_dir_0=local       // in local mem
    ia_mem_buffer_0=1        // in buffer 0
    oa_mem_dir=local         // output in local
    oa_mem_buffer=0          // in buffer 1
    cwram_addr=r21           // fc2 weights
    skip_localmem_clear=1    // do not clear output
}

// 2x2 "region" to get those two values back to shared mem
l136:ncx_MOVI r12, #2

l137:pe_MOV {
    ic_size=8
    start_ic=0
    current_ic=0
    finish_ic=8
    ia_size=r8
    oa_size=8
    ia_row_start=r0          // 0
    ia_col_start=r0          // 0
    ia_row_end=r12           // 2
    ia_col_end=r12           // 2
    ia_mem_dir_0=local       // local mem
    ia_mem_buffer_0=0        // in buffer 1
    oa_mem_dir=shared        // store in shared
    oa_mem_addr=r2           // final output is in r2 intermediate region
}



// load results back into NCX registers for easy reading,
// but we first need to do some bit twiddling to convert 512b -> 128b
l138:ncx_MOVI r3, #511            // bottom 9 bits/ncx_AND  r9, r2, r3    // r9 now has word index
ncx_AND  r9, r2, r3          // r9 now has word index
ncx_MOVI r11, #15872         // 0x3E00 mask
ncx_AND  r13, r2, r11        // r10 now has set & superset index
ncx_LSL  r19, r13, #2        // << this info by 2 to create gap in bits [10:9]
ncx_OR   r2,  r9, r19        // r2 should now have the twiddled result

ncx_MOVI r0, #0
ncx_MOVI r3, #255            // just want bottom 8 bit result, mask with 0x00FF
l139:ncx_LDS  r5, r0, r2          // load from the r2 region above into register r5
ncx_AND  r5, r5, r3          // mask 0x00FF
ncx_ADDI r2, r2, #1          // increment to next row
ncx_LDS  r7, r0, r2          // load from r2+1 into r7  
ncx_AND  r7, r7, r3          // mask 0x00FF

//r5=75/r7=84

////////////////////////////////////////////////////////////////
// FINAL RESULTS ARE NOW IN r5 AND r7 FOR M0 TO READ OVER AHB //
////////////////////////////////////////////////////////////////

// yay, finally done
ncx_HALT
