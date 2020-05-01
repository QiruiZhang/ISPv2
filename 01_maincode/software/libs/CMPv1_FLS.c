#include "CMPv1_FLS.h"

void flsif_config(uint8_t flsif_biten, uint8_t flsif_ch){
	p_FLSIF_CONFIG->flsif_biten = flsif_biten;
	p_FLSIF_CONFIG->flsif_ch = flsif_ch;
}
void flsif_senddata(uint32_t data){
	p_FLSIF_FIFO->as_int = data;
}
void flsif_initialize(uint8_t flsif_biten, uint8_t flsif_ch){
	p_FLSIF_ENABLE->softreset = 1;
	flsif_config(flsif_biten,flsif_ch);
	p_FLSIF_ENABLE->flsif_en  = 1;
}
