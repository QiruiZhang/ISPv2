//*******************************************************************
//Author: Hyochan An
//*******************************************************************
//
#include "CMPv1.h"
#include "CMPv1_H264.h"
#include "CMPv1_FLS.h"
#include "CMPv1_NE.h"
#include "CMPv1_IMGIF.h"
#include "FLPv2S_RF.h"
#include "PMUv7H_RF.h"
#include "SNSv10_RF.h"
#include "RDCv1_RF.h"
#include "mbus.h"

#define PRE_ADDR    0x1
#define FLP_ADDR    0x4
#define NODE_A_ADDR 0x8
#define SNS_ADDR    0xC
#define RDC_ADDR    0x5
#define PMU_ADDR    0xE

// FLPv2S Payloads
#define ERASE_PASS  0x4F

// Flag Idx
#define FLAG_ENUM       0
#define FLAG_PMU_SUB_0  1
#define FLAG_PMU_SUB_1  2
#define FLAG_GPIO_SUB   3

//********************************************************************
// Global Variables
//********************************************************************
volatile uint32_t cyc_num;
volatile uint32_t ind_mau;
volatile uint32_t irq_history;

int frame_flag;
int flash_flag;
int md_flag;
int h264_flag;
int ne_flag;
int mbustx_flag;
int mbusrx_flag;

//*******************************************************************
// INTERRUPT HANDLERS
//*******************************************************************
void handler_ext_int_softreset(void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_mbusmem  (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_reg0     (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_reg1     (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_reg2     (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_reg3     (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_reg4     (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_reg5     (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_reg6     (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_reg7     (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_mbusfwd  (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_mbusrx   (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_mbustx   (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_md       (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_vga      (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_ne       (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_fls      (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_h264     (void) __attribute__ ((interrupt ("IRQ")));
void handler_ext_int_h264_fifordy(void) __attribute__ ((interrupt ("IRQ")));


void handler_ext_int_softreset(void) { // SOFT_RESET
    *NVIC_ICPR = (0x1 << IRQ_SOFT_RESET); irq_history |= (0x1 << IRQ_SOFT_RESET);
    arb_debug_reg(IRQ_SOFT_RESET, 0x00000000);
}
void handler_ext_int_mbusmem(void) { // MBUS_MEM_WR
    *NVIC_ICPR = (0x1 << IRQ_MBUS_MEM); irq_history |= (0x1 << IRQ_MBUS_MEM);
    arb_debug_reg(IRQ_MBUS_MEM, 0x00000000);
}
void handler_ext_int_reg0(void) { // REG0
    *NVIC_ICPR = (0x1 << IRQ_REG0); irq_history |= (0x1 << IRQ_REG0);
    arb_debug_reg(IRQ_REG0, 0x00000000);
}
void handler_ext_int_reg1(void) { // REG1
    *NVIC_ICPR = (0x1 << IRQ_REG1); irq_history |= (0x1 << IRQ_REG1);
    arb_debug_reg(IRQ_REG1, 0x00000000);
}
void handler_ext_int_reg2(void) { // REG2
	*NVIC_ICPR = (0x1 << IRQ_REG2); irq_history |= (0x1 << IRQ_REG2);
    arb_debug_reg(IRQ_REG2, 0x00000000);
}
void handler_ext_int_reg3(void) { // REG3
    *NVIC_ICPR = (0x1 << IRQ_REG3); irq_history |= (0x1 << IRQ_REG3);
    arb_debug_reg(IRQ_REG3, 0x00000000);
}
void handler_ext_int_reg4(void) { // REG4
    *NVIC_ICPR = (0x1 << IRQ_REG4); irq_history |= (0x1 << IRQ_REG4);
    arb_debug_reg(IRQ_REG4, 0x00000000);
}
void handler_ext_int_reg5(void) { // REG5
    *NVIC_ICPR = (0x1 << IRQ_REG5); irq_history |= (0x1 << IRQ_REG5);
    arb_debug_reg(IRQ_REG5, 0x00000000);
}
void handler_ext_int_reg6(void) { // REG6
    *NVIC_ICPR = (0x1 << IRQ_REG6); irq_history |= (0x1 << IRQ_REG6);
    arb_debug_reg(IRQ_REG6, 0x00000000);
}
void handler_ext_int_reg7(void) { // REG7
    *NVIC_ICPR = (0x1 << IRQ_REG7); irq_history |= (0x1 << IRQ_REG7);
    arb_debug_reg(IRQ_REG7, 0x00000000);
}
void handler_ext_int_mbusfwd(void) { // MBUS_FWD
    *NVIC_ICPR = (0x1 << IRQ_MBUS_FWD); irq_history |= (0x1 << IRQ_MBUS_FWD);
    arb_debug_reg(IRQ_MBUS_FWD, 0x00000000);
}
void handler_ext_int_mbusrx(void) { // MBUS_RX
    *NVIC_ICPR = (0x1 << IRQ_MBUS_RX); irq_history |= (0x1 << IRQ_MBUS_RX);
    arb_debug_reg(IRQ_MBUS_RX, 0x00000000);
	*CMPv1_RX_IRQ = 1;
}
void handler_ext_int_mbustx(void) { // MBUS_TX
    *NVIC_ICPR = (0x1 << IRQ_MBUS_TX); irq_history |= (0x1 << IRQ_MBUS_TX);
    arb_debug_reg(IRQ_MBUS_TX, 0x00000000);
	*CMPv1_TX_IRQ = 1;
}
void handler_ext_int_md(void) { // MOTION_DETECTION
    *NVIC_ICPR = (0x1 << IRQ_MD); irq_history |= (0x1 << IRQ_MD);
    arb_debug_reg(IRQ_MD, 0x00000000);
	md_flag=1;
}
void handler_ext_int_vga(void) { // VGA
    *NVIC_ICPR = (0x1 << IRQ_VGA); irq_history |= (0x1 << IRQ_VGA);
    arb_debug_reg(IRQ_VGA, 0x00000000);
	frame_flag=1;
	imgif_clear_enc_done_int();
}
void handler_ext_int_ne(void) { // NE
    *NVIC_ICPR = (0x1 << IRQ_NE); irq_history |= (0x1 << IRQ_NE);
    arb_debug_reg(IRQ_NE, 0x00000000);
	ne_flag=1;
	ne_clear_interrupt();
}
void handler_ext_int_fls(void) { // FLS
    *NVIC_ICPR = (0x1 << IRQ_FLS); irq_history |= (0x1 << IRQ_FLS);
    arb_debug_reg(IRQ_FLS, 0x00000000);
	p_FLSIF_INTR->as_int  = 1;
	flash_flag=1;
}
void handler_ext_int_h264(void) { // H264
    *NVIC_ICPR = (0x1 << IRQ_H264); irq_history |= (0x1 << IRQ_H264);
    arb_debug_reg(IRQ_H264, 0x00000000);
	p_H264_INTR_DONE->as_int = 1;
	h264_flag=1;
}
void handler_ext_int_h264_fifordy(void) { // H264_fifordy
    *NVIC_ICPR = (0x1 << IRQ_H264_FIFORDY); irq_history |= (0x1 << IRQ_H264_FIFORDY);
    arb_debug_reg(IRQ_H264_FIFORDY, 0x00000000);
	p_H264_INTR_FIFO->as_int = 1;
}

//*******************************************************************
// USER FUNCTIONS
//*******************************************************************

//********************************************************************
// MAIN function starts here             
//********************************************************************

int main() {
	//********************************************************************
	//********************************************************************
	// MEM access test
	//********************************************************************
	//********************************************************************
	//enable_all_irq();
	enable_irq(0xFFFFF9FF);
	int i;
	int pat_cnt;
	int temp_reg;

	int pattern [8]; 
	pattern[0] = 0xDEADBEEF;
	pattern[1] = 0xABCDEF00; 
	pattern[2] = 0xAAAABBBB; 
	pattern[3] = 0xCCCCDDDD; 
	pattern[4] = 0xEEEEFFFF; 
	pattern[5] = 0xABABABAB; 
	pattern[6] = 0xCDCDCDCD;
	pattern[7] = 0xEFEFEFEF;

	imgif_initialize();
	//1. first write all data in all SRAM (You can use certain round-robin pattern)
	//2. read data in all SRAM and match
	//This is because of N2W works as a buffer
	//********************************************************************
	// IMG IF access test
	//********************************************************************
	arb_debug_ascii(0xD3, "IMGIF "); 
	imgif_mem_access_enable();
	
	//1. min max memory bank (64x512)	
 	arb_debug_ascii(0xD4, "MMAX"); 

	pat_cnt=0;
	// write pattern
	for(i=0;i<1024;i=i+1){
		*(p_MINMAX_SRAM_START+i)=pattern[pat_cnt];
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	pat_cnt=0;
	for(i=0;i<1024;i=i+1){
		temp_reg=*(p_MINMAX_SRAM_START+i);
		if(temp_reg != pattern[pat_cnt]) arb_debug_ascii(0xD5, "ERR"); else arb_debug_ascii(0xD5, "SUC"); 
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}

	//2. CD mem//64x512 (4) 128x512(4)
 	arb_debug_ascii(0xD4, "CDME"); 
	pat_cnt=0;
	// write pattern
	for(i=0;i<(2048*4 + 1024*4)*8/6;i=i+1){
		if(i%8 == 6 | i%8 == 7)
			continue;
		*(p_CD_SRAM_START+i)=pattern[pat_cnt];
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	pat_cnt=0;
	for(i=0;i<(2048*4 + 1024*4)*8/6;i=i+1){
		if(i%8 == 6 | i%8 == 7)
			continue;
		temp_reg=*(p_CD_SRAM_START+i);
		if(temp_reg != pattern[pat_cnt]) arb_debug_ascii(0xD5, "ERR"); else arb_debug_ascii(0xD5, "SUC"); 
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}

	//3. Ref mem//64x512 (3)
 	arb_debug_ascii(0xD4, "REFM"); 
	pat_cnt=0;
	// write pattern
	for(i=0;i<(1024*3);i=i+1){
		*(p_REF_SRAM_START+i)=pattern[pat_cnt];
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	pat_cnt=0;
	for(i=0;i<(1024*3);i=i+1){
		temp_reg=*(p_REF_SRAM_START+i);
		if(temp_reg != pattern[pat_cnt]) arb_debug_ascii(0xD5, "ERR"); else arb_debug_ascii(0xD5, "SUC"); 
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}

	//4. compmeme 64x512 (55)
 	arb_debug_ascii(0xD4, "COMP"); 
	pat_cnt=0;
	// write pattern
	for(i=0;i<(1024*55);i=i+1){
		*(p_COMP_SRAM_START+i)=pattern[pat_cnt];
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	pat_cnt=0;
	for(i=0;i<(1024*55);i=i+1){
		temp_reg=*(p_COMP_SRAM_START+i);
		if(temp_reg != pattern[pat_cnt]) arb_debug_ascii(0xD5, "ERR"); else arb_debug_ascii(0xD5, "SUC"); 
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	
	////********************************************************************
	//// NE access test
	////********************************************************************
	arb_debug_ascii(0xD3, "NE  ");


	//1. shared memory
	////128x512 (80)
	arb_debug_ascii(0xD4, "SHAR"); 
	pat_cnt=0;
	// write pattern
	for(i=0;i<(2048*52);i=i+1){
		*(p_NE_SHARED_MEM_START+i)=pattern[pat_cnt];
		//if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
		if(pat_cnt == 6){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	pat_cnt=0;
	for(i=0;i<(2048*52);i=i+1){
		temp_reg=*(p_NE_SHARED_MEM_START+i);
		if(temp_reg != pattern[pat_cnt]) arb_debug_ascii(0xD5, "ERR"); else arb_debug_ascii(0xD5, "SUC"); 
		//if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
		if(pat_cnt == 6){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	//simple version
	pat_cnt=0;
    	p_NE_CONF_AUTOGATE_PE->as_int = 0x10;
	for(i=0;i<(2048*5);i=i+1){
		*(p_NE_SHARED_MEM_START+i)=pattern[pat_cnt];
		//if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
		if(pat_cnt == 6){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	pat_cnt=0;
	for(i=0;i<(2048*5);i=i+1){
		temp_reg=*(p_NE_SHARED_MEM_START+i);
		if(temp_reg != pattern[pat_cnt]) arb_debug_ascii(0xD5, "ERR"); else arb_debug_ascii(0xD5, "SUC"); 
		//if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
		if(pat_cnt == 6){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}

	//2. weight memory
	//256x256 (4 )
	arb_debug_ascii(0xD4, "WEIG"); 
	pat_cnt=0;
	// write pattern
	for(i=0;i<(2048*4);i=i+1){
		*(p_NE_PE_WEIGHTBUF_START+i)=pattern[pat_cnt];
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	pat_cnt=0;
	for(i=0;i<(2048*4);i=i+1){
		temp_reg=*(p_NE_PE_WEIGHTBUF_START+i);
		if(temp_reg != pattern[pat_cnt]) arb_debug_ascii(0xD5, "ERR"); else arb_debug_ascii(0xD5, "SUC"); 
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}

	//3. Instr memeory
	//128x512 (2 )
	arb_debug_ascii(0xD4, "INST"); 
	pat_cnt=0;
	// write pattern
	for(i=0;i<(2048*2);i=i+1){
		*(p_NE_IMEM_START+i)=pattern[pat_cnt];
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	pat_cnt=0;
	for(i=0;i<(2048*2);i=i+1){
		temp_reg=*(p_NE_IMEM_START+i);
		if(temp_reg != pattern[pat_cnt]) arb_debug_ascii(0xD5, "ERR"); else arb_debug_ascii(0xD5, "SUC"); 
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	//4. local memeory
	//256x256 (4 )
	arb_debug_ascii(0xD4, "LOCA"); 
	pat_cnt=0;
	// write pattern
	for(i=0;i<(2048*4);i=i+1){
		*(p_NE_PE_LOCALMEM_START+i)=pattern[pat_cnt];
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	pat_cnt=0;
	for(i=0;i<(2048*4);i=i+1){
		temp_reg=*(p_NE_PE_LOCALMEM_START+i);
		if(temp_reg != pattern[pat_cnt]) arb_debug_ascii(0xD5, "ERR"); else arb_debug_ascii(0xD5, "SUC"); 
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	//5. accum memeory
	//32x32   (64)
	arb_debug_ascii(0xD4, "ACCU"); 
	ne_mem_access();
	pat_cnt=0;
	// write pattern
	for(i=0;i<(32*64);i=i+1){
		*(p_NE_PE_ACCUMULATORS_START+i)=pattern[pat_cnt];
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	pat_cnt=0;
	for(i=0;i<(32*64);i=i+1){
		temp_reg=*(p_NE_PE_ACCUMULATORS_START+i);
		if(temp_reg != pattern[pat_cnt]) arb_debug_ascii(0xD5, "ERR"); else arb_debug_ascii(0xD5, "SUC"); 
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	//6. Bias memeory
	//128x512 (1 )
	arb_debug_ascii(0xD4, "BIAS"); 
	pat_cnt=0;
	// write pattern
	for(i=0;i<2048*1;i=i+1){
		*(p_NE_PE_BIAS_BUFFER_START+i)=pattern[pat_cnt];
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	pat_cnt=0;
	for(i=0;i<2048*1;i=i+1){
		temp_reg=*(p_NE_PE_BIAS_BUFFER_START+i);
		if(temp_reg != pattern[pat_cnt]) arb_debug_ascii(0xD5, "ERR"); else arb_debug_ascii(0xD5, "SUC"); 
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	
	//********************************************************************
	// H264 access test
	//********************************************************************
	arb_debug_ascii(0xD3, "H264");
	
	h264_initialize();
	h264_mem_direct_access();
	
	pat_cnt = 0;
	for (i = 0; i < 1024; i++) {
		(p_H264_MEM_START+i)->as_int = pattern[pat_cnt];
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}
	// complementary read to flush the N2W buffer
	temp_reg = (p_H264_MEM_START + 1023) -> as_int;

	pat_cnt=0;
	for(i=0;i<1024;i=i+1){
		temp_reg=(p_H264_MEM_START+i) -> as_int;
		if(temp_reg != pattern[pat_cnt]) arb_debug_ascii(0xD5, "ERR"); else arb_debug_ascii(0xD5, "SUC"); 
		if(pat_cnt == 7){pat_cnt = 0;}else{pat_cnt = pat_cnt+1;}
	}

	
	//********************************************************************
	// FINISH             
	//********************************************************************
	arb_debug_ascii(0xD3, "CYAB"); //Print 4 chars 
	arb_debug_ascii(0xD4, "CYA "); //Print 4 chars 
	arb_debug_ascii(0xD5, "MAGB"); //Print 4 chars 
	arb_debug_ascii(0xD6, "MAG "); //Print 4 chars 
	arb_debug_ascii(0xD7, "YELB"); //Print 4 chars 
	arb_debug_ascii(0xD8, "YEL "); //Print 4 chars 
	arb_debug_ascii(0xD9, "GREB"); //Print 4 chars 
	arb_debug_ascii(0xDA, "GRE "); //Print 4 chars 
	arb_debug_reg(0xDB, 0xBEEF);   //Print 32bit hexacode
	arb_debug_reg(0xFF, 0);//END_OF_PROGRAM

	while(1){ delay(1); }
    return 1;
}
