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
	md_flag=1;
}
void handler_ext_int_vga(void) { // VGA
    *NVIC_ICPR = (0x1 << IRQ_VGA); irq_history |= (0x1 << IRQ_VGA);
    arb_debug_reg(IRQ_VGA, 0x00000000);
	frame_flag=1;
	imgif_clear_enc_done_int();
	//decoding_ref_config();
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
	p_FLSIF_INTR->as_int  = 0;
	flash_flag=1;
}
void handler_ext_int_h264(void) { // H264
    *NVIC_ICPR = (0x1 << IRQ_H264); irq_history |= (0x1 << IRQ_H264);
    arb_debug_reg(IRQ_H264, 0x00000000);
	p_H264_INTR_DONE->as_int  = 0;
	h264_flag=1;
}
void handler_ext_int_h264_fifordy(void) { // H264_fifordy
    *NVIC_ICPR = (0x1 << IRQ_H264_FIFORDY); irq_history |= (0x1 << IRQ_H264_FIFORDY);
    arb_debug_reg(IRQ_H264_FIFORDY, 0x00000000);
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
	// FULL FRAME TEST : REF image stream in JPEG out & H264 test
	//********************************************************************
	//********************************************************************

	int i;
	int mcb_index;
	int mcb_row;
	int mcb_col;
	uint32_t ahb_data;
	uint32_t smcb_row;
	uint32_t smcb_col;
	uint8_t maximum;
	uint8_t minimum;
	uint8_t mcb_data [256*4];
	uint32_t cd_map[40][30];

	int pixel_sub_margin 	= 4; // Don't touch unless we want to try optical black correction
	int active_width 	= 64; // Set these two
	int active_height 	= 64; // Set these two
	int mcb_per_row 	= active_width/16;
	int mcb_per_col 	= active_height/16;
	int total_mcb 		= mcb_per_row * mcb_per_col;

	int addr_index 		= 0;
	int col_index 		= 0;
	int row_index		= 0;
	int prog_mode		= 0;
	
	frame_flag=0;
	flash_flag=0;
	h264_flag=0;
	md_flag=0;
	ne_flag=0;
	//enable_all_irq();
	enable_irq(0xFFFFF9FF);
	
	//fls if intialize
	flsif_initialize(0x3, 0x3);
	
	//h264 initialize
	h264_initialize();
	p_H264_DEBUG->h264_debug_sram_sel = 0;
	p_H264_DEBUG->h264_debug_start_bypass = 0; //assume data is already in SRAM //no automatic MCB fetching
	h264_config(p_H264_COMPMEM_SADDR_YREF->as_int, p_H264_COMPMEM_SADDR_UVREF->as_int, 10,1);//quality factor = 10
	
	
	//imager if intialize
	imgif_bayer_mode_enable(3);

	dbg_imgif_active_region_config(0, active_height, 
					pixel_sub_margin, 
					pixel_sub_margin*5+active_width,
					pixel_sub_margin*2,
					pixel_sub_margin*4+active_width,
					pixel_sub_margin*3,
					pixel_sub_margin*3+active_width,
					active_height,
					mcb_per_row,
					mcb_per_col,
					total_mcb);

	imgif_ref_cd_mode_enable(3);
	imgif_initialize();
	rf_write (0,18);

	arb_debug_ascii(0xD3, "REFS");

	//Wait for reference image
    while(1){  
		delay(1);
		if(frame_flag){
			frame_flag=0;
			break;
		}
	}
	

	//imager if for current image
	imgif_bayer_mode_enable(3);
	imgif_curr_cd_mode_enable(3);
	//encoding_cur_config();
	imgif_initialize();

	//Image request to PRC
	if(prog_mode==0){
		//Image request to PRC
		rf_send (0,0,0x10,0);//+1 txcnt
	}

	arb_debug_ascii(0xD3, "CURS");

	//Wait for current image
    while(1){  
		delay(1);
		if(frame_flag){
			break;
		}
	}

	decoding_cur_config();

	if(prog_mode==1){
		//change detection map 
		for(mcb_col=0; mcb_col<mcb_per_row; mcb_col=mcb_col+1){
			ahb_data = imgif_cd_map_read(mcb_col);
			flsif_senddata(ahb_data);
			while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
			delay(1);
			for(mcb_row=0; mcb_row<mcb_per_row; mcb_row=mcb_row+1){
				cd_map[mcb_col][mcb_row] = (ahb_data & (1<<mcb_row))>>mcb_row;
			}
		}
	}
	else if(prog_mode==2){
		//fls if intialize
		flsif_initialize(0x1, 0x0); //H264 and 1channel
		
		//H264 channel
	    while(1){  
			delay(1);
			if(frame_flag){
				arb_debug_ascii(0xD3, "H264");
				for(mcb_row=0; mcb_row<mcb_per_row; mcb_row = mcb_row + 1){
					for(mcb_col=0; mcb_col<mcb_per_col; mcb_col = mcb_col + 1){
						//wait flash out
						if(cd_map[mcb_col][mcb_row]!=0){
							arb_debug_reg(0xDB, mcb_row*mcb_col);
							h264_start(mcb_row, mcb_col);
							//delay(1000);
							while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
							delay(1);
						}
					}
					delay(1);
				}
				delay(1);
				break;
			}
		}
	}
	else {
		//change detection map 
		for(mcb_col=0; mcb_col<mcb_per_row; mcb_col=mcb_col+1){
			ahb_data = imgif_cd_map_read(mcb_col);
			flsif_senddata(ahb_data);
			while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
			delay(1);
			for(mcb_row=0; mcb_row<mcb_per_row; mcb_row=mcb_row+1){
				cd_map[mcb_col][mcb_row] = (ahb_data & (1<<mcb_row))>>mcb_row;
			}
		}

		//fls if intialize
		flsif_initialize(0x1, 0x0); //H264 and 1channel
		
		//H264 channel
	    while(1){  
			delay(1);
			if(frame_flag){
				arb_debug_ascii(0xD3, "H264");
				for(mcb_row=0; mcb_row<mcb_per_row; mcb_row = mcb_row + 1){
					for(mcb_col=0; mcb_col<mcb_per_col; mcb_col = mcb_col + 1){
						//wait flash out
						if(cd_map[mcb_col][mcb_row]!=0){
							arb_debug_reg(0xDB, mcb_row*mcb_col);
							h264_start(mcb_row, mcb_col);
							//delay(1000);
							while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
							delay(1);
						}
					}
					delay(1);
				}
				delay(1);
				break;
			}
		}
	}


	arb_debug_reg(0xFF, 0);//END_OF_PROGRAM

	while(1){ delay(1); }
    return 1;
}
