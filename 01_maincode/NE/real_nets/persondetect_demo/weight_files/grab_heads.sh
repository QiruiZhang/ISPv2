#!/bin/bash


####################################
# This script grabs localmem dumps #
# and clips out the relevant data, #
# then compares this with the      #
# _msb_lsb.txt file                #
####################################




LAYER=${1}
OUTFILE="sim_${1}.txt"
DUMPDIR=/z/libra2_nn/full_ne/localdumps


if [[ -z $LAYER ]]; then
    echo -e "\nUsage: ${0} [layer]\n"
    echo -e "Valid layer options are: conv1 conv1relu maxpool1 conv2 conv2relu maxpool2\n"
    exit 1
fi

if [[ ! -d $DUMPDIR ]]; then
    echo "ERROR: $DUMPDIR not found"
    exit 1
fi


if [[ $LAYER == "conv1" ]]; then

    REALNUM=0
    rm -f $OUTFILE >/dev/null 2>&1
    while [ $REALNUM -lt 12 ]; do
        for i in ${DUMPDIR}/conv${REALNUM}.cycle*buf_1 ; do
            head -n16 $i >> $OUTFILE
        done
        REALNUM=$((REALNUM+1))
    done
    diff outconv1_msb_lsb.txt $OUTFILE > conv1.diff
    if [ $? -ne 0 ]; then
        echo "conv1: DIFFERENCE FOUND! See conv1.diff"
    else
        rm -f $OUTFILE
        rm -f conv1.diff
        echo "conv1: Perfect match! :-)"
    fi

elif [[ $LAYER == "conv1relu" ]]; then

    REALNUM=0
    rm -f $OUTFILE >/dev/null 2>&1
    while [ $REALNUM -lt 12 ]; do
        for i in ${DUMPDIR}/relu${REALNUM}.cycle*buf_0 ; do
            head -n16 $i >> $OUTFILE
        done
        REALNUM=$((REALNUM+1))
    done
    diff outconv1relu_msb_lsb.txt $OUTFILE > conv1relu.diff
    if [ $? -ne 0 ]; then
        echo "conv1relu: DIFFERENCE FOUND! See conv1relu.diff"
    else
        rm -f $OUTFILE
        rm -f conv1relu.diff
        echo "conv1relu: Perfect match! :-)"
    fi

elif [[ $LAYER == "maxpool1" ]]; then

    CNT=0
    REALNUM=0
    rm -f ${OUTFILE}* >/dev/null 2>&1
    while [ $REALNUM -lt 12 ]; do

        for i in ${DUMPDIR}/pool${REALNUM}.cycle*buf_1 ; do

            #echo "REALNUM: $REALNUM CNT: $CNT File: $i"

            if [[ $CNT -eq 3 ]]; then
                head -n8 dummy_pool.zeros | cut -c65-128 >> ${OUTFILE}.top
                CNT=$((CNT+1))
            elif [[ $CNT -eq 7 ]]; then
                head -n8 dummy_pool.zeros | cut -c65-128 >> ${OUTFILE}.top
                CNT=$((CNT+1))
            elif [[ $CNT -eq 11 ]]; then
                head -n8 dummy_pool.zeros | cut -c65-128 >> ${OUTFILE}.top
                CNT=$((CNT+1))

            fi

            if [ $((CNT%2)) -eq 0 ]; then
                head -n8 $i | cut -c65-128 >> ${OUTFILE}.bottom
            else
                head -n8 $i | cut -c65-128 >> ${OUTFILE}.top
            fi
            CNT=$((CNT+1))
            if [[ $CNT -eq 15 ]]; then
                head -n8 dummy_pool.zeros | cut -c65-128 >> ${OUTFILE}.top
                CNT=$((CNT+1))
            elif [[ $CNT -ge 16 ]]; then
                echo "WTF!?"
                exit 69
            fi

        done

        REALNUM=$((REALNUM+1))
    done
    paste -d" " ${OUTFILE}.top ${OUTFILE}.bottom > $OUTFILE
    sed -i -e "s/\ //g" $OUTFILE
    rm -f ${OUTFILE}.top ${OUTFILE}.bottom >/dev/null 2>&1
    diff outmaxpool1_msb_lsb.txt $OUTFILE > maxpool1.diff
    if [ $? -ne 0 ]; then
        echo "maxpool1: DIFFERENCE FOUND! See maxpool1.diff"
    else
        rm -f $OUTFILE
        rm -f maxpool1.diff
        echo "maxpool1: Perfect match! :-)"
    fi

elif [[ $LAYER == "conv2" ]]; then

    REALNUM=12
    rm -f $OUTFILE >/dev/null 2>&1
    while [ $REALNUM -lt 16 ]; do
        for i in ${DUMPDIR}/conv${REALNUM}.cycle*buf_1 ; do
            head -n32 $i >> $OUTFILE
        done
        REALNUM=$((REALNUM+1))
    done
    diff outconv2_msb_lsb.txt $OUTFILE > conv2.diff
    if [ $? -ne 0 ]; then
        echo "conv2: DIFFERENCE FOUND! See conv2.diff"
    else
        rm -f $OUTFILE
        rm -f conv2.diff
        echo "conv2: Perfect match! :-)"
    fi

elif [[ $LAYER == "conv2relu" ]]; then

    REALNUM=12
    rm -f $OUTFILE >/dev/null 2>&1
    while [ $REALNUM -lt 16 ]; do
        for i in ${DUMPDIR}/relu${REALNUM}.cycle*buf_0 ; do
            head -n32 $i >> $OUTFILE
        done
        REALNUM=$((REALNUM+1))
    done
    diff outconv2relu_msb_lsb.txt $OUTFILE > conv2relu.diff
    if [ $? -ne 0 ]; then
        echo "conv2relu: DIFFERENCE FOUND! See conv2relu.diff"
    else
        rm -f $OUTFILE
        rm -f conv2relu.diff
        echo "conv2relu: Perfect match! :-)"
    fi


elif [[ $LAYER == "maxpool2" ]]; then

    CNT=0
    REALNUM=12
    rm -f ${OUTFILE}* >/dev/null 2>&1
    while [ $REALNUM -lt 16 ]; do

        for i in ${DUMPDIR}/pool${REALNUM}.cycle*buf_1 ; do

            if [ $((CNT%2)) -eq 0 ]; then
                head -n16 $i | cut -c65-128 >> ${OUTFILE}.bottom
            else
                head -n16 $i | cut -c65-128 >> ${OUTFILE}.top
            fi
            CNT=$((CNT+1))

        done

        REALNUM=$((REALNUM+1))
    done
    paste -d" " ${OUTFILE}.top ${OUTFILE}.bottom > $OUTFILE
    sed -i -e "s/\ //g" $OUTFILE
    rm -f ${OUTFILE}.top ${OUTFILE}.bottom >/dev/null 2>&1
    diff outmaxpool2_msb_lsb.txt $OUTFILE > maxpool2.diff
    if [ $? -ne 0 ]; then
        echo "maxpool2: DIFFERENCE FOUND! See maxpool2.diff"
    else
        rm -f $OUTFILE
        rm -f maxpool2.diff
        echo "maxpool2: Perfect match! :-)"
    fi


else

    echo "ERROR: unknown layer $LAYER"
    echo "Valid options are: conv1 conv1relu maxpool1 conv2 conv2relu maxpool2"
    exit 1

fi
    

