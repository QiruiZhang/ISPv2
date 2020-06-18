#include <stdio.h>
#include <stdbool.h>
#include <wiringPi.h>

//left side
#define PCLK  8
#define P0    9 
#define P1    7 
#define P2    0 
#define P3    2 
#define P4    3 
#define P5    12
#define P6    13
#define P7    14
#define P8    30
#define P9    21
#define P10   22
#define P11   23
#define HSYNC 24
#define VSYNC 25
#define EXTCLK  27
#define EXTDAT0 28
#define EXTDAT1 29

//3 avail
//#define H_DUTY_CLK  1
//#define L_DUTY_CLK  1
//#define FRAME_DELAY 100
//#define LINE_DELAY  100
//bayer setting
//#define H_DUTY_CLK  100
//#define L_DUTY_CLK  100
//#define FRAME_FP    5000
//#define FRAME_BP    2000
//#define LINE_DELAY  100000
//#define LINE_FP     4500
//#define LINE_BP     4500
//
//#define H_DUTY_CLK  1
//#define L_DUTY_CLK  1
//#define FRAME_FP    600
//#define FRAME_BP    20
//#define LINE_DELAY  600
//#define LINE_FP     5
//#define LINE_BP     5
#define H_DUTY_CLK  1
#define L_DUTY_CLK  1
#define FRAME_FP    600
#define FRAME_BP    20
#define LINE_DELAY  600
#define LINE_FP     5
#define LINE_BP     5

//PI_THREAD (FLS)
//{
//}

void start_frame(void){
        digitalWrite(VSYNC,0 );
        digitalWrite(HSYNC,0 );

        digitalWrite(PCLK ,1 );
        delayMicroseconds(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delayMicroseconds(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delayMicroseconds(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delayMicroseconds(L_DUTY_CLK);

        digitalWrite(VSYNC,1 );
        delayMicroseconds(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delayMicroseconds(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delayMicroseconds(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delayMicroseconds(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delayMicroseconds(L_DUTY_CLK);

        delayMicroseconds(FRAME_FP);
}

void end_frame(void){
        delayMicroseconds(FRAME_BP);
        digitalWrite(PCLK ,1 );
        delayMicroseconds(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delayMicroseconds(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delayMicroseconds(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delayMicroseconds(L_DUTY_CLK);

        digitalWrite(VSYNC,0 );
        delayMicroseconds(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delayMicroseconds(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delayMicroseconds(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delayMicroseconds(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delayMicroseconds(L_DUTY_CLK);

        digitalWrite(VSYNC,0 );
        digitalWrite(HSYNC,0 );
}

void start_row(void){
        digitalWrite(PCLK ,1 );
        delayMicroseconds(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delayMicroseconds(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delayMicroseconds(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delayMicroseconds(L_DUTY_CLK);

        digitalWrite(HSYNC,1 );
        delayMicroseconds(L_DUTY_CLK);

        delayMicroseconds(LINE_FP);
}

void end_row(void){
        delayMicroseconds(LINE_BP);
        digitalWrite(PCLK ,0 );
        delayMicroseconds(L_DUTY_CLK);
        digitalWrite(HSYNC,0 );
        delayMicroseconds(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delayMicroseconds(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delayMicroseconds(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delayMicroseconds(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delayMicroseconds(L_DUTY_CLK);
}

void pixout(char* pix){
        digitalWrite(P11  ,(char)pix[0]  - '0');
        digitalWrite(P10  ,(char)pix[1]  - '0');
        digitalWrite(P9   ,(char)pix[2]  - '0');
        digitalWrite(P8   ,(char)pix[3]  - '0');
        digitalWrite(P7   ,(char)pix[4]  - '0');
        digitalWrite(P6   ,(char)pix[5]  - '0');
        digitalWrite(P5   ,(char)pix[6]  - '0');
        digitalWrite(P4   ,(char)pix[7]  - '0');
        digitalWrite(P3   ,(char)pix[8]  - '0');
        digitalWrite(P2   ,(char)pix[9]  - '0');
        digitalWrite(P1   ,(char)pix[10] - '0');
        digitalWrite(P0   ,(char)pix[11] - '0');
}

void output_pix(FILE* fp,int num_col){
        int i;
        char buf[13];

        for (i=0;i<num_col;i++){
            fscanf(fp,"%s",buf);
//printf("%s",buf);
            pixout(buf);
            digitalWrite(PCLK ,0 );
            delayMicroseconds(L_DUTY_CLK);
            digitalWrite(PCLK ,1 );
            delayMicroseconds(H_DUTY_CLK);
        }

}

int main()
{
        int i;
        int x;
        if(wiringPiSetup()== -1) return -1;

        char clk =1;
        char data[] = "1101";
        char buf[13];
        int  num_row=480;
        int  num_col=792;
        
        FILE *fp;
        //FILE *fp_fls;
        fp = fopen("./ref_frame2.txt","r");
        //fp_fls = fopen("./fls_out.txt","w");

        pinMode(PCLK ,OUTPUT);
        pinMode(P0   ,OUTPUT);
        pinMode(P1   ,OUTPUT);
        pinMode(P2   ,OUTPUT);
        pinMode(P3   ,OUTPUT);
        pinMode(P4   ,OUTPUT);
        pinMode(P5   ,OUTPUT);
        pinMode(P6   ,OUTPUT);
        pinMode(P7   ,OUTPUT);
        pinMode(P8   ,OUTPUT);
        pinMode(P9   ,OUTPUT);
        pinMode(P10  ,OUTPUT);
        pinMode(P11  ,OUTPUT);
        pinMode(HSYNC,OUTPUT);
        pinMode(VSYNC,OUTPUT);
        pinMode(EXTCLK ,INPUT);
        pinMode(EXTDAT0,INPUT);
        pinMode(EXTDAT1,INPUT);

        pixout("000000000000");
        digitalWrite(PCLK,0);
        digitalWrite(HSYNC,0);
        digitalWrite(VSYNC,0);
        delayMicroseconds(1000000);

        for(i=0;i<num_row;i++){
                if(i==0){
                    start_frame();        
                    start_row();        
            	    delayMicroseconds(LINE_FP);
                    output_pix(fp,num_col);
            	    delayMicroseconds(LINE_BP);
                    end_row();        
                }
                else if(i==(num_row-1)){
                    start_row();        
                    output_pix(fp,num_col);
                    end_row();
                    end_frame();
                }
                else{
                        if(i==3){
                                return 0;
                        }
                    start_row();        
                    output_pix(fp,num_col);
                    end_row();        
                }
                delayMicroseconds(LINE_DELAY);
        }
        fclose(fp);
        pixout("000000000000");
       

        ////flash read 
        //long index=0;
        //long interval=0;
        //char buffer[10000];

        //printf("dbg");

        //while(1){
        //     if (digitalRead(EXTCLK)==1){
        //             buffer[index]=digitalRead(EXTDAT0);
        //             index++;
        //             while(1){
        //                     if (digitalRead(EXTCLK)==0){
        //                             break;
        //                     }
        //             }
        //             break;
        //     }
        //}

        //while(1){
        //     if (digitalRead(EXTCLK)==1){
        //             buffer[index]=digitalRead(EXTDAT0);
        //             index++;
        //             interval=0;
        //             while(1){
        //                     if (digitalRead(EXTCLK)==0){
        //                             break;
        //                     }
        //             }
        //     }
        //     //else{
        //     //        interval++;
        //     //}
        //     if(index>5110){
        //             break;
        //     }
        //     //if(interval>50000){
        //     //        break;
        //     //}
        //}

        //for(i=0;i<(index-1);i++){
        //    fprintf(fp_fls,"%d\n",buffer[i]);
        //}
        //fclose(fp_fls);


        return 0;

}

