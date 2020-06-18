//************************************************************
// Desciption: CMPv1 H264 Header File
//************************************************************

/* Modifications by Qirui 02/08/2019
 * 1. commented out the structs and pointers for current frame macroblock addresses. The addresses of other registers are kept unchanged.
 */

// **  define HEADER file
#ifndef CMPV1_H264_H
#define CMPV1_H264_H

#include <stdint.h>
#include <stdbool.h>
/* Below is fetched from H264_SFRMAP.sv  => it will be translated
localparam H264_ENABLE = 8'h00/4; 
localparam H264_PARAM = 8'h04/4; 
localparam H264_CTRL = 8'h08/4; 
localparam H264_DEBUG = 8'h0C/4; 
localparam H264_MEM = 8'h10/4;
localparam H264_FIFO_CTRL = 8'h14/4;
localparam H264_FIFO_DATA = 8'h18/4;
localparam H264_INTR = 8'h1C/4;
localparam H264_STATUS = 8'h20/4;

H264_ENABLE: begin 
    o_ready = 1'b1; 
    o_hrdata = {23'd0, o_h264_en, 3'd0, o_h264_frm_rstn, 3'd0, o_h264_mcb_rstn};
end 
H264_PARAM: begin    
    o_ready = 1'b1;
    o_hrdata = {24'd0, o_h264_qp};
end
H264_CTRL: begin
    o_ready = 1'b1;
    o_hrdata = {8'd0, o_h264_mcbcol, o_h264_mcbrow, 7'd0, o_h264_start};
end
H264_DEBUG: begin
    o_ready = 1'b1;
    o_hrdata = {31'd0, o_h264_debug};
end 
H264_MEM: begin 
	if((state_sram == ST_IDLE)&&i_valid) begin
		o_mem_en    = 'b1;
		o_ready     = 'b0;
		o_hrdata    = 'b0;
	end
	else if(state_sram == ST_FIN) begin
		o_mem_en    = 'b0;
		o_ready     = i_mem_ready;
		o_hrdata    = i_dataout;
	end
end
H264_FIFO_CTRL: begin
    o_ready = 1'b1;
    o_hrdata = {15'd0,i_h264_fifo_rrdy,o_h264_fifo_rnbit,7'd0,o_h264_fifo_rreq};
end
H264_FIFO_DATA: begin
    o_ready = 1'b1;
    o_hrdata = i_h264_fifo_rdata;
end
H264_INTR: begin
    o_ready = 1'b1;
end
H264_STATUS: begin 
    o_ready = 1'b1; 
    o_hrdata = {16'd0,i_h264_cavlc_stat,i_h264_tq_stat,i_h264_pred_stat,i_h264_ctrl_stat};
end
*/
                      
// Register 0x04
typedef union H264_ENABLE{
  struct{
    unsigned h264_frm_rstn	:  1;
    unsigned reserv1		:  3;
    unsigned h264_en		:  1;
    unsigned reserv2  		: 27;
  };
  uint32_t as_int;
} H264_ENABLE_t;

// Register 0x08 
typedef union H264_PARAM{
  struct{
    unsigned h264_qp		:  8;
    unsigned reserv1  		: 24;
  };
  uint32_t as_int;
} H264_PARAM_t;

// Register 0x0C 
typedef union H264_CTRL{
  struct{
    unsigned h264_start	 	:  1;
    unsigned reserv1		:  7;
    unsigned h264_mcbrow	:  8;
    unsigned h264_mcbcol	:  8;
    unsigned reserv2  		:  8;
  };
  uint32_t as_int;
} H264_CTRL_t;

// Register 0x10
typedef union H264_COMPMEM_SADDR_YREF{
  struct{
    unsigned h264_Yref_saddr 	:  32;
  };
  uint32_t as_int;
} H264_COMPMEM_SADDR_YREF_t;

// Register 0x14
typedef union H264_COMPMEM_SADDR_UVREF{
  struct{
    unsigned h264_UVref_saddr 	:  32;
  };
  uint32_t as_int;
} H264_COMPMEM_SADDR_UVREF_t;

// Register 0x18
/*typedef union H264_COMPMEM_SADDR_YCUR{
  struct{
    unsigned h264_Ycur_saddr 	:  32;
  };
  uint32_t as_int;
} H264_COMPMEM_SADDR_YCUR_t;

// Register 0x1C
typedef union H264_COMPMEM_SADDR_UVCUR{
  struct{
    unsigned h264_UVcur_saddr 	:  32;
  };
  uint32_t as_int;
} H264_COMPMEM_SADDR_UVCUR_t;*/

// Register 0x1C
typedef union H264_INTR_STALL{
  uint32_t as_int;
} H264_INTR_STALL_t;


// Register 0x20
typedef union H264_DEBUG{
  struct{
    unsigned h264_debug_sram_sel	:  1;
    unsigned reserv1 			:  3;
    unsigned h264_debug_start_bypass	:  1;
    unsigned reserv2 			:  3;
    unsigned h264_debug_out_sel		:  1;
    unsigned reserv3 			:  3;
    unsigned h264_timer_stall_en	:  1;
    unsigned reserv4			:  3;
    unsigned h264_cycles_to_run		:  16;
  };
  uint32_t as_int;
} H264_DEBUG_t;


// Register 0x24
typedef union H264_FIFO{
  uint32_t as_int;
} H264_FIFO_t;

// Register 0x28
typedef union H264_FIFO_DATACNT{
  struct{
    unsigned h264_fifo_datacnt 	:  16;
    unsigned reserv1		:  16;
  };
  uint32_t as_int;
} H264_FIFO_DATACNT_t;

// Register 0x2C
typedef union H264_INTR_DONE{
  uint32_t as_int;
} H264_INTR_DONE_t;

// Register 0x30
typedef union H264_INTR_FIFO{
  uint32_t as_int;
} H264_INTR_FIFO_t;


// Register 0x34 
typedef union H264_STATUS{
  struct{
    unsigned h264_ctrl_stat	:  4;
    unsigned h264_pred_stat	:  4;
    unsigned h264_tq_stat	:  4;
    unsigned h264_cavlc_stat 	:  4;
    unsigned h264_left_mcb_valid:  1;
    unsigned reserv1		:  3;
    unsigned h264_top_mcb_valid :  1;
    unsigned reserv2		:  11;
  };
  uint32_t as_int;
} H264_STATUS_t;

// Register 0x38
typedef union H264_MEM_START{
  uint32_t as_int;
} H264_MEM_START_t;

// Register 0x1038
typedef union H264_MEM_END{
  uint32_t as_int;
} H264_MEM_END_t;


// Declaration
#define p_H264_ENABLE                  ((volatile H264_ENABLE_t 		     *) 0xA0200004)
#define p_H264_PARAM                   ((volatile H264_PARAM_t 			     *) 0xA0200008)
#define p_H264_CTRL                    ((volatile H264_CTRL_t 			     *) 0xA020000C)
#define p_H264_COMPMEM_SADDR_YREF      ((volatile H264_COMPMEM_SADDR_YREF_t  *) 0xA0200010)
#define p_H264_COMPMEM_SADDR_UVREF     ((volatile H264_COMPMEM_SADDR_UVREF_t *) 0xA0200014)
//#define p_H264_COMPMEM_SADDR_YCUR      ((volatile H264_COMPMEM_SADDR_YCUR_t  *) 0xA0200018)
//#define p_H264_COMPMEM_SADDR_UVCUR     ((volatile H264_COMPMEM_SADDR_UVCUR_t *) 0xA020001C)
#define p_H264_INTR_STALL              ((volatile H264_INTR_STALL_t 		     *) 0XA020001C)
#define p_H264_DEBUG                   ((volatile H264_DEBUG_t 			     *) 0xA0200020)
#define p_H264_FIFO                    ((volatile H264_FIFO_t 			     *) 0xA0200024)
#define p_H264_FIFO_DATACNT            ((volatile H264_FIFO_DATACNT_t 	     *) 0xA0200028)
#define p_H264_INTR_DONE               ((volatile H264_INTR_DONE_t 		     *) 0XA020002C)
#define p_H264_INTR_FIFO               ((volatile H264_INTR_FIFO_t 		     *) 0XA0200030)
#define p_H264_STATUS                  ((volatile H264_STATUS_t 			 *) 0xA0200034)
#define p_H264_MEM_START               ((volatile H264_MEM_START_t 		     *) 0xA0200038)
#define p_H264_MEM_END                 ((volatile H264_MEM_END_t 		     *) 0xA0201038)


//void h264_config(uint32_t saddr_cur_y, uint32_t saddr_cur_uv, uint8_t qp, uint8_t fls_direct);
//uint32_t h264_fetch_data(void);
//void h264_start(uint8_t x_idx, uint8_t y_idx);
//void h264_initialize(void);
////void h264_initialize(uint32_t saddr_cur_y, uint32_t saddr_cur_uv, uint8_t qp, unsigned fls_direct);
//
//void dbg_h264_enable(void);
//uint32_t dbg_h264_mem(uint32_t element_idx);
//uint32_t dbg_h264_ctrl_status(void);
//uint32_t dbg_h264_pred_status(void);
//uint32_t dbg_h264_tq_status(void);
//uint32_t dbg_h264_cavlc_status(void);
//uint32_t dbg_h264_left_mcb_valid(void);
//uint32_t dbg_h264_top_mcb_valid(void);
#endif // CMPV1_H264_H
