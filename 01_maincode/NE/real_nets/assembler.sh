#!/bin/sh


INPUTF=${1}

if [[ -f yyasm.py ]]; then
    python3 yyasm.py $INPUTF -l
    python3 yyasm.py $INPUTF
elif [[ -f ../yyasm.py ]]; then
    python3 ../yyasm.py $INPUTF -l
    python3 ../yyasm.py $INPUTF
elif [[ -f ../../yyasm.py ]]; then
    python3 ../../yyasm.py $INPUTF -l
    python3 ../../yyasm.py $INPUTF
elif [[ -f ../../../yyasm.py ]]; then
    python3 ../../../yyasm.py $INPUTF -l
    python3 ../../../yyasm.py $INPUTF
fi
