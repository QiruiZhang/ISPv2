///////////////////////////////////
// 192x192 densemode pe_MOV test //
///////////////////////////////////

ncx_MOVI    r0, #0          // McB index
ncx_MOVI    r1, #0          // dest base addr
ncx_MOVI    r2, #192        // total # McB

ncx_CP_B    r0, r1, r2, dense  // r2 ignored in densemode
ncx_ADDI    r1, r1, #4
ncx_ADDI    r0, r0, #1
ncx_ADDI    r4, r4, #1
ncx_BLT     r4, r2, #0, #3


// always zero
ncx_MOVI r19, #0



///////////////////////////////////////////////
// Now do pe_MOV in and out at various sizes //
///////////////////////////////////////////////



//   8x8x192
//----------------
ncx_MOVI r18, #8   // ia_size
ncx_MOVI r20, #0   // row/col_start
ncx_MOVI r21, #8   // row/col_end
pe_MOV {
    process_kernel_size=0
    output_kernel_size=0         
    ic_size=192
    start_ic=0
    current_ic=0
    finish_ic=192
    oc_size=192      
    start_oc=0
    current_oc=0
    finish_oc=192
    ia_size=r18
    oa_size=8
    ia_mem_addr_0=r19
    ia_mem_dir_0=1
    oa_mem_dir=0
    oa_mem_buffer=0
    oa_mem_addr=r19
    ia_row_start=r20
    ia_col_start=r20
    ia_row_end=r21
    ia_col_end=r21
}

ncx_MOVI r23, #2000  // destination in shared mem
ncx_MOVI r18, #8

pe_MOV {
    process_kernel_size=0
    output_kernel_size=0         
    ic_size=192
    start_ic=0
    current_ic=0
    finish_ic=192
    oc_size=192
    start_oc=0
    current_oc=0
    finish_oc=192
    ia_size=r18
    oa_size=8
    ia_mem_dir_0=0
    ia_mem_buffer_0=0
    ia_mem_addr_0=r19
    oa_mem_dir=1
    oa_mem_addr=r23
    ia_row_size=8
    ia_col_size=8
    ia_row_start=r20
    ia_col_start=r20
    ia_row_end=r21
    ia_col_end=r21
    conv_clear_finished=1
}



ncx_HALT
