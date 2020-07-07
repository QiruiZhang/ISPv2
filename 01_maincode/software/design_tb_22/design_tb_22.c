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
int h264_flag;
int ne_flag;
int mbustx_flag;
int mbusrx_flag;

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
}
void handler_ext_int_vga(void) { // VGA
    *NVIC_ICPR = (0x1 << IRQ_VGA); irq_history |= (0x1 << IRQ_VGA);
    arb_debug_reg(IRQ_VGA, 0x00000000);
	frame_flag=1;
	imgif_clear_enc_done_int();
}
void handler_ext_int_ne(void) { // NE
    *NVIC_ICPR = (0x1 << IRQ_NE); irq_history |= (0x1 << IRQ_NE);
    arb_debug_reg(IRQ_NE, 0x00000000);
	ne_flag=1;
	ne_clear_interrupt();
}
void handler_ext_int_fls(void) { // FLS
    *NVIC_ICPR = (0x1 << IRQ_FLS); irq_history |= (0x1 << IRQ_FLS);
    arb_debug_reg(IRQ_FLS, 0x00000000);
	p_FLSIF_INTR->as_int  = 1;
	flash_flag=1;
}
void handler_ext_int_h264(void) { // H264
    *NVIC_ICPR = (0x1 << IRQ_H264); irq_history |= (0x1 << IRQ_H264);
    arb_debug_reg(IRQ_H264, 0x00000000);
	p_H264_INTR_DONE->as_int = 1;
	h264_flag=1;
}
void handler_ext_int_h264_fifordy(void) { // H264_fifordy
    *NVIC_ICPR = (0x1 << IRQ_H264_FIFORDY); irq_history |= (0x1 << IRQ_H264_FIFORDY);
    arb_debug_reg(IRQ_H264_FIFORDY, 0x00000000);
	p_H264_INTR_FIFO->as_int = 1;
}

//*******************************************************************
// USER FUNCTIONS
//*******************************************************************

//********************************************************************
// MAIN function starts here             
//********************************************************************
//#define ERROR_ADDR_LOG    0x4000
//#define ERROR_WORD_LOG    0x8000
//#define ERROR_XOR_LOG     0xC000
#define REG_RUN_CPU		  ((volatile uint32_t *) 0xA0000080)

#define ERROR_LOG		  ((volatile uint32_t *) 0x00003C00)
#define ERROR_ADDR_LOG	  ((volatile uint32_t *) 0x00004000)
#define ERROR_WORD_LOG	  ((volatile uint32_t *) 0x00008000)
#define ERROR_XOR_LOG	  ((volatile uint32_t *) 0x0000C000)

#define TESTING_PROGRESS  ((volatile uint32_t *) 0x00003C1C)
#define ERROR_LOG_SUMMARY ((volatile uint32_t *) 0x00003C20)
#define ERROR_LOG_DETAIL  ((volatile uint32_t *) 0x00003C78)

#define TOTAL_WORDS			262144


//Global Variable Initialize here is useless. Must initialize in main function for C
uint32_t word_err_cnt = 0;
uint32_t single_word_cnt = 0; //word contain <= 2 error bits
uint32_t multi_word_cnt = 0;
uint32_t bit_err_cnt = 0;
uint32_t single_bit_cnt = 0; //word contains <= 2 error bits
uint32_t multi_bit_cnt = 0;
uint32_t log_cnt;
uint32_t total_word_cnt;

const uint32_t m1  = 0x55555555;
const uint32_t m2  = 0x33333333;
const uint32_t m4  = 0x0f0f0f0f;
const uint32_t m8  = 0x00ff00ff;
const uint32_t m16 = 0x0000ffff;

uint32_t popcount32(uint32_t x){
	x = (x & m1)  + ((x >> 1)  & m1 ); 
	x = (x & m2)  + ((x >> 2)  & m2 ); 
	x = (x & m4)  + ((x >> 4)  & m4 ); 
	x = (x & m8)  + ((x >> 8)  & m8 ); 
	x = (x & m16) + ((x >> 16) & m16 ); 
	return x;
}

void failBitCnt(volatile uint32_t * startaddr, uint32_t size, bool skip, int skip_num){
//size: how many 32-bit words
//skip: true - skip addr 8*n + 6/7 for CD SRAM testing
//		false - don't skip
	uint32_t addr,addr1;
	int i;
	
	uint32_t pattern, pattern1;
	uint32_t error_word, error_word1;
	
	for(i=0;i<size;i=i+2){
		if(skip && (i % 8 >= skip_num))
			continue;
			
		total_word_cnt = total_word_cnt + 2;	
		
		//Thoroughly test mem with 6 data patterns
		addr = (startaddr+i);
		addr1 = (startaddr+i+1);
		uint32_t temp_xor = 0;
		uint32_t temp_xor1 = 0;
		for(int p=0;p<6;p++){
			switch(p)
			{
				case 0:
					pattern = addr;
					pattern1 = addr1;
					break;
				case 1:
					pattern = ~addr;
					pattern1 = ~addr1;
					break;
				case 2:
					pattern = 0x00000000;
					pattern1 = 0x00000000;
					break;
				case 3:
					pattern = 0xFFFFFFFF;
					pattern1 = 0xFFFFFFFF;
					break;
				case 4:
					pattern = 0xAAAAAAAA;
					pattern1 = 0xAAAAAAAA;
					break;
				case 5:
					pattern = 0x55555555;
					pattern1 = 0x55555555;
					break;
				default:
					pattern = addr;
					pattern1 = addr1;
					break;
			}
			
			*(startaddr+i)=pattern; 
			*(startaddr+i+1)=pattern1;
			
			if(i > size-20){
				*(startaddr+i-17) = pattern;
			}else{
				*(startaddr+i+17) = pattern;
			}
			
			uint32_t temp_reg=*(startaddr+i);
			uint32_t temp_reg1=*(startaddr+i+1);

			if(i > size-20){
				*(startaddr+i-17) = pattern1;
			}else{
				*(startaddr+i+17) = pattern1;
			}
			
			if(temp_reg != pattern) {
				temp_xor = temp_xor | (temp_reg^pattern);
				error_word = temp_reg;
			}
			
			if(temp_reg1 != pattern1) {
				temp_xor1 = temp_xor1 | (temp_reg1^pattern1);
				error_word1 = temp_reg1;
			}
		}
		
		//Count errorbit
		uint32_t error_bitcnt = popcount32(temp_xor);
		if(error_bitcnt > 0){
			bit_err_cnt += error_bitcnt;
			if(single_word_cnt < 4096 && error_bitcnt < 4){
				*(ERROR_ADDR_LOG + single_word_cnt) = addr;
				*(ERROR_WORD_LOG + single_word_cnt) = error_word;
				*(ERROR_XOR_LOG  + single_word_cnt) = temp_xor;
			}
			if(error_bitcnt > 3){
				multi_word_cnt++;
				multi_bit_cnt += error_bitcnt;
			}else{
				single_word_cnt++;
				single_bit_cnt += error_bitcnt;
			}
			word_err_cnt++;
		}
		
		uint32_t error_bitcnt1 = popcount32(temp_xor1);
		if(error_bitcnt1 > 0){
			bit_err_cnt += error_bitcnt1;
			if(single_word_cnt < 4096 && error_bitcnt1 < 4){
				*(ERROR_ADDR_LOG + single_word_cnt) = addr1;
				*(ERROR_WORD_LOG + single_word_cnt) = error_word1;
				*(ERROR_XOR_LOG  + single_word_cnt) = temp_xor1;
			}
			if(error_bitcnt1 > 3){
				multi_word_cnt++;
				multi_bit_cnt += error_bitcnt1;
			}else{
				single_word_cnt++;
				single_bit_cnt += error_bitcnt1;
			}
			word_err_cnt++;
		}
	}
	return;
}


uint32_t bank, block, progress, jump;
void BlockTest(volatile uint32_t * startaddr, uint32_t size, uint32_t num_bank, uint32_t mask){
	uint32_t prev_single_word_cnt, prev_multi_word_cnt;
	uint32_t prev_single_word_cnt_b, prev_multi_word_cnt_b;
	
	prev_single_word_cnt_b = single_word_cnt;
	prev_multi_word_cnt_b = multi_word_cnt;
	
	for(int i = 0; i < num_bank ; i++){
		prev_single_word_cnt = single_word_cnt;
		prev_multi_word_cnt = multi_word_cnt;
		failBitCnt(startaddr + i*size, size, false, 0);
		*(ERROR_LOG_DETAIL + bank) = ((single_word_cnt - prev_single_word_cnt) << 16 ) | (multi_word_cnt - prev_multi_word_cnt);
		bank++;
		progress = (total_word_cnt << 5) / TOTAL_WORDS;
		*(TESTING_PROGRESS) = ~(0xFFFFFFFF >> progress);
	}
	
	*(ERROR_LOG_SUMMARY + block) = (single_word_cnt - prev_single_word_cnt_b) | mask; 
	*(ERROR_LOG_SUMMARY + jump + block) = (multi_word_cnt - prev_multi_word_cnt_b) | mask;
	block++;
}

void BlockTest_CD(volatile uint32_t * startaddr, uint32_t size, uint32_t num_bank, uint32_t mask){
	uint32_t prev_single_word_cnt, prev_multi_word_cnt;
	uint32_t prev_single_word_cnt_b, prev_multi_word_cnt_b;
	
	prev_single_word_cnt_b = single_word_cnt;
	prev_multi_word_cnt_b = multi_word_cnt;
	
	for(int i = 0; i < num_bank; i++){
		prev_single_word_cnt = single_word_cnt;
		prev_multi_word_cnt = multi_word_cnt;
		failBitCnt(startaddr + i*size, size, true, 2);
		*(ERROR_LOG_DETAIL + bank) = ((single_word_cnt - prev_single_word_cnt) << 16 ) | (multi_word_cnt - prev_multi_word_cnt);
		bank++;
		progress = (total_word_cnt << 5) / TOTAL_WORDS;
		*(TESTING_PROGRESS) = ~(0xFFFFFFFF >> progress);
		
		prev_single_word_cnt = single_word_cnt;
		prev_multi_word_cnt = multi_word_cnt;
		failBitCnt(startaddr + i*size + 2, size, true, 4);
		*(ERROR_LOG_DETAIL + bank) = ((single_word_cnt - prev_single_word_cnt) << 16 ) | (multi_word_cnt - prev_multi_word_cnt);
		bank++;
		progress = (total_word_cnt << 5) / TOTAL_WORDS;
		*(TESTING_PROGRESS) = ~(0xFFFFFFFF >> progress);
	}
	
	*(ERROR_LOG_SUMMARY + block) = (single_word_cnt - prev_single_word_cnt_b) | mask; 
	*(ERROR_LOG_SUMMARY + jump + block) = (multi_word_cnt - prev_multi_word_cnt_b) | mask;
	block++;
}


int main() {
	//********************************************************************
	//********************************************************************
	// MEM access test
	//********************************************************************
	//********************************************************************
	//enable_all_irq();
	enable_irq(0xFFFFF9FF);
	
	//error_msg = {0, 0, 0, 0, 0, 0};
	word_err_cnt = 0;
	single_word_cnt = 0; //word contain <= 2 error bits
	multi_word_cnt = 0;
	bit_err_cnt = 0;
	single_bit_cnt = 0; //word contains <= 2 error bits
	multi_bit_cnt = 0;
	log_cnt = 0;
	total_word_cnt = 0;
	
	block = 0;
	bank = 0;
	progress = 0;
	jump = 11;
	
	
	for(int i = 0; i < 256; i++){
		*(ERROR_LOG + i) = 0;
	}
	for(int i = 0; i < 4096; i++){
		*(ERROR_ADDR_LOG + i) = 0;
		*(ERROR_WORD_LOG + i) = 0;
		*(ERROR_XOR_LOG  + i) = 0;
	}
	

	imgif_initialize();
	//1. first write all data in all SRAM (You can use certain round-robin pattern)
	//2. read data in all SRAM and match
	//This is because of N2W works as a buffer
	//********************************************************************
	// IMG IF access test
	//********************************************************************
	imgif_mem_access_enable();
	
	// 1. min max memory bank (64x512)
	BlockTest(p_MINMAX_SRAM_START, 2*512, 1, 0x10000000);
	
	//2. CD mem//64x512 (4) 128x512(4)
	//			  #words/row * #rows * #banks
	BlockTest_CD(p_CD_SRAM_START, 8*512, 4, 0x20000000);
	
	//3. Ref mem//64x512 (3)
	BlockTest(p_REF_SRAM_START, 2*512, 3, 0x30000000);

	//4. compmeme 64x512 (55)
	BlockTest(p_COMP_SRAM_START, 2*512, 55, 0x40000000);
	
	//********************************************************************
	// NE access test
	//********************************************************************
	ne_mem_access();

	// //5. shared memory
	// //128x512 (80)
	BlockTest(p_NE_SHARED_MEM_START, 4*512, 52, 0x50000000);

	// //6. weight memory
	// //256x256 (4 )
	BlockTest(p_NE_PE_WEIGHTBUF_START, 8*256, 4, 0x60000000);

	// //7. Instr memeory
	// //128x512 (2 )
	BlockTest(p_NE_IMEM_START, 4*512, 2, 0x70000000);
	
	// //8. local memeory
	// //256x256 (4 )
	BlockTest(p_NE_PE_LOCALMEM_START, 8*256, 4, 0x80000000);
	
	// //9. accum memeory
	// //32x32   (64)
	BlockTest(p_NE_PE_ACCUMULATORS_START, 1*32, 64, 0x90000000);

	// //10. Bias memeory
	// //128x512 (1 )
	BlockTest(p_NE_PE_BIAS_BUFFER_START, 4*512, 1, 0xA0000000);

	// //********************************************************************
	// // H264 access test
	// //********************************************************************
	// //11. Bias memeory
	// //64x512 (1 )
	h264_initialize();
	h264_mem_direct_access();
	
	BlockTest(p_H264_MEM_START, 2*512, 1, 0xB0000000);
	
	//********************************************************************
	// FINISH             
	//********************************************************************
	// uint32_t pattern [8]; 
	// pattern[0] = 0xDEADBEEF;
	// pattern[1] = 0xABCDEF00; 
	// pattern[2] = 0xAAAABBBB; 
	// pattern[3] = 0xCCCCDDDD; 
	// pattern[4] = 0xEEEEFFFF; 
	// pattern[5] = 0xABABABAB; 
	// pattern[6] = 0xCDCDCDCD;
	// pattern[7] = 0xEFEFEFEF;
	
	// mbus_write_message(0x11,pattern,7);
	
	*(ERROR_LOG + 0) = word_err_cnt;
	*(ERROR_LOG + 1) = single_word_cnt;
	*(ERROR_LOG + 2) = multi_word_cnt;
	*(ERROR_LOG + 3) = bit_err_cnt;
	*(ERROR_LOG + 4) = single_bit_cnt;
	*(ERROR_LOG + 5) = multi_bit_cnt;
	*(ERROR_LOG + 6) = total_word_cnt;

	flsif_initialize(0x3, 0x3);
	flsif_senddata(word_err_cnt   );
	while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
	flsif_senddata(single_word_cnt);
	while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
	flsif_senddata(multi_word_cnt );
	while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
	flsif_senddata(bit_err_cnt    );
	while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
	flsif_senddata(single_bit_cnt );
	while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
	flsif_senddata(multi_bit_cnt  );
	while(1) { if (flash_flag) { flash_flag =0; delay(1); break; } delay(1); }
	flsif_senddata(total_word_cnt );
	
	//*REG_RUN_CPU = 0;
	rf_write(32,0);
	
	//while(1){ delay(1); }
    return 1;
}
