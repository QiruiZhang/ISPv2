#include "CMPv1_IMGIF.h"

//-----------------------------------------------------------------//
// NORMAL OPERATION FUNCTIONS
//-----------------------------------------------------------------//

// IMGIF_IMG_INFO
// Set initial configuration
// 
// img_type:
// INTENSITY 	0
// BAYER	1
//
// imgif_mode
// DEBUG 	0
// NORMAL 	1
//
// flash_debug_en
// FALSE 	0
// TRUE 	1
void imgif_info_config(uint8_t img_type, uint8_t img_mode, uint8_t flash_debug_en) {
	p_IMGIF_IMG_INFO->img_type 	= img_type;
	p_IMGIF_IMG_INFO->img_mode 	= img_mode;
	p_IMGIF_IMG_INFO->flash_dbg_en 	= flash_debug_en;
}

// Change img_type to INTENSITY (md frame)
void imgif_intensity_mode_enable() {
	p_IMGIF_IMG_INFO->img_type = 0;
	p_IMGIF_IMG_INFO->img_mode = 1;
	p_IMGIF_IMG_INFO->flash_dbg_en 	= 0;
}

// Change img_type to BAYER 
void imgif_bayer_mode_enable(uint8_t nbit_truncate) {
	p_IMGIF_IMG_INFO->img_type = 1;
	p_IMGIF_IMG_INFO->img_mode = 1;
	p_IMGIF_IMG_INFO->flash_dbg_en 	= 0;
	p_COMPMEM_CONFIG->compmem_config_nbit_truncate = nbit_truncate;
	p_B_CONV->sat_en =1;
}

// Disable all automatic shifting and bit conversion - for debugging
void dbg_imgif_disable_md_shift() {
	p_B_CONV->auto_min_max_en 	= 0;
	p_B_CONV->auto_shift_en 	= 0;
	p_B_CONV->bit_shift 		= 0;
	p_B_CONV->shift_dir 		= 1;
	p_B_CONV->sat_en 		= 0;
	p_B_CONV->sat_shift 		= 0;	
}

// Turn on debug mode
void dbg_imgif_enable() {
	p_IMGIF_IMG_INFO->img_type = 0;
	p_IMGIF_IMG_INFO->img_mode = 0;
	p_IMGIF_IMG_INFO->flash_dbg_en 	= 1;
}

// Turn on debug mode
void imgif_mem_access_enable() {
	p_IMGIF_IMG_INFO->img_mode = 0;
}
// Turn off debug mode
void imgif_mem_access_disable() {
	p_IMGIF_IMG_INFO->img_mode = 1;
}

// Turn on just flash debugging
// Specify the source of the flash: bayer - 0, y - 1, g - 2
// If y or g is chosen, choose the McB number from 0-4 that will be streamed out
void dbg_imgif_flash_enable(uint8_t flash_src, uint8_t flash_mcb_num) {
	p_IMGIF_IMG_INFO->flash_dbg_en 		= 1;
	p_IMGIF_IMG_INFO->flash_dbg_src 	= flash_src;
	p_IMGIF_IMG_INFO->flash_dbg_mcb_num 	= flash_mcb_num;
}

// IMGIF_IF_CTRL
// Initializ imgif
void imgif_initialize(){
	p_IMGIF_IF_CTRL->softreset 	= 1;
	p_IMGIF_IF_CTRL->imgif_en 	= 1;
}

// IMGIF_TB_MARGIN - change top and bottom margin
void imgif_tb_margin_config(uint8_t t_margin, uint16_t b_margin) {
	p_IMGIF_TB_MARGIN->v_t_margin 	= t_margin;
	p_IMGIF_TB_MARGIN->v_b_margin 	= b_margin;
}

// IMGIF_OB_RESOL - change horizontal ob size
// h_ob_start: pixel that optical black begins on in horizontal direction before active region
// h_ob_end: pixel that optical black region ends on in horizontal direction after active region
// v_ob_start: line that optical black region begins on in vertical direction before active region
void imgif_ob_resol_config(uint16_t h_ob_start, uint16_t h_ob_end, uint8_t v_ob_start) {
	p_IMGIF_OB_RESOL->h_ob_start 	= h_ob_start;
	p_IMGIF_OB_RESOL->h_ob_end 	= h_ob_end;
	p_IMGIF_OB_RESOL->v_ob_start 	= v_ob_start;
}

// IMGIF_H_OB_INFO - change horizontal opt black configuration
// h_ob_en: enable horizontal optical black correction
// h_ob_margin_w: width of optical black margin
// h_ob_sum_w: number of pixels to include in optical black average - should be power of 2 for accurate average
// h_ob_shift_w: number of pixels to shift for average - should be equal to clog2(h_ob_sum_w)
void imgif_h_ob_info_config(uint8_t en, uint8_t h_ob_margin_w, uint8_t h_ob_sum_w, uint8_t h_ob_shift_w) {
	p_IMGIF_H_OB_INFO->h_ob_en 	= en;
	p_IMGIF_H_OB_INFO->h_ob_m_w 	= h_ob_margin_w;
	p_IMGIF_H_OB_INFO->h_ob_s_w	= h_ob_sum_w;
	p_IMGIF_H_OB_INFO->h_ob_shift_w = h_ob_shift_w;
}

// IMGIF_T_OB_INFO - change top opt black configuration
// t_ob_en: enable top optical black correction
// t_ob_num_rows: number of rows to include when calculating top optical black value - should be power of 2 for accurate average
// t_ob_num_rows_shift: number of pixels to shift for average number of rows - should be equal to clog2(t_ob_num_rows)
// t_ob_sum_w: number of pixels to include in optical black averaging in each optical black row - should be power of 2 for accurate average
// t_ob_sum_w_shift: number of pixels to shift for average in each optical black row - should be equal to clog2(t_ob_sum_w)
void imgif_t_ob_info_config(uint8_t en, uint8_t t_ob_num_rows, uint8_t t_ob_num_rows_shift, uint16_t t_ob_sum_w, uint8_t t_ob_sum_w_shift) {
	p_IMGIF_T_OB_INFO->t_ob_en 		= en;
	p_IMGIF_T_OB_INFO->t_ob_n_r 		= t_ob_num_rows;
	p_IMGIF_T_OB_INFO->t_ob_n_r_shift 	= t_ob_num_rows_shift;
	p_IMGIF_T_OB_INFO->t_ob_s_w 		= t_ob_sum_w;
	p_IMGIF_T_OB_INFO->t_ob_s_w_shift 	= t_ob_sum_w_shift;
}

// Change active region to smaller image
// a_start: pixel that active region begins on in horizontal direction
// a_end: pixel that active region ends on in horizontal direction (a_end - a_start = width of active region)
// num_rows: number of rows in active region
// mcb_per_row: number of macroblocks per row
// mcb_per_col: number of macroblocks per col
// total_mcb: total number of macroblocks in the active region
// t_margin: row number that active region begins on (zero indexed)
// b_margin: row number that active region ends on (non_inclusive)
// Example: t_margin = 1, b_margin = 481 - active region starts on the 2nd row and ends on the 481st row
void imgif_active_region_config(uint8_t t_margin, uint16_t b_margin, uint16_t a_start, uint16_t a_end, uint16_t num_rows, uint8_t mcb_per_row, uint8_t mcb_per_col, uint16_t total_mcb) {

	p_IMGIF_ACTIVE_RESOL->a_start 	= a_start;	
	p_IMGIF_ACTIVE_RESOL->a_end 	= a_end;	
	p_IMGIF_ACTIVE_RESOL->num_rows 	= num_rows;	

	p_IMGIF_ACTIVE_CONFIG->mcb_per_row 	= mcb_per_row;
	p_IMGIF_ACTIVE_CONFIG->mcb_per_col 	= mcb_per_col;
	p_IMGIF_ACTIVE_CONFIG->total_mcb 	= total_mcb;

	p_IMGIF_TB_MARGIN->v_t_margin 	= t_margin;
	p_IMGIF_TB_MARGIN->v_b_margin 	= b_margin;
} 

// Change active region to smaller image and modify margin widths.
// This is used for grabbing smaller subportions of the image, but not meant
// for regular usage beyond debugging. Doesn't include ability to do OB
// correction.
// a_start: pixel that active region begins on in horizontal direction
// a_end: pixel that active region ends on in horizontal direction (a_end - a_start = width of active region)
// ob_start/ob_end: pixel that optical black region begins and ends on in horizontal direction
// sa_start/sa_end: pixel that semiactive region begins and ends on in horizontal direction
// num_rows: number of rows in active region
// mcb_per_row: number of macroblocks per row
// mcb_per_col: number of macroblocks per col
// total_mcb: total number of macroblocks in the active region
// t_margin: row number that active region begins on (zero indexed)
// b_margin: row number that active region ends on (non_inclusive)
void dbg_imgif_active_region_config(uint8_t t_margin,
				    uint8_t b_margin,
				    uint16_t ob_start,
				    uint16_t ob_end,
				    uint16_t sa_start,
				    uint16_t sa_end,
				    uint16_t a_start,
				    uint16_t a_end,
				    uint16_t num_rows,
				    uint16_t mcb_per_row,
				    uint16_t mcb_per_col,
			  	    uint16_t total_mcb) {

	p_IMGIF_OB_RESOL->h_ob_start 		= ob_start;	
	p_IMGIF_OB_RESOL->h_ob_end 		= ob_end;	

	p_IMGIF_SEMI_ACTIVE_RESOL->sa_start 	= sa_start;	
	p_IMGIF_SEMI_ACTIVE_RESOL->sa_end 	= sa_end;	
	
	p_IMGIF_ACTIVE_RESOL->a_start 		= a_start;	
	p_IMGIF_ACTIVE_RESOL->a_end 		= a_end;	
	p_IMGIF_ACTIVE_RESOL->num_rows 		= num_rows;	

	p_IMGIF_ACTIVE_CONFIG->mcb_per_row 	= mcb_per_row;
	p_IMGIF_ACTIVE_CONFIG->mcb_per_col 	= mcb_per_col;
	p_IMGIF_ACTIVE_CONFIG->total_mcb 	= total_mcb;

	p_IMGIF_TB_MARGIN->v_t_margin 	= t_margin;
	p_IMGIF_TB_MARGIN->v_b_margin 	= b_margin;

}

// Change CD mode
// cd_mode:
// CURR frame 	1
// REF frame	0
void imgif_cd_ctrl_config(uint8_t reset, uint8_t en, uint8_t cd_mode) {
	p_IMGIF_CD_CTRL->softreset 	= reset;
	p_IMGIF_CD_CTRL->cd_en		= en;
	p_IMGIF_CD_CTRL->cd_mode 	= cd_mode;
}

// Initialize cd_mode to CURR frame
void imgif_curr_cd_mode_enable(uint8_t nbit_truncate) {
	p_IMGIF_CD_CTRL->softreset 	= 1;
	p_IMGIF_CD_CTRL->cd_en		= 1;
	p_IMGIF_CD_CTRL->cd_mode 	= 1;
	p_COMPMEM_CONFIG->compmem_config_nbit_truncate = nbit_truncate;
	p_B_CONV->sat_en =1;
}

// Initialize cd_mode to REF frame
void imgif_ref_cd_mode_enable(uint8_t nbit_truncate) {
	p_IMGIF_CD_CTRL->softreset 	= 1;
	p_IMGIF_CD_CTRL->cd_en		= 1;
	p_IMGIF_CD_CTRL->cd_mode 	= 0;
	p_COMPMEM_CONFIG->compmem_config_nbit_truncate = nbit_truncate;
	p_B_CONV->sat_en =1;
}

// Set dilation pattern
//  Dilate pattern: starting from upper left in LtR, row by row
// 	patt[0]	patt[1]	patt[2]
//	patt[3]	   x	patt[4]
//	patt[5]	patt[6]	patt[7]
//
// 1 indicates block should be dilated, 0 indicates no dilation
void imgif_dilate_patt_config(uint8_t dilate_patt) {
	p_IMGIF_DILATE_PATT->pattern = dilate_patt;
}

// Access CD_MAP 
// Data is accessed on a per column basis i.e. accessing offset = 2 will grab
// the 3rd column of the 30 row x 40 column cd_map
uint32_t imgif_cd_map_read(uint16_t offset) {
	return *((volatile uint32_t *)(p_CD_MAP_START + offset));
}

// Clear the motion detected image ready interrupt
void imgif_clear_md_done_int() {
	p_MD_DONE_INT->interrupt = 0;
}

// Clear the vga encoding done interrupt
void imgif_clear_enc_done_int() {
	p_ENC_DONE_INT->interrupt = 0;
}

// Read from CD SRAM - not dbg since this happens during motion detected mode
uint32_t imgif_cd_sram_read(uint16_t addr) {
	return *((volatile uint32_t *)(p_CD_SRAM_START + addr));
}

//uint32_t** imgif_cd_map_compile(void) {
//	uint32_t mcb_col;
//	uint32_t mcb_row;
//	uint32_t ahb_data;
//	uint32_t cd_map   [40][30];
//
//	for(mcb_col=0; mcb_col<40; mcb_col=mcb_col+1){
//		ahb_data = imgif_cd_map_read(mcb_col);
//		for(mcb_row=0; mcb_row<30; mcb_row=mcb_row+1){
//			cd_map[mcb_col][mcb_row] = (uint8_t)((ahb_data & (1<<mcb_row))>>mcb_row);
//		}
//	}
//	return cd_map;
//}

// Reads motion detected frame from memory and returns it in an array
void imgif_md_frame_read(uint32_t  md_frame_arr_in[32][20]) {


	uint16_t base_addr = 0;
	uint32_t read_val;
	
	int row = 0;
	int col = 0;

	uint16_t i = 0;
	uint16_t j = 0;
	uint16_t k = 0;

	arb_debug_ascii(0xDA, "MDRD");
	for(i = 0; i < 64; i++) {
		if (i < 32) 	row = i % 16;
		else 		row = (i % 16) + 16;
		if ((i > 15 && i < 32) || i > 47) {
			read_val = *((volatile uint32_t *)(p_CD_SRAM_START + base_addr));
			col = 16;
			for (j = 0; j < 4; j++) {
				md_frame_arr_in[row][col] = (read_val >> (j * 8)) & 0xFF;

				//arb_debug_ascii(0xDA, "IDX");
				//arb_debug_reg(0xDB, row);
				//arb_debug_reg(0xDB, col);
				//arb_debug_reg(0xDB, md_frame_arr_in[row][col]);
				
				col++;
			}
		} else {
			col = 0;
			for (k = 0; k < 4; k++) {
				read_val = *((volatile uint32_t *)(p_CD_SRAM_START + base_addr + k));
				for (j = 0; j < 4; j++) {
					md_frame_arr_in[row][col] = (read_val >> (j * 8)) & 0xFF;
					//arb_debug_ascii(0xDA, "IDX");
					//arb_debug_reg(0xDB, row);
					//arb_debug_reg(0xDB, col);
					//arb_debug_reg(0xDB, md_frame_arr_in[row][col]);
					
					col++;
				}
			}
		}
		base_addr += 4;
	}

}

// compression memory for encoding
void decoding_ref_config() {
	p_COMPMEM_CONFIG->compmem_config_dec_en = 1;
	p_IMGIF_CD_CTRL->cd_mode 	= 0;
}
void decoding_cur_config() {
	p_COMPMEM_CONFIG->compmem_config_dec_en = 1;
	p_IMGIF_CD_CTRL->cd_mode 	= 1;
}
void encoding_ref_config() {
	p_COMPMEM_CONFIG->compmem_config_dec_en = 0;
	p_IMGIF_CD_CTRL->cd_mode 	= 0;
}
void encoding_cur_config() {
	p_COMPMEM_CONFIG->compmem_config_dec_en = 0;
	p_IMGIF_CD_CTRL->cd_mode 	= 1;
}

// update starting address for current frame
void decoding_config() {
	p_FRMMEM_SSADDR->frmmem_ssaddr_y = p_MCB_ADDR->mcb_addr_y;
	p_FRMMEM_SSADDR->frmmem_ssaddr_uv = p_MCB_ADDR->mcb_addr_uv;
}

// check min max of Y of MCB
uint8_t max_cur_y(uint32_t idx) {
	uint32_t temp;
	temp=*(p_MINMAX_SRAM_START +idx);
	return ((temp & 0xff000000)>>24);
}
uint8_t min_cur_y(uint32_t idx) {
	uint32_t temp;
	temp=*(p_MINMAX_SRAM_START +idx);
	return ((temp & 0xff0000)>>16);
}
uint8_t max_ref_y(uint32_t idx) {
	uint32_t temp;
	temp=*(p_MINMAX_SRAM_START +idx);
	return ((temp & 0xff00)>>8);
}
uint8_t min_ref_y(uint32_t idx) {
	uint32_t temp;
	temp=*(p_MINMAX_SRAM_START +idx);
	return ((temp & 0xff));
}

uint32_t mcb_data_y(uint32_t mcb_index) {
	return *((uint32_t *)(p_MCBRD_SRAM_START+mcb_index));
}
uint32_t mcb_data_uv(uint32_t mcb_index) {
	return *((uint32_t *)(p_MCBRD_SRAM_START+mcb_index+1200));
}
//-----------------------------------------------------------------//
// DEBUGGING FUNCTIONS
//-----------------------------------------------------------------//

// Get cd_ctrl module state
//
// IDLE: 		0
// CD_READ:		1
// CD_ANALYSIS: 	2
// CD_STREAMING_NOP: 	3
// CD_STREAMING: 	4
uint32_t dbg_imgif_cd_ctrl_status(void) {
	return p_IMGIF_DBG_STATUS->cd_ctrl_state;
}

// Get row_pack module state
//
// IDLE: 		0 
// PIX_RDY:		1
// OB_DUMMY:		2
// OB:			3 
// SEMI_ACTIVE: 	4
// ACTIVE:		5
// TOP_MARGIN:		6 
// BOTTOM_MARGIN:	7 
// EOR:			8 
uint32_t dbg_imgif_row_pack_status(void) {
	return p_IMGIF_DBG_STATUS->row_pack_state;
}

// Get hamm_sum state
//
// IDLE:	0
// COUNTING:	1
// DONE:	2
uint32_t dbg_imgif_hamm_sum_status(void) {
	return p_IMGIF_DBG_STATUS->hamm_sum_state;
}

// Get ref_accum state
//
// IDLE: 	0
// FILLING:	1
// DONE:	2
uint32_t dbg_imgif_ref_accum_status(void) {
	return p_IMGIF_DBG_STATUS->ref_accum_state;
}

// Get current hamming sum value
uint32_t dbg_imgif_hamm_sum_val(void) {
	return p_IMGIF_DBG_STATUS->hamm_sum_val;
}

// Get CD SRAM state
// READING:	0
// WRITING: 	1
uint32_t dbg_imgif_cd_sram_status(void) {
	return p_IMGIF_DBG_SRAM->cd_sram_state;
}

// Current CD SRAM address being accessed
uint32_t dbg_imgif_cd_sram_addr(void) {
	return p_IMGIF_DBG_SRAM->cd_sram_addr;
}

// Get REF SRAM state
//
// READING: 	0
// WRITING: 	1
uint32_t dbg_imgif_ref_sram_status(void) {
	return p_IMGIF_DBG_SRAM->ref_sram_state;
}

// Current REF SRAM address being accessed
uint32_t dbg_imgif_ref_sram_addr(void) {
	return p_IMGIF_DBG_SRAM->ref_sram_addr;
}

//Q_param change
void Q_Y_90_set(){
	p_Q_Y_ROW00->col0 	= 0b00101011;
	p_Q_Y_ROW00->col1 	= 0b00100000;
	p_Q_Y_ROW00->col2 	= 0b00011010;
	p_Q_Y_ROW00->col3 	= 0b00001110;
	p_Q_Y_ROW01->col0 	= 0b00000110;
	p_Q_Y_ROW01->col1 	= 0b00000110;
	p_Q_Y_ROW01->col2 	= 0b00000110;
	p_Q_Y_ROW01->col3 	= 0b00000110;
	p_Q_Y_ROW10->col0 	= 0b00100000;
	p_Q_Y_ROW10->col1 	= 0b00100000;
	p_Q_Y_ROW10->col2 	= 0b00011010;
	p_Q_Y_ROW10->col3 	= 0b00001010;
	p_Q_Y_ROW11->col0 	= 0b00000110;
	p_Q_Y_ROW11->col1 	= 0b00000110;
	p_Q_Y_ROW11->col2 	= 0b00000110;
	p_Q_Y_ROW11->col3 	= 0b00000110;
	p_Q_Y_ROW20->col0 	= 0b00011010;
	p_Q_Y_ROW20->col1 	= 0b00011010;
	p_Q_Y_ROW20->col2 	= 0b00001100;
	p_Q_Y_ROW20->col3 	= 0b00000110;
	p_Q_Y_ROW21->col0 	= 0b00000110;
	p_Q_Y_ROW21->col1 	= 0b00000110;
	p_Q_Y_ROW21->col2 	= 0b00000110;
	p_Q_Y_ROW21->col3 	= 0b00000110;
	p_Q_Y_ROW30->col0 	= 0b00001110;
	p_Q_Y_ROW30->col1 	= 0b00001010;
	p_Q_Y_ROW30->col2 	= 0b00000110;
	p_Q_Y_ROW30->col3 	= 0b00000110;
	p_Q_Y_ROW31->col0 	= 0b00000110;
	p_Q_Y_ROW31->col1 	= 0b00000110;
	p_Q_Y_ROW31->col2 	= 0b00000110;
	p_Q_Y_ROW31->col3 	= 0b00000110;
	p_Q_Y_ROW40->col0 	= 0b00000110;
	p_Q_Y_ROW40->col1 	= 0b00000110;
	p_Q_Y_ROW40->col2 	= 0b00000110;
	p_Q_Y_ROW40->col3 	= 0b00000110;
	p_Q_Y_ROW41->col0 	= 0b00000110;
	p_Q_Y_ROW41->col1 	= 0b00000110;
	p_Q_Y_ROW41->col2 	= 0b00000110;
	p_Q_Y_ROW41->col3 	= 0b00000110;
	p_Q_Y_ROW50->col0 	= 0b00000110;
	p_Q_Y_ROW50->col1 	= 0b00000110;
	p_Q_Y_ROW50->col2 	= 0b00000110;
	p_Q_Y_ROW50->col3 	= 0b00000110;
	p_Q_Y_ROW51->col0 	= 0b00000110;
	p_Q_Y_ROW51->col1 	= 0b00000110;
	p_Q_Y_ROW51->col2 	= 0b00000110;
	p_Q_Y_ROW51->col3 	= 0b00000110;
	p_Q_Y_ROW60->col0 	= 0b00000110;
	p_Q_Y_ROW60->col1 	= 0b00000110;
	p_Q_Y_ROW60->col2 	= 0b00000110;
	p_Q_Y_ROW60->col3 	= 0b00000110;
	p_Q_Y_ROW61->col0 	= 0b00000110;
	p_Q_Y_ROW61->col1 	= 0b00000110;
	p_Q_Y_ROW61->col2 	= 0b00000110;
	p_Q_Y_ROW61->col3 	= 0b00000110;
	p_Q_Y_ROW70->col0 	= 0b00000110;
	p_Q_Y_ROW70->col1 	= 0b00000110;
	p_Q_Y_ROW70->col2 	= 0b00000110;
	p_Q_Y_ROW70->col3 	= 0b00000110;
	p_Q_Y_ROW71->col0 	= 0b00000110;
	p_Q_Y_ROW71->col1 	= 0b00000110;
	p_Q_Y_ROW71->col2 	= 0b00000110;
	p_Q_Y_ROW71->col3 	= 0b00000110;

	p_INV_Q_Y_ROW00->col0 	=0b00000011;
	p_INV_Q_Y_ROW00->col1 	=0b00000100;
	p_INV_Q_Y_ROW00->col2 	=0b00000101;
	p_INV_Q_Y_ROW00->col3 	=0b00001001;
	p_INV_Q_Y_ROW01->col0 	=0b00010100;
	p_INV_Q_Y_ROW01->col1 	=0b00010100;
	p_INV_Q_Y_ROW01->col2 	=0b00010100;
	p_INV_Q_Y_ROW01->col3 	=0b00010100;
	p_INV_Q_Y_ROW10->col0 	=0b00000100;
	p_INV_Q_Y_ROW10->col1 	=0b00000100;
	p_INV_Q_Y_ROW10->col2 	=0b00000101;
	p_INV_Q_Y_ROW10->col3 	=0b00001101;
	p_INV_Q_Y_ROW11->col0 	=0b00010100;
	p_INV_Q_Y_ROW11->col1 	=0b00010100;
	p_INV_Q_Y_ROW11->col2 	=0b00010100;
	p_INV_Q_Y_ROW11->col3 	=0b00010100;
	p_INV_Q_Y_ROW20->col0 	=0b00000101;
	p_INV_Q_Y_ROW20->col1 	=0b00000101;
	p_INV_Q_Y_ROW20->col2 	=0b00001011;
	p_INV_Q_Y_ROW20->col3 	=0b00010100;
	p_INV_Q_Y_ROW21->col0 	=0b00010100;
	p_INV_Q_Y_ROW21->col1 	=0b00010100;
	p_INV_Q_Y_ROW21->col2 	=0b00010100;
	p_INV_Q_Y_ROW21->col3 	=0b00010100;
	p_INV_Q_Y_ROW30->col0 	=0b00001001;
	p_INV_Q_Y_ROW30->col1 	=0b00001101;
	p_INV_Q_Y_ROW30->col2 	=0b00010100;
	p_INV_Q_Y_ROW30->col3 	=0b00010100;
	p_INV_Q_Y_ROW31->col0 	=0b00010100;
	p_INV_Q_Y_ROW31->col1 	=0b00010100;
	p_INV_Q_Y_ROW31->col2 	=0b00010100;
	p_INV_Q_Y_ROW31->col3 	=0b00010100;
	p_INV_Q_Y_ROW40->col0 	=0b00010100;
	p_INV_Q_Y_ROW40->col1 	=0b00010100;
	p_INV_Q_Y_ROW40->col2 	=0b00010100;
	p_INV_Q_Y_ROW40->col3 	=0b00010100;
	p_INV_Q_Y_ROW41->col0 	=0b00010100;
	p_INV_Q_Y_ROW41->col1 	=0b00010100;
	p_INV_Q_Y_ROW41->col2 	=0b00010100;
	p_INV_Q_Y_ROW41->col3 	=0b00010100;
	p_INV_Q_Y_ROW50->col0 	=0b00010100;
	p_INV_Q_Y_ROW50->col1 	=0b00010100;
	p_INV_Q_Y_ROW50->col2 	=0b00010100;
	p_INV_Q_Y_ROW50->col3 	=0b00010100;
	p_INV_Q_Y_ROW51->col0 	=0b00010100;
	p_INV_Q_Y_ROW51->col1 	=0b00010100;
	p_INV_Q_Y_ROW51->col2 	=0b00010100;
	p_INV_Q_Y_ROW51->col3 	=0b00010100;
	p_INV_Q_Y_ROW60->col0 	=0b00010100;
	p_INV_Q_Y_ROW60->col1 	=0b00010100;
	p_INV_Q_Y_ROW60->col2 	=0b00010100;
	p_INV_Q_Y_ROW60->col3 	=0b00010100;
	p_INV_Q_Y_ROW61->col0 	=0b00010100;
	p_INV_Q_Y_ROW61->col1 	=0b00010100;
	p_INV_Q_Y_ROW61->col2 	=0b00010100;
	p_INV_Q_Y_ROW61->col3 	=0b00010100;
	p_INV_Q_Y_ROW70->col0 	=0b00010100;
	p_INV_Q_Y_ROW70->col1 	=0b00010100;
	p_INV_Q_Y_ROW70->col2 	=0b00010100;
	p_INV_Q_Y_ROW70->col3 	=0b00010100;
	p_INV_Q_Y_ROW71->col0 	=0b00010100;
	p_INV_Q_Y_ROW71->col1 	=0b00010100;
	p_INV_Q_Y_ROW71->col2 	=0b00010100;
	p_INV_Q_Y_ROW71->col3 	=0b00010100;
}

/////////////////////////////////////
/////      !! WARNING !!      ///////
/////////////////////////////////////
// These functions do not do any   //
// bounds checks, so too high of   //
// an address could cause problems //
/////////////////////////////////////

// Read and write from CD sram
void dbg_imgif_cd_sram_write(uint16_t offset, uint32_t data) {
	*((volatile uint32_t *)(p_CD_SRAM_START + offset)) = data;
}

// Read and write from REF sram
void dbg_imgif_ref_sram_write(uint16_t offset, uint32_t data) {
	*((volatile uint32_t *)(p_REF_SRAM_START + offset)) = data;
}

uint32_t dbg_imgif_ref_sram_read(uint16_t offset) {
	return *((volatile uint32_t *)(p_REF_SRAM_START + offset));
}

uint32_t dbg_imgif_mcbrd_sram_read(uint16_t offset) {
	return *((volatile uint32_t *)(p_MCBRD_SRAM_START + offset));
}

