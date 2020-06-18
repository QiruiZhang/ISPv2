//*******************************************************************
//Author: Hyochan An
//*******************************************************************
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

//volatile flpv2s_r0F_t FLPv2S_R0F_IRQ      = FLPv2S_R0F_DEFAULT;
//volatile flpv2s_r12_t FLPv2S_R12_PWR_CONF = FLPv2S_R12_DEFAULT;
//volatile flpv2s_r07_t FLPv2S_R07_GO       = FLPv2S_R07_DEFAULT;
//
//volatile pmuv7h_r51_t PMUv7H_R51_CONF = PMUv7H_R51_DEFAULT;
//volatile pmuv7h_r52_t PMUv7H_R52_IRQ  = PMUv7H_R52_DEFAULT;

// Select Testing
volatile uint32_t do_cycle0  = 1; // System Halt and Resume
volatile uint32_t do_cycle1  = 1; // PMU Testing
volatile uint32_t do_cycle2  = 1; // Register test
volatile uint32_t do_cycle3  = 1; // MEM IRQ
volatile uint32_t do_cycle4  = 1; // Flash Erase
volatile uint32_t do_cycle5  = 1; // Memory Streaming 1
volatile uint32_t do_cycle6  = 1; // Memory Streaming 2
volatile uint32_t do_cycle7  = 1; // TIMER16
volatile uint32_t do_cycle8  = 1; // TIMER32
#ifdef PREv17
volatile uint32_t do_cycle9  = 1; // GPIO (only for PRE)
volatile uint32_t do_cycle10 = 1; // SPI (only for PRE)
#else
volatile uint32_t do_cycle9  = 0;
volatile uint32_t do_cycle10 = 0;
#endif
volatile uint32_t do_cycle11 = 1; // Watch-Dog

int frame_flag;
int flash_flag;
int md_flag;
int h264_flag;
int ne_flag;



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
	imgif_clear_md_done_int();
	md_flag=1;
}
void handler_ext_int_vga(void) { // VGA
    *NVIC_ICPR = (0x1 << IRQ_VGA); irq_history |= (0x1 << IRQ_VGA);
    arb_debug_reg(IRQ_VGA, 0x00000000);
	frame_flag=1;
	imgif_clear_enc_done_int();
	p_COMPMEM_CONFIG->compmem_config_dec_en = 1;
	//ne_enable();
}
void handler_ext_int_ne(void) { // NE
	         	flsif_senddata(0xFFAA);
    *NVIC_ICPR = (0x1 << IRQ_NE); irq_history |= (0x1 << IRQ_NE);
	         	flsif_senddata(0xFFAA);
    arb_debug_reg(IRQ_NE, 0x00000000);
	ne_flag=1;
	         	flsif_senddata(0xFFAA);
	ne_clear_interrupt();
}
void handler_ext_int_fls(void) { // FLS
    *NVIC_ICPR = (0x1 << IRQ_FLS); irq_history |= (0x1 << IRQ_FLS);
    arb_debug_reg(IRQ_FLS, 0x00000000);
	p_FLSIF_INTR->as_int  = 0;
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
}

//*******************************************************************
// USER FUNCTIONS
//*******************************************************************
void merge_md_arr(uint32_t md_frame_arr_in[32][20], uint32_t merged_arr[32][5]) {

	int r;
	int c;

	for(r=0;r<32;r++) {
		for(c=0;c<5;c++) {
			merged_arr[r][c] = 	(md_frame_arr_in[r][c*4+3]<<24) 	+ 
					     	(md_frame_arr_in[r][c*4+2]<<16) 	+
					    	(md_frame_arr_in[r][c*4+1]<<8)  	+
						md_frame_arr_in[r][c*4];

			// Printing debug
//		 	arb_debug_ascii(0xDA, "PRNT");
//			arb_debug_reg(0xDB, r);
//			arb_debug_reg(0xDB, c);
//			arb_debug_reg(0xDB, merged_arr[r][c]);
		}
	}

}

void print_md_frame_arr(uint32_t md_frame_arr_in[32][20]) {
	int r;
	int c;

	arb_debug_ascii(0xDA, "PRMD");

	for(r=0;r<32;r++) {
		for(c=0;c<20;c++) {
			arb_debug_reg(0xDB, r);
			arb_debug_reg(0xDB, c);
			arb_debug_reg(0xDB, md_frame_arr_in[r][c]);
		}
	}
}

//********************************************************************
// MAIN function starts here             
//********************************************************************
#define   p_     ((volatile uint32_t                     *) 0xA01D6100)

int main() {
	//********************************************************************
	//********************************************************************
	// MD FRAME TEST ut
	//********************************************************************
	//********************************************************************

	int i;
	int chunk;
	int mode=2; //1: just bayer output, 2: NE works

	uint32_t merged_frame[32][5];
	uint32_t md_frame_arr[32][20];

	uint32_t temp0;
	uint32_t temp1;
	int r;
	int c;
	
	frame_flag=0;
	flash_flag=0;
	h264_flag=0;
	md_flag=0;
	ne_flag=0;
	enable_all_irq();
	//enable_irq(0xFFFFF9FF);
	
	//fls if intialize
	flsif_initialize(0x3, 0x3); //AHB path
	p_NE_RESET_AND_ENABLE->as_int=0x11;
	flsif_senddata(p_NE_RESET_AND_ENABLE->as_int);
	
	//h264 initialize
	//h264_initialize();
	//h264_config(p_H264_COMPMEM_SADDR_YREF->as_int, p_H264_COMPMEM_SADDR_UVREF->as_int, 20,1);//quality factor = 10
	
	//imager if intialize
	imgif_intensity_mode_enable();
	imgif_initialize();

	rf_write(0,22);
	//wait for motion detection
    	while(1){  delay(1); if(md_flag){ md_flag = 0; break; } }

	//imgif_mem_access_enable();
	dbg_imgif_disable_md_shift();
	p_B_CONV->min = 0; // set manual minimum to 0 - default is 70
	imgif_md_frame_read(md_frame_arr);
	merge_md_arr(md_frame_arr, merged_frame);

	if(mode == 1){
		for(r=0;r<32;r++) {
			for(c=0;c<5;c++) {
				flsif_senddata(merged_frame[r][c]);
    				while(1){  delay(1); if(flash_flag){ flash_flag = 0; break; } }
			}
		}
	}
	else if(mode ==2 ){
		    // enable the NE
		    ne_enable();
		
		
		    // load the md frame into NE for Person Detection
		    arb_debug_ascii(0xDA, "LDNE");
		    ne_load_md_frame(md_frame_arr, 98304);//32bit addr
		
		    while(1){
		    	//// preload NCX registers with params for Person Detect
		    	//arb_debug_ascii(0xDA, "PDRG");
		    	//ne_set_ncx_register(0, 512 );//1st MBC index //512bit addr
		    	//ne_set_ncx_register(1, 0x0000);//1st MBC destaddr
		    	//ne_set_ncx_register(2, 2     );//stride
		    	//ne_set_ncx_register(3, 6656 );//huff weight ssaddr
		    	//ne_set_ncx_register(4, 6672 );//huff weight enaddr
		    	//ne_set_ncx_register(5, 6672 );//huff loc table ssaddr
		    	//ne_set_ncx_register(6, 6676 );//huff loc table enaddr
		    	//ne_set_ncx_register(7, 7168 );//bias ssaddr
		    	//ne_set_ncx_register(8, 7169 );//bias enaddr
		    	//ne_set_ncx_register(9, 0x0020);//mov instr size
		    	//ne_set_ncx_register(10,0x0000);
		    	//ne_set_ncx_register(11,0x0000);
		    	//ne_set_ncx_register(12,0x0009);
		    	//ne_set_ncx_register(13,0x0009);
		    	//ne_set_ncx_register(14,0x0000);
		    	//ne_set_ncx_register(15,0x000A);
		    	//ne_set_ncx_register(16,7680  );//weight ssaddr
		    	//ne_set_ncx_register(17,7720  );//weight enaddr
		    	//ne_set_ncx_register(18,3584  );//output addr(512bit addr)
		    	//ne_set_ncx_register(19,0x5800);
		    	//ne_set_ncx_register(20,0x5805);
		    	//ne_set_ncx_register(21,0x0000);
		    	//ne_set_ncx_register(22,0x0000);
		    	//ne_set_ncx_register(23,10240);//input addr
		    ne_set_ncx_register(0, 0x0000);
		    ne_set_ncx_register(1, 24576 );//input image data(128b)
		    ne_set_ncx_register(2, 5632  );//1st intermediate(512b)
		    ne_set_ncx_register(3, 0x0000);
		    ne_set_ncx_register(4, 6144  );//2nd intermediate(512b)
		    ne_set_ncx_register(5, 7168  );//conv1 bias ss(128b)
		    ne_set_ncx_register(6, 7169  );//conv1 bias end(128b)

		    ne_set_ncx_register(7, 0x0000);
		    ne_set_ncx_register(8, 0x0000);
		    ne_set_ncx_register(9, 0x0000);
		    ne_set_ncx_register(10,0x0000);
		    ne_set_ncx_register(11,0x0000);

		    ne_set_ncx_register(12,8704  );//conv1 weight ss(128b)
		    ne_set_ncx_register(13,2560  );//conv1 huff w table start(128b)
		    ne_set_ncx_register(14,2576  );//conv1 huff w table end  (128b)
		    ne_set_ncx_register(15,2580  );//conv1 huff loc table end(128b)

		    ne_set_ncx_register(16,12288 );//conv2 weight ss(128b)
		    ne_set_ncx_register(17,10240 );//conv2 huff w table start(128b)
		    ne_set_ncx_register(18,10258 );//conv2 huff w table end  (128b)
		    ne_set_ncx_register(19,11776 );//conv2 bias start (128b)

		    ne_set_ncx_register(20,7680  );//dfc1 weight (512b)
		    ne_set_ncx_register(21,9728  );//dfc2 weight (512b)
		    ne_set_ncx_register(22,28672 );//dfc1 bias start (128b)
		    ne_set_ncx_register(23,10264 );//conv2 huff loc table end(128b)

	        //*(p_NE_IMEM_START   ) = 0b01111100000000000000000000000000;
	        //*(p_NE_IMEM_START+1 ) = 0b01001010100000001000000000000000;
	        //*(p_NE_IMEM_START+1 ) = 0b01001111010100000100111000000000;
	        //*(p_NE_IMEM_START+3 ) = 0b00010001000001000010000000000000;
	        //*(p_NE_IMEM_START+4 ) = 0b00001000100101001010000000000000;
	        //*(p_NE_IMEM_START+5 ) = 0b10000001111010100000100111000000;
	        //*(p_NE_IMEM_START+6 ) = 0b01001111001000001001110000000000;
	        //*(p_NE_IMEM_START+7 ) = 0b10011000000100101001010000000000;
	        //*(p_NE_IMEM_START+8 ) = 0b00111101010000010011100000000001;
	        //*(p_NE_IMEM_START+9 ) = 0b01000100000100001000000000000001;
	        //*(p_NE_IMEM_START+10) = 0b00100010010100101000000000000000;
	        //*(p_NE_IMEM_START+11) = 0b00000111101010000010011100000000;
	        //*(p_NE_IMEM_START+12) = 0b00000001010000101000000000000000;
	        //*(p_NE_IMEM_START+13) = 0b00000000000000000000000000000000;
	        //*(p_NE_IMEM_START+14) = 0b00000000000000000000000000000000;
	        //*(p_NE_IMEM_START+15) = 0b10010101000000000000000000000000;
	        //*(p_NE_IMEM_START+16) = 0b00000000000000000000000000000000;
	        //*(p_NE_IMEM_START+17) = 0b11111000000000000000000000000000;
	        //*(p_NE_IMEM_START+18) = 0b00000000011010001110000000000111;
	        //*(p_NE_IMEM_START+19) = 0b00000000000000000000000000000000;
	        //*(p_NE_IMEM_START+20) = 0b00000000000000000000000000000000;
	        //*(p_NE_IMEM_START+21) = 0b00000000000000000000000000000000;
	        //*(p_NE_IMEM_START+22) = 0b00000000000000000000000000000000;
	        //*(p_NE_IMEM_START+23) = 0b01100000000000000000000000000000;
	        //*(p_NE_IMEM_START+24) = 0b00000000000000000000000000000000;
	        //*(p_NE_IMEM_START+25) = 0b11111000000000000000000000000000;
	        //*(p_NE_IMEM_START+26) = 0b00000000011100001111000000000111;
	        //*(p_NE_IMEM_START+27) = 0b00000000000000000000000000000000;
	        //*(p_NE_IMEM_START+28) = 0b00000000000000000000000000000000;
	        //*(p_NE_IMEM_START+29) = 0b00000000000000000000000000000000;
	        //*(p_NE_IMEM_START+30) = 0b00000000000000000000000000000000;
	        //*(p_NE_IMEM_START+31) = 0b01100100000000000000000000000000;

		    //int cnt;
		    //for (cnt=0; cnt<32; cnt=cnt+1){
	        //    	flsif_senddata(*(p_NE_IMEM_START+cnt));
    		//	while(1){  delay(1); if(flash_flag){ flash_flag = 0; break; } }
		    //}
		
		
		    // run Person Detect
		    arb_debug_ascii(0xDA, "PD  ");
		    ne_start(0);

	            //flsif_senddata(p_NE_RESET_AND_ENABLE->as_int);
    		    //    	while(1){  delay(1); if(flash_flag){ flash_flag = 0; break; } }
	            //flsif_senddata(p_NE_START->as_int);
    		    //    	while(1){  delay(1); if(flash_flag){ flash_flag = 0; break; } }
	            //flsif_senddata(p_NE_CONF_FRAMEMEM_BASEADDR);
    		    //    	while(1){  delay(1); if(flash_flag){ flash_flag = 0; break; } }

	            //flsif_senddata(p_NE_CONF_AUTOGATE_PE->as_int);
    		    //    	while(1){  delay(1); if(flash_flag){ flash_flag = 0; break; } }
	            //flsif_senddata(p_NE_DBG_DEBUGMODE_PE->as_int);
    		    //    	while(1){  delay(1); if(flash_flag){ flash_flag = 0; break; } }
	            //flsif_senddata(p_NE_DBG_ADVANCE_PE_BY_CYCLES->as_int);
    		    //    	while(1){  delay(1); if(flash_flag){ flash_flag = 0; break; } }

	            //flsif_senddata(p_NE_PE_STATE_VARS_GROUP1->as_int);
    		    //    	while(1){  delay(1); if(flash_flag){ flash_flag = 0; break; } }
	            //flsif_senddata(p_NE_PE_STATE_VARS_GROUP2->as_int);
    		    //    	while(1){  delay(1); if(flash_flag){ flash_flag = 0; break; } }
	            //flsif_senddata(p_NE_PE_STATE_VARS_GROUP3->as_int);
    		    //    	while(1){  delay(1); if(flash_flag){ flash_flag = 0; break; } }
	            //flsif_senddata(p_NE_PE_STATE_VARS_GROUP4->as_int);
    		    //    	while(1){  delay(1); if(flash_flag){ flash_flag = 0; break; } }
	            //flsif_senddata(p_NE_PE_STATE_VARS_GROUP5->as_int);
    		    //    	while(1){  delay(1); if(flash_flag){ flash_flag = 0; break; } }
	            //flsif_senddata(p_NE_DECOMP_STATE_VARS_GROUP1->as_int);
    		    //    	while(1){  delay(1); if(flash_flag){ flash_flag = 0; break; } }
	            //flsif_senddata(p_NE_DECOMP_STATE_VARS_GROUP2->as_int);
		    //
		    //for (cnt=0; cnt<128; cnt=cnt+1){
		    //    *(p_NE_IMEM_START+cnt)=cnt;
		    //}

		    while(1){ delay(1); if(ne_flag){ ne_flag = 0; break; } }
	            flsif_senddata(0xFFAA);
		    arb_debug_ascii(0xDA, "check");
		    }

		
		    // check result
		    uint16_t result = 0;
		    result = ne_get_ncx_register(5);
		    if(result != 74) {rf_write(1,0xFFFF);}//arb_debug_ascii("ERR");}
		    result = ne_get_ncx_register(7);
		    if(result != 84) {rf_write(2,0xFFFF);}//arb_debug_ascii("ERR");}
		    arb_debug_ascii(0xDA, *(((volatile uint32_t *)0xa013c100)+0));
		    arb_debug_ascii(0xDA, *(((volatile uint32_t *)0xa013c100)+1));
		    arb_debug_ascii(0xDA, *(((volatile uint32_t *)0xa013c100)+2));
		    arb_debug_ascii(0xDA, *(((volatile uint32_t *)0xa013c100)+3));
		    arb_debug_ascii(0xDA, *(((volatile uint32_t *)0xa013c100)+4));
		    arb_debug_ascii(0xDA, *(((volatile uint32_t *)0xa013c100)+5));
		    arb_debug_ascii(0xDA, *(((volatile uint32_t *)0xa013c100)+6));
		    arb_debug_ascii(0xDA, *(((volatile uint32_t *)0xa013c100)+7));
		    arb_debug_ascii(0xDA, *(((volatile uint32_t *)0xa013c100)+8));
		    arb_debug_ascii(0xDA, *(((volatile uint32_t *)0xa013c100)+9));
		    arb_debug_ascii(0xDA, *(((volatile uint32_t *)0xa013c100)+10));
		    arb_debug_ascii(0xDA, *(((volatile uint32_t *)0xa013c100)+11));
		    arb_debug_ascii(0xDA, *(((volatile uint32_t *)0xa013c100)+12));
		    arb_debug_ascii(0xDA, *(((volatile uint32_t *)0xa013c100)+13));
		    arb_debug_ascii(0xDA, *(((volatile uint32_t *)0xa013c100)+14));
		    arb_debug_ascii(0xDA, *(((volatile uint32_t *)0xa013c100)+15));
		    arb_debug_reg(0xFF, 0);//END_OF_PROGRAM
	}
	else {
		for(r=0;r<32;r++) {
			for(c=0;c<5;c++) {
				flsif_senddata(merged_frame[r][c]);
    				while(1){  delay(1); if(flash_flag){ flash_flag = 0; break; } }
			}
		}
		    // enable the NE
		    ne_enable();
		
		
		    // load the md frame into NE for Person Detection
		    arb_debug_ascii(0xDA, "LDNE");
		    ne_load_md_frame(md_frame_arr, 0);
		
		
		    // preload NCX registers with params for Person Detect
		    arb_debug_ascii(0xDA, "PDRG");
		    ne_set_ncx_register(0, 0x0000);
		    ne_set_ncx_register(1, 0x0000);
		    ne_set_ncx_register(2, 0x0002);
		    ne_set_ncx_register(3, 0x1000);
		    ne_set_ncx_register(4, 0x1010);
		    ne_set_ncx_register(5, 0x1010);
		    ne_set_ncx_register(6, 0x1014);
		    ne_set_ncx_register(7, 0x1400);
		    ne_set_ncx_register(8, 0x1401);
		    ne_set_ncx_register(9, 0x0020);
		    ne_set_ncx_register(10,0x0000);
		    ne_set_ncx_register(11,0x0000);
		    ne_set_ncx_register(12,0x0009);
		    ne_set_ncx_register(13,0x0009);
		    ne_set_ncx_register(14,0x0000);
		    ne_set_ncx_register(15,0x000A);
		    ne_set_ncx_register(16,0x1800);
		    ne_set_ncx_register(17,0x0008);
		    ne_set_ncx_register(18,0x0080);
		    //ne_set_ncx_register(19,0x5800);
		    //ne_set_ncx_register(20,0x5805);
		    ne_set_ncx_register(21,0x0000);
		    ne_set_ncx_register(22,0x0000);
		    ne_set_ncx_register(23,0x0011);
		
		
		    // run Person Detect
		    arb_debug_ascii(0xDA, "PD  ");
		    ne_start(NE_PERSON_DETECTION_IMEM_START_ADDR);
		    while(1){ delay(1); if(ne_flag){ ne_flag = 0; break; } }
		
		    // check result
		    uint16_t result = 0;
		    result = ne_get_ncx_register(5);
		    if(result != 74) {arb_debug_ascii("ERR ");rf_write(1,0xFFFF);}
		    result = ne_get_ncx_register(7);
		    if(result != 84) {arb_debug_ascii("ERR ");rf_write(2,0xFFFF);}
	}

	arb_debug_reg(0xFF, 0);//END_OF_PROGRAM

	while(1){ delay(1); }
    return 1;
}
