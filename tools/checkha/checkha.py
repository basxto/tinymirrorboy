#!/usr/bin/env python
"""
CHECKsum HAck
Copyright 2022 Sebastian "basxto" Riedel
[License: MIT]

Fixes the header checksum via a different byte
"""
import sys
import argparse


# convert str to integer and accept rgbds syntax
def str2int(x):
    y = 0
    x = x.replace('$', "0x", 1).replace('%', "0b", 1).replace('&', "0", 1).replace('#0', "0", 1).lower()
    if (x[0] == '0' and x[1] == 'x'):
        y = int(x, base=16)
    elif (x[0] == '0' and x[1] == 'b'):
        y = int(x, base=2)
    elif (x[0] == '0'):
        y = int(x, base=8)
    else:
        y = int(x, base=10)
    return y

def parse_argv(argv):
    p = argparse.ArgumentParser()
    p.add_argument("file")
    p.add_argument("address")
    #p.add_argument("baseaddress")
    return p.parse_args(argv[1:])

def main(argv=None):
    args = parse_argv(argv or sys.argv)
    address = str2int(args.address)
    basea = 0x34#str2int(args.baseaddress)
    maxa = 0x140

    #if (address < 0x134 or address > 0x143):
    #    print('Address has to be between 0x134 and 0x143')
    #    exit()

    with open(args.file, "rb+") as infp:
        infp.seek(0x100)
        data = infp.read(0x40)
        checksum = data[0xD]
        print("Actual checksum is 0x{:02x}".format(checksum))

        # substract the wanted checksum from the real one
        checksum = -checksum
        for i in range(basea, basea+25):
            if( i < 0x40):
                if (0x100+i) != address:
                    checksum += data[i]
            else:
                if (0x100+i-0x40) != address:
                    checksum += data[i-0x40]

        # fix up if still negative
        if checksum < 0:
            checksum = 0xFF - checksum

        # calculate the 8b inverse in two's complement
        checksum = 0xFF - ((checksum - 2) & 0xFF)

        if(address > 0x140):
            address = address - 0x40

        infp.seek(address)
        infp.write(checksum.to_bytes(1, 'little'))

    print("Byte 0x{:02x} set to 0x{:02x}".format(address, checksum))


if __name__=='__main__':
    main()