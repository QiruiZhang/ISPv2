//************************************************************
// Desciption: CMPv1 FLS Header File
//************************************************************

// **  define HEADER file
#ifndef CMPV1_FLSIF_H
#define CMPV1_FLSIF_H

#include <stdint.h>
// ** Below is fetched from FLSIF_SFRMAP.sv  => it will be translated
//localparam FLSIF_ENABLE=8'h00; 
//localparam FLSIF_STATUS=8'h01;
//localparam FLSIF_CONFIG=8'h02; 
//localparam FLSIF_FIFO  =8'h03;
//localparam FLSIF_INTR  =8'h04;
//FLSIF_ENABLE:begin o_ready = 1'b1; o_hrdata = {24'b0,3'b0,o_flsif_en,3'b0,softreset};end      
//FLSIF_STATUS:begin o_ready = 1'b1; o_hrdata = {31'b0,i_state_fsm};end
//FLSIF_CONFIG:begin o_ready = 1'b1; o_hrdata = {28'b0,o_flsif_ch,2'b0,o_flsif_biten};end 
//FLSIF_FIFO  :begin o_ready = ready_fifo; end
//FLSIF_INTR  :begin o_ready = 1'b1; end
                      
// Register 0x00 
typedef union FLSIF_ENABLE{
  struct{
    unsigned softreset		:  1;
    unsigned reserv1		:  3;
    unsigned flsif_en		:  1;
    unsigned reserv2  		: 27;
  };
  uint32_t as_int;
} FLSIF_ENABLE_t;

// Register 0x04 
typedef union FLSIF_STATUS{
  struct{
    unsigned status 		:  1;
    unsigned reserv1 		:  31;
  };
  uint32_t as_int;
} FLSIF_STATUS_t;

// Register 0x08 
typedef union FLSIF_CONFIG{
  struct{
    unsigned flsif_biten	:  2;
    unsigned reserv1		:  2;
    unsigned flsif_ch		:  2;
    unsigned reserv2 		: 26;
  };
  uint32_t as_int;
} FLSIF_CONFIG_t;

// Register 0x0C 
typedef union FLSIF_FIFO{
  uint32_t as_int;
} FLSIF_FIFO_t;

// Register 0x10 
typedef union FLSIF_INTR{
  struct{
    unsigned deassert		:  1;
    unsigned reserv1 		:  31;
  };
  uint32_t as_int;
} FLSIF_INTR_t;

// Declaration
#define p_FLSIF_ENABLE ((volatile FLSIF_ENABLE_t *) 0xA0500000)
#define p_FLSIF_STATUS ((volatile FLSIF_STATUS_t *) 0xA0500004)
#define p_FLSIF_CONFIG ((volatile FLSIF_CONFIG_t *) 0xA0500008)
#define p_FLSIF_FIFO   ((volatile FLSIF_FIFO_t   *) 0xA050000C)
#define p_FLSIF_INTR   ((volatile FLSIF_INTR_t   *) 0XA0500010)

void flsif_config(uint8_t flsif_biten, uint8_t flsif_ch);
void flsif_senddata(uint32_t data);
void flsif_initialize(uint8_t flsif_biten, uint8_t flsif_ch);

#endif // CMPV1_RF_H
