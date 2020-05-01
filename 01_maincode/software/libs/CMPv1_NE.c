#include "CMPv1_NE.h"

void ne_mem_access(void){
	ne_enable();
	ne_set_conf_autogate_pe(0);
}

// sets the frame mem's base mmap addr for fetching McB's
void ne_set_frame_mem_addr(uint32_t frame_mem_addr){
    *p_NE_CONF_FRAMEMEM_BASEADDR = frame_mem_addr;
}

// get frame mem addr
volatile uint32_t ne_get_frame_mem_addr(){
    return *p_NE_CONF_FRAMEMEM_BASEADDR;
}


// turns on softreset for NE logic, but not its SRAMs
// (to reset FSMs but keep weights, etc.)
void ne_softreset(){
    p_NE_RESET_AND_ENABLE->resetn = 0;
}


// disables resets and opens clock gate
void ne_enable(){
    p_NE_RESET_AND_ENABLE->as_int = 0x00000011;
}


// enables clock gate without resetting NE
void ne_set_clockgated(){
    p_NE_RESET_AND_ENABLE->as_int = 0x00000010;
}


// read current enable status
NE_RESET_AND_ENABLE_t ne_get_reset_and_enable(){
    return *p_NE_RESET_AND_ENABLE;
}


// start NE at instruction #
void ne_start(uint16_t inst_addr){
    p_NE_START->as_int = (inst_addr & 0x01FF);
}


// reset NE's interrupt flag
void ne_clear_interrupt(){
    *p_NE_INTERRUPT_STATUS = 0;
}





void ne_load_md_frame(volatile uint32_t md_frame_arr[][20], uint32_t base_dest){

    uint32_t temp0, temp1, r;

    for(r=0; r<32; r++) {
        temp0 = 0;
        temp0 |= (  md_frame_arr[r][0] & 0xFF       );
        temp0 |= ( (md_frame_arr[r][1] & 0xFF) << 8 );
        temp0 |= ( (md_frame_arr[r][2] & 0xFF) << 16);
        temp0 |= ( (md_frame_arr[r][3] & 0xFF) << 24);
        temp1 = 0;
        temp1 |= (  md_frame_arr[r][4] & 0xFF       );
        temp1 |= ( (md_frame_arr[r][5] & 0xFF) << 8 );
        temp1 |= ( (md_frame_arr[r][6] & 0xFF) << 16);
        temp1 |= ( (md_frame_arr[r][7] & 0xFF) << 24);
        ne_sharedmem_write(base_dest + (r*16) + 0, temp0);
        ne_sharedmem_write(base_dest + (r*16) + 1, temp1);
        ne_sharedmem_write(base_dest + (r*16) + 2, 0);
        ne_sharedmem_write(base_dest + (r*16) + 3, 0);

        temp0 = 0;
        temp0 |= (  md_frame_arr[r][8] & 0xFF       );
        temp0 |= ( (md_frame_arr[r][9] & 0xFF) << 8 );
        temp0 |= ( (md_frame_arr[r][10] & 0xFF) << 16);
        temp0 |= ( (md_frame_arr[r][11] & 0xFF) << 24);
        temp1 = 0;
        temp1 |= (  md_frame_arr[r][12] & 0xFF       );
        temp1 |= ( (md_frame_arr[r][13] & 0xFF) << 8 );
        temp1 |= ( (md_frame_arr[r][14] & 0xFF) << 16);
        temp1 |= ( (md_frame_arr[r][15] & 0xFF) << 24);
        ne_sharedmem_write(base_dest + (r*16) + 4, temp0);
        ne_sharedmem_write(base_dest + (r*16) + 5, temp1);
        ne_sharedmem_write(base_dest + (r*16) + 6, 0);
        ne_sharedmem_write(base_dest + (r*16) + 7, 0);

        temp0 = 0;
        temp0 |= (  md_frame_arr[r][16] & 0xFF       );
        temp0 |= ( (md_frame_arr[r][17] & 0xFF) << 8 );
        temp0 |= ( (md_frame_arr[r][18] & 0xFF) << 16);
        temp0 |= ( (md_frame_arr[r][19] & 0xFF) << 24);
        ne_sharedmem_write(base_dest + (r*16) + 8,  temp0);
        ne_sharedmem_write(base_dest + (r*16) + 9,  0);
        ne_sharedmem_write(base_dest + (r*16) + 10, 0);
        ne_sharedmem_write(base_dest + (r*16) + 11, 0);
        ne_sharedmem_write(base_dest + (r*16) + 12, 0);
        ne_sharedmem_write(base_dest + (r*16) + 13, 0);
        ne_sharedmem_write(base_dest + (r*16) + 14, 0);
        ne_sharedmem_write(base_dest + (r*16) + 15, 0);
    }
}





// all NCX register reads
volatile uint16_t ne_get_ncx_register(uint8_t reg){
    switch(reg){
        case 0:
            return p_NE_NCX_REGISTERS_R0->val;
        case 1:
            return p_NE_NCX_REGISTERS_R1->val;
        case 2:
            return p_NE_NCX_REGISTERS_R2->val;
        case 3:
            return p_NE_NCX_REGISTERS_R3->val;
        case 4:
            return p_NE_NCX_REGISTERS_R4->val;
        case 5:
            return p_NE_NCX_REGISTERS_R5->val;
        case 6:
            return p_NE_NCX_REGISTERS_R6->val;
        case 7:
            return p_NE_NCX_REGISTERS_R7->val;
        case 8:
            return p_NE_NCX_REGISTERS_R8->val;
        case 9:
            return p_NE_NCX_REGISTERS_R9->val;
        case 10:
            return p_NE_NCX_REGISTERS_R10->val;
        case 11:
            return p_NE_NCX_REGISTERS_R11->val;
        case 12:
            return p_NE_NCX_REGISTERS_R12->val;
        case 13:
            return p_NE_NCX_REGISTERS_R13->val;
        case 14:
            return p_NE_NCX_REGISTERS_R14->val;
        case 15:
            return p_NE_NCX_REGISTERS_R15->val;
        case 16:
            return p_NE_NCX_REGISTERS_R16->val;
        case 17:
            return p_NE_NCX_REGISTERS_R17->val;
        case 18:
            return p_NE_NCX_REGISTERS_R18->val;
        case 19:
            return p_NE_NCX_REGISTERS_R19->val;
        case 20:
            return p_NE_NCX_REGISTERS_R20->val;
        case 21:
            return p_NE_NCX_REGISTERS_R21->val;
        case 22:
            return p_NE_NCX_REGISTERS_R22->val;
        case 23:
            return p_NE_NCX_REGISTERS_R23->val;
        default:
            // ERROR!!!!
            return 0xFFFF;
    }
} 


// all NCX register writes
void ne_set_ncx_register(uint8_t reg, uint16_t val){
    switch(reg){
        case 0:
            p_NE_NCX_REGISTERS_R0->val = val;
            break;
        case 1:
            p_NE_NCX_REGISTERS_R1->val = val;
            break;
        case 2:
            p_NE_NCX_REGISTERS_R2->val = val;
            break;
        case 3:
            p_NE_NCX_REGISTERS_R3->val = val;
            break;
        case 4:
            p_NE_NCX_REGISTERS_R4->val = val;
            break;
        case 5:
            p_NE_NCX_REGISTERS_R5->val = val;
            break;
        case 6:
            p_NE_NCX_REGISTERS_R6->val = val;
            break;
        case 7:
            p_NE_NCX_REGISTERS_R7->val = val;
            break;
        case 8:
            p_NE_NCX_REGISTERS_R8->val = val;
            break;
        case 9:
            p_NE_NCX_REGISTERS_R9->val = val;
            break;
        case 10:
            p_NE_NCX_REGISTERS_R10->val = val;
            break;
        case 11:
            p_NE_NCX_REGISTERS_R11->val = val;
            break;
        case 12:
            p_NE_NCX_REGISTERS_R12->val = val;
            break;
        case 13:
            p_NE_NCX_REGISTERS_R13->val = val;
            break;
        case 14:
            p_NE_NCX_REGISTERS_R14->val = val;
            break;
        case 15:
            p_NE_NCX_REGISTERS_R15->val = val;
            break;
        case 16:
            p_NE_NCX_REGISTERS_R16->val = val;
            break;
        case 17:
            p_NE_NCX_REGISTERS_R17->val = val;
            break;
        case 18:
            p_NE_NCX_REGISTERS_R18->val = val;
            break;
        case 19:
            p_NE_NCX_REGISTERS_R19->val = val;
            break;
        case 20:
            p_NE_NCX_REGISTERS_R20->val = val;
            break;
        case 21:
            p_NE_NCX_REGISTERS_R21->val = val;
            break;
        case 22:
            p_NE_NCX_REGISTERS_R22->val = val;
            break;
        case 23:
            p_NE_NCX_REGISTERS_R23->val = val;
            break;
        default:
            // ERROR!!!
            break;
    }
}



// get and set for PE auto clock gating mode
//--------------
volatile uint8_t ne_get_conf_autogate_pe(){
    return (volatile uint8_t) p_NE_CONF_AUTOGATE_PE->en;
}

void ne_set_conf_autogate_pe(uint8_t en){
    p_NE_CONF_AUTOGATE_PE->en = (en & 0x01);
}


// debug mode control
//--------------
volatile uint8_t dbg_ne_get_debugmode(){
    return (volatile uint8_t) p_NE_DBG_DEBUGMODE_PE->en;
}

void dbg_ne_set_debugmode(uint8_t en){
    p_NE_DBG_DEBUGMODE_PE->en = (en & 0x01);
}


// cycles to advance before sleeping again while in debug mode
void dbg_ne_advance(uint16_t cycles){
    p_NE_DBG_ADVANCE_PE_BY_CYCLES->num = cycles;
}


// get all debugmode state variables
NE_DBG_STATE_t dbg_ne_get_state(){
    NE_DBG_STATE_t state;
    state.pe_g1 = *p_NE_PE_STATE_VARS_GROUP1;
    state.pe_g2 = *p_NE_PE_STATE_VARS_GROUP2;
    state.pe_g3 = *p_NE_PE_STATE_VARS_GROUP3;
    state.pe_g4 = *p_NE_PE_STATE_VARS_GROUP4;
    state.pe_g5 = *p_NE_PE_STATE_VARS_GROUP5;
    state.decomp_g1 = *p_NE_DECOMP_STATE_VARS_GROUP1;
    state.decomp_g2 = *p_NE_DECOMP_STATE_VARS_GROUP2;
    return state;
}



//-----------------------------------------------------------------//



/////////////////////////////////////
/////      !! WARNING !!      ///////
/////////////////////////////////////
// These functions do not do any   //
// bounds checks, so too high of   //
// an address to, e.g., imem could //
// actually end up being an addr   //
// in shared mem!                  //
/////////////////////////////////////

void ne_imem_write(uint16_t addr, uint32_t data){
    *((volatile uint32_t *)(p_NE_IMEM_START+addr)) = data;
}
volatile uint32_t ne_imem_read(uint16_t addr){
    return *((volatile uint32_t *)(p_NE_IMEM_START+addr));
}

void ne_sharedmem_write(uint32_t addr, uint32_t data){
    *((volatile uint32_t *)(p_NE_SHARED_MEM_START+addr)) = data;
}
volatile uint32_t ne_sharedmem_read(uint16_t addr){
    return *((volatile uint32_t *)(p_NE_SHARED_MEM_START+addr));
}

void dbg_ne_pe_localmem_write(uint16_t addr, uint32_t data){
    *((volatile uint32_t *)(p_NE_PE_LOCALMEM_START+addr)) = data;
}
volatile uint32_t dbg_ne_pe_localmem_read(uint16_t addr){
    return *((volatile uint32_t *)(p_NE_PE_LOCALMEM_START+addr));
}

void dbg_ne_pe_weightbuf_write(uint16_t addr, uint32_t data){
    *((volatile uint32_t *)(p_NE_PE_WEIGHTBUF_START+addr)) = data;
}
volatile uint32_t dbg_ne_pe_weightbuf_read(uint16_t addr){
    return *((volatile uint32_t *)(p_NE_PE_WEIGHTBUF_START+addr));
}

void dbg_ne_pe_accumulators_write(uint16_t addr, volatile uint32_t data){
    *((volatile uint32_t *)(p_NE_PE_ACCUMULATORS_START+addr)) = data;
}
volatile uint32_t dbg_ne_pe_accumulators_read(uint16_t addr){
    return *((volatile uint32_t *)(p_NE_PE_ACCUMULATORS_START+addr));
}

void dbg_ne_pe_bias_buffer_write(uint16_t addr, uint32_t data){
    *((volatile uint32_t *)(p_NE_PE_BIAS_BUFFER_START+addr)) = data;
}
volatile uint32_t dbg_ne_pe_bias_buffer_read(uint16_t addr){
    return *((volatile uint32_t *)(p_NE_PE_BIAS_BUFFER_START+addr));
}



