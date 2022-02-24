/* Frame simulator to test the control electronics of the DELTA camera
   This program generates a ROM .mif file containing 2 frames of the
   three CCDs on which photo-event are projected.

   Simulation of a simplified case for demo, where there are only 2 
   segments per CCD.

   ( compile with: g++ -lm frame_simu.c -o frame_simu )

   By S. Morel, Zthorus-Labs 
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define NB_PH 3   /* number of photo-event per frame */
#define PI 3.1415926

int main(int argc, char **argv)
{
  FILE *rom;
  int **x_ph; /* coordinates of photo-events */
  int **y_ph;
  char **bm;           /* bitmap of frames, as written to ROM */
  float p;             /* projected coordinate */
  int p_int;
  int row;
  int seg;  
  int i,j,k,n;

  x_ph=(int **)malloc(2*sizeof(int *));
  y_ph=(int **)malloc(2*sizeof(int *));
  if ((x_ph==NULL) || (y_ph==NULL)) exit(0);
  for (i=0;i<2;i++)
  {
    x_ph[i]=(int *)malloc(NB_PH*sizeof(int));
    y_ph[i]=(int *)malloc(NB_PH*sizeof(int));
    if ((x_ph[i]==NULL) || (y_ph[i]==NULL)) exit(0);
  }
  bm=(char **)malloc(128*sizeof(char *));
  if (bm==NULL) exit(0);
  for (i=0;i<128;i++)
  {
    bm[i]=(char *)malloc(7*sizeof(char));
    if (bm[i]==NULL) exit(0);
    strcpy(bm[i],"000000000000");
  }

  x_ph[0][0]=200; y_ph[0][0]=400;
  x_ph[0][1]=300; y_ph[0][1]=200;
  x_ph[0][2]=400; y_ph[0][2]=300;
  x_ph[1][0]=200; y_ph[1][0]=400;
  x_ph[1][1]=300; y_ph[1][1]=200;
  x_ph[1][2]=400; y_ph[1][2]=300;

  for (i=0;i<2;i++)
  {
    for (j=0;j<NB_PH;j++)
    {
      for (k=0;k<3;k++)
      {
        p=(x_ph[i][j]-256)*cos(k*2*PI/3.0)+(y_ph[i][j]-296)*sin(k*2*PI/3.0)+256;
        p_int=floor(p);
        seg=p_int/256;
        row=(p_int-256*seg)/4+64*i;
        n=4*k+2*seg;

        printf("x=%d y=%d => p=%f p_int=%d seg=%d row=%d\n",x_ph[i][j],y_ph[i][j],p,p_int,seg,row);

        switch((p_int-256*seg)%4)
        {
          case 0: bm[row-1][n+1]='1';
                  bm[row][n]='1'; bm[row][n+1]='1';
                  break;

          case 1: bm[row][n]='1'; bm[row][n+1]='1';
                  break;

          case 2: bm[row][n]='1'; bm[row][n+1]='1';
                  bm[row+1][n]='1'; 
                  break;

          case 3: bm[row][n+1]='1';
                  bm[row+1][n]='1';
                  break;
        } 
      }
    }
  }

  rom=fopen("simu_rom.mif","w");
  if (rom==NULL) exit(0);
  fprintf(rom,"-- Simulated CCD frames of Delta-Cam\n");
  fprintf(rom,"-- Format for each word is (MSB to LSB):\n");
  fprintf(rom,"--  * pixel even segment 0 axis A\n"); 
  fprintf(rom,"--  * pixel odd segment 0 axis A\n"); 
  fprintf(rom,"--  * pixel even segment 1 axis A\n"); 
  fprintf(rom,"--  * pixel odd segment 1 axis A\n"); 
  fprintf(rom,"--  * pixel even segment 0 axis B\n"); 
  fprintf(rom,"--  * pixel odd segment 0 axis B\n"); 
  fprintf(rom,"--  * pixel even segment 1 axis B\n"); 
  fprintf(rom,"--  * pixel odd segment 1 axis B\n"); 
  fprintf(rom,"--  * pixel even segment 0 axis C\n"); 
  fprintf(rom,"--  * pixel odd segment 0 axis C\n"); 
  fprintf(rom,"--  * pixel even segment 1 axis C\n"); 
  fprintf(rom,"--  * pixel odd segment 1 axis C\n\n");
  fprintf(rom,"WIDTH=12;\n");
  fprintf(rom,"DEPTH=128;\n\n");
  fprintf(rom,"ADDRESS_RADIX=UNS;\n");
  fprintf(rom,"DATA_RADIX=BIN;\n\n"); 
  fprintf(rom,"CONTENT BEGIN\n");

  i=0;
  while (i<128)
  {
    if ((strcmp(bm[i],"000000000000") != 0) || (i==63))
    {
      fprintf(rom,"%d : %s;\n",i,bm[i]);
      i++;
    }
    else
    {
      j=i;
      k=1;
      if (i<64) i++;
      while ((i<128) && (k==1))
      {
        if (strcmp(bm[i],"000000000000") !=0) k=0;
        else i++;
      }
      if (i==(j+1)) fprintf(rom,"%d : %s;\n",j,bm[j]);
      else fprintf(rom,"[%d..%d] : 000000000000;\n",j,i-1);
    }
  }
  fprintf(rom,"END;\n");
  fclose(rom);
}
 

