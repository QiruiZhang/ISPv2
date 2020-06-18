//************************************************************
// Desciption: CMPv1 NE Header File
//************************************************************

// **  define HEADER file
#ifndef CMPV1_NE_H
#define CMPV1_NE_H

#include <stdint.h>
#include <stdbool.h>

// NE_RESET_AND_ENABLE
typedef union NE_RESET_AND_ENABLE{
    struct{
       volatile unsigned enable       : 1;
       volatile unsigned reserv1      : 3;
       volatile unsigned resetn       : 1;
       volatile unsigned reserv2      : 27;
    };
    volatile uint32_t as_int;
} NE_RESET_AND_ENABLE_t;


// NE_START
typedef union NE_START{
    struct{
        volatile unsigned inst_start_addr : 9;
        volatile unsigned reserv          : 23;
    };
    volatile uint32_t as_int;
} NE_START_t;


// all NCX register types
typedef union NE_NCX_REGISTERS{
    struct{
        volatile unsigned val    : 16;
        volatile unsigned reserv : 16;
    };
    volatile uint32_t as_int;
} NE_NCX_REGISTERS_t;


// NE_CONF_AUTOGATE_PE
typedef union NE_CONF_AUTOGATE_PE{
    struct{
        volatile unsigned en     : 1;
        volatile unsigned reserv : 31;
    };
    volatile uint32_t as_int;
} NE_CONF_AUTOGATE_PE_t;


// NE_DBG_DEBUGMODE_PE
typedef union NE_DBG_DEBUGMODE_PE{
    struct{
        volatile unsigned en     : 1;
        volatile unsigned reserv : 31;
    };
    volatile uint32_t as_int;
} NE_DBG_DEBUGMODE_PE_t;


// NE_DBG_ADVANCE_PE_BY_CYCLES
typedef union NE_DBG_ADVANCE_PE_BY_CYCLES{
    struct{
        volatile unsigned num    : 16;
        volatile unsigned reserv : 16;
    };
    volatile uint32_t as_int;
} NE_DBG_ADVANCE_PE_BY_CYCLES_t;


// NE_PE_STATE_VARS_GROUP1
typedef union NE_PE_STATE_VARS_GROUP1{
    struct{
        volatile unsigned w_row_cnt                   : 4;
        volatile unsigned w_col_cnt                   : 4;
        volatile unsigned ia_row_pointer              : 4;
        volatile unsigned ia_col_pointer              : 4;
        volatile unsigned ia_fifo_ptr                 : 4;
        volatile unsigned ia_fifo_initialized         : 1;
        volatile unsigned ia_fifo_status              : 2;
        volatile unsigned ia_fifo_index               : 1;
        volatile unsigned instruction_oa_mem_buffer   : 1;
        volatile unsigned instruction_oa_mem_dir      : 1;
        volatile unsigned instruction_ia_mem_buffer_0 : 1;
        volatile unsigned instruction_ia_mem_dir_0    : 1;
        volatile unsigned instruction_opcdoe          : 4;
    };
    volatile uint32_t as_int;
} NE_PE_STATE_VARS_GROUP1_t;


// NE_PE_STATE_VARS_GROUP2
typedef union NE_PE_STATE_VARS_GROUP2{
    struct{
        volatile unsigned add_valid_inputs       : 4;
        volatile unsigned local_mem_write_status : 2;
        volatile unsigned local_mem_status       : 2;
        volatile unsigned pe_shared_mem_status   : 2;
        volatile unsigned shared_read_status_d   : 2;
        volatile unsigned shared_read_status     : 2;
        volatile unsigned PE_array_ia_col        : 4;
        volatile unsigned PE_array_ia_row        : 4;
        volatile unsigned PE_array_w_col         : 4;
        volatile unsigned PE_array_w_row         : 4;
        volatile unsigned reserv                 : 2;
    };
    volatile uint32_t as_int;
} NE_PE_STATE_VARS_GROUP2_t;


// NE_PE_STATE_VARS_GROUP3
typedef union NE_PE_STATE_VARS_GROUP3{
    struct{
        volatile unsigned write_padding : 8;
        volatile unsigned write_oc      : 8;
        volatile unsigned write_col     : 8;
        volatile unsigned write_row     : 8;
    };
    volatile uint32_t as_int;
} NE_PE_STATE_VARS_GROUP3_t;


// NE_PE_STATE_VARS_GROUP4
typedef union NE_PE_STATE_VARS_GROUP4{
    struct{
        volatile unsigned instruction_current_oc : 12;
        volatile unsigned instruction_current_ic : 12;
        volatile unsigned reserv                 : 8;
    };
    volatile uint32_t as_int;
} NE_PE_STATE_VARS_GROUP4_t;


// NE_PE_STATE_VARS_GROUP5
typedef union NE_PE_STATE_VARS_GROUP5{
    struct{
        volatile unsigned instruction_sparse_fc_mov       : 1;
        volatile unsigned instruction_sparse_fc_process   : 1;
        volatile unsigned instruction_sparse_fc_clean     : 1;
        volatile unsigned instruction_conv_clear_finished : 1;
        volatile unsigned instruction_conv_clear_addr     : 10;
        volatile unsigned instruction_ia_col_current      : 8;
        volatile unsigned instruction_ia_row_current      : 8;
        volatile unsigned reserv                          : 2;
    };
    volatile uint32_t as_int;
} NE_PE_STATE_VARS_GROUP5_t;


// NE_DECOMP_STATE_VARS_GROUP1
typedef union NE_DECOMP_STATE_VARS_GROUP1{
    struct{
        volatile unsigned loc                : 8;
        volatile unsigned packet_1_valid     : 1;
        volatile unsigned packet_0_valid     : 1;
        volatile unsigned w_0_or_idx_1       : 1;
        volatile unsigned subtree_num        : 5;
        volatile unsigned packet_end         : 1;
        volatile unsigned packet_ptr         : 7;
        volatile unsigned reserv             : 8;
    };
    volatile uint32_t as_int;
} NE_DECOMP_STATE_VARS_GROUP1_t;


// NE_DECOMP_STATE_VARS_GROUP2
typedef union NE_DECOMP_STATE_VARS_GROUP2{
    struct{
        volatile unsigned processing_bits : 16;
        volatile unsigned packet_col      : 8;
        volatile unsigned packet_row      : 8;
    };
    volatile uint32_t as_int;
} NE_DECOMP_STATE_VARS_GROUP2_t;




// for easier debugging for programmer
typedef struct NE_DBG_STATE{
    NE_PE_STATE_VARS_GROUP1_t     pe_g1;
    NE_PE_STATE_VARS_GROUP2_t     pe_g2;
    NE_PE_STATE_VARS_GROUP3_t     pe_g3;
    NE_PE_STATE_VARS_GROUP4_t     pe_g4;
    NE_PE_STATE_VARS_GROUP5_t     pe_g5;
    NE_DECOMP_STATE_VARS_GROUP1_t decomp_g1;
    NE_DECOMP_STATE_VARS_GROUP2_t decomp_g2;
} NE_DBG_STATE_t;




//-----------------------------------------------------------------------------//


// Declaration
#define   p_NE_RESET_AND_ENABLE         ((volatile NE_RESET_AND_ENABLE_t        *) 0xA0100000)
#define   p_NE_START                    ((volatile NE_START_t                   *) 0xA0100004)
#define   p_NE_CONF_FRAMEMEM_BASEADDR   ((volatile uint32_t                     *) 0xA0100008)
#define   p_NE_NCX_REGISTERS_R0         ((volatile NE_NCX_REGISTERS_t           *) 0xA010000C)
#define   p_NE_NCX_REGISTERS_R1         ((volatile NE_NCX_REGISTERS_t           *) 0xA0100010)
#define   p_NE_NCX_REGISTERS_R2         ((volatile NE_NCX_REGISTERS_t           *) 0xA0100014)
#define   p_NE_NCX_REGISTERS_R3         ((volatile NE_NCX_REGISTERS_t           *) 0xA0100018)
#define   p_NE_NCX_REGISTERS_R4         ((volatile NE_NCX_REGISTERS_t           *) 0xA010001C)
#define   p_NE_NCX_REGISTERS_R5         ((volatile NE_NCX_REGISTERS_t           *) 0xA0100020)
#define   p_NE_NCX_REGISTERS_R6         ((volatile NE_NCX_REGISTERS_t           *) 0xA0100024)
#define   p_NE_NCX_REGISTERS_R7         ((volatile NE_NCX_REGISTERS_t           *) 0xA0100028)
#define   p_NE_NCX_REGISTERS_R8         ((volatile NE_NCX_REGISTERS_t           *) 0xA010002C)
#define   p_NE_NCX_REGISTERS_R9         ((volatile NE_NCX_REGISTERS_t           *) 0xA0100030)
#define   p_NE_NCX_REGISTERS_R10        ((volatile NE_NCX_REGISTERS_t           *) 0xA0100034)
#define   p_NE_NCX_REGISTERS_R11        ((volatile NE_NCX_REGISTERS_t           *) 0xA0100038)
#define   p_NE_NCX_REGISTERS_R12        ((volatile NE_NCX_REGISTERS_t           *) 0xA010003C)
#define   p_NE_NCX_REGISTERS_R13        ((volatile NE_NCX_REGISTERS_t           *) 0xA0100040)
#define   p_NE_NCX_REGISTERS_R14        ((volatile NE_NCX_REGISTERS_t           *) 0xA0100044)
#define   p_NE_NCX_REGISTERS_R15        ((volatile NE_NCX_REGISTERS_t           *) 0xA0100048)
#define   p_NE_NCX_REGISTERS_R16        ((volatile NE_NCX_REGISTERS_t           *) 0xA010004C)
#define   p_NE_NCX_REGISTERS_R17        ((volatile NE_NCX_REGISTERS_t           *) 0xA0100050)
#define   p_NE_NCX_REGISTERS_R18        ((volatile NE_NCX_REGISTERS_t           *) 0xA0100054)
#define   p_NE_NCX_REGISTERS_R19        ((volatile NE_NCX_REGISTERS_t           *) 0xA0100058)
#define   p_NE_NCX_REGISTERS_R20        ((volatile NE_NCX_REGISTERS_t           *) 0xA010005C)
#define   p_NE_NCX_REGISTERS_R21        ((volatile NE_NCX_REGISTERS_t           *) 0xA0100060)
#define   p_NE_NCX_REGISTERS_R22        ((volatile NE_NCX_REGISTERS_t           *) 0xA0100064)
#define   p_NE_NCX_REGISTERS_R23        ((volatile NE_NCX_REGISTERS_t           *) 0xA0100068)
#define   p_NE_CONF_AUTOGATE_PE         ((volatile NE_CONF_AUTOGATE_PE_t        *) 0xA010006C)
#define   p_NE_DBG_DEBUGMODE_PE         ((volatile NE_DBG_DEBUGMODE_PE_t        *) 0xA0100070)
#define   p_NE_DBG_ADVANCE_PE_BY_CYCLES ((volatile NE_DBG_ADVANCE_PE_BY_CYCLES_t*) 0xA0100074)
#define   p_NE_PE_STATE_VARS_GROUP1     ((volatile NE_PE_STATE_VARS_GROUP1_t    *) 0xA0100078)
#define   p_NE_PE_STATE_VARS_GROUP2     ((volatile NE_PE_STATE_VARS_GROUP2_t    *) 0xA010007C)
#define   p_NE_PE_STATE_VARS_GROUP3     ((volatile NE_PE_STATE_VARS_GROUP3_t    *) 0xA0100080)
#define   p_NE_PE_STATE_VARS_GROUP4     ((volatile NE_PE_STATE_VARS_GROUP4_t    *) 0xA0100084)
#define   p_NE_PE_STATE_VARS_GROUP5     ((volatile NE_PE_STATE_VARS_GROUP5_t    *) 0xA0100088)
#define   p_NE_DECOMP_STATE_VARS_GROUP1 ((volatile NE_DECOMP_STATE_VARS_GROUP1_t*) 0xA010008C)
#define   p_NE_DECOMP_STATE_VARS_GROUP2 ((volatile NE_DECOMP_STATE_VARS_GROUP2_t*) 0xA0100090)
#define   p_NE_INTERRUPT_STATUS         ((volatile uint32_t                     *) 0xA01000FC)

#define   p_NE_IMEM_START               ((volatile uint32_t                     *) 0xA0100100)
#define   p_NE_SHARED_MEM_START         ((volatile uint32_t                     *) 0xA0104100)
#define   p_NE_PE_LOCALMEM_START        ((volatile uint32_t                     *) 0xA01C4100)
#define   p_NE_PE_WEIGHTBUF_START       ((volatile uint32_t                     *) 0xA01CC100)
#define   p_NE_PE_ACCUMULATORS_START    ((volatile uint32_t                     *) 0xA01D4100)
#define   p_NE_PE_BIAS_BUFFER_START     ((volatile uint32_t                     *) 0xA01D6100)


// starting addrs for the different networks
#define NE_PERSON_DETECTION_IMEM_START_ADDR  2
#define NE_FACE_DETECTION_IMEM_START_ADDR    0
//#define NE_RESIZE_IMEM_START_ADDR
//#define NE_FACE_RECOGNITION_IMEM_START_ADDR 



// see libs/CMPv1_NE.c for implementations
void ne_set_frame_mem_addr(uint32_t frame_mem_addr);
volatile uint32_t ne_get_frame_mem_addr();
void ne_softreset();
void ne_enable();
void ne_set_clockgated();
NE_RESET_AND_ENABLE_t ne_get_reset_and_enable();
void ne_start(uint16_t inst_addr);
void ne_clear_interrupt();
volatile uint16_t ne_get_ncx_register(uint8_t reg);
void ne_set_ncx_register(uint8_t reg, uint16_t val);
volatile uint8_t ne_get_conf_autogate_pe();
void ne_set_conf_autogate_pe(uint8_t en);
volatile uint8_t dbg_ne_get_debugmode();
void dbg_ne_set_debugmode(uint8_t en);
void dbg_ne_advance(uint16_t cycles);
NE_DBG_STATE_t dbg_ne_get_state();
void ne_imem_write(uint16_t addr, uint32_t data);
volatile uint32_t ne_imem_read(uint16_t addr);
void ne_sharedmem_write(uint32_t addr, uint32_t data);
volatile uint32_t ne_sharedmem_read(uint16_t addr);
void dbg_ne_pe_localmem_write(uint16_t addr, uint32_t data);
volatile uint32_t dbg_ne_pe_localmem_read(uint16_t addr);
void dbg_ne_pe_weightbuf_write(uint16_t addr, uint32_t data);
volatile uint32_t dbg_ne_pe_weightbuf_read(uint16_t addr);
void dbg_ne_pe_accumulators_write(uint16_t addr, uint32_t data);
volatile uint32_t dbg_ne_pe_accumulators_read(uint16_t addr);
void dbg_ne_pe_bias_buffer_write(uint16_t addr, uint32_t data);
volatile uint32_t dbg_ne_pe_bias_buffer_read(uint16_t addr);
void ne_load_md_frame(volatile uint32_t md_frame_arr[][20], uint32_t base_dest);




#endif // CMPV1_NE_H
