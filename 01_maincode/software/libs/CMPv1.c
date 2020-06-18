//*******************************************************************
//Author: Hyochan An
//Description: CMPv1 lib file
//*******************************************************************

#include "CMPv1.h"
#include "mbus.h"

//*******************************************************************
// OTHER FUNCTIONS
//*******************************************************************

void delay(unsigned ticks){
  unsigned i;
  for (i=0; i < ticks; i++)
    asm("nop;");
}

void WFI(){
  asm("wfi;");
}
//**************************************************
// M0 IRQ SETTING
//**************************************************
void enable_all_irq() { *NVIC_ICPR = 0xFFFFFFFF; *NVIC_ISER = 0xFFFFFFFF; }
void enable_irq(uint32_t code) { *NVIC_ICPR = 0xFFFFFFFF; *NVIC_ISER = code; }
void disable_all_irq() { *NVIC_ICPR = 0xFFFFFFFF; *NVIC_ICER = 0xFFFFFFFF; }
void clear_all_pend_irq() { *NVIC_ICPR = 0xFFFFFFFF; }

//**************************************************
// PRC/PRE FLAGS Register
//**************************************************
//uint32_t set_flag ( uint32_t bit_idx, uint32_t value ) {
//    uint32_t reg_val = (*REG_FLAGS & (~(0x1 << bit_idx))) | (value << bit_idx);
//    *REG_FLAGS = reg_val;
//    return reg_val;
//}
//    
//uint8_t get_flag ( uint32_t bit_idx ) {
//    uint8_t reg_val = (*REG_FLAGS & (0x1 << bit_idx)) >> bit_idx;
//    return reg_val;
//}

//**************************************************
// MBUS IRQ SETTING
//**************************************************
//void set_halt_until_reg(uint32_t reg_id) { *SREG_CONF_HALT = reg_id; }
//void set_halt_until_mem_wr(void) { *SREG_CONF_HALT = HALT_UNTIL_MEM_WR; }
//void set_halt_until_mbus_rx(void) { *SREG_CONF_HALT = HALT_UNTIL_MBUS_RX; }
//void set_halt_until_mbus_tx(void) { *SREG_CONF_HALT = HALT_UNTIL_MBUS_TX; }
//void set_halt_until_mbus_trx(void) { *SREG_CONF_HALT = HALT_UNTIL_MBUS_TRX; }
//void set_halt_until_mbus_fwd(void) { *SREG_CONF_HALT = HALT_UNTIL_MBUS_FWD; }
//void set_halt_disable(void) { *SREG_CONF_HALT = HALT_DISABLE; }
//void set_halt_config(uint8_t new_config) { *SREG_CONF_HALT = new_config; }
//uint8_t get_current_halt_config(void) { return (uint8_t) *SREG_CONF_HALT; }
//void halt_cpu (void) { *SCTR_REG_HALT_ADDR = SCTR_CMD_HALT_CPU; }

//*******************************************************************
// RF functions
//*******************************************************************
void rf_write (uint32_t id, uint32_t data) { 
	//*CMPv1_FUID_CMDLEN//lower4bit: FUID(0:Write to RF, 1: Read from RF)//high2bit:cmd_length
	*CMPv1_FUID_CMDLEN=0x10;
	*CMPv1_CMD=0x0; //third
	*CMPv1_CMD=0x0; //second
	*CMPv1_CMD=(id<<24)|(data & 0xFFFFFF); //first
}

uint32_t rf_read (uint32_t id) { 
	return *((uint32_t *)(CMPv1_R00+id));
}

void rf_send (uint8_t rf_ssaddr, uint8_t rf_len_1, uint8_t target_prefix, uint8_t target_addr) { 
	//*CMPv1_FUID_CMDLEN//lower4bit: FUID(0:Write to RF, 1: Read from RF)//high2bit:cmd_length
	*CMPv1_FUID_CMDLEN=0x11;
	*CMPv1_CMD=0x0; //third
	*CMPv1_CMD=0x0; //second
	//*CMPv1_CMD=(4<<36)|(1<<32)|(rf_ssaddr<<24)|(rf_len<<16)|(target_prefix<<8)|(target_addr<<0); //Prefix,FUID//startaddress,lenght//MBUSaddress,address2writeon//
	*CMPv1_CMD=(rf_ssaddr<<24)|(rf_len_1<<16)|(target_prefix<<8)|(target_addr<<0); //Prefix,FUID//startaddress,lenght//MBUSaddress,address2writeon//
}
//*******************************************************************
// VERIOLG SIM DEBUG PURPOSE ONLY!!
//*******************************************************************
void arb_debug_reg (uint8_t id, uint32_t code) { 
    uint32_t temp_addr = 0xBFFF0000 | (id << 2);
    *((volatile uint32_t *) temp_addr) = code;
}
void arb_debug_ascii (uint8_t id, char* code) { 
    uint32_t temp_addr = 0xBFFF0000 | (id << 2);
    *((volatile uint32_t *) temp_addr) = (code[0]<<24)|(code[1]<<16)|(code[2]<<8)|(code[3]);
}
