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
	// Reference & Current frame image test
	//********************************************************************
	//********************************************************************

	int i;
	int mcb_index;
	uint32_t mcb_row;
	uint32_t mcb_col;
	uint32_t smcb_row;
	uint32_t smcb_col;
	uint32_t ahb_data;
	uint8_t mcb_data [256*4];
	uint32_t cd_map[40][30];
	uint8_t maximum;
	uint8_t minimum;
	
	frame_flag=0;
	flash_flag=0;
	h264_flag=0;
	md_flag=0;
	ne_flag=0;
	mbustx_flag=0;
	mbusrx_flag=0;
	enable_all_irq();

	
	//fls if intialize
	flsif_initialize(0x3, 0x3);
	
	//h264 initialize
	h264_initialize();
	p_H264_DEBUG->h264_debug_sram_sel = 0;
	p_H264_DEBUG->h264_debug_start_bypass = 0;
	h264_config(p_H264_COMPMEM_SADDR_YREF->as_int, p_H264_COMPMEM_SADDR_UVREF->as_int, 20,1);//quality factor = 20
	
	//imager if intialize
	imgif_bayer_mode_enable(3);
	imgif_dilate_patt_config(0b01011010);
	//Q_Y_90_set();
	imgif_ref_cd_mode_enable(3);
	imgif_initialize();

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
	imgif_initialize();

	//Image request to PRC
	rf_write (0,0xDEADBEEF);//+1 txcnt
	rf_send (0,0,0x10,0);//+1 txcnt

	//Wait for current image
    while(1){  
		delay(1);
		if(frame_flag){
			break;
		}
	}

	//arb_debug_reg(0xFF, 0);//END_OF_PROGRAM
	decoding_cur_config();

	//Y channel
    while(1){  
		delay(1);
		if(frame_flag){
			arb_debug_ascii(0xD3, "CURY");
			for(mcb_index=0; mcb_index<1200; mcb_index=mcb_index+1)	{
				arb_debug_reg(0xDB, mcb_index);
				for(i=0; i<(64); i=i+1){
					flsif_senddata(mcb_data_y(mcb_index));
					while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
					delay(1);
				}
				delay(1);
			}
			break;
		}
	}
	// UV channel
    while(1){  
		delay(1);
		if(frame_flag){
			arb_debug_ascii(0xD3, "CURC");
			for(mcb_index=0; mcb_index<1200; mcb_index=mcb_index+1)	{
				arb_debug_reg(0xDB, mcb_index);
				for(i=0; i<(32); i=i+1){
					flsif_senddata(mcb_data_uv(mcb_index));
					while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
					delay(1);
				}
				delay(1);
			}
			break;
		}
	}

	//fls if intialize
	flsif_initialize(0x1, 0x0); //H264 and 1channel

	//H264 channel
    while(1){  
		delay(1);
		if(frame_flag){
			arb_debug_ascii(0xD3, "H264");
			for(mcb_row=0; mcb_row<30; mcb_row = mcb_row + 1){
				for(mcb_col=0; mcb_col<40; mcb_col = mcb_col + 1){
					//wait flash out
					arb_debug_reg(0xDB, mcb_row*mcb_col);
					h264_start(mcb_row, mcb_col);
					while(1) { delay(1); if (flash_flag) { flash_flag =0; break; } }
				}
				delay(1);
			}
			delay(1);
			break;
		}
	}

	//read CD map
	for(mcb_col=0; mcb_col<40; mcb_col=mcb_col+1){
		ahb_data = imgif_cd_map_read(mcb_col);
		for(mcb_row=0; mcb_row<30; mcb_row=mcb_row+1){
			cd_map[mcb_col][mcb_row] = ((ahb_data & (1<<mcb_row))>>mcb_row);
		}
	}

	//for(mcb_row=0; mcb_row<30; mcb_row=mcb_row+1){
	//	for(mcb_col=0; mcb_col<40; mcb_col=mcb_col+1){
	//			arb_debug_reg(0xDB, cd_map[mcb_col][mcb_row]);
	//	}
	//}

	////min-max value check
	//arb_debug_ascii(0xD3, "CUR");

	//for(smcb_row=0+6; smcb_row<7; smcb_row=smcb_row+1){
	//	for(smcb_col=0+13; smcb_col<14; smcb_col=smcb_col+1) {
	//		if( (cd_map[2*smcb_col  ][2*smcb_row  ] == 1) ||
	//			(cd_map[2*smcb_col+1][2*smcb_row  ] == 1) ||
	//			(cd_map[2*smcb_col  ][2*smcb_row+1] == 1) ||
	//			(cd_map[2*smcb_col+1][2*smcb_row+1] == 1)
	//			) {

	//			for(i=0; i<(256/4); i=i+1){
	//				ahb_data = mcb_data_y((smcb_row*2)*40+(smcb_col*2));
	//				mcb_data[4*i  ] = ((ahb_data & 0xff      )     );
	//				mcb_data[4*i+1] = ((ahb_data & 0xff00    ) >>8 );
	//				mcb_data[4*i+2] = ((ahb_data & 0xff0000  ) >>16);
	//				mcb_data[4*i+3] = ((ahb_data & 0xff000000) >>24);
	//			}
	//			for(i=(256/4); i<(256/4)*2; i=i+1){
	//				ahb_data = mcb_data_y(((smcb_row*2)+1)*40+(smcb_col*2));
	//				mcb_data[4*i  ] = ((ahb_data & 0xff      )     );
	//				mcb_data[4*i+1] = ((ahb_data & 0xff00    ) >>8 );
	//				mcb_data[4*i+2] = ((ahb_data & 0xff0000  ) >>16);
	//				mcb_data[4*i+3] = ((ahb_data & 0xff000000) >>24);
	//			}
	//			for(i=(256/4)*2; i<(256/4)*3; i=i+1){
	//				ahb_data = mcb_data_y((smcb_row*2)*40+(smcb_col*2)+1);
	//				mcb_data[4*i  ] = ((ahb_data & 0xff      )     );
	//				mcb_data[4*i+1] = ((ahb_data & 0xff00    ) >>8 );
	//				mcb_data[4*i+2] = ((ahb_data & 0xff0000  ) >>16);
	//				mcb_data[4*i+3] = ((ahb_data & 0xff000000) >>24);
	//			}
	//			for(i=(256/4)*3; i<(256/4)*4; i=i+1){
	//				ahb_data = mcb_data_y(((smcb_row*2)+1)*40+(smcb_col*2)+1);
	//				mcb_data[4*i  ] = ((ahb_data & 0xff      )     );
	//				mcb_data[4*i+1] = ((ahb_data & 0xff00    ) >>8 );
	//				mcb_data[4*i+2] = ((ahb_data & 0xff0000  ) >>16);
	//				mcb_data[4*i+3] = ((ahb_data & 0xff000000) >>24);
	//			}
	//			maximum = 0x00;
	//			minimum = 0xFF;
	//			//find max for current MCB
	//			if (cd_map[2*smcb_col  ][2*smcb_row  ] == 1){
	//				for (i=0; i<256; i=i+1){
	//					if( *(mcb_data+i) > maximum ){
	//						maximum = *(mcb_data+i);
	//					}
	//				}
	//			}
	//			if (cd_map[2*smcb_col+1][2*smcb_row  ] == 1){
	//				for (i=256; i<256*2; i=i+1){
	//					if( *(mcb_data+i) > maximum ){
	//						maximum = *(mcb_data+i);
	//					}
	//				}
	//			}
	//			if (cd_map[2*smcb_col  ][2*smcb_row+1] == 1){
	//				for (i=256*2; i<256*3; i=i+1){
	//					if( *(mcb_data+i) > maximum ){
	//						maximum = *(mcb_data+i);
	//					}
	//				}
	//			}
	//			if (cd_map[2*smcb_col+1][2*smcb_row+1] == 1){
	//				for (i=256*3; i<256*4; i=i+1){
	//					if( *(mcb_data+i) > maximum ){
	//						maximum = *(mcb_data+i);
	//					}
	//				}
	//			}

	//			//find min for current MCB
	//			if (cd_map[2*smcb_col  ][2*smcb_row  ] == 1){
	//				for (i=0; i<256; i=i+1){
	//					if( *(mcb_data+i) < minimum ){
	//						minimum = *(mcb_data+i);
	//					}
	//				}
	//			}
	//			if (cd_map[2*smcb_col+1][2*smcb_row  ] == 1){
	//				for (i=256; i<256*2; i=i+1){
	//					if( *(mcb_data+i) < minimum ){
	//						minimum = *(mcb_data+i);
	//					}
	//				}
	//			}
	//			if (cd_map[2*smcb_col  ][2*smcb_row+1] == 1){
	//				for (i=256*2; i<256*3; i=i+1){
	//					if( *(mcb_data+i) < minimum ){
	//						minimum = *(mcb_data+i);
	//					}
	//				}
	//			}
	//			if (cd_map[2*smcb_col+1][2*smcb_row+1] == 1){
	//				for (i=256*3; i<256*4; i=i+1){
	//					if( *(mcb_data+i) < minimum ){
	//						minimum = *(mcb_data+i);
	//					}
	//				}
	//			}
	//			arb_debug_ascii(0xD3, "CUR");

	//			arb_debug_ascii(0xD3, "MAX");
	//			arb_debug_reg(0xDB, maximum);
	//			arb_debug_ascii(0xD3, "MIN");
	//			arb_debug_reg(0xDB, minimum);

	//			p_IMGIF_IMG_INFO->img_type = 0;
	//			if((max_cur_y(smcb_row*20+smcb_col) > (maximum + 20))||(max_cur_y(smcb_row*20+smcb_col) < (maximum - 20))){
	//				arb_debug_reg(0xDB, max_cur_y(smcb_row*20+smcb_col));
	//				arb_debug_reg(0xDB, maximum);
	//				arb_debug_ascii(0xD5, "ERR");
	//			}
	//			else{
	//				arb_debug_reg(0xDB, max_cur_y(smcb_row*20+smcb_col));
	//				arb_debug_reg(0xDB, maximum);
	//				arb_debug_ascii(0xD5, "SUC");
	//			}
	//			if((min_cur_y(smcb_row*20+smcb_col) > (minimum+20))||(min_cur_y(smcb_row*20+smcb_col) < (minimum - 20))){
	//				arb_debug_reg(0xDB, min_cur_y(smcb_row*20+smcb_col));
	//				arb_debug_reg(0xDB, minimum);
	//				arb_debug_ascii(0xD5, "ERR");
	//			}
	//			else{
	//				arb_debug_reg(0xDB, min_cur_y(smcb_row*20+smcb_col));
	//				arb_debug_reg(0xDB, minimum);
	//				arb_debug_ascii(0xD5, "SUC");
	//			}
	//		}
	//	}
	//}

	//decoding_ref_config();

	//arb_debug_ascii(0xD3, "REF");
	//for(smcb_row=0; smcb_row<(30/2); smcb_row=smcb_row+1){
	//	for(smcb_col=0; smcb_col<(40/2); smcb_col=smcb_col+1){
	//		for(i=0; i<(256/4); i=i+1){
	//			ahb_data = mcb_data_y((smcb_row*2)*40+(smcb_col*2));
	//			mcb_data[4*i  ] = ((ahb_data & 0xff      )     );
	//			mcb_data[4*i+1] = ((ahb_data & 0xff00    ) >>8 );
	//			mcb_data[4*i+2] = ((ahb_data & 0xff0000  ) >>16);
	//			mcb_data[4*i+3] = ((ahb_data & 0xff000000) >>24);
	//		}
	//		for(i=(256/4); i<(256/4)*2; i=i+1){
	//			ahb_data = mcb_data_y(((smcb_row*2)+1)*40+(smcb_col*2));
	//			mcb_data[4*i  ] = ((ahb_data & 0xff      )     );
	//			mcb_data[4*i+1] = ((ahb_data & 0xff00    ) >>8 );
	//			mcb_data[4*i+2] = ((ahb_data & 0xff0000  ) >>16);
	//			mcb_data[4*i+3] = ((ahb_data & 0xff000000) >>24);
	//		}
	//		for(i=(256/4)*2; i<(256/4)*3; i=i+1){
	//			ahb_data = mcb_data_y((smcb_row*2)*40+(smcb_col*2)+1);
	//			mcb_data[4*i  ] = ((ahb_data & 0xff      )     );
	//			mcb_data[4*i+1] = ((ahb_data & 0xff00    ) >>8 );
	//			mcb_data[4*i+2] = ((ahb_data & 0xff0000  ) >>16);
	//			mcb_data[4*i+3] = ((ahb_data & 0xff000000) >>24);
	//		}
	//		for(i=(256/4)*3; i<(256/4)*4; i=i+1){
	//			ahb_data = mcb_data_y(((smcb_row*2)+1)*40+(smcb_col*2)+1);
	//			mcb_data[4*i  ] = ((ahb_data & 0xff      )     );
	//			mcb_data[4*i+1] = ((ahb_data & 0xff00    ) >>8 );
	//			mcb_data[4*i+2] = ((ahb_data & 0xff0000  ) >>16);
	//			mcb_data[4*i+3] = ((ahb_data & 0xff000000) >>24);
	//		}
	//		maximum = *mcb_data;
	//		minimum = *mcb_data;
	//		for (i=0; i<256*4 ; i=i+1){
	//			if( *(mcb_data+i) > maximum ){
	//				maximum = *(mcb_data+i);
	//			}
	//		}
	//		for (i=0; i<256*4 ; i=i+1){
	//			if( *(mcb_data+i) < minimum ){
	//				minimum = *(mcb_data+i);
	//			}
	//		}
	//		arb_debug_ascii(0xD3, "MAX");
	//		arb_debug_reg(0xDB, maximum);
	//		arb_debug_ascii(0xD3, "MIN");
	//		arb_debug_reg(0xDB, minimum);

	//		p_IMGIF_IMG_INFO->img_type = 0;

	//		arb_debug_ascii(0xD3, "REF");
	//		if((max_ref_y(smcb_row*20+smcb_col) > (maximum + 5))||(max_ref_y(smcb_row*20+smcb_col) < (maximum - 5))){
	//			arb_debug_reg(0xDB, max_ref_y(smcb_row*20+smcb_col) );
	//			arb_debug_reg(0xDB, maximum);
	//			arb_debug_ascii(0xD5, "ERR");
	//		}
	//		else
	//			arb_debug_ascii(0xD5, "SUC");
	//		if((min_ref_y(smcb_row*20+smcb_col) > (minimum+5))||(min_ref_y(smcb_row*20+smcb_col) < (minimum - 5))){
	//			arb_debug_reg(0xDB, min_ref_y(smcb_row*20+smcb_col) );
	//			arb_debug_reg(0xDB, minimum);
	//			arb_debug_ascii(0xD5, "ERR");
	//		}
	//		else
	//			arb_debug_ascii(0xD5, "SUC");
	//	}
	//}

	arb_debug_reg(0xFF, 0);//END_OF_PROGRAM

	while(1){ delay(1); }
    return 1;
}
