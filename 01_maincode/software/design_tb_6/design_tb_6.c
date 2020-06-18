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


// Face Detection golden results to check
const uint16_t fd_results_0[] = { 102, // (0,0)
                                  180, // (0,1)
                                  81, // (0,2)
                                  59, // (1,0)
                                  81, // (1,1)
                                  65, // (1,2)
                                  167, // (2,0)
                                  183, // (2,1)
                                  250  // (2,2)
                              };
const uint16_t fd_results_1[] = { 97, // (0,0)
                                  171, // (0,1)
                                  77, // (0,2)
                                  56, // (1,0)
                                  77, // (1,1)
                                  61, // (1,2)
                                  159, // (2,0)
                                  167, // (2,1)
                                  198  // (2,2)
                              };



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
	p_ENC_DONE_INT->as_int   = 1;
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


//********************************************************************
// MAIN function starts here             
//********************************************************************

int main() {
	//********************************************************************
	//********************************************************************
	// SMALL FRAME TEST 4x4 MCB FRAME
	//********************************************************************
	//********************************************************************

	int i;
	int j;
	int mcb_row;
	int mcb_col;
	int cur_ssaddr_y;
	int cur_ssaddr_uv;
	int cd_map   [40][30];
	uint32_t md_frame_arr[32][20];
	uint32_t merged_frame[32][5];
	int ahb_data;

	int pixel_sub_margin 	= 4; // Don't touch unless we want to try optical black correction
	int active_width 	= 64; // Set these two
	int active_height 	= 64; // Set these two
	int mcb_per_row 	= active_width/16;
	int mcb_per_col 	= active_height/16;
	int total_mcb 		= mcb_per_row * mcb_per_col;


    volatile uint16_t result = 0;

	frame_flag=0;
	flash_flag=0;
	h264_flag=0;
	md_flag=0;
	ne_flag=0;
	enable_all_irq();

    ne_set_clockgated();

	if(rf_read(0)==0) {
		arb_debug_ascii(0xD3, "REF");

		//image if initialize
		imgif_bayer_mode_enable(3);
		//imgif_active_region_config(0, 32, 76, 76+32, 32, 2, 2, 4);
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

		encoding_ref_config();
		imgif_ref_cd_mode_enable(3);
		imgif_initialize();

		//ne initialize for flushing N2W
		arb_debug_reg(0xDB,ne_imem_read(0));
		arb_debug_reg(0xDB,ne_sharedmem_read(0));

		//wait frame comming in
    	while(1){ delay(1); if(frame_flag){ frame_flag=0; break; } }
		
		arb_debug_ascii(0xD3, "ADDR");
    	cur_ssaddr_y = p_MCB_ADDR->mcb_addr_y;
    	cur_ssaddr_uv= p_MCB_ADDR->mcb_addr_uv;
		rf_write(1,cur_ssaddr_y);
		rf_write(2,cur_ssaddr_uv);
		arb_debug_reg(0xDB,cur_ssaddr_y);
		arb_debug_reg(0xDB,cur_ssaddr_uv);

		//fls if intialize
		flsif_initialize(0x3, 0x3);
	    //decoding_ref_config();
		////Y channel
		//arb_debug_ascii(0xD3, "REFY");
		//for(mcb_row=0; mcb_row<mcb_per_row; mcb_row=mcb_row+1)	{
		//	for(mcb_col=0; mcb_col<mcb_per_col; mcb_col=mcb_col+1)	{
		//		arb_debug_reg(0xDB, (mcb_row*40)+mcb_col);
		//		for(i=0; i<(64); i=i+1){
		//			flsif_senddata(*((uint32_t *)(p_MCBRD_SRAM_START+(mcb_row*40)+mcb_col)));
		//			while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
		//			delay(1);
		//		}
		//		delay(1);
		//	}
		//	delay(1);
		//}
		//// UV channel
		//arb_debug_ascii(0xD3, "REFC");
		//for(mcb_row=0; mcb_row<mcb_per_row; mcb_row=mcb_row+1)	{
		//	for(mcb_col=0; mcb_col<mcb_per_col; mcb_col=mcb_col+1)	{
		//		arb_debug_reg(0xDB, (mcb_row*40)+mcb_col);
		//		for(i=0; i<(32); i=i+1){
		//			flsif_senddata(*((uint32_t *)(1200+p_MCBRD_SRAM_START+(mcb_row*40)+mcb_col)));
		//			while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
		//			delay(1);
		//		}
		//		delay(1);
		//	}
		//	delay(1);
		//}

		//Image request to PRC
		rf_write (0,0x1);//+1 txcnt
		arb_debug_reg(0xDB,rf_read(0));
		rf_send (0,0,0x10,0);//+1 txcnt

		while(1){delay(1);};
	}
	else if(rf_read(0)==1){
		arb_debug_ascii(0xD3, "MD  ");

    	p_FRMMEM_SSADDR->frmmem_ssaddr_y  = rf_read(1);
    	p_FRMMEM_SSADDR->frmmem_ssaddr_uv = rf_read(2);
		//imager if intialize
		imgif_intensity_mode_enable();
		imgif_initialize();
		rf_send (0,0,0x10,0);//+1 txcnt

		//wait for motion detection
    	while(1){  delay(1); if(md_flag){ md_flag = 0; break; } }

		//imgif_mem_access_enable();
		dbg_imgif_disable_md_shift();
		p_B_CONV->min = 0; // set manual minimum to 0 - default is 70
		
		imgif_md_frame_read(md_frame_arr);
		
		merge_md_arr(md_frame_arr, merged_frame);

		////////////////////person detect////////////////////////////////////

        // load frame and registers
		arb_debug_ascii(0xD3, "NELD");
        ne_enable();
        ne_load_md_frame(md_frame_arr, 0);
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
        ne_set_ncx_register(19,0x5800);
        ne_set_ncx_register(20,0x5805);
        ne_set_ncx_register(21,0x0000);
        ne_set_ncx_register(22,0x0000);
        ne_set_ncx_register(23,0x0011);

        // run net
        arb_debug_ascii(0xD3, "NEPD");
        ne_start(NE_PERSON_DETECTION_IMEM_START_ADDR);
        while(1){ delay(1); if(ne_flag){ ne_flag = 0; break; } }
        
		
		////////////////////person detect result check////////////////////////
        result = ne_get_ncx_register(5);
        if(result != 74) arb_debug_ascii(0xD5, "ERR ");
        result = ne_get_ncx_register(7);
        if(result != 84) arb_debug_ascii(0xD5, "ERR ");

        // gate the NE again to save power
        //ne_set_clockgated();

	}
	arb_debug_ascii(0xD3, "CUR");
	flsif_initialize(0x3, 0x3);
	
	//imgif_active_region_config(0, 32, 76, 76+32, 32, 2, 2, 4);
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

	//ssaddr recover

	//imager if for current image
	imgif_bayer_mode_enable(3);
	imgif_curr_cd_mode_enable(3);
	encoding_cur_config();
	imgif_initialize();

	arb_debug_ascii(0xD3, "REQ");
	rf_send (0,0,0x10,0);//+1 txcnt

	//wait frame comming in
    while(1){ delay(1); if(frame_flag){ frame_flag=0; break; } }
	decoding_cur_config();

	//NE input generation
	//int ne_input_gen;	
	//ne_input_gen = 0;
	//int R,C;
	//if(ne_input_gen == 1){
	//	arb_debug_ascii(0xD3, "INPU");
	//	for(R=0; R<3; R=R+1) {
	//		for(C=0; C<3; C=C+1) {
	//			for(mcb_row=0+R; mcb_row<2+R; mcb_row=mcb_row+1)	{
	//				for(mcb_col=0+C; mcb_col<2+C; mcb_col=mcb_col+1)	{
	//					arb_debug_reg(0xDB, (mcb_row*40)+mcb_col);
	//					for(i=0; i<(64); i=i+1){
	//						flsif_senddata(*((uint32_t *)(p_MCBRD_SRAM_START+(mcb_row*40)+mcb_col)));
	//						while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
	//						delay(1);
	//					}
	//					delay(1);
	//				}
	//				delay(1);
	//			}
	//		}
	//	}
	//	arb_debug_reg(0xFF, 0);//END_OF_PROGRAM
	//	while(1){ delay(1); }
	//}

	////////////////////face detect////////////////////////
    ne_enable();

    for(i=0; i < 3; i++) {
        for(j=0; j < 3; j++) {
            arb_debug_ascii(0xD3, "NELD");
            ne_set_ncx_register(0, (i*40)+j); // 0,1,40,41 then 1,2,41,42 ... 82,83,122,123
            ne_set_ncx_register(1, 0x0000); // base dest addr of input in NE Sharedmem
            ne_set_ncx_register(2, 0x0002); // region width in macroblocks (2, for 2x2)
            ne_set_ncx_register(3, 0x1000); // conv1 huffman W table start
            ne_set_ncx_register(4, 0x1010); // conv1 huffman W table end
            ne_set_ncx_register(5, 0x1010); // conv1 huffman L table start
            ne_set_ncx_register(6, 0x1014); // conv1 huffman L table end
            ne_set_ncx_register(7, 0x1400); // conv1 bias start
            ne_set_ncx_register(8, 0x1401); // conv1 bias end
            ne_set_ncx_register(9, 0x0020); // input image size in pixels (32, for 32x32)
            ne_set_ncx_register(15,0x000A); // conv1,2 input size (10x10)
            ne_set_ncx_register(16,0x1800); // conv1 weights addr
            ne_set_ncx_register(18,0x0080); // conv1relu output address for sharedmem
            ne_set_ncx_register(19,0x5800); // conv2 bias start
            ne_set_ncx_register(20,0x5805); // conv2 bias end
            arb_debug_ascii(0xD3, "NEFD"); // Face Detect Window running
            ne_start(NE_FACE_DETECTION_IMEM_START_ADDR);
            while(1){ delay(1); if(ne_flag){ ne_flag = 0; break; } }

            arb_debug_ascii(0xD3, "CMP ");
            // now need to do something with results, but not sure
            // what, so this is up to Sid
            result = ne_get_ncx_register(5);
            if(result != fd_results_0[(i*3)+j]) arb_debug_ascii(0xD5, "ERR ");
            result = ne_get_ncx_register(7);
            if(result != fd_results_1[(i*3)+j]) arb_debug_ascii(0xD5, "ERR ");

        }
    }

    ne_set_clockgated();

	////////////////////face recorg////////////////////////
	
	////////////////////H264       ////////////////////////
	decoding_ref_config();
	//Y channel
	arb_debug_ascii(0xD3, "REFY");
	for(mcb_row=0; mcb_row<mcb_per_row; mcb_row=mcb_row+1)	{
		for(mcb_col=0; mcb_col<mcb_per_col; mcb_col=mcb_col+1)	{
			arb_debug_reg(0xDB, (mcb_row*40)+mcb_col);
			for(i=0; i<(64); i=i+1){
				flsif_senddata(*((uint32_t *)(p_MCBRD_SRAM_START+(mcb_row*40)+mcb_col)));
				while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
				delay(1);
			}
			delay(1);
		}
		delay(1);
	}
	// UV channel
	arb_debug_ascii(0xD3, "REFC");
	for(mcb_row=0; mcb_row<mcb_per_row; mcb_row=mcb_row+1)	{
		for(mcb_col=0; mcb_col<mcb_per_col; mcb_col=mcb_col+1)	{
			arb_debug_reg(0xDB, (mcb_row*40)+mcb_col);
			for(i=0; i<(32); i=i+1){
				flsif_senddata(*((uint32_t *)(1200+p_MCBRD_SRAM_START+(mcb_row*40)+mcb_col)));
				while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
				delay(1);
			}
			delay(1);
		}
		delay(1);
	}

	decoding_cur_config();

	h264_initialize();
	h264_config(p_H264_COMPMEM_SADDR_YREF->as_int, p_H264_COMPMEM_SADDR_UVREF->as_int, 10,1);//quality factor = 10

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

	////change detection map flash out
	//for(mcb_col=0; mcb_col<mcb_per_col; mcb_col=mcb_col+1){
	//	for(mcb_row=0; mcb_row<mcb_per_row; mcb_row=mcb_row+1){
	//		flsif_senddata(cd_map[mcb_col][mcb_row]);
	//		while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
	//		delay(1);
	//	}
	//}

	flsif_initialize(0x1, 0x0); //H264 and 1channel
	//H264 channel
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

	//disable imgif (turn off chip)
	p_IMGIF_IF_CTRL->imgif_en 	= 0;
	//imager if for current image
	imgif_bayer_mode_enable(3);
	imgif_curr_cd_mode_enable(3);
	encoding_cur_config();
	imgif_initialize();

	//Image request to PRC
	rf_write (0,0xDEADBEEF);//+1 txcnt
	rf_send (0,0,0x10,0);//+1 txcnt
	//wait frame comming in
    while(1){ delay(1); if(frame_flag){frame_flag=0; break; } }
	
	//Image request to PRC
	rf_write (0,0xDEADBEEF);//+1 txcnt
	rf_send (0,0,0x10,0);//+1 txcnt
	//wait frame comming in
    while(1){ delay(1); if(frame_flag){frame_flag=0; break; } }
	arb_debug_reg(0xFF, 0);//END_OF_PROGRAM

	while(1){ delay(1); }
    return 1;
}
