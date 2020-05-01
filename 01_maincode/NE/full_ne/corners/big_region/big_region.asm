///////////////////////////////////
// 256x256 input image CP_B test //
///////////////////////////////////

ncx_MOVI    r0, #0          // McB index
ncx_MOVI    r1, #0          // dest base addr
ncx_MOVI    r2, #16         // region width (McB's)
ncx_MOVI    r3, #0          // McB row counter

ncx_MOVI    r4, #0          // McB col counter

ncx_CP_B    r0, r1, r2
ncx_ADDI    r1, r1, #2
ncx_ADDI    r0, r0, #1
ncx_ADDI    r4, r4, #1
ncx_BLT     r4, r2, #0, #5

ncx_ADDI    r3, r3, #1
ncx_LSL     r5, r3, #9      // r5=r3*512 (#addrs in 1 row)
ncx_MOV     r1, r5
ncx_BLT     r3, r2, #0, #5

ncx_HALT
