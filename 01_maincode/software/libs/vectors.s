.cpu cortex-m0
.syntax unified
.thumb

/* Interrupt Vector Table for CMPv1 (64kB SRAM) */
.section .vectors
.word	0x10000	@ stack top
.word	_start	@ reset vector
.word   handler_nmi          /* 2 NMI */
.word   handler_hard         /* 3 HardFault */
.word   hang                 /* 4 RESERVED */
.word   hang                 /* 5 RESERVED */
.word   hang                 /* 6 RESERVED */
.word   hang                 /* 7 RESERVED */
.word   hang                 /* 8 RESERVED */
.word   hang                 /* 9 RESERVED*/
.word   hang                 /* 10 RESERVED */
.word   handler_svcall       /* 11 SVCall */
.word   hang                 /* 12 RESERVED */
.word   hang                 /* 13 RESERVED */
.word   handler_pendsv       /* 14 PendSV */
.word   handler_systick      /* 15 SysTick */
.word   handler_ext_int_softreset   /* 16 External Interrupt(0)  */
.word   handler_ext_int_mbusmem     /* 17 External Interrupt(1)  */
.word   handler_ext_int_reg0        /* 18 External Interrupt(2)  */
.word   handler_ext_int_reg1        /* 19 External Interrupt(3)  */
.word   handler_ext_int_reg2        /* 20 External Interrupt(4)  */
.word   handler_ext_int_reg3        /* 21 External Interrupt(5)  */
.word   handler_ext_int_reg4        /* 22 External Interrupt(6)  */
.word   handler_ext_int_reg5        /* 23 External Interrupt(7)  */
.word   handler_ext_int_reg6        /* 24 External Interrupt(8)  */
.word   handler_ext_int_reg7        /* 25 External Interrupt(9)  */
.word   handler_ext_int_mbusfwd     /* 26 External Interrupt(10) */
.word   handler_ext_int_mbusrx      /* 27 External Interrupt(11) */
.word   handler_ext_int_mbustx      /* 28 External Interrupt(12) */
.word   handler_ext_int_md          /* 29 External Interrupt(13) */
.word   handler_ext_int_vga         /* 30 External Interrupt(14) */
.word   handler_ext_int_ne          /* 31 External Interrupt(15) */
.word   handler_ext_int_fls         /* 32 External Interrupt(16) */
.word   handler_ext_int_h264        /* 33 External Interrupt(17) */
.word   handler_ext_int_h264_fifordy/* 34 External Interrupt(18) */
.word   handler_ext_int_h264_stall  /* 35 External Interrupt(19) */


.align 4
.thumb_func
hang:   b .

.weak handler_nmi, hang
.weak handler_hard, hang
.weak handler_svcall, hang
.weak handler_pendsv, hang
.weak handler_systick, hang
.weak handler_ext_int_softreset ,hang
.weak handler_ext_int_mbusmem ,hang
.weak handler_ext_int_reg0 ,hang
.weak handler_ext_int_reg1 ,hang
.weak handler_ext_int_reg2 ,hang
.weak handler_ext_int_reg3 ,hang
.weak handler_ext_int_reg4 ,hang
.weak handler_ext_int_reg5 ,hang
.weak handler_ext_int_reg6 ,hang
.weak handler_ext_int_reg7 ,hang
.weak handler_ext_int_mbusfwd ,hang
.weak handler_ext_int_mbusrx ,hang
.weak handler_ext_int_mbustx ,hang
.weak handler_ext_int_md ,hang
.weak handler_ext_int_vg ,hang
.weak handler_ext_int_ne ,hang
.weak handler_ext_int_fls ,hang
.weak handler_ext_int_h264 ,hang
.weak handler_ext_int_h264_fifordy ,hang
.weak handler_ext_int_h264_stall ,hang

.text
.func _start
.global _start
_start:
	bl main		@ call main() function
	b _start	@ expect to never get here, but just in case restart
.endfunc

.end
