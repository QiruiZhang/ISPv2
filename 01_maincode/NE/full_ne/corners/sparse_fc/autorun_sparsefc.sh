#!/bin/bash

MAX_ITERS=10
ICHAN=256
OCHAN=64
OASIZE=1
IASIZE=1

if [[ ${1} =~ ^[0-9]+$ ]]; then
    MAX_ITERS=${1}
    if [[ ${2} =~ ^[0-9]+$ ]]; then
        ICHAN=${2}
        if [[ ${3} =~ ^[0-9]+$ ]]; then
            OCHAN=${3}
            if [[ ${4} =~ ^[0-9]+$ ]]; then
                OASIZE=${4}
                if [[ ${5} =~ ^[0-9]+$ ]]; then
                    IASIZE=${5}
                fi
            fi
        fi
    fi
elif ! [[ -z ${1} ]]; then
    echo -e "\nUsage: ./autorun_sparsefc.sh [iters] [ichan] [ochan] [oasize] [iasize]\n\n"
    echo -e "     iters:  number of random iterations, default 10"
    echo -e "     ichan:  input channels, default 256"
    echo -e "     ochan:  output channels, default 64"
    echo -e "    oasize:  output square size, default 1"
    echo -e "    iasize:  input square size, default 1"
    exit 3
fi


ITERS=0
MOVIC=8
if [[ $ICHAN -gt 511 ]]; then
    MOVIC=16
fi
if [[ $ICHAN -gt 1023 ]]; then
    MOVIC=32
fi
if [[ $ICHAN -gt 2047 ]]; then
    MOVIC=64
fi
# else higher is not supported


echo -e "\nRunning ${MAX_ITERS} random iterations of Sparse FCs with ic: ${ICHAN} oc: ${OCHAN} oasize: ${OASIZE} iasize: ${IASIZE}\n"

sed -e "s/REPLACEME_ICHAN/${ICHAN}/g" /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/gen_inputs_fc.py > /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/temp1
sed -e "s/REPLACEME_OCHAN/${OCHAN}/g" /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/temp1 > /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/temp2
sed -e "s/REPLACEME_OASIZE/${OASIZE}/g" /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/temp2 > /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/temp3
sed -e "s/REPLACEME_IASIZE/${IASIZE}/g" /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/temp3 > /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/runnable_gen_inputs_fc.py
rm -f /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/temp{1,2,3}


sed -e "s/REPLACEME_ICHAN/${ICHAN}/g" /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/sparse_test.asm > /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/temp1
sed -e "s/REPLACEME_OCHAN/${OCHAN}/g" /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/temp1 > /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/temp2
sed -e "s/REPLACEME_IASIZE/${IASIZE}/g" /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/temp2 > /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/temp3
sed -e "s/REPLACEME_OASIZE/${IASIZE}/g" /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/temp3 > /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/temp4
sed -e "s/REPLACEME_MOVIC/${MOVIC}/g" /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/temp4 > /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/runnable_sparse_test.asm
rm -f /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/temp{1,2,3,4}
cd /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc
python3 ../../../real_nets/assembler_v2.py runnable_sparse_test.asm
cp ne_instructions.hex /z/libra2_nn/full_ne/ne_instructions.txt

while [ $ITERS -lt $MAX_ITERS ]; do

    printf "Iteration ${ITERS}\n=============================\n"

    printf "Generating data...."
    cd /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc    
    python3 runnable_gen_inputs_fc.py > log
    cp -r unified_sram /z/libra2_nn/full_ne/
    cp ncx_rf.txt /z/libra2_nn/full_ne/ncx_rf.txt
    printf "      done\n"
    
    printf "Running VCS...."
    cd /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE
    make pfullne >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        printf "          ERROR!!!!\n"
        exit 1
    else
        printf "          done\n"
    fi


    printf "Comparing result:  "
    head -n20 /z/libra2_nn/full_ne/localdumps/sfc*buf_1 > hw.out
    head -n20 /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/big_oa.mem > gold.out

    diff -i hw.out gold.out

    if [ $? -ne 0 ]; then
        echo -e "      \e[91mERROR!\e[0m\n\n"
        cp hw.out /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/hw.out
        cp gold.out /afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/vsim/NE/test/full_ne/corners/sparse_fc/gold.out
        exit 2
    else
        echo -e "      \e[92mPASSED!\e[0m\n\n"
        rm -f hw.out gold.out
    fi


    ITERS=$((ITERS+1))

done
    

