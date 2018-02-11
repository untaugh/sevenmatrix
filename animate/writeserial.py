#!/usr/bin/python3

# this is slow! it takes 40 minutes to transfer 32Mb

import serial
import argparse
from pathlib import Path

#data_file_name = 'frames.bin'
baud = 115200

def serReadByte(ser):
    byte = ser.read()
    while not byte:
        byte = ser.read()
    return byte

def Verify(ser, data_file_name):
    ser = initSerial(False)
    count = 0
    print('Verifying data ...')
    ser.write(b'r') # reset page counter
    with Path(data_file_name).open('rb') as f:
        byteF = f.read(1)
        while byteF:
            if not count % 256:
                ser.write(b'v')
            count += 1
            byteS = serReadByte(ser)
            if byteF != byteS:
                print('data mismatch at byte 0x%x' % (count))
                print('read 0x%x, expected 0x%x' % (byteS[0], byteF[0]))
                exit()
            byteF = f.read(1)
    print('Verify OK')
    ser.close()

def Program(ser, data_file_name):
    print('Programming data ...')
    ser = initSerial(True)
    
    # write 'w' to begin memory erase and write
    ser.write(b'w')

    count = 0

    with Path(data_file_name).open('rb') as f:
        bytewrite = f.read(1)
        while bytewrite:
            count += 1
            try:
                n = ser.write(bytewrite)
                if not n:
                    print('error writing byte %d' % (count))
                    exit()
            except e:
                print(e)
                exit()
            byteread = ser.read()
            if len(byteread):
                print(byteread.decode(), end='')
            bytewrite = f.read(1)

    print('%d bytes written.' % (count))
    ser.close()

#parser = argparse.ArgumentParser(description='Write binary data to serial')
#parser.add_argument('-v', action='store_true')
#parser.add_argument('-p', action='store_true')
#args = parser.parse_args()

#flowcontrol = not args.v

def initSerial(flowcontrol):
    return serial.Serial(port='/dev/ttyUSB0',timeout=0,baudrate=baud, xonxoff=flowcontrol)

#ser = initSerial(flowcontrol)

#if args.v:
#    Verify(ser)
#elif args.p:
#Program(ser)

#ser.close()



