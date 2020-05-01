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
	p_MD_DONE_INT->as_int 	= 1;
}
void handler_ext_int_vga(void) { // VGA
    *NVIC_ICPR = (0x1 << IRQ_VGA); irq_history |= (0x1 << IRQ_VGA);
    arb_debug_reg(IRQ_VGA, 0x00000000);
	frame_flag=1;
	p_ENC_DONE_INT->as_int   = 1;
	p_COMPMEM_CONFIG->compmem_config_dec_en = 1;
	//ne_enable();
}
void handler_ext_int_ne(void) { // NE
    *NVIC_ICPR = (0x1 << IRQ_NE); irq_history |= (0x1 << IRQ_NE);
    arb_debug_reg(IRQ_NE, 0x00000000);
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
	//************************** SFR TEST ********************************            
	//********************************************************************
	//********************************************************************
	int temp_reg;
	uint32_t wr_val;
	uint32_t addr_offset;
	uint32_t err_cnt;
	uint32_t err_cnt_imgif;	
	uint32_t err_cnt_ne   ;	
	uint32_t err_cnt_h264 ;	
	uint32_t err_cnt_rf   ;	
	uint32_t err_cnt_fls  ;	

	err_cnt_imgif =0;	
	err_cnt_ne    =0;	
	err_cnt_h264  =0;	
	err_cnt_rf    =0;	
	err_cnt_fls   =0;	
	frame_flag=0;
	flash_flag=0;
	enable_irq(0xFFFFF9FF);
	//enable_all_irq();


	//********************************************************************
	// IMG IF SFR TEST             
	//********************************************************************
	arb_debug_ascii(0xD3, "IMGF "); 
	
	// IMGIF_IF_CTRL
	// default val check
	arb_debug_ascii(0xDA, "EN");
	temp_reg=p_IMGIF_IF_CTRL->imgif_en;
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_IF_CTRL->imgif_en = !temp_reg;
	if(temp_reg == p_IMGIF_IF_CTRL->imgif_en) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// default val check
	arb_debug_ascii(0xDA, "RSTN");
	temp_reg=p_IMGIF_IF_CTRL->softreset;
	if(temp_reg != 0x1) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_IF_CTRL->softreset= !temp_reg;
	if(temp_reg == p_IMGIF_IF_CTRL->softreset) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	p_IMGIF_IF_CTRL->softreset= 0x1;

	// IMGIF_IMG_INFO
	// default val check
	arb_debug_ascii(0xDA, "TYP");
	temp_reg=p_IMGIF_IMG_INFO->img_type;
	arb_debug_reg(0xDB, temp_reg);
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_IMG_INFO->img_type = !temp_reg;
	if(temp_reg == p_IMGIF_IMG_INFO->img_type) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// default val check
	arb_debug_ascii(0xDA, "MOD");
	temp_reg=p_IMGIF_IMG_INFO->img_mode;
	if(temp_reg != 0x1) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_IMG_INFO->img_mode = !temp_reg;
	if(temp_reg == p_IMGIF_IMG_INFO->img_mode) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// default val check
	arb_debug_ascii(0xDA, "FLD");
	temp_reg=p_IMGIF_IMG_INFO->flash_dbg_en;
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_IMG_INFO->flash_dbg_en = !temp_reg;
	if(temp_reg == p_IMGIF_IMG_INFO->flash_dbg_en) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// IMGIF_TB_MARGIN
	// default val check
	arb_debug_ascii(0xDA, "TM ");
	temp_reg=p_IMGIF_TB_MARGIN->v_t_margin;
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_TB_MARGIN->v_t_margin = !temp_reg;
	if(temp_reg == p_IMGIF_TB_MARGIN->v_t_margin) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// default val check
	arb_debug_ascii(0xDA, "BM ");
	temp_reg=p_IMGIF_TB_MARGIN->v_b_margin;
	if(temp_reg != 480) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_TB_MARGIN->v_b_margin = 300;
	if(temp_reg == p_IMGIF_TB_MARGIN->v_b_margin) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// IMGIF_OB_RESOL
	// default val check
	arb_debug_ascii(0xDA, "OBS");
	temp_reg=p_IMGIF_OB_RESOL->h_ob_start;
	if(temp_reg != 4) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_OB_RESOL->h_ob_start = 3;
	if(temp_reg == p_IMGIF_OB_RESOL->h_ob_start) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// default val check
	arb_debug_ascii(0xDA, "OBE");
	temp_reg=p_IMGIF_OB_RESOL->h_ob_end;
	if(temp_reg != 788) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_OB_RESOL->h_ob_end = 760;
	if(temp_reg == p_IMGIF_OB_RESOL->h_ob_end) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// default val check
	arb_debug_ascii(0xDA, "VOBS");
	temp_reg=p_IMGIF_OB_RESOL->v_ob_start;
	if(temp_reg != 4) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_OB_RESOL->v_ob_start = 3;
	if(temp_reg == p_IMGIF_OB_RESOL->v_ob_start) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// IMGIF_H_OB_INFO
	// default val check
	arb_debug_ascii(0xDA, "HOBE");
	temp_reg=p_IMGIF_H_OB_INFO->h_ob_en;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_H_OB_INFO->h_ob_en = !temp_reg;
	if(temp_reg == p_IMGIF_H_OB_INFO->h_ob_en) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// default val check
	arb_debug_ascii(0xDA, "HMW");
	temp_reg=p_IMGIF_H_OB_INFO->h_ob_m_w;
	if(temp_reg != 46) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_H_OB_INFO->h_ob_m_w = 30;
	if(temp_reg == p_IMGIF_H_OB_INFO->h_ob_m_w) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	
	// default val check
	arb_debug_ascii(0xDA, "HSW");
	temp_reg=p_IMGIF_H_OB_INFO->h_ob_s_w;
	if(temp_reg != 32) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_H_OB_INFO->h_ob_s_w = 3;
	if(temp_reg == p_IMGIF_H_OB_INFO->h_ob_s_w) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// default val check
	arb_debug_ascii(0xDA, "HSH");
	temp_reg=p_IMGIF_H_OB_INFO->h_ob_shift_w;
	if(temp_reg != 5) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_H_OB_INFO->h_ob_shift_w = 3;
	if(temp_reg == p_IMGIF_H_OB_INFO->h_ob_shift_w) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// IMGIF_T_OB_INFO
	// default val check
	arb_debug_ascii(0xDA, "TEN");
	temp_reg=p_IMGIF_T_OB_INFO->t_ob_en;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_T_OB_INFO->t_ob_en = !temp_reg;
	if(temp_reg == p_IMGIF_T_OB_INFO->t_ob_en) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "TNR");
	temp_reg=p_IMGIF_T_OB_INFO->t_ob_n_r;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_T_OB_INFO->t_ob_n_r = !temp_reg;
	if(temp_reg == p_IMGIF_T_OB_INFO->t_ob_n_r) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "TNRS");
	temp_reg=p_IMGIF_T_OB_INFO->t_ob_n_r_shift;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_T_OB_INFO->t_ob_n_r_shift = !temp_reg;
	if(temp_reg == p_IMGIF_T_OB_INFO->t_ob_n_r_shift) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "TSW");
	temp_reg=p_IMGIF_T_OB_INFO->t_ob_s_w;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_T_OB_INFO->t_ob_s_w = !temp_reg;
	if(temp_reg == p_IMGIF_T_OB_INFO->t_ob_s_w) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "TSWS");
	temp_reg=p_IMGIF_T_OB_INFO->t_ob_s_w_shift;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_T_OB_INFO->t_ob_s_w_shift = !temp_reg;
	if(temp_reg == p_IMGIF_T_OB_INFO->t_ob_s_w_shift) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// IMGIF_SEMI_ACTIVE_RESOL
	// default val check
	arb_debug_ascii(0xDA, "SAS");
	temp_reg=p_IMGIF_SEMI_ACTIVE_RESOL->sa_start;
	if(temp_reg != 50) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_SEMI_ACTIVE_RESOL->sa_start = 40;
	if(temp_reg == p_IMGIF_SEMI_ACTIVE_RESOL->sa_start) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "SAE");
	temp_reg=p_IMGIF_SEMI_ACTIVE_RESOL->sa_end;
	if(temp_reg != 742) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_SEMI_ACTIVE_RESOL->sa_end = 740;
	if(temp_reg == p_IMGIF_SEMI_ACTIVE_RESOL->sa_end) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// IMGIF_ACTIVE_RESOL
	// default val check
	arb_debug_ascii(0xDA, "AS");
	temp_reg=p_IMGIF_ACTIVE_RESOL->a_start;
	if(temp_reg != 76) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_ACTIVE_RESOL->a_start = 70;
	if(temp_reg == p_IMGIF_ACTIVE_RESOL->a_start) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "AE");
	temp_reg=p_IMGIF_ACTIVE_RESOL->a_end;
	if(temp_reg != 716) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_ACTIVE_RESOL->a_end = 710;
	if(temp_reg == p_IMGIF_ACTIVE_RESOL->a_end) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "NR");
	temp_reg=p_IMGIF_ACTIVE_RESOL->num_rows;
	if(temp_reg != 480) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_ACTIVE_RESOL->num_rows = 70;
	if(temp_reg == p_IMGIF_ACTIVE_RESOL->num_rows) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// IMGIF_ACTIVE_CONFIG
	// default val check
	arb_debug_ascii(0xDA, "MBPR");
	temp_reg=p_IMGIF_ACTIVE_CONFIG->mcb_per_row;
	if(temp_reg != 40) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_ACTIVE_CONFIG->mcb_per_row = 30;
	if(temp_reg == p_IMGIF_ACTIVE_CONFIG->mcb_per_row) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "MBPC");
	temp_reg=p_IMGIF_ACTIVE_CONFIG->mcb_per_col;
	if(temp_reg != 30) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_ACTIVE_CONFIG->mcb_per_col = 10;
	if(temp_reg == p_IMGIF_ACTIVE_CONFIG->mcb_per_col) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "TMB");
	temp_reg=p_IMGIF_ACTIVE_CONFIG->total_mcb;
	if(temp_reg != 1200) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_ACTIVE_CONFIG->total_mcb = 70;
	if(temp_reg == p_IMGIF_ACTIVE_CONFIG->total_mcb) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// IMGIF_PAIR_LUT
	// default val check
	arb_debug_ascii(0xDA, "PL0");
	temp_reg=p_IMGIF_PAIR_LUT_0->as_int;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_PAIR_LUT_0->as_int = 0xFFFFFFFF;
	if(temp_reg == p_IMGIF_PAIR_LUT_0->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "PL1");
	temp_reg=p_IMGIF_PAIR_LUT_1->as_int;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_PAIR_LUT_1->as_int = 0xFFFFFFFF;
	if(temp_reg == p_IMGIF_PAIR_LUT_1->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "PL2");
	temp_reg=p_IMGIF_PAIR_LUT_2->as_int;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_PAIR_LUT_2->as_int = 0xFFFFFFFF;
	if(temp_reg == p_IMGIF_PAIR_LUT_2->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "PL3");
	temp_reg=p_IMGIF_PAIR_LUT_3->as_int;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_PAIR_LUT_3->as_int = 0xFFFFFFFF;
	if(temp_reg == p_IMGIF_PAIR_LUT_3->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// IMGIF_CD_CTRL
	// default val check
	arb_debug_ascii(0xDA, "CDRS");
	temp_reg=p_IMGIF_CD_CTRL->softreset;
	if(temp_reg != 0x1) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_CD_CTRL->softreset = !temp_reg;
	if(temp_reg == p_IMGIF_CD_CTRL->softreset) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "CDEN");
	temp_reg=p_IMGIF_CD_CTRL->cd_en;
	if(temp_reg != 0x1) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_CD_CTRL->cd_en = !temp_reg;
	if(temp_reg == p_IMGIF_CD_CTRL->cd_en) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "CDMD");
	temp_reg=p_IMGIF_CD_CTRL->cd_mode;
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_CD_CTRL->cd_mode = !temp_reg;
	if(temp_reg == p_IMGIF_CD_CTRL->cd_mode) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// IMGIF_CD_CONFIG
	// default val check
	arb_debug_ascii(0xDA, "DFT");
	temp_reg=p_IMGIF_CD_CONFIG->diff_thresh;
	if(temp_reg != 16) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_CD_CONFIG->diff_thresh = 19;
	if(temp_reg == p_IMGIF_CD_CONFIG->diff_thresh) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "DN");
	temp_reg=p_IMGIF_CD_CONFIG->denoise;
	if(temp_reg != 8) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_CD_CONFIG->denoise = 10;
	if(temp_reg == p_IMGIF_CD_CONFIG->denoise) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "CDT");
	temp_reg=p_IMGIF_CD_CONFIG->cd_thresh;
	if(temp_reg != 19) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_CD_CONFIG->cd_thresh = 13;
	if(temp_reg == p_IMGIF_CD_CONFIG->cd_thresh) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "AD");
	temp_reg=p_IMGIF_CD_CONFIG->a_dir;
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_CD_CONFIG->a_dir = !temp_reg;
	if(temp_reg == p_IMGIF_CD_CONFIG->a_dir) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "BD");
	temp_reg=p_IMGIF_CD_CONFIG->b_dir;
	if(temp_reg != 0x1) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_CD_CONFIG->b_dir = !temp_reg;
	if(temp_reg == p_IMGIF_CD_CONFIG->b_dir) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// IMGIF_DILATE_PATT
	// default val check
	arb_debug_ascii(0xDA, "DP");
	temp_reg=p_IMGIF_DILATE_PATT->pattern;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_DILATE_PATT->pattern = 7;
	if(temp_reg == p_IMGIF_DILATE_PATT->pattern) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// IMGIF_SRAM_ADDR
	// default val check
	arb_debug_ascii(0xDA, "CDSR");
	temp_reg=p_IMGIF_SRAM_ADDR->cd_sram;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_SRAM_ADDR->cd_sram = 7;
	if(temp_reg == p_IMGIF_SRAM_ADDR->cd_sram) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// default val check
	arb_debug_ascii(0xDA, "RFSR");
	temp_reg=p_IMGIF_SRAM_ADDR->ref_sram;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_IMGIF_SRAM_ADDR->ref_sram = 7;
	if(temp_reg == p_IMGIF_SRAM_ADDR->ref_sram) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// IMGIF_PIX_RANGE
	// default val check - read only signal
	arb_debug_ascii(0xDA, "LP");
	temp_reg=p_IMGIF_PIX_RANGE->pix_low;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "MP");
	temp_reg=p_IMGIF_PIX_RANGE->pix_high;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// B_CONV
	// default val check
	arb_debug_ascii(0xDA, "AMME");
	temp_reg=p_B_CONV->auto_min_max_en;
	if(temp_reg != 0x1) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_B_CONV->auto_min_max_en = !temp_reg;
	if(temp_reg == p_B_CONV->auto_min_max_en) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "MIN");
	temp_reg=p_B_CONV->min;
	if(temp_reg != 70) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_B_CONV->min = 60;
	if(temp_reg == p_B_CONV->min) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "MAX");
	temp_reg=p_B_CONV->max;
	if(temp_reg != 1023) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_B_CONV->max = 1000;
	if(temp_reg == p_B_CONV->max) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "ASE");
	temp_reg=p_B_CONV->auto_shift_en;
	if(temp_reg != 0x1) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_B_CONV->auto_shift_en = !temp_reg;
	if(temp_reg == p_B_CONV->auto_shift_en) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "SD");
	temp_reg=p_B_CONV->shift_dir;
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_B_CONV->shift_dir = !temp_reg;
	if(temp_reg == p_B_CONV->shift_dir) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "BS");
	temp_reg=p_B_CONV->bit_shift;
	if(temp_reg != 2) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_B_CONV->bit_shift = 4;
	if(temp_reg == p_B_CONV->bit_shift) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "SE");
	temp_reg=p_B_CONV->sat_en;
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_B_CONV->sat_en = !temp_reg;
	if(temp_reg == p_B_CONV->sat_en) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "SS");
	temp_reg=p_B_CONV->sat_shift;
	if(temp_reg != 1) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_B_CONV->sat_shift = 2;
	if(temp_reg == p_B_CONV->sat_shift) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// COMPMEM_CONFIG
	arb_debug_ascii(0xDA, "CCDE");
	temp_reg=p_COMPMEM_CONFIG->compmem_config_dec_en;
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_COMPMEM_CONFIG->compmem_config_dec_en = !temp_reg;
	if(temp_reg == p_COMPMEM_CONFIG->compmem_config_dec_en) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "CCOR");
	temp_reg=p_COMPMEM_CONFIG->compmem_config_odd_row_b;
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_COMPMEM_CONFIG->compmem_config_odd_row_b = !temp_reg;
	if(temp_reg == p_COMPMEM_CONFIG->compmem_config_odd_row_b) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "CCOC");
	temp_reg=p_COMPMEM_CONFIG->compmem_config_odd_col_g;
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_COMPMEM_CONFIG->compmem_config_odd_col_g = !temp_reg;
	if(temp_reg == p_COMPMEM_CONFIG->compmem_config_odd_col_g) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "CCNT");
	temp_reg=p_COMPMEM_CONFIG->compmem_config_nbit_truncate;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_COMPMEM_CONFIG->compmem_config_nbit_truncate = 4;
	if(temp_reg == p_COMPMEM_CONFIG->compmem_config_nbit_truncate) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// FRMMEM_SSADDR
	arb_debug_ascii(0xDA, "FMSY");
	temp_reg=p_FRMMEM_SSADDR->frmmem_ssaddr_y;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_FRMMEM_SSADDR->frmmem_ssaddr_y = 4;
	if(temp_reg == p_FRMMEM_SSADDR->frmmem_ssaddr_y) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "FMSU");
	temp_reg=p_FRMMEM_SSADDR->frmmem_ssaddr_uv;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_FRMMEM_SSADDR->frmmem_ssaddr_uv = 4;
	if(temp_reg == p_FRMMEM_SSADDR->frmmem_ssaddr_uv) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// MCB_ADDR 
	arb_debug_ascii(0xDA, "MBAY");
	temp_reg=p_MCB_ADDR->mcb_addr_y;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "MBAU");
	temp_reg=p_MCB_ADDR->mcb_addr_uv;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// YUV_MAT_ROW0	
	arb_debug_ascii(0xDA, "YMR0");
	temp_reg=p_YUV_MAT_ROW0->col0;
	if(temp_reg != 0b001001101) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_YUV_MAT_ROW0->col0 = temp_reg+2;
	if(temp_reg == p_YUV_MAT_ROW0->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "YMR1");
	temp_reg=p_YUV_MAT_ROW0->col1;
	if(temp_reg != 0b010010110) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_YUV_MAT_ROW0->col1 = temp_reg+2;
	if(temp_reg == p_YUV_MAT_ROW0->col1) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "YMR2");
	temp_reg=p_YUV_MAT_ROW0->col2;
	if(temp_reg != 0b000011101) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_YUV_MAT_ROW0->col2 = temp_reg+2;
	if(temp_reg == p_YUV_MAT_ROW0->col2) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// YUV_MAT_ROW1	
	arb_debug_ascii(0xDA, "YMR0");
	temp_reg=p_YUV_MAT_ROW1->col0;
	if(temp_reg != 0b111010101) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_YUV_MAT_ROW1->col0 = temp_reg+2;
	if(temp_reg == p_YUV_MAT_ROW1->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "YMR1");
	temp_reg=p_YUV_MAT_ROW1->col1;
	if(temp_reg != 0b110101100) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_YUV_MAT_ROW1->col1 = temp_reg+2;
	if(temp_reg == p_YUV_MAT_ROW1->col1) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "YMR2");
	temp_reg=p_YUV_MAT_ROW1->col2;
	if(temp_reg != 0b001111111) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_YUV_MAT_ROW1->col2 = temp_reg+2;
	if(temp_reg == p_YUV_MAT_ROW1->col2) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	// YUV_MAT_ROW2	
	arb_debug_ascii(0xDA, "YMR0");
	temp_reg=p_YUV_MAT_ROW2->col0;
	if(temp_reg != 0b001111111) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_YUV_MAT_ROW2->col0 = temp_reg+2;
	if(temp_reg == p_YUV_MAT_ROW2->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "YMR1");
	temp_reg=p_YUV_MAT_ROW2->col1;
	if(temp_reg != 0b110010110) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_YUV_MAT_ROW2->col1 = temp_reg+2;
	if(temp_reg == p_YUV_MAT_ROW2->col1) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	arb_debug_ascii(0xDA, "YMR2");
	temp_reg=p_YUV_MAT_ROW2->col2;
	if(temp_reg != 0b111101011) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	// write-read test
	p_YUV_MAT_ROW2->col2 = temp_reg+2;
	if(temp_reg == p_YUV_MAT_ROW2->col2) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// Q_Y
	arb_debug_ascii(0xDA, "QY00");
	temp_reg=p_Q_Y_ROW00->col0;
	if(temp_reg != 0b00010000) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_Q_Y_ROW00->col0 = temp_reg+2;
	if(temp_reg == p_Q_Y_ROW00->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "QY01");
	temp_reg=p_Q_Y_ROW01->col0;
	if(temp_reg != 0b00001010) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_Q_Y_ROW01->col0 = temp_reg+2;
	if(temp_reg == p_Q_Y_ROW01->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "QY10");
	temp_reg=p_Q_Y_ROW10->col0;
	if(temp_reg != 0b00010101) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_Q_Y_ROW10->col0 = temp_reg+2;
	if(temp_reg == p_Q_Y_ROW10->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "QY11");
	temp_reg=p_Q_Y_ROW11->col0;
	if(temp_reg != 0b00001001) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_Q_Y_ROW11->col0 = temp_reg+2;
	if(temp_reg == p_Q_Y_ROW11->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// INV_Q_Y
	arb_debug_ascii(0xDA, "IQY0");
	temp_reg=p_INV_Q_Y_ROW00->col0;
	if(temp_reg != 0b00010000) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_INV_Q_Y_ROW00->col0 = temp_reg+2;
	if(temp_reg == p_INV_Q_Y_ROW00->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "IQY1");
	temp_reg=p_INV_Q_Y_ROW01->col0;
	if(temp_reg != 0b00011000) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_INV_Q_Y_ROW01->col0 = temp_reg+2;
	if(temp_reg == p_INV_Q_Y_ROW01->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "IQY0");
	temp_reg=p_INV_Q_Y_ROW10->col0;
	if(temp_reg != 0b00001100) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_INV_Q_Y_ROW10->col0 = temp_reg+2;
	if(temp_reg == p_INV_Q_Y_ROW10->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "IQY1");
	temp_reg=p_INV_Q_Y_ROW11->col0;
	if(temp_reg != 0b00011010) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_INV_Q_Y_ROW11->col0 = temp_reg+2;
	if(temp_reg == p_INV_Q_Y_ROW11->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// DCT_Y
	arb_debug_ascii(0xDA, "DCY0");
	temp_reg=p_DCT_Y_ROW00->col0;
	if(temp_reg != 0b01011011) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_DCT_Y_ROW00->col0 = temp_reg+2;
	if(temp_reg == p_DCT_Y_ROW00->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "DCY1");
	temp_reg=p_DCT_Y_ROW01->col0;
	if(temp_reg != 0b01011011) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_DCT_Y_ROW01->col0 = temp_reg+2;
	if(temp_reg == p_DCT_Y_ROW01->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "DCY0");
	temp_reg=p_DCT_Y_ROW10->col0;
	if(temp_reg != 0b01111110) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_DCT_Y_ROW10->col0 = temp_reg+2;
	if(temp_reg == p_DCT_Y_ROW10->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "DCY1");
	temp_reg=p_DCT_Y_ROW11->col0;
	if(temp_reg != 0b11100111) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_DCT_Y_ROW11->col0 = temp_reg+2;
	if(temp_reg == p_DCT_Y_ROW11->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// Q_UV
	arb_debug_ascii(0xDA, "QUV0");
	temp_reg=p_Q_UV_ROW00->col0;
	if(temp_reg != 0b00001111) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_Q_UV_ROW00->col0 = temp_reg+2;
	if(temp_reg == p_Q_UV_ROW00->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "QUV1");
	temp_reg=p_Q_UV_ROW01->col0;
	if(temp_reg != 0b00000010) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_Q_UV_ROW01->col0 = temp_reg+2;
	if(temp_reg == p_Q_UV_ROW01->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "QUV0");
	temp_reg=p_Q_UV_ROW10->col0;
	if(temp_reg != 0b00001110) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_Q_UV_ROW10->col0 = temp_reg+2;
	if(temp_reg == p_Q_UV_ROW10->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "QUV1");
	temp_reg=p_Q_UV_ROW11->col0;
	if(temp_reg != 0b00000010) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_Q_UV_ROW11->col0 = temp_reg+2;
	if(temp_reg == p_Q_UV_ROW11->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// INV_Q_UV
	arb_debug_ascii(0xDA, "IQU0");
	temp_reg=p_INV_Q_UV_ROW00->col0;
	if(temp_reg != 0b00010001) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_INV_Q_UV_ROW00->col0 = temp_reg+2;
	if(temp_reg == p_INV_Q_UV_ROW00->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "IQU1");
	temp_reg=p_INV_Q_UV_ROW01->col0;
	if(temp_reg != 0b01100011) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_INV_Q_UV_ROW01->col0 = temp_reg+2;
	if(temp_reg == p_INV_Q_UV_ROW01->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "IQU0");
	temp_reg=p_INV_Q_UV_ROW10->col0;
	if(temp_reg != 0b00010010) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_INV_Q_UV_ROW10->col0 = temp_reg+2;
	if(temp_reg == p_INV_Q_UV_ROW10->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "IQU1");
	temp_reg=p_INV_Q_UV_ROW11->col0;
	if(temp_reg != 0b01100011) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_INV_Q_UV_ROW11->col0 = temp_reg+2;
	if(temp_reg == p_INV_Q_UV_ROW11->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// DCT_UV
	arb_debug_ascii(0xDA, "DCU0");
	temp_reg=p_DCT_UV_ROW00->col0;
	if(temp_reg != 0b01011011) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_DCT_UV_ROW00->col0 = temp_reg+2;
	if(temp_reg == p_DCT_UV_ROW00->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "DCU1");
	temp_reg=p_DCT_UV_ROW01->col0;
	if(temp_reg != 0b01011011) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_DCT_UV_ROW01->col0 = temp_reg+2;
	if(temp_reg == p_DCT_UV_ROW01->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "DCU0");
	temp_reg=p_DCT_UV_ROW10->col0;
	if(temp_reg != 0b01111110) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_DCT_UV_ROW10->col0 = temp_reg+2;
	if(temp_reg == p_DCT_UV_ROW10->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "DCU1");
	temp_reg=p_DCT_UV_ROW11->col0;
	if(temp_reg != 0b11100111) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	p_DCT_UV_ROW11->col0 = temp_reg+2;
	if(temp_reg == p_DCT_UV_ROW11->col0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// IMGIF_DBG_STATUS 
	arb_debug_ascii(0xDA, "IDRS");
	temp_reg=p_IMGIF_DBG_STATUS->row_pack_state;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "IDCS");
	temp_reg=p_IMGIF_DBG_STATUS->cd_ctrl_state;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "IDHS");
	temp_reg=p_IMGIF_DBG_STATUS->hamm_sum_state;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "IDRS");
	temp_reg=p_IMGIF_DBG_STATUS->ref_accum_state;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "IDHV");
	temp_reg=p_IMGIF_DBG_STATUS->hamm_sum_val;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// IMGIF_DBG_SRAM
	arb_debug_ascii(0xDA, "ICSS");
	temp_reg=p_IMGIF_DBG_SRAM->cd_sram_state;
	if(temp_reg != 0x1) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	arb_debug_reg(0xDB, temp_reg);

	arb_debug_ascii(0xDA, "ICSA");
	temp_reg=p_IMGIF_DBG_SRAM->cd_sram_addr;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// Default is WRITING (1'b1), but tb changes cd_mode to CD_CURR,
	// so ref_sram_state changes to READING
	arb_debug_ascii(0xDA, "IRSS");
	temp_reg=p_IMGIF_DBG_SRAM->ref_sram_state;
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	arb_debug_ascii(0xDA, "IRSA");
	temp_reg=p_IMGIF_DBG_SRAM->ref_sram_addr;
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// MD_DONE_INT
	arb_debug_ascii(0xDA, "MDIN");
	temp_reg=p_MD_DONE_INT->interrupt;
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// ENC_DONE_INT
	arb_debug_ascii(0xDA, "MDIN");
	temp_reg=p_ENC_DONE_INT->interrupt;
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};

	// CD_MAP
	arb_debug_ascii(0xDA, "CDMP");
	temp_reg=imgif_cd_map_read((uint16_t)2);
	if(temp_reg != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_imgif++;};
	
	//// CD_SRAM
	//// Turn on debug mode
	//dbg_imgif_enable();

	//// read & write from CD SRAM bank 0
	//arb_debug_ascii(0xDA, "CDS0");
	//addr_offset = 0;
	//dbg_imgif_cd_sram_write(addr_offset, 0x0);
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//arb_debug_reg(0xDB, temp_reg);
	//if(temp_reg != 0) arb_debug_ascii(0xD5, "ERR");
	//dbg_imgif_cd_sram_write(addr_offset, 0xDEADBEEF);

	//// read & write from CD SRAM bank 1
	//arb_debug_ascii(0xDA, "CDS1");
	//addr_offset = addr_offset + 2;
	//dbg_imgif_cd_sram_write(addr_offset, 0x0);
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg != 0) arb_debug_ascii(0xD5, "ERR");
	//dbg_imgif_cd_sram_write(addr_offset, 0xDEADBEEF);
	//
	//// read & write from CD SRAM bank 2
	//arb_debug_ascii(0xDA, "CDS2");
	//addr_offset = 511*8;
	//dbg_imgif_cd_sram_write(addr_offset, 0x0);
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg != 0) arb_debug_ascii(0xD5, "ERR");
	//dbg_imgif_cd_sram_write(addr_offset, 0xDEADBEEF);
	//
	//// read & write from CD SRAM bank 3
	//arb_debug_ascii(0xDA, "CDS3");
	//addr_offset = addr_offset + 2;
	//dbg_imgif_cd_sram_write(addr_offset, 0x0);
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg != 0) arb_debug_ascii(0xD5, "ERR");
	//dbg_imgif_cd_sram_write(addr_offset, 0xDEADBEEF);
	//
	//// read & write from CD SRAM bank 4
	//arb_debug_ascii(0xDA, "CDS4");
	//addr_offset = 512*8;
	//dbg_imgif_cd_sram_write(addr_offset, 0x0);
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg != 0) arb_debug_ascii(0xD5, "ERR");
	//dbg_imgif_cd_sram_write(addr_offset, 0xDEADBEEF);
	//
	//// read & write from CD SRAM bank 5
	//arb_debug_ascii(0xDA, "CDS5");
	//addr_offset = addr_offset + 2;
	//dbg_imgif_cd_sram_write(addr_offset, 0x0);
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg != 0) arb_debug_ascii(0xD5, "ERR");
	//dbg_imgif_cd_sram_write(addr_offset, 0xDEADBEEF);
	//
	//// read & write from CD SRAM bank 6
	//arb_debug_ascii(0xDA, "CDS6");
	//addr_offset = 1023*8;
	//dbg_imgif_cd_sram_write(addr_offset, 0x0);
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg != 0) arb_debug_ascii(0xD5, "ERR");
	//dbg_imgif_cd_sram_write(addr_offset, 0xDEADBEEF);
	//
	//// read & write from CD SRAM bank 7
	//arb_debug_ascii(0xDA, "CDS7");
	//addr_offset = addr_offset + 2;
	//dbg_imgif_cd_sram_write(addr_offset, 0x0);
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg != 0) arb_debug_ascii(0xD5, "ERR");
	//dbg_imgif_cd_sram_write(addr_offset, 0xDEADBEEF);
	//
	//// read & write from CD SRAM bank 8
	//arb_debug_ascii(0xDA, "CDS8");
	//addr_offset = 1024*8;
	//dbg_imgif_cd_sram_write(addr_offset, 0x0);
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg != 0) arb_debug_ascii(0xD5, "ERR");
	//dbg_imgif_cd_sram_write(addr_offset, 0xDEADBEEF);
	//
	//// read & write from CD SRAM bank 9
	//arb_debug_ascii(0xDA, "CDS9");
	//addr_offset = addr_offset + 2;
	//dbg_imgif_cd_sram_write(addr_offset, 0x0);
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg != 0) arb_debug_ascii(0xD5, "ERR");
	//dbg_imgif_cd_sram_write(addr_offset, 0xDEADBEEF);
	//
	//// read & write from CD SRAM bank 10
	//arb_debug_ascii(0xDA, "CDSA");
	//addr_offset = 1535*8;
	//dbg_imgif_cd_sram_write(addr_offset, 0x0);
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg != 0) arb_debug_ascii(0xD5, "ERR");
	//dbg_imgif_cd_sram_write(addr_offset, 0xDEADBEEF);
	//
	//// read & write from CD SRAM bank 11
	//arb_debug_ascii(0xDA, "CDSB");
	//addr_offset = addr_offset + 2;
	//dbg_imgif_cd_sram_write(addr_offset, 0x0);
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg != 0) arb_debug_ascii(0xD5, "ERR");
	//dbg_imgif_cd_sram_write(addr_offset, 0xDEADBEEF);
	//
	//// read & write from CD SRAM bank 12
	//arb_debug_ascii(0xDA, "CDSC");
	//addr_offset = 1536*8;
	//dbg_imgif_cd_sram_write(addr_offset, 0x0);
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg != 0) arb_debug_ascii(0xD5, "ERR");
	//dbg_imgif_cd_sram_write(addr_offset, 0xDEADBEEF);
	//
	//// read & write from CD SRAM bank 13
	//arb_debug_ascii(0xDA, "CDSD");
	//addr_offset = addr_offset + 2;
	//dbg_imgif_cd_sram_write(addr_offset, 0x0);
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg != 0) arb_debug_ascii(0xD5, "ERR");
	//dbg_imgif_cd_sram_write(addr_offset, 0xDEADBEEF);
	//
	//// read & write from CD SRAM bank 14
	//arb_debug_ascii(0xDA, "CDSE");
	//addr_offset = 2047*8;
	//dbg_imgif_cd_sram_write(addr_offset, 0x0);
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg != 0) arb_debug_ascii(0xD5, "ERR");
	//dbg_imgif_cd_sram_write(addr_offset, 0xDEADBEEF);
	//
	//// read & write from CD SRAM bank 15
	//arb_debug_ascii(0xDA, "CDSF");
	//addr_offset = addr_offset + 2;
	//dbg_imgif_cd_sram_write(addr_offset, 0x0);
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg != 0) arb_debug_ascii(0xD5, "ERR");
	//dbg_imgif_cd_sram_write(addr_offset, 0xDEADBEEF);
	//
	//// check read from CD SRAM bank 0
	//arb_debug_ascii(0xDA, "CDS0");
	//addr_offset = 0;
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg!=0xDEADBEEF) {
	//	arb_debug_ascii(0xD5, "ERR");
	//}
	//arb_debug_reg(0xDB, temp_reg);

	//// read & write from CD SRAM bank 1
	//arb_debug_ascii(0xDA, "CDS1");
	//addr_offset = addr_offset + 2;
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg!=0xDEADBEEF) {
	//	arb_debug_ascii(0xD5, "ERR");
	//}
	//arb_debug_reg(0xDB, temp_reg);
	//
	//// read & write from CD SRAM bank 2
	//arb_debug_ascii(0xDA, "CDS2");
	//addr_offset = 511*8;
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg!=0xDEADBEEF) {
	//	arb_debug_ascii(0xD5, "ERR");
	//}
	//arb_debug_reg(0xDB, temp_reg);
	//
	//// read & write from CD SRAM bank 3
	//arb_debug_ascii(0xDA, "CDS3");
	//addr_offset = addr_offset + 2;
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg!=0xDEADBEEF) {
	//	arb_debug_ascii(0xD5, "ERR");
	//}
	//arb_debug_reg(0xDB, temp_reg);
	//
	//// read & write from CD SRAM bank 4
	//arb_debug_ascii(0xDA, "CDS4");
	//addr_offset = 512*8;
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg!=0xDEADBEEF) {
	//	arb_debug_ascii(0xD5, "ERR");
	//}
	//arb_debug_reg(0xDB, temp_reg);
	//
	//// read & write from CD SRAM bank 5
	//arb_debug_ascii(0xDA, "CDS5");
	//addr_offset = addr_offset + 2;
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg!=0xDEADBEEF) {
	//	arb_debug_ascii(0xD5, "ERR");
	//}
	//arb_debug_reg(0xDB, temp_reg);
	//
	//// read & write from CD SRAM bank 6
	//arb_debug_ascii(0xDA, "CDS6");
	//addr_offset = 1023*8;
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg!=0xDEADBEEF) {
	//	arb_debug_ascii(0xD5, "ERR");
	//}
	//arb_debug_reg(0xDB, temp_reg);
	//
	//// read & write from CD SRAM bank 7
	//arb_debug_ascii(0xDA, "CDS7");
	//addr_offset = addr_offset + 2;
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg!=0xDEADBEEF) {
	//	arb_debug_ascii(0xD5, "ERR");
	//}
	//arb_debug_reg(0xDB, temp_reg);
	//
	//// read & write from CD SRAM bank 8
	//arb_debug_ascii(0xDA, "CDS8");
	//addr_offset = 1024*8;
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg!=0xDEADBEEF) {
	//	arb_debug_ascii(0xD5, "ERR");
	//}
	//arb_debug_reg(0xDB, temp_reg);
	//
	//// read & write from CD SRAM bank 9
	//arb_debug_ascii(0xDA, "CDS9");
	//addr_offset = addr_offset + 2;
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg!=0xDEADBEEF) {
	//	arb_debug_ascii(0xD5, "ERR");
	//}
	//arb_debug_reg(0xDB, temp_reg);
	//
	//// read & write from CD SRAM bank 10
	//arb_debug_ascii(0xDA, "CDSA");
	//addr_offset = 1535*8;
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg!=0xDEADBEEF) {
	//	arb_debug_ascii(0xD5, "ERR");
	//}
	//arb_debug_reg(0xDB, temp_reg);
	//
	//// read & write from CD SRAM bank 11
	//arb_debug_ascii(0xDA, "CDSB");
	//addr_offset = addr_offset + 2;
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg!=0xDEADBEEF) {
	//	arb_debug_ascii(0xD5, "ERR");
	//}
	//arb_debug_reg(0xDB, temp_reg);
	//
	//// read & write from CD SRAM bank 12
	//arb_debug_ascii(0xDA, "CDSC");
	//addr_offset = 1536*8;
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg!=0xDEADBEEF) {
	//	arb_debug_ascii(0xD5, "ERR");
	//}
	//arb_debug_reg(0xDB, temp_reg);
	//
	//// read & write from CD SRAM bank 13
	//arb_debug_ascii(0xDA, "CDSD");
	//addr_offset = addr_offset + 2;
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg!=0xDEADBEEF) {
	//	arb_debug_ascii(0xD5, "ERR");
	//}
	//arb_debug_reg(0xDB, temp_reg);
	//
	//// read & write from CD SRAM bank 14
	//arb_debug_ascii(0xDA, "CDSE");
	//addr_offset = 2047*8;
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg!=0xDEADBEEF) {
	//	arb_debug_ascii(0xD5, "ERR");
	//}
	//arb_debug_reg(0xDB, temp_reg);
	//
	//// read & write from CD SRAM bank 15
	//arb_debug_ascii(0xDA, "CDSF");
	//addr_offset = addr_offset + 2;
	//temp_reg=imgif_cd_sram_read(addr_offset);
	//if(temp_reg!=0xDEADBEEF) {
	//	arb_debug_ascii(0xD5, "ERR");
	//}
	//arb_debug_reg(0xDB, temp_reg);

	//********************************************************************
	// NE TEST             
	//********************************************************************
	arb_debug_ascii(0xD3, "NE  ");


    // now actually un-reset
    ne_enable();

    // NE_RESET_AND_ENABLE
    arb_debug_ascii(0xDA, "RST");
    NE_RESET_AND_ENABLE_t rst_en_result = ne_get_reset_and_enable();
    if(rst_en_result.enable == 0 || rst_en_result.resetn == 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_ne++;};


    // read & set & re-read framemem_baseaddr
    arb_debug_ascii(0xDA, "FMB");
    if(ne_get_frame_mem_addr() != 0xA0411290) {arb_debug_ascii(0xD5, "ERR");err_cnt_ne++;};
    ne_set_frame_mem_addr(0xBEEFBEEF);
    if(ne_get_frame_mem_addr() != 0xBEEFBEEF) {arb_debug_ascii(0xD5, "ERR");err_cnt_ne++;};
    ne_set_frame_mem_addr(0xA0411290);
    if(ne_get_frame_mem_addr() != 0xA0411290) {arb_debug_ascii(0xD5, "ERR");err_cnt_ne++;};


    // write & read back every NCX register
    uint8_t ii = 0;
    uint8_t jj = 0;
    arb_debug_ascii(0xDA, "NXRG");
    for(ii=0; ii < 24; ii++){
        ne_set_ncx_register(ii, (uint16_t) (ii) );
        delay(1);
        jj = ne_get_ncx_register(ii);
        arb_debug_ascii(0xDA, ii + '0');
        arb_debug_ascii(0xDA, jj + '0');
        if(ii != jj) {arb_debug_ascii(0xD5, "ERR");err_cnt_ne++;};
    }


    // set and unset autogate mode (default is 1)
    // keep it unset so that the accumulator reads work
    //arb_debug_ascii(0xDA, "AUG");
    //if(ne_get_conf_autogate_pe() != 1) {arb_debug_ascii(0xD5, "ERR");err_cnt_ne++;};
    //ne_set_conf_autogate_pe(0);
    //if(ne_get_conf_autogate_pe() != 0) {arb_debug_ascii(0xD5, "ERR");err_cnt_ne++;};


    //---------------------------------------
    // write & read the different memories
    
    //// imem only has 1 bank (actually 2 in parallel)
    //arb_debug_ascii(0xDA, "IMEM");
    //ne_imem_write(0x0,  0xBEEFB0D0);
    //ne_imem_write(0x4,  0xBEEFB0D1);
    //ne_imem_write(0x8,  0xBEEFB0D2);
    //ne_imem_write(0xC,  0xBEEFB0D3);
    //ne_imem_write(0x10, 0xBEEFB0D4);
    //ne_imem_write(0x14, 0xBEEFB0D5);
    //ne_imem_write(0x18, 0xBEEFB0D6);
    //ne_imem_write(0x1C, 0xBEEFB0D7);
    //if(ne_imem_read(0x0) != 0xBEEFB0D0) arb_debug_ascii(0xD5, "ERR");
    //if(ne_imem_read(0x4) != 0xBEEFB0D1) arb_debug_ascii(0xD5, "ERR");
    //if(ne_imem_read(0x8) != 0xBEEFB0D2) arb_debug_ascii(0xD5, "ERR");
    //if(ne_imem_read(0xC) != 0xBEEFB0D3) arb_debug_ascii(0xD5, "ERR");
    //if(ne_imem_read(0x10) != 0xBEEFB0D4) arb_debug_ascii(0xD5, "ERR");
    //if(ne_imem_read(0x14) != 0xBEEFB0D5) arb_debug_ascii(0xD5, "ERR");
    //if(ne_imem_read(0x18) != 0xBEEFB0D6) arb_debug_ascii(0xD5, "ERR");
    //if(ne_imem_read(0x1C) != 0xBEEFB0D7) arb_debug_ascii(0xD5, "ERR");
   

    //// sharedmem has 80 banks
    //int i=0;
    //for(i=0; i < (8192*80); i += 8192){

    //    arb_debug_ascii(0xDA, "SMEM");
    //    ne_sharedmem_write(0x0 + i,  0xBEEFB0D0);
    //    ne_sharedmem_write(0x4 + i,  0xBEEFB0D1);
    //    ne_sharedmem_write(0x8 + i,  0xBEEFB0D2);
    //    ne_sharedmem_write(0xC + i,  0xBEEFB0D3);
    //    if(ne_sharedmem_read(0x0 + i) != 0xBEEFB0D0) arb_debug_ascii(0xD5, "ERR");
    //    if(ne_sharedmem_read(0x4 + i) != 0xBEEFB0D1) arb_debug_ascii(0xD5, "ERR");
    //    if(ne_sharedmem_read(0x8 + i) != 0xBEEFB0D2) arb_debug_ascii(0xD5, "ERR");
    //    if(ne_sharedmem_read(0xC + i) != 0xBEEFB0D3) arb_debug_ascii(0xD5, "ERR");

    //}


    //// localmem has 2 banks (each are 4 in parallel)
    //arb_debug_ascii(0xDA, "LMEM");
    //dbg_ne_pe_localmem_write(0x0,  0xBEEFB0D0);
    //dbg_ne_pe_localmem_write(0x4,  0xBEEFB0D1);
    //dbg_ne_pe_localmem_write(0x8,  0xBEEFB0D2);
    //dbg_ne_pe_localmem_write(0xC,  0xBEEFB0D3);
    //dbg_ne_pe_localmem_write(0x10, 0xBEEFB0D4);
    //dbg_ne_pe_localmem_write(0x14, 0xBEEFB0D5);
    //dbg_ne_pe_localmem_write(0x18, 0xBEEFB0D6);
    //dbg_ne_pe_localmem_write(0x1C, 0xBEEFB0D7);
    //dbg_ne_pe_localmem_write(0x20,  0xBEEFB0D0);
    //dbg_ne_pe_localmem_write(0x24,  0xBEEFB0D1);
    //dbg_ne_pe_localmem_write(0x28,  0xBEEFB0D2);
    //dbg_ne_pe_localmem_write(0x2C,  0xBEEFB0D3);
    //dbg_ne_pe_localmem_write(0x30, 0xBEEFB0D4);
    //dbg_ne_pe_localmem_write(0x34, 0xBEEFB0D5);
    //dbg_ne_pe_localmem_write(0x38, 0xBEEFB0D6);
    //dbg_ne_pe_localmem_write(0x3C, 0xBEEFB0D7);
    //if(dbg_ne_pe_localmem_read(0x0) != 0xBEEFB0D0) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x4) != 0xBEEFB0D1) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x8) != 0xBEEFB0D2) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0xC) != 0xBEEFB0D3) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x10) != 0xBEEFB0D4) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x14) != 0xBEEFB0D5) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x18) != 0xBEEFB0D6) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x1C) != 0xBEEFB0D7) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x20) != 0xBEEFB0D0) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x24) != 0xBEEFB0D1) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x28) != 0xBEEFB0D2) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x2C) != 0xBEEFB0D3) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x30) != 0xBEEFB0D4) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x34) != 0xBEEFB0D5) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x38) != 0xBEEFB0D6) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x3C) != 0xBEEFB0D7) arb_debug_ascii(0xD5, "ERR");
    //arb_debug_ascii(0xDA, "LMEM");
    //dbg_ne_pe_localmem_write(0x0 + 2048,  0xBEEFB0D0);
    //dbg_ne_pe_localmem_write(0x4 + 2048,  0xBEEFB0D1);
    //dbg_ne_pe_localmem_write(0x8 + 2048,  0xBEEFB0D2);
    //dbg_ne_pe_localmem_write(0xC + 2048,  0xBEEFB0D3);
    //dbg_ne_pe_localmem_write(0x10 + 2048, 0xBEEFB0D4);
    //dbg_ne_pe_localmem_write(0x14 + 2048, 0xBEEFB0D5);
    //dbg_ne_pe_localmem_write(0x18 + 2048, 0xBEEFB0D6);
    //dbg_ne_pe_localmem_write(0x1C + 2048, 0xBEEFB0D7);
    //dbg_ne_pe_localmem_write(0x20 + 2048,  0xBEEFB0D0);
    //dbg_ne_pe_localmem_write(0x24 + 2048,  0xBEEFB0D1);
    //dbg_ne_pe_localmem_write(0x28 + 2048,  0xBEEFB0D2);
    //dbg_ne_pe_localmem_write(0x2C + 2048,  0xBEEFB0D3);
    //dbg_ne_pe_localmem_write(0x30 + 2048, 0xBEEFB0D4);
    //dbg_ne_pe_localmem_write(0x34 + 2048, 0xBEEFB0D5);
    //dbg_ne_pe_localmem_write(0x38 + 2048, 0xBEEFB0D6);
    //dbg_ne_pe_localmem_write(0x3C + 2048, 0xBEEFB0D7);
    //if(dbg_ne_pe_localmem_read(0x0 + 2048) != 0xBEEFB0D0) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x4 + 2048) != 0xBEEFB0D1) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x8 + 2048) != 0xBEEFB0D2) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0xC + 2048) != 0xBEEFB0D3) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x10 + 2048) != 0xBEEFB0D4) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x14 + 2048) != 0xBEEFB0D5) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x18 + 2048) != 0xBEEFB0D6) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x1C + 2048) != 0xBEEFB0D7) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x20 + 2048) != 0xBEEFB0D0) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x24 + 2048) != 0xBEEFB0D1) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x28 + 2048) != 0xBEEFB0D2) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x2C + 2048) != 0xBEEFB0D3) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x30 + 2048) != 0xBEEFB0D4) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x34 + 2048) != 0xBEEFB0D5) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x38 + 2048) != 0xBEEFB0D6) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_localmem_read(0x3C + 2048) != 0xBEEFB0D7) arb_debug_ascii(0xD5, "ERR");

    //// same for weight buffer mem
    //arb_debug_ascii(0xDA, "WMEM");
    //dbg_ne_pe_weightbuf_write(0x0,  0xBEEFB0D0);
    //dbg_ne_pe_weightbuf_write(0x4,  0xBEEFB0D1);
    //dbg_ne_pe_weightbuf_write(0x8,  0xBEEFB0D2);
    //dbg_ne_pe_weightbuf_write(0xC,  0xBEEFB0D3);
    //dbg_ne_pe_weightbuf_write(0x10, 0xBEEFB0D4);
    //dbg_ne_pe_weightbuf_write(0x14, 0xBEEFB0D5);
    //dbg_ne_pe_weightbuf_write(0x18, 0xBEEFB0D6);
    //dbg_ne_pe_weightbuf_write(0x1C, 0xBEEFB0D7);
    //dbg_ne_pe_weightbuf_write(0x20,  0xBEEFB0D0);
    //dbg_ne_pe_weightbuf_write(0x24,  0xBEEFB0D1);
    //dbg_ne_pe_weightbuf_write(0x28,  0xBEEFB0D2);
    //dbg_ne_pe_weightbuf_write(0x2C,  0xBEEFB0D3);
    //dbg_ne_pe_weightbuf_write(0x30, 0xBEEFB0D4);
    //dbg_ne_pe_weightbuf_write(0x34, 0xBEEFB0D5);
    //dbg_ne_pe_weightbuf_write(0x38, 0xBEEFB0D6);
    //dbg_ne_pe_weightbuf_write(0x3C, 0xBEEFB0D7);
    //if(dbg_ne_pe_weightbuf_read(0x0) != 0xBEEFB0D0) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x4) != 0xBEEFB0D1) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x8) != 0xBEEFB0D2) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0xC) != 0xBEEFB0D3) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x10) != 0xBEEFB0D4) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x14) != 0xBEEFB0D5) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x18) != 0xBEEFB0D6) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x1C) != 0xBEEFB0D7) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x20) != 0xBEEFB0D0) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x24) != 0xBEEFB0D1) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x28) != 0xBEEFB0D2) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x2C) != 0xBEEFB0D3) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x30) != 0xBEEFB0D4) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x34) != 0xBEEFB0D5) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x38) != 0xBEEFB0D6) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x3C) != 0xBEEFB0D7) arb_debug_ascii(0xD5, "ERR");
    //arb_debug_ascii(0xDA, "WMEM");
    //dbg_ne_pe_weightbuf_write(0x0 + 2048,  0xBEEFB0D0);
    //dbg_ne_pe_weightbuf_write(0x4 + 2048,  0xBEEFB0D1);
    //dbg_ne_pe_weightbuf_write(0x8 + 2048,  0xBEEFB0D2);
    //dbg_ne_pe_weightbuf_write(0xC + 2048,  0xBEEFB0D3);
    //dbg_ne_pe_weightbuf_write(0x10 + 2048, 0xBEEFB0D4);
    //dbg_ne_pe_weightbuf_write(0x14 + 2048, 0xBEEFB0D5);
    //dbg_ne_pe_weightbuf_write(0x18 + 2048, 0xBEEFB0D6);
    //dbg_ne_pe_weightbuf_write(0x1C + 2048, 0xBEEFB0D7);
    //dbg_ne_pe_weightbuf_write(0x20 + 2048,  0xBEEFB0D0);
    //dbg_ne_pe_weightbuf_write(0x24 + 2048,  0xBEEFB0D1);
    //dbg_ne_pe_weightbuf_write(0x28 + 2048,  0xBEEFB0D2);
    //dbg_ne_pe_weightbuf_write(0x2C + 2048,  0xBEEFB0D3);
    //dbg_ne_pe_weightbuf_write(0x30 + 2048, 0xBEEFB0D4);
    //dbg_ne_pe_weightbuf_write(0x34 + 2048, 0xBEEFB0D5);
    //dbg_ne_pe_weightbuf_write(0x38 + 2048, 0xBEEFB0D6);
    //dbg_ne_pe_weightbuf_write(0x3C + 2048, 0xBEEFB0D7);
    //if(dbg_ne_pe_weightbuf_read(0x0 + 2048) != 0xBEEFB0D0) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x4 + 2048) != 0xBEEFB0D1) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x8 + 2048) != 0xBEEFB0D2) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0xC + 2048) != 0xBEEFB0D3) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x10 + 2048) != 0xBEEFB0D4) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x14 + 2048) != 0xBEEFB0D5) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x18 + 2048) != 0xBEEFB0D6) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x1C + 2048) != 0xBEEFB0D7) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x20 + 2048) != 0xBEEFB0D0) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x24 + 2048) != 0xBEEFB0D1) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x28 + 2048) != 0xBEEFB0D2) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x2C + 2048) != 0xBEEFB0D3) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x30 + 2048) != 0xBEEFB0D4) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x34 + 2048) != 0xBEEFB0D5) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x38 + 2048) != 0xBEEFB0D6) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_weightbuf_read(0x3C + 2048) != 0xBEEFB0D7) arb_debug_ascii(0xD5, "ERR");

    //// bias buf is just 1 bank all by itself
    //arb_debug_ascii(0xDA, "BBUF");
    //dbg_ne_pe_bias_buffer_write(0x0,  0xBEEFB0D0);
    //dbg_ne_pe_bias_buffer_write(0x4,  0xBEEFB0D1);
    //dbg_ne_pe_bias_buffer_write(0x8,  0xBEEFB0D2);
    //dbg_ne_pe_bias_buffer_write(0xC,  0xBEEFB0D3);
    //if(dbg_ne_pe_bias_buffer_read(0x0) != 0xBEEFB0D0) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_bias_buffer_read(0x4) != 0xBEEFB0D1) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_bias_buffer_read(0x8) != 0xBEEFB0D2) arb_debug_ascii(0xD5, "ERR");
    //if(dbg_ne_pe_bias_buffer_read(0xC) != 0xBEEFB0D3) arb_debug_ascii(0xD5, "ERR");



    //// accumulators are 64 banks
    //for(i=0; i < (32*64); i+=32){
    //    arb_debug_ascii(0xDA, "ACCM");
    //    dbg_ne_pe_accumulators_write(0x0 + i,  0xBEEFB0D0+i);
    //    if(dbg_ne_pe_accumulators_read(0x0 + i) != 0xBEEFB0D0+i) arb_debug_ascii(0xD5, "ERR");
    //}

	
	
	//********************************************************************
	// H264 TEST             
	//********************************************************************
	arb_debug_ascii(0xD3,"H264");


	p_H264_ENABLE->h264_en = 0x0;
	p_H264_DEBUG->h264_debug_sram_sel = 0x0;
	p_H264_DEBUG->h264_debug_start_bypass = 0x0;
	p_H264_DEBUG->h264_debug_out_sel = 0x0;

	// H264_ENABLE
	//Read Write registers
	//default value check
	arb_debug_ascii(0xDA, "RG0a");
	temp_reg=p_H264_ENABLE->h264_frm_rstn;
	if(temp_reg !=0x1){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}
	//write-read test	
	p_H264_ENABLE->h264_frm_rstn = 0x0;
	if(p_H264_ENABLE->h264_frm_rstn != 0x0) {arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}
	p_H264_ENABLE->h264_frm_rstn = 0x1;
	
	arb_debug_ascii(0xDA, "RG0b");
	temp_reg=p_H264_ENABLE->h264_en;
	if(temp_reg !=0x0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	
	p_H264_ENABLE->h264_en = 0x1;
	if(p_H264_ENABLE->h264_en != 0x1){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}
	p_H264_ENABLE->h264_en = 0x0;

	//H264_PARAM
	arb_debug_ascii(0xDA, "RG1 ");
	temp_reg=p_H264_PARAM->h264_qp;
	if(temp_reg !=0x1E){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	
	p_H264_PARAM->h264_qp = 0x10;
	if(p_H264_PARAM->h264_qp != 0x10) {arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}

	//H264_CTRL
	arb_debug_ascii(0xDA, "RG2a");
	temp_reg=p_H264_CTRL->h264_start;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	
	p_H264_CTRL->h264_start = 0x1;
	if(p_H264_CTRL->h264_start != 0x1) {arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}
	p_H264_CTRL->h264_start = 0x0;

	

	arb_debug_ascii(0xDA, "RG2b");
	temp_reg=p_H264_CTRL->h264_mcbrow;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	
	p_H264_CTRL->h264_mcbrow = 0x10;
	if(p_H264_CTRL->h264_mcbrow != 0x10) {arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}

	arb_debug_ascii(0xDA, "RG2c");
	temp_reg=p_H264_CTRL->h264_mcbcol;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	
	p_H264_CTRL->h264_mcbcol = 0x20;
	if(p_H264_CTRL->h264_mcbcol != 0x20) {arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}

	//H264_COMPMEM_SADDR
	arb_debug_ascii(0xDA, "RG3 ");
	temp_reg=p_H264_COMPMEM_SADDR_YREF->as_int;
	if(temp_reg != 0xA0411290 ){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	
	p_H264_COMPMEM_SADDR_YREF->as_int = 0xA0411290;
	if(p_H264_COMPMEM_SADDR_YREF->as_int != 0xA0411290) {arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}

	arb_debug_ascii(0xDA, "RG4 ");
	temp_reg=p_H264_COMPMEM_SADDR_UVREF->as_int;
	if(temp_reg != 0xA0412550 ){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	
	p_H264_COMPMEM_SADDR_UVREF->as_int = 0xA0412550;
	if(p_H264_COMPMEM_SADDR_UVREF->as_int != 0xA0412550) {arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}

	/*arb_debug_ascii(0xDA, "RG5 ");
	temp_reg=p_H264_COMPMEM_SADDR_YCUR->as_int;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");}	
	p_H264_COMPMEM_SADDR_YCUR->as_int = 2401;
	if(p_H264_COMPMEM_SADDR_YCUR->as_int != 2401) arb_debug_ascii(0xD5,"ERR");

	arb_debug_ascii(0xDA, "RG6 ");
	temp_reg=p_H264_COMPMEM_SADDR_UVCUR->as_int;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");}	
	p_H264_COMPMEM_SADDR_UVCUR->as_int = 3601;
	if(p_H264_COMPMEM_SADDR_UVCUR->as_int != 3601) arb_debug_ascii(0xD5,"ERR");*/

	//H264_DEBUG
	arb_debug_ascii(0xDA, "RG7a");
	temp_reg=p_H264_DEBUG->h264_debug_sram_sel;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	
	p_H264_DEBUG->h264_debug_sram_sel = 0x1;
	if(p_H264_DEBUG->h264_debug_sram_sel != 0x1) {arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}

	arb_debug_ascii(0xDA, "RG7b");
	temp_reg=p_H264_DEBUG->h264_debug_start_bypass;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	
	p_H264_DEBUG->h264_debug_start_bypass = 0x1;
	if(p_H264_DEBUG->h264_debug_start_bypass != 0x1) {arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}
	p_H264_DEBUG->h264_debug_start_bypass = 0x0;

	arb_debug_ascii(0xDA, "RG7c");
	temp_reg=p_H264_DEBUG->h264_debug_out_sel;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	
	p_H264_DEBUG->h264_debug_out_sel = 0x1;
	if(p_H264_DEBUG->h264_debug_out_sel != 0x1) {arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}
	p_H264_DEBUG->h264_debug_out_sel = 0x0;

	arb_debug_ascii(0xDA, "RG7d");
	temp_reg=p_H264_DEBUG->h264_timer_stall_en;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	
	p_H264_DEBUG->h264_timer_stall_en = 0x1;
	if(p_H264_DEBUG->h264_timer_stall_en != 0x1) {arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}
	p_H264_DEBUG->h264_timer_stall_en = 0x0;

	arb_debug_ascii(0xDA, "RG7e");
	temp_reg=p_H264_DEBUG->h264_cycles_to_run;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	
	p_H264_DEBUG->h264_cycles_to_run = 0xABCD;
	if(p_H264_DEBUG->h264_cycles_to_run != 0xABCD) {arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}
	p_H264_DEBUG->h264_cycles_to_run = 0x0000;


	//H264_FIFO
	arb_debug_ascii(0xDA, "RG8 ");
	temp_reg=p_H264_FIFO->as_int;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	

	//H264_FIFO_DATACNT
	arb_debug_ascii(0xDA, "RG9 ");
	temp_reg=p_H264_FIFO_DATACNT->as_int;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	

	//H264_INTR_DONE
	arb_debug_ascii(0xDA, "RGA ");
	p_H264_INTR_DONE->as_int = 0;

	//H264_INTR_FIFO
	arb_debug_ascii(0xDA, "RGB ");
	p_H264_INTR_FIFO->as_int = 0;

	//H264_STATUS
	arb_debug_ascii(0xDA, "RGCa");
	temp_reg=p_H264_STATUS->h264_ctrl_stat;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	

	arb_debug_ascii(0xDA, "RGCb");
	temp_reg=p_H264_STATUS->h264_pred_stat;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	

	arb_debug_ascii(0xDA, "RGCc");
	temp_reg=p_H264_STATUS->h264_tq_stat;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	

	arb_debug_ascii(0xDA, "RGCd");
	temp_reg=p_H264_STATUS->h264_cavlc_stat;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	

	arb_debug_ascii(0xDA, "RGCe");
	temp_reg=p_H264_STATUS->h264_left_mcb_valid;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	

	arb_debug_ascii(0xDA, "RGCf");
	temp_reg=p_H264_STATUS->h264_top_mcb_valid;
	if(temp_reg != 0){arb_debug_ascii(0xD5,"ERR");err_cnt_h264++;}	

	////H264_MEM
	//p_H264_ENABLE->h264_en = 0x1;	

	//arb_debug_ascii(0xDA, "MEM0");
	//// write 0xABCDEFFFF12345678 into physical address 0
	//(p_H264_MEM_START+0)->as_int = 0x12345678;
	//(p_H264_MEM_START+1)->as_int = 0xABCDEFFF;
	////(p_H264_MEM_START+1)->as_int = 0xABCDEFFF;
	//temp_reg = (p_H264_MEM_START+1023)->as_int;

	//// read logical address 0
 	//(p_H264_MEM_START+1022)->as_int = 0x0;
	//(p_H264_MEM_START+1023)->as_int = 0x0;
	//temp_reg = (p_H264_MEM_START+0)->as_int;
	//if(temp_reg != 0x12345678){arb_debug_ascii(0xD5,"ERR");}	
	//
	//// read logical address 1
	//(p_H264_MEM_START+1022)->as_int = 0x0;
	//(p_H264_MEM_START+1023)->as_int = 0x0;
	//temp_reg = (p_H264_MEM_START+1)->as_int;
	//if(temp_reg != 0xABCDEFFF){arb_debug_ascii(0xD5,"ERR");}

	//arb_debug_ascii(0xDA, "MEM1");
	//// write 0xFFFEDCBA87654321 into physical address 255
	//(p_H264_MEM_START+255*2)->as_int = 0x87654321;
	//(p_H264_MEM_START+255*2+1)->as_int = 0xFFFEDCBA;
	//temp_reg = (p_H264_MEM_START+1023)->as_int;

	//// read logical address 510
	//(p_H264_MEM_START+1022)->as_int = 0x0;
	//(p_H264_MEM_START+1023)->as_int = 0x0;
	//temp_reg = (p_H264_MEM_START+255*2)->as_int;
	//if(temp_reg != 0x87654321){arb_debug_ascii(0xD5,"ERR");}	
	//
	//// read logical address 511
	//(p_H264_MEM_START+1022)->as_int = 0x0;
	//(p_H264_MEM_START+1023)->as_int = 0x0;
	//temp_reg = (p_H264_MEM_START+255*2+1)->as_int;
	//if(temp_reg != 0xFFFEDCBA){arb_debug_ascii(0xD5,"ERR");}	

	//arb_debug_ascii(0xDA, "MEM2");
	//// write 0xFFFEDCBA87654321 into physical address 510
	//(p_H264_MEM_START+510*2)->as_int = 0x56781234;
	//(p_H264_MEM_START+510*2+1)->as_int = 0xEFFFABCD;
	//temp_reg = (p_H264_MEM_START+1023)->as_int;

	//// read logical address 1020
	//(p_H264_MEM_START+1022)->as_int = 0x0;
	//(p_H264_MEM_START+1023)->as_int = 0x0;
	//temp_reg = (p_H264_MEM_START+510*2)->as_int;
	//if(temp_reg != 0x56781234){arb_debug_ascii(0xD5,"ERR");}	
	//
	//// read logical address 1021
	//(p_H264_MEM_START+1022)->as_int = 0x0;
	//(p_H264_MEM_START+1023)->as_int = 0x0;
	//temp_reg = (p_H264_MEM_START+510*2+1)->as_int;
	//if(temp_reg != 0xEFFFABCD){arb_debug_ascii(0xD5,"ERR");}
		


	//********************************************************************
	// RF TEST             
	//********************************************************************
	arb_debug_ascii(0xD3, "RF  "); 

	arb_debug_ascii(0xDA, "REG0");
	temp_reg=CMPv1_R00->MBUS_R0;
	wr_val = 0xFFFFFF;
	rf_write (0,wr_val);
	delay(1);
	if(wr_val != CMPv1_R00->MBUS_R0) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	arb_debug_ascii(0xDA, "REG1");
	temp_reg=CMPv1_R01->MBUS_R1;
	wr_val = 0xFFFFFF;
	rf_write (1,wr_val);
	delay(1);
	if(wr_val != CMPv1_R01->MBUS_R1) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	arb_debug_ascii(0xDA, "REG2");
	temp_reg=CMPv1_R02->MBUS_R2;
	wr_val = 0xFFFFFF;
	rf_write (2,wr_val);
	delay(1);
	if(wr_val != CMPv1_R02->MBUS_R2) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	arb_debug_ascii(0xDA, "REG3");
	temp_reg=CMPv1_R03->MBUS_R3;
	wr_val = 0xFFFFFF;
	rf_write (3,wr_val);
	delay(1);
	if(wr_val != CMPv1_R03->MBUS_R3) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	arb_debug_ascii(0xDA, "REG4");
	temp_reg=CMPv1_R04->MBUS_R4;
	wr_val = 0xFFFFFF;
	rf_write (4,wr_val);
	delay(1);
	if(wr_val != CMPv1_R04->MBUS_R4) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	arb_debug_ascii(0xDA, "REG5");
	temp_reg=CMPv1_R05->MBUS_R5;
	wr_val = 0xFFFFFF;
	rf_write (5,wr_val);
	delay(1);
	if(wr_val != CMPv1_R05->MBUS_R5) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	arb_debug_ascii(0xDA, "REG6");
	temp_reg=CMPv1_R06->MBUS_R6;
	wr_val = 0xFFFFFF;
	rf_write (6,wr_val);
	delay(1);
	if(wr_val != CMPv1_R06->MBUS_R6) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	arb_debug_ascii(0xDA, "REG7");
	temp_reg=CMPv1_R07->MBUS_R7;
	wr_val = 0xFFFFFF;
	rf_write (7,wr_val);
	delay(1);
	if(wr_val != CMPv1_R07->MBUS_R7) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	arb_debug_ascii(0xDA, "REG8");
	temp_reg=CMPv1_R08->CHIP_ID;
	wr_val = 0xFFFF;
	rf_write (8,wr_val);
	delay(1);
	if(wr_val != CMPv1_R08->CHIP_ID) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	arb_debug_ascii(0xDA, "REG9");
	temp_reg=CMPv1_R09->FLAGS;
	wr_val = 0xFFFFFF;
	rf_write (9,wr_val);
	delay(1);
	if(wr_val != CMPv1_R09->FLAGS) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	//arb_debug_ascii(0xDA, "REGA");
	//temp_reg=CMPv1_R0A->as_int;
	//wr_val = 0x11F7;
	//rf_write (10,wr_val);
	//delay(1);
	//if(wr_val != CMPv1_R0A->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	arb_debug_ascii(0xDA, "REGB");
	temp_reg=CMPv1_R0B->as_int;
	wr_val = 0x1;
	rf_write (11,wr_val);
	delay(1);
	if(wr_val != CMPv1_R0B->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	////SWRW
	//arb_debug_ascii(0xDA, "REGC");
	//temp_reg=CMPv1_R0C->as_int;
	//wr_val = 0xE;
	//rf_write (12,wr_val);
	//delay(1);
	//if(wr_val != CMPv1_R0C->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	////SRAM RESET
	//arb_debug_ascii(0xDA, "REGD"); //temp_reg=CMPv1_R0D->as_int;
	//wr_val = 0x1;
	//rf_write (13,wr_val);
	//delay(1);
	//if(wr_val != CMPv1_R0D->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	////SRAM ISOLATE
	//arb_debug_ascii(0xDA, "REGE");
	//temp_reg=CMPv1_R0E->as_int;
	//wr_val = 0xE;
	//rf_write (14,wr_val);
	//delay(1);
	//if(wr_val != CMPv1_R0E->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	////SRAM TUNING
	//arb_debug_ascii(0xDA, "REGF");
	//temp_reg=CMPv1_R0F->as_int;
	//wr_val = 0x1FFFFF;
	//rf_write (15,wr_val);
	//delay(1);
	//if(wr_val != CMPv1_R0F->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	//arb_debug_ascii(0xDA, "REG0");
	//temp_reg=CMPv1_R10->as_int;
	//rf_write (16,wr_val);
	//delay(1);
	//if(wr_val != CMPv1_R10->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	//arb_debug_ascii(0xDA, "REG0");
	//temp_reg=CMPv1_R11->as_int;
	//rf_write (17,wr_val);
	//delay(1);
	//if(wr_val != CMPv1_R11->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	//arb_debug_ascii(0xDA, "REG0");
	//temp_reg=CMPv1_R12->as_int;
	//rf_write (18,wr_val);
	//delay(1);
	//if(wr_val != CMPv1_R12->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	//arb_debug_ascii(0xDA, "REG0");
	//temp_reg=CMPv1_R13->as_int;
	//rf_write (19,wr_val);
	//delay(1);
	//if(wr_val != CMPv1_R13->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	//arb_debug_ascii(0xDA, "REG0");
	//temp_reg=CMPv1_R14->as_int;
	//rf_write (20,wr_val);
	//delay(1);
	//if(wr_val != CMPv1_R14->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	//VCOMP
	arb_debug_ascii(0xDA, "REG0");
	temp_reg=CMPv1_R15->as_int;
	wr_val = 0x7FFFF;
	rf_write (21,wr_val);
	delay(1);
	if(wr_val != CMPv1_R15->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	//arb_debug_ascii(0xDA, "REG0");
	//temp_reg=CMPv1_R16->as_int;
	//wr_val = 0x1F1F;
	//rf_write (22,wr_val);
	//delay(1);
	//if(wr_val != CMPv1_R16->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};

	//HEADER
	arb_debug_ascii(0xDA, "REG0");
	temp_reg=CMPv1_R17->as_int;
	wr_val = 0b100100;
	rf_write (23,wr_val);
	delay(1);
	if(wr_val != CMPv1_R17->as_int) {arb_debug_ascii(0xD5, "ERR");err_cnt_rf++;};
	//********************************************************************
	// FLS IF SFR TEST             
	//********************************************************************
	arb_debug_ascii(0xD3, "FLS"); //0xD0 for bold green 0xDA for normal green

	//Read Write registers
	//default value check
	arb_debug_ascii(0xDA, "REG0");
	temp_reg=p_FLSIF_ENABLE->softreset;
	if(temp_reg != 0x1){arb_debug_ascii(0xD5, "ERR");err_cnt_fls++;}
	//write-read test
	p_FLSIF_ENABLE->softreset = ! temp_reg ;
	if(temp_reg == p_FLSIF_ENABLE->softreset) {arb_debug_ascii(0xD5, "ERR");err_cnt_fls++;};

	arb_debug_ascii(0xDA, "REG1");
	temp_reg=p_FLSIF_ENABLE->flsif_en;
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_fls++;};
	p_FLSIF_ENABLE->flsif_en = ! temp_reg ;
	if(temp_reg == p_FLSIF_ENABLE->flsif_en) {arb_debug_ascii(0xD5, "ERR");err_cnt_fls++;};

	arb_debug_ascii(0xDA, "REG2");
	temp_reg=p_FLSIF_CONFIG->flsif_biten;
	if(temp_reg != 0x3) {arb_debug_ascii(0xD5, "ERR");err_cnt_fls++;};
	p_FLSIF_CONFIG->flsif_biten = ! temp_reg ;
	if(temp_reg == p_FLSIF_CONFIG->flsif_biten) {arb_debug_ascii(0xD5, "ERR");err_cnt_fls++;};

	arb_debug_ascii(0xDA, "REG3");
	temp_reg=p_FLSIF_CONFIG->flsif_ch;
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_fls++;};
	p_FLSIF_CONFIG->flsif_ch = ! temp_reg ;
	if(temp_reg == p_FLSIF_CONFIG->flsif_ch) {arb_debug_ascii(0xD5, "ERR");err_cnt_fls++;};

	//Read only registers
	arb_debug_ascii(0xDA, "REG4");
	temp_reg = p_FLSIF_STATUS->status;
	if(temp_reg != 0x0) {arb_debug_ascii(0xD5, "ERR");err_cnt_fls++;};

	//FIFO test
	arb_debug_ascii(0xDA, "REG5");
	p_FLSIF_FIFO->as_int = 0xDEADBEEF;

	rf_write (0,err_cnt_imgif);
	rf_write (1,err_cnt_ne   );
	rf_write (2,err_cnt_h264 );
	rf_write (3,err_cnt_rf   );
	rf_write (4,err_cnt_fls  );
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
	arb_debug_reg(0xFF, 0);//END_OF_PROGRAM : it makes program end
	while(1){ delay(1); }
    return 1;
}
