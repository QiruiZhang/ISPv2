//************************************************************
// Desciption: Helper functions for M0 programming
//************************************************************


#include "misc_lib.h"

uint32_t reverseBits(uint32_t num) 
{ 
    uint32_t count = sizeof(num) * 8 - 1; 
    uint32_t reverse_num = num; 
                  
    num >>= 1;  
    while(num) 
    { 
        reverse_num <<= 1;        
        reverse_num |= num & 1; 
        num >>= 1; 
        count--; 
    } 
    reverse_num <<= count; 
    return reverse_num; 
} 
