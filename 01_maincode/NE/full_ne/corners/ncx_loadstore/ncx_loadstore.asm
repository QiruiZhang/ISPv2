///////////////////////////
// NCX STORE & LOAD TEST //
///////////////////////////



//------------------------------------------------------
// write incrementing value to incrementing 16b chunk,
// then increment dest addr, then read them all back
//------------------------------------------------------
ncx_MOVI    r3, #1000               // dest memory addr
ncx_MOVI    r5, #1005               // stop at this addr (inclusive)
ncx_MOVI    r1, #420                // initial write data

ncx_MOVI    r0, #8                  // 8x16b = 128b
ncx_MOVI    r2, #0                  // 16b chunk select
ncx_MOVI    r4, #0                  // loop counter

ncx_STS     r1, r2, r3              // mem[r3][r2+:16] = r1
ncx_ADDI    r1, r1, #1
ncx_ADDI    r2, r2, #1
ncx_ADDI    r4, r4, #1
ncx_BLT     r4, r0, #0, #6          // loop back to STS 8 times

ncx_ADDI    r3, r3, #1
ncx_BLE     r3, r5, #0, #3          // repeat the above for new mem addr




//--------------------------------------------
// now read a few back out into a ton of regs
//--------------------------------------------
ncx_MOVI    r3, #1000
ncx_MOVI    r2, #0
ncx_LDS     r6, r2, r3
ncx_ADDI    r2, r2, #1
ncx_LDS     r7, r2, r3
ncx_ADDI    r2, r2, #1
ncx_LDS     r8, r2, r3
ncx_ADDI    r2, r2, #1
ncx_LDS     r9, r2, r3
ncx_ADDI    r2, r2, #1
ncx_LDS     r10, r2, r3
ncx_ADDI    r2, r2, #1
ncx_LDS     r11, r2, r3
ncx_ADDI    r2, r2, #1
ncx_LDS     r12, r2, r3
ncx_ADDI    r2, r2, #1
ncx_LDS     r13, r2, r3
ncx_ADDI    r2, r2, #1

ncx_MOVI    r3, #1005
ncx_MOVI    r2, #0
ncx_LDS     r14, r2, r3
ncx_ADDI    r2, r2, #1
ncx_LDS     r15, r2, r3
ncx_ADDI    r2, r2, #1
ncx_LDS     r16, r2, r3
ncx_ADDI    r2, r2, #1
ncx_LDS     r17, r2, r3
ncx_ADDI    r2, r2, #1
ncx_LDS     r18, r2, r3
ncx_ADDI    r2, r2, #1
ncx_LDS     r19, r2, r3
ncx_ADDI    r2, r2, #1
ncx_LDS     r20, r2, r3
ncx_ADDI    r2, r2, #1
ncx_LDS     r21, r2, r3



// done, see regfile dump for result
ncx_HALT
