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

#define H_DUTY_CLK 1
#define L_DUTY_CLK 1
#define FRAME_DELAY 4
#define LINE_DELAY  4 

//PI_THREAD (FLS)
//{
//}

void start_frame(void){
        digitalWrite(VSYNC,0 );
        digitalWrite(HSYNC,0 );

        digitalWrite(PCLK ,1 );
        delay(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delay(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delay(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delay(L_DUTY_CLK);

        digitalWrite(VSYNC,1 );
        delay(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delay(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delay(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delay(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delay(L_DUTY_CLK);

        delay(FRAME_DELAY);
}

void end_frame(void){
        delay(FRAME_DELAY);
        digitalWrite(PCLK ,1 );
        delay(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delay(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delay(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delay(L_DUTY_CLK);

        digitalWrite(VSYNC,0 );
        delay(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delay(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delay(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delay(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delay(L_DUTY_CLK);

        digitalWrite(VSYNC,0 );
        digitalWrite(HSYNC,0 );
}

void start_row(void){
        digitalWrite(PCLK ,1 );
        delay(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delay(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delay(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delay(L_DUTY_CLK);

        digitalWrite(HSYNC,1 );
        delay(L_DUTY_CLK);

        delay(LINE_DELAY);
}

void end_row(void){
        delay(LINE_DELAY);
        digitalWrite(HSYNC,0 );
        delay(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delay(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delay(L_DUTY_CLK);

        digitalWrite(PCLK ,1 );
        delay(H_DUTY_CLK);
        digitalWrite(PCLK ,0 );
        delay(L_DUTY_CLK);
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

            delay(L_DUTY_CLK);
            digitalWrite(PCLK ,1 );
            delay(H_DUTY_CLK);
            digitalWrite(PCLK ,0 );
            delay(L_DUTY_CLK);
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
        int  num_row=32;
        int  num_col=20;
        
        FILE *fp;
        FILE *fp_fls;
        fp = fopen("./md_frame.txt","r");
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
        delay(1000);

        for(i=0;i<num_row;i++){
                if(i==0){
                    start_frame();        
                    start_row();        
                    output_pix(fp,num_col);
                    end_row();        
                }
                else if(i==(num_row-1)){
                    start_row();        
                    output_pix(fp,num_col);
                    end_row();
                    end_frame();
                }
                else{
                    start_row();        
                    output_pix(fp,num_col);
                    end_row();        
                }
                delay(LINE_DELAY);
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

