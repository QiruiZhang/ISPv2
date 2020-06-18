import datetime
import time
import libra
import libraview
import colorama
import sys
from colorama import init
from colorama import Fore, Back, Style

colorama.init()

print(Fore.CYAN)
print(Style.BRIGHT)

date = datetime.datetime.now().strftime("%m%d")
hour = datetime.datetime.now().strftime("%H%M")
vw = libraview.libraview()
base_path = sys.argv[1]
print(base_path)
test_num = input("\t Which program?:   ")
filename = r'\tb_%s_%s_%s.bin'%(test_num,date,hour)
vw.capture_img(base_path+filename)
print("\t\t> output :",filename[1:])
print(Fore.RESET)
