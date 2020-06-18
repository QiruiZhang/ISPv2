import string
import sys
import glob
import os
import filecmp
import numpy as np
import matplotlib.pyplot as plt
import file_bit_change

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

if sys.argv[1] == '0' :
    list_of_files = glob.glob('03_captures/isp2/*') # * means all if need specific format then *.csv
    filename = max(list_of_files, key=os.path.getctime)
    if 'mod' in filename:
        filename = filename[:-4]
else :
    filename = sys.argv[1]
print("file to plot :", filename)

def YUV2RGB( yuv ):
    m = np.array([[ 1.0, 1.0, 1.0],
                 [-0.000007154783816076815, -0.3441331386566162, 1.7720025777816772],
                 [ 1.4019975662231445, -0.7141380310058594 , 0.00001542569043522235] ])
    rgb = np.dot(yuv,m)
    rgb[:,:,0]-=179.45477266423404
    rgb[:,:,1]+=135.45870971679688
    rgb[:,:,2]-=226.8183044444304
    return rgb


###########main########
nbit_data = 8
W=640 
H=480
#H=16*21
#W=64 
#H=64
mcb_row = int(H/16)
mcb_col = int(W/16)
C=3

if C==1:
    total_bits = H*W*nbit_data
    img_vec   = np.zeros((H*W))
elif C==3:
    total_bits = H*W*nbit_data*1.5
    img_vec   = np.zeros((int(1.5*H*W)))

img_vec = file_bit_change.file_bit_change(filename=filename,length=nbit_data,indexing=0)

print(len(img_vec))

img_mat   = np.zeros((H,W,C))
img_mat_y = np.zeros((H,W))
img_mat_u = np.zeros((int(H/2),int(W/2)))
img_mat_v = np.zeros((int(H/2),int(W/2)))

#Y
i=0
for mcb_row_idx in range(mcb_row):
    for mcb_col_idx in range(mcb_col):
        for row in range(16):
            for col in range(16):
                img_mat_y[(mcb_row_idx)*16+row,(mcb_col_idx)*16+col] = img_vec[i];
                i= i +1;
#Y_sample
img_mat[:,:,0] = img_mat_y;

#UV
if C == 3:
    for mcb_row_idx in range(mcb_row):
        for mcb_col_idx in range(mcb_col):
            for row in range(8):
                for col in range(8):
                    img_mat_u[(mcb_row_idx)*8+row,(mcb_col_idx)*8+col] = img_vec[i];
                    i= i +1;
            for row in range(8):
                for col in range(8):
                    img_mat_v[(mcb_row_idx)*8+row,(mcb_col_idx)*8+col] = img_vec[i];
                    i= i +1;
    row_uv, col_uv = int(np.shape(img_mat_u)[0]), int(np.shape(img_mat_u)[1])
    #UV_upsample
    for i in range(row_uv):
        for j in range(col_uv):
            img_mat[i*2+0, j*2+0, 1] = img_mat_u[i,j];
            img_mat[i*2+1, j*2+0, 1] = img_mat_u[i,j];
            img_mat[i*2+0, j*2+1, 1] = img_mat_u[i,j];
            img_mat[i*2+1, j*2+1, 1] = img_mat_u[i,j];
            img_mat[i*2+0, j*2+0, 2] = img_mat_v[i,j];
            img_mat[i*2+1, j*2+0, 2] = img_mat_v[i,j];
            img_mat[i*2+0, j*2+1, 2] = img_mat_v[i,j];
            img_mat[i*2+1, j*2+1, 2] = img_mat_v[i,j];
    #YUV to RGB
    img_mat = YUV2RGB(img_mat)


#image plot
if C==1:
    fig1 = plt.figure()
    ax = fig1.add_subplot(1,1,1)
    ax.imshow(img_mat_y.astype('uint8'),cmap='gray')
    #ax.imshow(img_mat_y)
else:
    fig1 = plt.figure()
    ax = fig1.add_subplot(2,2,1)
    ax.imshow(img_mat.astype('uint8'))
    #fig2 = plt.figure()
    ax2 = fig1.add_subplot(2,2,2)
    ax2.imshow(img_mat_y.astype('uint8'),cmap='gray',vmin=0,vmax=255)
    #fig3 = plt.figure()
    ax3 = fig1.add_subplot(2,2,3)
    ax3.imshow(img_mat_u.astype('uint8'),cmap='gray',vmin=0,vmax=255)
    #fig4 = plt.figure()
    ax4 = fig1.add_subplot(2,2,4)
    ax4.imshow(img_mat_v.astype('uint8'),cmap='gray',vmin=0,vmax=255)

plt.show()
