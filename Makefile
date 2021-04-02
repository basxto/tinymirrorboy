
.SUFFIXES:

RGBDS:=

AS=$(RGBDS)rgbasm
ASFLAGS=
LD=$(RGBDS)rgblink
LDFLAGS=
FIX:=$(RGBDS)rgbfix
TCH:=tools/titchack/titchack.py
# cgb builtin palette
palette:=0x9c

ROM:=sierpinskiboy
EXT:=cgb

.PHONY: build clean
build: $(ROM).$(EXT)

%.o: %.s
	$(AS) -o $@ $^

%.$(EXT): %.o
	$(LD) -o $@ -m $*.map -n $*.sym $^
	$(TCH) $@ '$$142' '$(palette)'
	$(FIX) -f h $@

clean:
	$(RM) $(ROM).$(EXT) *.o *.sym *.map