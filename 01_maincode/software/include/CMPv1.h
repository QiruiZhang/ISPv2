//*******************************************************************
//Author: Hyochan An
//Description: CMPv1 header file
//*******************************************************************

#ifndef CMPV1_H
#define CMPV1_H
#define CMPv1

//*********************************************************
// Boolean Constants
//*********************************************************
#define TRUE  1
#define FALSE 0

//*********************************************************
// GOC Data Address
//*********************************************************
#define GOC_DATA_IRQ ((volatile uint32_t *) 0x8C)

//*********************************************************
// Reserved IRQ Address
//*********************************************************
#define IRQ14VEC        ((volatile uint32_t *) 0x00000078)
#define IRQ16VEC        ((volatile uint32_t *) 0x00000080)
#define IRQ17VEC        ((volatile uint32_t *) 0x00000084)

//*********************************************************
// M0 Interrupts
//---------------------------------------------------------
// NOTE: These values must be consistent with files below:
//       vectors.s, CMPv1.v, CMPv1_debug.v
//*********************************************************
#define IRQ_SOFT_RESET 0
#define IRQ_MBUS_MEM   1
#define IRQ_REG0       2
#define IRQ_REG1       3
#define IRQ_REG2       4
#define IRQ_REG3       5
#define IRQ_REG4       6
#define IRQ_REG5       7
#define IRQ_REG6       8
#define IRQ_REG7       9 
#define IRQ_MBUS_FWD  10
#define IRQ_MBUS_RX   11
#define IRQ_MBUS_TX   12
#define IRQ_MD        13
#define IRQ_VGA       14
#define IRQ_NE        15
#define IRQ_FLS       16
#define IRQ_H264      17
#define IRQ_H264_FIFORDY 18
#define IRQ_H264_STALL   19

//*********************************************************
// ARMv6 Architecture NVIC Registers
//*********************************************************
#define NVIC_ISER       ((volatile uint32_t *) 0xE000E100)  // Interrupt Set-Enable Register
#define NVIC_ICER       ((volatile uint32_t *) 0xE000E180)  // Interrupt Clear-Enable Register
#define NVIC_ISPR       ((volatile uint32_t *) 0xE000E200)  // Interrupt Set-Pending Register
#define NVIC_ICPR       ((volatile uint32_t *) 0xE000E280)  // Interrupt Clear-Pending Register
#define NVIC_IPR0       ((volatile uint32_t *) 0xE000E400)  // Interrupt Priority Register
#define NVIC_IPR1       ((volatile uint32_t *) 0xE000E404)  // Interrupt Priority Register
#define NVIC_IPR2       ((volatile uint32_t *) 0xE000E408)  // Interrupt Priority Register
#define NVIC_IPR3       ((volatile uint32_t *) 0xE000E40C)  // Interrupt Priority Register
#define NVIC_IPR4       ((volatile uint32_t *) 0xE000E410)  // Interrupt Priority Register
#define NVIC_IPR5       ((volatile uint32_t *) 0xE000E414)  // Interrupt Priority Register
#define NVIC_IPR6       ((volatile uint32_t *) 0xE000E418)  // Interrupt Priority Register
#define NVIC_IPR7       ((volatile uint32_t *) 0xE000E41C)  // Interrupt Priority Register

//*********************************************************
// ARMv6 Architecture System Control and ID Registers
//*********************************************************
#define SCID_ACTLR      ((volatile uint32_t *) 0xE000E008)  // The Auxiliary Control Register
#define SCID_CPUID      ((volatile uint32_t *) 0xE000ED00)  // CPUID Base Register
#define SCID_ICSR       ((volatile uint32_t *) 0xE000ED04)  // Interrupt Control State Register
#define SCID_VTOR       ((volatile uint32_t *) 0xE000ED08)  // Vector Table Offset Register
#define SCID_AIRCR      ((volatile uint32_t *) 0xE000ED0C)  // Application Interrupt and Reset Control Register
#define SCID_SCR        ((volatile uint32_t *) 0xE000ED10)  // Optional System Control Register
#define SCID_CCR        ((volatile uint32_t *) 0xE000ED14)  // Configuration and Control Register
#define SCID_SHPR2      ((volatile uint32_t *) 0xE000ED1C)  // System Handler Priority Register 2
#define SCID_SHPR3      ((volatile uint32_t *) 0xE000ED20)  // System Handler Priority Register 3
#define SCID_SHCSR      ((volatile uint32_t *) 0xE000ED24)  // System Handler Control and State Regsiter
#define SCID_DFSR       ((volatile uint32_t *) 0xE000ED30)  // Debug Fault Status Register


//*********************************************************
// INCLUDES...
//*********************************************************
#include <stdint.h>
#include <stdbool.h>
#include "CMPv1_RF.h"

//*********************************************************
// Register File MMIO Addresses
//*********************************************************
#define CMPv1_R00      ((volatile cmpv1_r00_t *) 0xA0300000)/*{{{*/
#define CMPv1_R01      ((volatile cmpv1_r01_t *) 0xA0300004)
#define CMPv1_R02      ((volatile cmpv1_r02_t *) 0xA0300008)
#define CMPv1_R03      ((volatile cmpv1_r03_t *) 0xA030000c)
#define CMPv1_R04      ((volatile cmpv1_r04_t *) 0xA0300010)
#define CMPv1_R05      ((volatile cmpv1_r05_t *) 0xA0300014)
#define CMPv1_R06      ((volatile cmpv1_r06_t *) 0xA0300018)
#define CMPv1_R07      ((volatile cmpv1_r07_t *) 0xA030001c)
#define CMPv1_R08      ((volatile cmpv1_r08_t *) 0xA0300020)
#define CMPv1_R09      ((volatile cmpv1_r09_t *) 0xA0300024)
#define CMPv1_R0A      ((volatile cmpv1_r0A_t *) 0xA0300028)
#define CMPv1_R0B      ((volatile cmpv1_r0B_t *) 0xA030002c)
#define CMPv1_R0C      ((volatile cmpv1_r0C_t *) 0xA0300030)
#define CMPv1_R0D      ((volatile cmpv1_r0D_t *) 0xA0300034)
#define CMPv1_R0E      ((volatile cmpv1_r0E_t *) 0xA0300038)
#define CMPv1_R0F      ((volatile cmpv1_r0F_t *) 0xA030003c)
#define CMPv1_R10      ((volatile cmpv1_r10_t *) 0xA0300040)
#define CMPv1_R11      ((volatile cmpv1_r11_t *) 0xA0300044)
#define CMPv1_R12      ((volatile cmpv1_r12_t *) 0xA0300048)
#define CMPv1_R13      ((volatile cmpv1_r13_t *) 0xA030004c)
#define CMPv1_R14      ((volatile cmpv1_r14_t *) 0xA0300050)
#define CMPv1_R15      ((volatile cmpv1_r15_t *) 0xA0300054)
#define CMPv1_R16      ((volatile cmpv1_r16_t *) 0xA0300058)
#define CMPv1_R17      ((volatile cmpv1_r17_t *) 0xA030005c)
//#define CMPv1_R18      ((volatile cmpv1_r18_t *) 0xA0300060)
//#define CMPv1_R19      ((volatile cmpv1_r19_t *) 0xA0300064)
//#define CMPv1_R1A      ((volatile cmpv1_r1A_t *) 0xA0300068)
//#define CMPv1_R1B      ((volatile cmpv1_r1B_t *) 0xA030006c)
//#define CMPv1_R1C      ((volatile cmpv1_r1C_t *) 0xA0300070)
//#define CMPv1_R1D      ((volatile cmpv1_r1D_t *) 0xA0300074)
//#define CMPv1_R1E      ((volatile cmpv1_r1E_t *) 0xA0300078)
//#define CMPv1_R1F      ((volatile cmpv1_r1F_t *) 0xA030007c)
#define CMPv1_R20      ((volatile cmpv1_r20_t *) 0xA0300080)
//#define CMPv1_R21      ((volatile cmpv1_r21_t *) 0xA0300084)
//#define CMPv1_R22      ((volatile cmpv1_r22_t *) 0xA0300088)
//#define CMPv1_R23      ((volatile cmpv1_r23_t *) 0xA030008c)
//#define CMPv1_R24      ((volatile cmpv1_r24_t *) 0xA0300090)
//#define CMPv1_R25      ((volatile cmpv1_r25_t *) 0xA0300094)
//#define CMPv1_R26      ((volatile cmpv1_r26_t *) 0xA0300098)
//#define CMPv1_R27      ((volatile cmpv1_r27_t *) 0xA030009c)
//#define CMPv1_R28      ((volatile cmpv1_r28_t *) 0xA03000a0)
#define CMPv1_R29      ((volatile cmpv1_r29_t *) 0xA03000a4)
#define CMPv1_R2A      ((volatile cmpv1_r2A_t *) 0xA03000a8)
#define CMPv1_R2B      ((volatile cmpv1_r2B_t *) 0xA03000ac)
#define CMPv1_R2C      ((volatile cmpv1_r2C_t *) 0xA03000b0)
#define CMPv1_R2D      ((volatile cmpv1_r2D_t *) 0xA03000b4)
#define CMPv1_R2E      ((volatile cmpv1_r2E_t *) 0xA03000b8)
#define CMPv1_R2F      ((volatile cmpv1_r2F_t *) 0xA03000bc)
#define CMPv1_R30      ((volatile cmpv1_r30_t *) 0xA03000c0)
//#define CMPv1_R31      ((volatile cmpv1_r31_t *) 0xA03000c4)
//#define CMPv1_R32      ((volatile cmpv1_r32_t *) 0xA03000c8)
#define CMPv1_R33      ((volatile cmpv1_r33_t *) 0xA03000cc)
//#define CMPv1_R34      ((volatile cmpv1_r34_t *) 0xA03000d0)
//#define CMPv1_R35      ((volatile cmpv1_r35_t *) 0xA03000d4)
//#define CMPv1_R36      ((volatile cmpv1_r36_t *) 0xA03000d8)
//#define CMPv1_R37      ((volatile cmpv1_r37_t *) 0xA03000dc)
//#define CMPv1_R38      ((volatile cmpv1_r38_t *) 0xA03000e0)
//#define CMPv1_R39      ((volatile cmpv1_r39_t *) 0xA03000e4)
//#define CMPv1_R3A      ((volatile cmpv1_r3A_t *) 0xA03000e8)
//#define CMPv1_R3B      ((volatile cmpv1_r3B_t *) 0xA03000ec)
//#define CMPv1_R3C      ((volatile cmpv1_r3C_t *) 0xA03000f0)
//#define CMPv1_R3D      ((volatile cmpv1_r3D_t *) 0xA03000f4)
//#define CMPv1_R3E      ((volatile cmpv1_r3E_t *) 0xA03000f8)
//#define CMPv1_R3F      ((volatile cmpv1_r3F_t *) 0xA03000fc)
#define CMPv1_R40      ((volatile cmpv1_r40_t *) 0xA0300100)
#define CMPv1_FUID_CMDLEN  ((volatile uint32_t *) 0xA0300104)
#define CMPv1_CMD          ((volatile uint32_t *) 0xA0300108)
#define CMPv1_TX_IRQ       ((volatile uint32_t *) 0xA030010C)
#define CMPv1_RX_IRQ       ((volatile uint32_t *) 0xA0300110)
/*}}}*/
//*********************************************************
// FUNCTIONS
//*********************************************************

/**
 * @brief   Insert 'nop's 
 *
 * @param   ticks       Num of 'nop's to be inserted. The actual idle time would be 2*ticks cycles due to the 'for' loop.
 *
 * @usage   delay(104);
 */
void delay(unsigned ticks);


/**
 * @brief   Wait for interrupt
 *
 * @param   N/A
 *
 * @usage   WFI();
 */
void WFI();


/**
 * @brief   Enable all interrupts
 *
 * @param   N/A
 *
 * @usage   enable_all_irq();
 */
void enable_all_irq();


/**
 * @brief   Enable all interrupts
 *
 * @param   N/A
 *
 * @usage   enable_irq();
 */
void enable_irq(uint32_t code);

/**
 * @brief   Disable all interrupts
 *
 * @param   N/A
 *
 * @usage   disable_all_irq();
 */
void disable_all_irq();


/**
 * @brief   Clear all pending interrupts
 *
 * @param   N/A
 *
 * @usage   clear_all_pend_irq();
 */
void clear_all_pend_irq();


/**
 * @brief   Set flag
 *
 * @param   bit_idx     bit index into which the value is written
 *          value       flag value
 *
 * @usage   set_flag(0, 1);
 */
uint32_t set_flag(uint32_t bit_idx, uint32_t value);


/**
 * @brief   Get flag
 *
 * @param   bit_idx     bit index in Flag Register to read
 *
 * @usage   get_flag(0);
 */
uint8_t get_flag(uint32_t bit_idx);


/**
 * @brief   Set a new SREG_CONF_HALT value
 *
 * @param   new_config  4-bit SREG_CONF_HALT value
 *
 * @usage   set_halt_config(0x9);
 *          set_halt_config(HALT_UNTIL_MBUS_RX);
 */
void set_halt_config(uint8_t new_config);


/**
 * @brief   Return the current SREG_CONF_HALT value
 *
 * @param   N/A
 *
 * @usage   uint8_t current_halt_cpu_setting = get_current_halt_config();
 */
uint8_t get_current_halt_config(void);


/**
 * @brief   This configures SREG_CONF_HALT like below:
 *              SREG_CONF_HALT     = reg_id;
 *
 * @param   reg_id  8-bit Register interrupt masking pattern
 *
 * @usage   set_halt_until_reg(0xF0);
 */
void set_halt_until_reg(uint32_t reg_id);


/**
 * @brief   This configures SREG_CONF_HALT like below:
 *              SREG_CONF_HALT     = HALT_UNTIL_MEM_WR;
 *
 * @param   N/A
 *
 * @usage   set_halt_until_mem_wr();
 */
void set_halt_until_mem_wr(void);


/**
 * @brief   This configures SREG_CONF_HALT like below:
 *              SREG_CONF_HALT     = HALT_UNTIL_MBUS_RX;
 *
 * @param   N/A
 *
 * @usage   set_halt_until_mbus_rx();
 */
void set_halt_until_mbus_rx(void);


/**
 * @brief   This configures SREG_CONF_HALT like below:
 *              SREG_CONF_HALT     = HALT_UNTIL_MBUS_TX;
 *
 * @param   N/A
 *
 * @usage   set_halt_until_mbus_tx();
 */
void set_halt_until_mbus_tx(void);


/**
 * @brief   This configures SREG_CONF_HALT like below:
 *              SREG_CONF_HALT     = HALT_UNTIL_MBUS_TRX;
 *
 * @param   N/A
 *
 * @usage   set_halt_until_mbus_trx();
 */
void set_halt_until_mbus_trx(void);


/**
 * @brief   This configures SREG_CONF_HALT like below:
 *              SREG_CONF_HALT     = HALT_UNTIL_MBUS_FWD;
 *
 * @param   N/A
 *
 * @usage   set_halt_until_mbus_fwd();
 */
void set_halt_until_mbus_fwd(void);


/**
 * @brief   This configures SREG_CONF_HALT like below:
 *              SREG_CONF_HALT     = HALT_DISABLE;
 *
 * @param   N/A
 *
 * @usage   set_halt_disable();
 */
void set_halt_disable(void);


/**
 * @brief   Immediately put CPU in halt. CPU resumes its operation when the event specifiedin SREG_CONF_HALT occurs.
 *
 * @param   N/A
 *
 * @usage   halt_cpu();
 */
void halt_cpu(void);

///**
// * @brief   Write into ARB debug register
// *          !!!    THIS IS FOR VERILOG SIM ONLY    !!!
// *
// * @param   id          debug id (informational use only)
// *          code        debug code (informational use only)
// */
void arb_debug_reg (uint8_t id, uint32_t code);

#endif // CMPV1_H

