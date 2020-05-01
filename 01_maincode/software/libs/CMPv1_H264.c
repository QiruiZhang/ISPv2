#include "CMPv1_H264.h"

void h264_mem_direct_access(void){
	p_H264_DEBUG->h264_debug_sram_sel = 1;
	p_H264_DEBUG->h264_debug_out_sel = 1;  
}

void h264_config(uint32_t saddr_ref_y, uint32_t saddr_ref_uv, uint8_t qp, uint8_t fls_direct){
	p_H264_COMPMEM_SADDR_YREF->as_int = saddr_ref_y;
	p_H264_COMPMEM_SADDR_UVREF->as_int = saddr_ref_uv;
	p_H264_PARAM->h264_qp = qp;
	p_H264_DEBUG->h264_debug_out_sel = !fls_direct;
}

uint32_t h264_fetch_data(void){
	return p_H264_FIFO->as_int;
}

void h264_start(uint8_t row, uint8_t col){
	p_H264_CTRL->as_int = (col<<16) | (row<<8) | 1;
}

void h264_initialize(){
	p_H264_ENABLE->h264_frm_rstn = 1;
	p_H264_ENABLE->h264_en = 1;
}

void dbg_h264_enable(void){
	p_H264_DEBUG->h264_debug_sram_sel = 1;
	p_H264_DEBUG->h264_debug_start_bypass = 1; //assume data is already in SRAM //no automatic MCB fetching
	p_H264_DEBUG->h264_debug_out_sel = 1;  //1 : output to FIFO
}

// addr should range from 0 ~ 511
void h264_mem_write(uint32_t addr, uint32_t wdata){
	(p_H264_MEM_START+addr*2)->as_int = wdata;
	(p_H264_MEM_START+addr*2+1)->as_int = 0x00000000;
}

// addr should range from 0 ~ 511
uint32_t h264_mem_read(uint32_t addr){
	return (p_H264_MEM_START + addr*2)->as_int;
}

uint32_t dbg_h264_mem(uint32_t element_idx){
	return *((volatile uint32_t *)(p_H264_MEM_START+element_idx));
}
uint32_t dbg_h264_ctrl_status(void){
	return p_H264_STATUS->h264_ctrl_stat;
}
uint32_t dbg_h264_pred_status(void){
	return p_H264_STATUS->h264_pred_stat;
}
uint32_t dbg_h264_tq_status(void){
	return p_H264_STATUS->h264_tq_stat;
}
uint32_t dbg_h264_cavlc_status(void){
	return p_H264_STATUS->h264_cavlc_stat;
}
uint32_t dbg_h264_left_mcb_valid(void){
	return p_H264_STATUS->h264_left_mcb_valid;
}
uint32_t dbg_h264_top_mcb_valid(void){
	return p_H264_STATUS->h264_top_mcb_valid;
}
