//************************************************************
// Desciption: CMPv1 FLS Header File
//************************************************************

// **  define HEADER file
//
#ifndef CMPV1_IMGIF_H
#define CMPV1_IMGIF_H

#include <stdint.h>
#include <stdbool.h>
                      
// Register 0x00
typedef union IMGIF_IF_CTRL {
	struct {
		unsigned softreset 	:  1;
		unsigned reserv1 	:  3;
		unsigned imgif_en 	:  1;
		unsigned reserv2 	: 27;
	};
	uint32_t as_int;
} IMGIF_IF_CTRL_t;

// Register 0x04
typedef union IMGIF_IMG_INFO {
	struct {
		unsigned img_type		:  1;
		unsigned reserv1 		:  3;
		unsigned img_mode 		:  1;
		unsigned reserv2 		:  3;
		unsigned flash_dbg_en   	:  1;
		unsigned reserv3		:  3;
		unsigned flash_dbg_src  	:  2;
		unsigned reserv4		:  2;
		unsigned flash_dbg_mcb_num 	:  3;
		unsigned reserv5 		:  13;
	};
	uint32_t as_int;
} IMGIF_IMG_INFO_t;

//// Register 0x08
//typedef union IMGIF_IMG_RESOL {
//	struct {
//		unsigned h_resol	: 10;
//		unsigned v_resol 	: 10;
//		unsigned reserv1 	: 12;
//	};
//	uint32_t as_int;
//} IMGIF_IMG_RESOL_t;

// Register 0x0C
typedef union IMGIF_TB_MARGIN {
	struct {
		unsigned v_t_margin 	: 5;
		unsigned reserv1 	: 3;
		unsigned v_b_margin 	: 10;
		unsigned reserv2 	: 14;
	};
	uint32_t as_int;
} IMGIF_TB_MARGIN_t;

// Register 0x10
typedef union IMGIF_OB_RESOL {
	struct {
		unsigned h_ob_start 	: 10;
		unsigned h_ob_end 	: 10;
		unsigned v_ob_start 	: 3;
		unsigned reserv1 	: 9;
	};
	uint32_t as_int;
} IMGIF_OB_RESOL_t;

// Register 0x14
typedef union IMGIF_H_OB_INFO {
	struct {
		unsigned h_ob_en 	: 1;
		unsigned h_ob_m_w 	: 6;
		unsigned h_ob_s_w 	: 6;
		unsigned h_ob_shift_w 	: 6;
		unsigned h_ob_man_en	: 1;
		unsigned h_ob_man_val	: 12;
	};
	uint32_t as_int;
} IMGIF_H_OB_INFO_t;

// Register 0x18
typedef union IMGIF_T_OB_INFO {
	struct {
		unsigned t_ob_en 	: 1;
		unsigned reserv1 	: 3;
		unsigned t_ob_n_r 	: 5;
		unsigned reserv2 	: 3;
		unsigned t_ob_n_r_shift : 3;
		unsigned t_ob_s_w	: 10;
		unsigned reserv3 	: 3;
		unsigned t_ob_s_w_shift : 4;
	};
	uint32_t as_int;
} IMGIF_T_OB_INFO_t;

// Register 0x1C
typedef union IMGIF_SEMI_ACTIVE_RESOL {
	struct {
		unsigned sa_start 	: 10;
		unsigned sa_end 	: 10;
		unsigned reserv1 	: 12;
	};
	uint32_t as_int;
} IMGIF_SEMI_ACTIVE_RESOL_t;

// Register 0x20
typedef union IMGIF_ACTIVE_RESOL {
	struct {
		unsigned a_start 	: 10;
		unsigned a_end 		: 10;
		unsigned num_rows 	: 10;
		unsigned reserv1 	: 2;
	};
	uint32_t as_int;
} IMGIF_ACTIVE_RESOL_t;

typedef union IMGIF_ACTIVE_CONFIG {
	struct {
		unsigned mcb_per_row	: 6;
		unsigned reserv1 	: 2;
		unsigned mcb_per_col	: 5;
		unsigned reserv2 	: 3;
		unsigned total_mcb	: 11;
		unsigned reserv3	: 5;
	};
	uint32_t as_int;
} IMGIF_ACTIVE_CONFIG_t;

// Register 0x24
typedef union IMGIF_PAIR_LUT_0 {
	struct {
		unsigned data : 32;
	};
	uint32_t as_int;
} IMGIF_PAIR_LUT_0_t;

// Register 0x28
typedef union IMGIF_PAIR_LUT_1 {
	struct {
		unsigned data : 32;
	};
	uint32_t as_int;
} IMGIF_PAIR_LUT_1_t;

// Register 0x2C
typedef union IMGIF_PAIR_LUT_2 {
	struct {
		unsigned data : 32;
	};
	uint32_t as_int;
} IMGIF_PAIR_LUT_2_t;

// Register 0x30
typedef union IMGIF_PAIR_LUT_3 {
	struct {
		unsigned data : 32;
	};
	uint32_t as_int;
} IMGIF_PAIR_LUT_3_t;

// Register 0x34
typedef union IMGIF_CD_CTRL {
	struct {
		unsigned softreset 	: 1;
		unsigned reserv1 	: 3;
		unsigned cd_en		: 1;
		unsigned reserv2	: 3;
		unsigned cd_mode 	: 1;
		unsigned reserv3 	: 23;
	};
	uint32_t as_int;
} IMGIF_CD_CTRL_t;

// Register 0x38
typedef union IMGIF_CD_CONFIG {
	struct {
		unsigned diff_thresh 	: 6;
		unsigned denoise 	: 5;
		unsigned cd_thresh 	: 6;
		unsigned reserv1	: 3;
		unsigned a_dir 		: 1;
		unsigned reserv2 	: 3;
		unsigned b_dir 		: 1;
		unsigned reserv3 	: 8;
	};
	uint32_t as_int;
} IMGIF_CD_CONFIG_t;

// Register 0x3C
typedef union IMGIF_DILATE_PATT {
	struct {
		unsigned pattern 	: 8;
		unsigned reserv1 	: 24;
	};
	uint32_t as_int;
} IMGIF_DILATE_PATT_t;

// Register 0x40
typedef union IMGIF_SRAM_ADDR {
	struct {
		unsigned cd_sram 	: 11;
		unsigned reserv1 	: 1;
		unsigned ref_sram 	: 11;
		unsigned reserv2 	: 9;
	};
	uint32_t as_int;
} IMGIF_SRAM_ADDR_t;

// Register 0x44
typedef union IMGIF_PIX_RANGE {
	struct {
		unsigned pix_low 	: 12;
		unsigned pix_high 	: 12;
		unsigned reserv1 	: 8;
	};
	uint32_t as_int;
} IMGIF_PIX_RANGE_t;

typedef union B_CONV {
	struct {
		unsigned auto_min_max_en 	: 1;
		unsigned min			: 10; 
		unsigned max 			: 10;
		unsigned auto_shift_en		: 1;
		unsigned shift_dir		: 1;
		unsigned bit_shift 		: 4; 
		unsigned sat_en			: 1;
		unsigned sat_shift		: 4;
	};
	uint32_t as_int;
} B_CONV_t;

//logic                                  dec_en       ; // Need to add
//logic	                        	    odd_row_b     ; // Connect to r/w registers in SFR map 
//logic                           	    odd_col_g     ; // Connect to r/w registers in SFR map   
//logic        [P_NBIT_SHIFT_CNT-1:0]     nbit_truncate ; // Connect to r/w registers in SFR map
typedef union COMPMEM_CONFIG {
	struct {
		unsigned compmem_config_dec_en       : 1 ;
		unsigned reserv1                     : 3 ;
		unsigned compmem_config_odd_row_b    : 1 ;
		unsigned compmem_config_odd_col_g    : 1 ;
		unsigned reserv2                     : 2 ;
		unsigned compmem_config_nbit_truncate: 3 ;
		unsigned reserv3		     : 1 ;
		unsigned compmem_config_dec_cnt_en   : 1 ;
		unsigned reserv4                     : 19;
	};
	uint32_t as_int;
} COMPMEM_CONFIG_t;

//logic [P_BW_ADDR_FRM_SRAM -1:0]         frm_ssaddr_y  ; // Connect to r/w registers in SFR map
//logic [P_BW_ADDR_FRM_SRAM_UV -1:0]      frm_ssaddr_uv ; // Connect to r/w registers in SFR map
typedef union FRMMEM_SSADDR {
	struct {
		unsigned frmmem_ssaddr_y   :14;
		unsigned reserv1           :2 ;
		unsigned frmmem_ssaddr_uv  :14;
		unsigned reserv2           :2 ;
	};
	uint32_t as_int;
} FRMMEM_SSADDR_t;

//logic [P_BW_ADDR_FRM_SRAM -1:0]         mcb_addr_y    ; // Connect to r registers in SFR map
//logic [P_BW_ADDR_FRM_SRAM_UV -1:0]      mcb_addr_uv   ; // Connect to r registers in SFR map
typedef union MCB_ADDR {
	struct {
		unsigned mcb_addr_y  : 14;
		unsigned reserv1     : 2;	
		unsigned mcb_addr_uv : 14;	
		unsigned reserv2     : 2;	
	};
	uint32_t as_int;
} MCB_ADDR_t;

typedef union YUV_MAT_ROW0 {/*{{{*/
	struct {
		unsigned col0  : 9;
		unsigned col1  : 9;
		unsigned col2  : 9;
		unsigned reserv     : 5;
	};
	uint32_t as_int;
} YUV_MAT_ROW0_t;
typedef union YUV_MAT_ROW1 {
	struct {
		unsigned col0  : 9;
		unsigned col1  : 9;
		unsigned col2  : 9;
		unsigned reserv     : 5;
	};
	uint32_t as_int;
} YUV_MAT_ROW1_t;
typedef union YUV_MAT_ROW2 {
	struct {
		unsigned col0  : 9;
		unsigned col1  : 9;
		unsigned col2  : 9;
		unsigned reserv     : 5;
	};
	uint32_t as_int;
} YUV_MAT_ROW2_t;/*}}}*/
typedef union Q_Y_ROW00 {/*{{{*/
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_Y_ROW00_t;
typedef union Q_Y_ROW01 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_Y_ROW01_t;
typedef union Q_Y_ROW10 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_Y_ROW10_t;
typedef union Q_Y_ROW11 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_Y_ROW11_t;
typedef union Q_Y_ROW20 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_Y_ROW20_t;
typedef union Q_Y_ROW21 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_Y_ROW21_t;
typedef union Q_Y_ROW30 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_Y_ROW30_t;
typedef union Q_Y_ROW31 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_Y_ROW31_t;/*}}}*/

typedef union Q_Y_ROW40 {/*{{{*/
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_Y_ROW40_t;
typedef union Q_Y_ROW41 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_Y_ROW41_t;
typedef union Q_Y_ROW50 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_Y_ROW50_t;
typedef union Q_Y_ROW51 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_Y_ROW51_t;
typedef union Q_Y_ROW60 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_Y_ROW60_t;
typedef union Q_Y_ROW61 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_Y_ROW61_t;
typedef union Q_Y_ROW70 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_Y_ROW70_t;
typedef union Q_Y_ROW71 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_Y_ROW71_t;/*}}}*/

typedef union INV_Q_Y_ROW00 {/*{{{*/
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_Y_ROW00_t;
typedef union INV_Q_Y_ROW01 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_Y_ROW01_t;
typedef union INV_Q_Y_ROW10 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_Y_ROW10_t;
typedef union INV_Q_Y_ROW11 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_Y_ROW11_t;
typedef union INV_Q_Y_ROW20 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_Y_ROW20_t;
typedef union INV_Q_Y_ROW21 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_Y_ROW21_t;
typedef union INV_Q_Y_ROW30 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_Y_ROW30_t;
typedef union INV_Q_Y_ROW31 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_Y_ROW31_t;/*}}}*/

typedef union INV_Q_Y_ROW40 {/*{{{*/
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_Y_ROW40_t;
typedef union INV_Q_Y_ROW41 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_Y_ROW41_t;
typedef union INV_Q_Y_ROW50 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_Y_ROW50_t;
typedef union INV_Q_Y_ROW51 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_Y_ROW51_t;
typedef union INV_Q_Y_ROW60 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_Y_ROW60_t;
typedef union INV_Q_Y_ROW61 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_Y_ROW61_t;
typedef union INV_Q_Y_ROW70 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_Y_ROW70_t;
typedef union INV_Q_Y_ROW71 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_Y_ROW71_t;/*}}}*/

typedef union DCT_Y_ROW00 {/*{{{*/
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_Y_ROW00_t;
typedef union DCT_Y_ROW01 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_Y_ROW01_t;
typedef union DCT_Y_ROW10 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_Y_ROW10_t;
typedef union DCT_Y_ROW11 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_Y_ROW11_t;
typedef union DCT_Y_ROW20 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_Y_ROW20_t;
typedef union DCT_Y_ROW21 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_Y_ROW21_t;
typedef union DCT_Y_ROW30 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_Y_ROW30_t;
typedef union DCT_Y_ROW31 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_Y_ROW31_t;/*}}}*/

typedef union DCT_Y_ROW40 {/*{{{*/
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_Y_ROW40_t;
typedef union DCT_Y_ROW41 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_Y_ROW41_t;
typedef union DCT_Y_ROW50 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_Y_ROW50_t;
typedef union DCT_Y_ROW51 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_Y_ROW51_t;
typedef union DCT_Y_ROW60 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_Y_ROW60_t;
typedef union DCT_Y_ROW61 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_Y_ROW61_t;
typedef union DCT_Y_ROW70 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_Y_ROW70_t;
typedef union DCT_Y_ROW71 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_Y_ROW71_t;/*}}}*/

typedef union Q_UV_ROW00 {/*{{{*/
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_UV_ROW00_t;
typedef union Q_UV_ROW01 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_UV_ROW01_t;
typedef union Q_UV_ROW10 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_UV_ROW10_t;
typedef union Q_UV_ROW11 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_UV_ROW11_t;
typedef union Q_UV_ROW20 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_UV_ROW20_t;
typedef union Q_UV_ROW21 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_UV_ROW21_t;
typedef union Q_UV_ROW30 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_UV_ROW30_t;
typedef union Q_UV_ROW31 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_UV_ROW31_t;/*}}}*/

typedef union Q_UV_ROW40 {/*{{{*/
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_UV_ROW40_t;
typedef union Q_UV_ROW41 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_UV_ROW41_t;
typedef union Q_UV_ROW50 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_UV_ROW50_t;
typedef union Q_UV_ROW51 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_UV_ROW51_t;
typedef union Q_UV_ROW60 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_UV_ROW60_t;
typedef union Q_UV_ROW61 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_UV_ROW61_t;
typedef union Q_UV_ROW70 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_UV_ROW70_t;
typedef union Q_UV_ROW71 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} Q_UV_ROW71_t;/*}}}*/

typedef union INV_Q_UV_ROW00 {/*{{{*/
struct {
	unsigned col0  : 8;
	unsigned col1  : 8;
	unsigned col2  : 8;
	unsigned col3  : 8;
};
uint32_t as_int;
} INV_Q_UV_ROW00_t;
typedef union INV_Q_UV_ROW01 {
struct {
	unsigned col0  : 8;
	unsigned col1  : 8;
	unsigned col2  : 8;
	unsigned col3  : 8;
};
uint32_t as_int;
} INV_Q_UV_ROW01_t;
typedef union INV_Q_UV_ROW10 {
struct {
	unsigned col0  : 8;
	unsigned col1  : 8;
	unsigned col2  : 8;
	unsigned col3  : 8;
};
uint32_t as_int;
} INV_Q_UV_ROW10_t;
typedef union INV_Q_UV_ROW11 {
struct {
	unsigned col0  : 8;
	unsigned col1  : 8;
	unsigned col2  : 8;
	unsigned col3  : 8;
};
uint32_t as_int;
} INV_Q_UV_ROW11_t;
typedef union INV_Q_UV_ROW20 {
struct {
	unsigned col0  : 8;
	unsigned col1  : 8;
	unsigned col2  : 8;
	unsigned col3  : 8;
};
uint32_t as_int;
} INV_Q_UV_ROW20_t;
typedef union INV_Q_UV_ROW21 {
struct {
	unsigned col0  : 8;
	unsigned col1  : 8;
	unsigned col2  : 8;
	unsigned col3  : 8;
};
uint32_t as_int;
} INV_Q_UV_ROW21_t;
typedef union INV_Q_UV_ROW30 {
struct {
	unsigned col0  : 8;
	unsigned col1  : 8;
	unsigned col2  : 8;
	unsigned col3  : 8;
};
uint32_t as_int;
} INV_Q_UV_ROW30_t;
typedef union INV_Q_UV_ROW31 {
struct {
	unsigned col0  : 8;
	unsigned col1  : 8;
	unsigned col2  : 8;
	unsigned col3  : 8;
};
uint32_t as_int;
} INV_Q_UV_ROW31_t;/*}}}*/

typedef union INV_Q_UV_ROW40 {/*{{{*/
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_UV_ROW40_t;
typedef union INV_Q_UV_ROW41 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_UV_ROW41_t;
typedef union INV_Q_UV_ROW50 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_UV_ROW50_t;
typedef union INV_Q_UV_ROW51 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_UV_ROW51_t;
typedef union INV_Q_UV_ROW60 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_UV_ROW60_t;
typedef union INV_Q_UV_ROW61 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_UV_ROW61_t;
typedef union INV_Q_UV_ROW70 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_UV_ROW70_t;
typedef union INV_Q_UV_ROW71 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} INV_Q_UV_ROW71_t;/*}}}*/

typedef union DCT_UV_ROW00 {/*{{{*/
struct {
	unsigned col0  : 8;
	unsigned col1  : 8;
	unsigned col2  : 8;
	unsigned col3  : 8;
};
uint32_t as_int;
} DCT_UV_ROW00_t;
typedef union DCT_UV_ROW01 {
struct {
	unsigned col0  : 8;
	unsigned col1  : 8;
	unsigned col2  : 8;
	unsigned col3  : 8;
};
uint32_t as_int;
} DCT_UV_ROW01_t;
typedef union DCT_UV_ROW10 {
struct {
	unsigned col0  : 8;
	unsigned col1  : 8;
	unsigned col2  : 8;
	unsigned col3  : 8;
};
uint32_t as_int;
} DCT_UV_ROW10_t;
typedef union DCT_UV_ROW11 {
struct {
	unsigned col0  : 8;
	unsigned col1  : 8;
	unsigned col2  : 8;
	unsigned col3  : 8;
};
uint32_t as_int;
} DCT_UV_ROW11_t;
typedef union DCT_UV_ROW20 {
struct {
	unsigned col0  : 8;
	unsigned col1  : 8;
	unsigned col2  : 8;
	unsigned col3  : 8;
};
uint32_t as_int;
} DCT_UV_ROW20_t;
typedef union DCT_UV_ROW21 {
struct {
	unsigned col0  : 8;
	unsigned col1  : 8;
	unsigned col2  : 8;
	unsigned col3  : 8;
};
uint32_t as_int;
} DCT_UV_ROW21_t;
typedef union DCT_UV_ROW30 {
struct {
	unsigned col0  : 8;
	unsigned col1  : 8;
	unsigned col2  : 8;
	unsigned col3  : 8;
};
uint32_t as_int;
} DCT_UV_ROW30_t;
typedef union DCT_UV_ROW31 {
struct {
	unsigned col0  : 8;
	unsigned col1  : 8;
	unsigned col2  : 8;
	unsigned col3  : 8;
};
uint32_t as_int;
} DCT_UV_ROW31_t;/*}}}*/

typedef union DCT_UV_ROW40 {/*{{{*/
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_UV_ROW40_t;
typedef union DCT_UV_ROW41 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_UV_ROW41_t;
typedef union DCT_UV_ROW50 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_UV_ROW50_t;
typedef union DCT_UV_ROW51 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_UV_ROW51_t;
typedef union DCT_UV_ROW60 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_UV_ROW60_t;
typedef union DCT_UV_ROW61 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_UV_ROW61_t;
typedef union DCT_UV_ROW70 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_UV_ROW70_t;
typedef union DCT_UV_ROW71 {
	struct {
		unsigned col0  : 8;
		unsigned col1  : 8;
		unsigned col2  : 8;
		unsigned col3  : 8;
	};
	uint32_t as_int;
} DCT_UV_ROW71_t;/*}}}*/

typedef union ENC_DONE_INT {
	struct {
		unsigned interrupt : 1;
		unsigned reserv    : 31;
	};
	uint32_t as_int;
} ENC_DONE_INT_t;

typedef union MD_DONE_INT {
	struct {
		unsigned interrupt : 1;
		unsigned reserv    : 31;
	};
	uint32_t as_int;
} MD_DONE_INT_t;

typedef union IMGIF_DBG_STATUS {
	struct {	
		unsigned row_pack_state 	: 4;
		unsigned cd_ctrl_state  	: 3;
		unsigned reserv1 		: 1;
		unsigned hamm_sum_state 	: 2;
		unsigned reserv2 		: 2;
		unsigned ref_accum_state	: 2;
		unsigned reserv3 		: 2;
		unsigned hamm_sum_val 		: 8;
		unsigned reserv4 		: 8;
	};
	uint32_t as_int;
} IMGIF_DBG_STATUS_t;

typedef union IMGIF_DBG_SRAM {
	struct {	
		unsigned cd_sram_state 	: 1;
		unsigned reserve1 	: 3;
		unsigned cd_sram_addr 	: 11;
		unsigned reserv2 	: 1;
		unsigned ref_sram_state : 1;
		unsigned reserv3 	: 3;
		unsigned ref_sram_addr  : 11;
		unsigned reserv4 	: 1;
	};
	uint32_t as_int;
} IMGIF_DBG_SRAM_t;

typedef union IMGIF_COMPMEM_STATUS {
	struct {
		unsigned state_jpeg_y 	: 3;
		unsigned reserve1 	: 1;
		unsigned cnt_mmcb_y	: 2;
		unsigned reserve2 	: 2;
		unsigned state_jpeg_uv 	: 3;
		unsigned reserve3 	: 1;
		unsigned cnt_mmcb_uv 	: 1;
		unsigned reserve4 	: 3;
		unsigned state_pack_y 	: 1;
		unsigned state_unpack_y	: 1;
		unsigned state_pack_uv 	: 1;
		unsigned state_unpack_uv: 1;
		unsigned state_dejpeg 	: 2;
		unsigned reserve5 	: 10;
	};
	uint32_t as_int;
} IMGIF_COMPMEM_STATUS_t; 

// Declarations
#define p_IMGIF_IF_CTRL 		((volatile IMGIF_IF_CTRL_t     		*) 0xA0400000)
#define p_IMGIF_IMG_INFO 		((volatile IMGIF_IMG_INFO_t 		*) 0xA0400004)
#define p_IMGIF_TB_MARGIN 		((volatile IMGIF_TB_MARGIN_t 		*) 0xA0400008)
#define p_IMGIF_OB_RESOL 		((volatile IMGIF_OB_RESOL_t 		*) 0xA040000C)
#define p_IMGIF_H_OB_INFO 		((volatile IMGIF_H_OB_INFO_t 		*) 0xA0400010)
#define p_IMGIF_T_OB_INFO 		((volatile IMGIF_T_OB_INFO_t 		*) 0xA0400014)
#define p_IMGIF_SEMI_ACTIVE_RESOL 	((volatile IMGIF_SEMI_ACTIVE_RESOL_t 	*) 0xA0400018)
#define p_IMGIF_ACTIVE_RESOL 		((volatile IMGIF_ACTIVE_RESOL_t 	*) 0xA040001C)
#define p_IMGIF_ACTIVE_CONFIG 		((volatile IMGIF_ACTIVE_CONFIG_t 	*) 0xA0400020)
#define p_IMGIF_PAIR_LUT_0 		((volatile IMGIF_PAIR_LUT_0_t 		*) 0xA0400024)
#define p_IMGIF_PAIR_LUT_1 		((volatile IMGIF_PAIR_LUT_1_t 		*) 0xA0400028)
#define p_IMGIF_PAIR_LUT_2 		((volatile IMGIF_PAIR_LUT_2_t 		*) 0xA040002C)
#define p_IMGIF_PAIR_LUT_3 		((volatile IMGIF_PAIR_LUT_3_t 		*) 0xA0400030)
#define p_IMGIF_CD_CTRL 		((volatile IMGIF_CD_CTRL_t   		*) 0xA0400034)
#define p_IMGIF_CD_CONFIG 		((volatile IMGIF_CD_CONFIG_t 		*) 0xA0400038)
#define p_IMGIF_DILATE_PATT 		((volatile IMGIF_DILATE_PATT_t 		*) 0xA040003C)
#define p_IMGIF_SRAM_ADDR 		((volatile IMGIF_SRAM_ADDR_t 		*) 0xA0400040)
#define p_IMGIF_PIX_RANGE 		((volatile IMGIF_PIX_RANGE_t 		*) 0xA0400044)
#define p_B_CONV 	    		((volatile B_CONV_t 	    		*) 0xA0400048)
#define p_COMPMEM_CONFIG    		((volatile COMPMEM_CONFIG_t  		*) 0xA04100F0)
#define p_FRMMEM_SSADDR     		((volatile FRMMEM_SSADDR_t   		*) 0xA04100F4)
#define p_MCB_ADDR          		((volatile MCB_ADDR_t        		*) 0xA04100F8)
#define p_YUV_MAT_ROW0      		((volatile YUV_MAT_ROW0_t    		*) 0xA04100FC)
#define p_YUV_MAT_ROW1      		((volatile YUV_MAT_ROW1_t    		*) 0xA0410100)
#define p_YUV_MAT_ROW2 			((volatile YUV_MAT_ROW2_t    		*) 0xA0410104)
#define p_Q_Y_ROW00         		((volatile Q_Y_ROW00_t       		*) 0xA0410108)
#define p_Q_Y_ROW01         		((volatile Q_Y_ROW01_t       		*) 0xA041010C)
#define p_Q_Y_ROW10         		((volatile Q_Y_ROW10_t       		*) 0xA0410110)
#define p_Q_Y_ROW11         		((volatile Q_Y_ROW11_t       		*) 0xA0410114)
#define p_Q_Y_ROW20         		((volatile Q_Y_ROW20_t       		*) 0xA0410118)
#define p_Q_Y_ROW21         		((volatile Q_Y_ROW21_t       		*) 0xA041011C)
#define p_Q_Y_ROW30         		((volatile Q_Y_ROW30_t       		*) 0xA0410120)
#define p_Q_Y_ROW31         		((volatile Q_Y_ROW31_t       		*) 0xA0410124)
#define p_Q_Y_ROW40         		((volatile Q_Y_ROW40_t       		*) 0xA0410128)
#define p_Q_Y_ROW41         		((volatile Q_Y_ROW41_t       		*) 0xA041012C)
#define p_Q_Y_ROW50         		((volatile Q_Y_ROW50_t       		*) 0xA0410130)
#define p_Q_Y_ROW51         		((volatile Q_Y_ROW51_t       		*) 0xA0410134)
#define p_Q_Y_ROW60         		((volatile Q_Y_ROW60_t       		*) 0xA0410138)
#define p_Q_Y_ROW61         		((volatile Q_Y_ROW61_t       		*) 0xA041013C)
#define p_Q_Y_ROW70         		((volatile Q_Y_ROW70_t       		*) 0xA0410140)
#define p_Q_Y_ROW71         		((volatile Q_Y_ROW71_t       		*) 0xA0410144)
#define p_INV_Q_Y_ROW00     		((volatile INV_Q_Y_ROW00_t   		*) 0xA0410148)
#define p_INV_Q_Y_ROW01     		((volatile INV_Q_Y_ROW01_t   		*) 0xA041014C)
#define p_INV_Q_Y_ROW10     		((volatile INV_Q_Y_ROW10_t   		*) 0xA0410150)
#define p_INV_Q_Y_ROW11     		((volatile INV_Q_Y_ROW11_t   		*) 0xA0410154)
#define p_INV_Q_Y_ROW20     		((volatile INV_Q_Y_ROW20_t   		*) 0xA0410158)
#define p_INV_Q_Y_ROW21     		((volatile INV_Q_Y_ROW21_t   		*) 0xA041015C)
#define p_INV_Q_Y_ROW30     		((volatile INV_Q_Y_ROW30_t   		*) 0xA0410160)
#define p_INV_Q_Y_ROW31     		((volatile INV_Q_Y_ROW31_t   		*) 0xA0410164)
#define p_INV_Q_Y_ROW40     		((volatile INV_Q_Y_ROW40_t   		*) 0xA0410168)
#define p_INV_Q_Y_ROW41     		((volatile INV_Q_Y_ROW41_t   		*) 0xA041016C)
#define p_INV_Q_Y_ROW50     		((volatile INV_Q_Y_ROW50_t   		*) 0xA0410170)
#define p_INV_Q_Y_ROW51     		((volatile INV_Q_Y_ROW51_t   		*) 0xA0410174)
#define p_INV_Q_Y_ROW60     		((volatile INV_Q_Y_ROW60_t   		*) 0xA0410178)
#define p_INV_Q_Y_ROW61     		((volatile INV_Q_Y_ROW61_t   		*) 0xA041017C)
#define p_INV_Q_Y_ROW70     		((volatile INV_Q_Y_ROW70_t   		*) 0xA0410180)
#define p_INV_Q_Y_ROW71     		((volatile INV_Q_Y_ROW71_t   		*) 0xA0410184)
#define p_DCT_Y_ROW00       		((volatile DCT_Y_ROW00_t     		*) 0xA0410188)
#define p_DCT_Y_ROW01       		((volatile DCT_Y_ROW01_t     		*) 0xA041018C)
#define p_DCT_Y_ROW10       		((volatile DCT_Y_ROW10_t     		*) 0xA0410190)
#define p_DCT_Y_ROW11       		((volatile DCT_Y_ROW11_t     		*) 0xA0410194)
#define p_DCT_Y_ROW20       		((volatile DCT_Y_ROW20_t     		*) 0xA0410198)
#define p_DCT_Y_ROW21       		((volatile DCT_Y_ROW21_t     		*) 0xA041019C)
#define p_DCT_Y_ROW30       		((volatile DCT_Y_ROW30_t     		*) 0xA04101A0)
#define p_DCT_Y_ROW31       		((volatile DCT_Y_ROW31_t     		*) 0xA04101A4)
#define p_DCT_Y_ROW40       		((volatile DCT_Y_ROW40_t     		*) 0xA04101A8)
#define p_DCT_Y_ROW41       		((volatile DCT_Y_ROW41_t     		*) 0xA04101AC)
#define p_DCT_Y_ROW50       		((volatile DCT_Y_ROW50_t     		*) 0xA04101B0)
#define p_DCT_Y_ROW51       		((volatile DCT_Y_ROW51_t     		*) 0xA04101B4)
#define p_DCT_Y_ROW60       		((volatile DCT_Y_ROW60_t     		*) 0xA04101B8)
#define p_DCT_Y_ROW61       		((volatile DCT_Y_ROW61_t     		*) 0xA04101BC)
#define p_DCT_Y_ROW70       		((volatile DCT_Y_ROW70_t     		*) 0xA04101C0)
#define p_DCT_Y_ROW71       		((volatile DCT_Y_ROW71_t     		*) 0xA04101C4)
#define p_Q_UV_ROW00        		((volatile Q_UV_ROW00_t      		*) 0xA04101C8)
#define p_Q_UV_ROW01        		((volatile Q_UV_ROW01_t      		*) 0xA04101CC)
#define p_Q_UV_ROW10        		((volatile Q_UV_ROW10_t      		*) 0xA04101D0)
#define p_Q_UV_ROW11        		((volatile Q_UV_ROW11_t      		*) 0xA04101D4)
#define p_Q_UV_ROW20        		((volatile Q_UV_ROW20_t      		*) 0xA04101D8)
#define p_Q_UV_ROW21        		((volatile Q_UV_ROW21_t      		*) 0xA04101DC)
#define p_Q_UV_ROW30        		((volatile Q_UV_ROW30_t      		*) 0xA04101E0)
#define p_Q_UV_ROW31        		((volatile Q_UV_ROW31_t      		*) 0xA04101E4)
#define p_Q_UV_ROW40        		((volatile Q_UV_ROW40_t      		*) 0xA04101E8)
#define p_Q_UV_ROW41        		((volatile Q_UV_ROW41_t      		*) 0xA04101EC)
#define p_Q_UV_ROW50        		((volatile Q_UV_ROW50_t      		*) 0xA04101F0)
#define p_Q_UV_ROW51        		((volatile Q_UV_ROW51_t      		*) 0xA04101F4)
#define p_Q_UV_ROW60        		((volatile Q_UV_ROW60_t      		*) 0xA04101F8)
#define p_Q_UV_ROW61        		((volatile Q_UV_ROW61_t      		*) 0xA04101FC)
#define p_Q_UV_ROW70        		((volatile Q_UV_ROW70_t      		*) 0xA0410200)
#define p_Q_UV_ROW71        		((volatile Q_UV_ROW71_t      		*) 0xA0410204)
#define p_INV_Q_UV_ROW00    		((volatile INV_Q_UV_ROW00_t  		*) 0xA0410208)
#define p_INV_Q_UV_ROW01    		((volatile INV_Q_UV_ROW01_t  		*) 0xA041020C)
#define p_INV_Q_UV_ROW10    		((volatile INV_Q_UV_ROW10_t  		*) 0xA0410210)
#define p_INV_Q_UV_ROW11    		((volatile INV_Q_UV_ROW11_t  		*) 0xA0410214)
#define p_INV_Q_UV_ROW20    		((volatile INV_Q_UV_ROW20_t  		*) 0xA0410218)
#define p_INV_Q_UV_ROW21    		((volatile INV_Q_UV_ROW21_t  		*) 0xA041021C)
#define p_INV_Q_UV_ROW30    		((volatile INV_Q_UV_ROW30_t  		*) 0xA0410220)
#define p_INV_Q_UV_ROW31    		((volatile INV_Q_UV_ROW31_t  		*) 0xA0410224)
#define p_INV_Q_UV_ROW40    		((volatile INV_Q_UV_ROW40_t  		*) 0xA0410228)
#define p_INV_Q_UV_ROW41    		((volatile INV_Q_UV_ROW41_t  		*) 0xA041022C)
#define p_INV_Q_UV_ROW50    		((volatile INV_Q_UV_ROW50_t  		*) 0xA0410230)
#define p_INV_Q_UV_ROW51    		((volatile INV_Q_UV_ROW51_t  		*) 0xA0410234)
#define p_INV_Q_UV_ROW60    		((volatile INV_Q_UV_ROW60_t  		*) 0xA0410238)
#define p_INV_Q_UV_ROW61    		((volatile INV_Q_UV_ROW61_t  		*) 0xA041023C)
#define p_INV_Q_UV_ROW70    		((volatile INV_Q_UV_ROW70_t  		*) 0xA0410240)
#define p_INV_Q_UV_ROW71    		((volatile INV_Q_UV_ROW71_t  		*) 0xA0410244)
#define p_DCT_UV_ROW00      		((volatile DCT_UV_ROW00_t    		*) 0xA0410248)
#define p_DCT_UV_ROW01      		((volatile DCT_UV_ROW01_t    		*) 0xA041024C)
#define p_DCT_UV_ROW10      		((volatile DCT_UV_ROW10_t    		*) 0xA0410250)
#define p_DCT_UV_ROW11      		((volatile DCT_UV_ROW11_t    		*) 0xA0410254)
#define p_DCT_UV_ROW20      		((volatile DCT_UV_ROW20_t    		*) 0xA0410258)
#define p_DCT_UV_ROW21      		((volatile DCT_UV_ROW21_t    		*) 0xA041025C)
#define p_DCT_UV_ROW30      		((volatile DCT_UV_ROW30_t    		*) 0xA0410260)
#define p_DCT_UV_ROW31      		((volatile DCT_UV_ROW31_t    		*) 0xA0410264)
#define p_DCT_UV_ROW40      		((volatile DCT_UV_ROW40_t    		*) 0xA0410268)
#define p_DCT_UV_ROW41      		((volatile DCT_UV_ROW41_t    		*) 0xA041026C)
#define p_DCT_UV_ROW50      		((volatile DCT_UV_ROW50_t    		*) 0xA0410270)
#define p_DCT_UV_ROW51      		((volatile DCT_UV_ROW51_t    		*) 0xA0410274)
#define p_DCT_UV_ROW60      		((volatile DCT_UV_ROW60_t    		*) 0xA0410278)
#define p_DCT_UV_ROW61      		((volatile DCT_UV_ROW61_t    		*) 0xA041027C)
#define p_DCT_UV_ROW70      		((volatile DCT_UV_ROW70_t    		*) 0xA0410280)
#define p_DCT_UV_ROW71      		((volatile DCT_UV_ROW71_t    		*) 0xA0410284)
#define p_ENC_DONE_INT      		((volatile ENC_DONE_INT_t    		*) 0xA0410288)
#define p_MD_DONE_INT 			((volatile MD_DONE_INT_t    		*) 0xA041028C)
//define p_MD_DONE_INT 			((volatile MD_DONE_INT_t    		*) 0xA041028C)
//define p_MINMAX_SRAM_START 		((volatile uint32_t			*) 0xA0410290)
#define p_MINMAX_SRAM_START 		((volatile uint32_t			*) 0xA0410290)
#define p_MCBRD_SRAM_START 	    	((volatile uint32_t  			*) 0xA0411290)
#define p_CD_MAP_START 			((volatile uint32_t  			*) 0xA040004C)
#define p_CD_SRAM_START 		((volatile uint32_t  			*) 0xA04000F0)
#define p_REF_SRAM_START 		((volatile uint32_t  			*) 0xA044D810)
#define p_IMGIF_DBG_STATUS 		((volatile IMGIF_DBG_STATUS_t 		*) 0xA0450810)
#define p_IMGIF_DBG_SRAM 		((volatile IMGIF_DBG_SRAM_t 		*) 0xA0450814)
#define p_IMGIF_COMPMEM_STATUS 		((volatile IMGIF_COMPMEM_STATUS_t 	*) 0xA0450818 
#define p_COMP_SRAM_START 		((volatile uint32_t 			*) 0xA0413810)
#endif // CMPV1_RF_H
