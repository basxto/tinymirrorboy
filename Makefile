
.SUFFIXES:

RGBDS:=

AS=$(RGBDS)rgbasm
ASFLAGS=--halt-without-nop
LD=$(RGBDS)rgblink
LDFLAGS=
FIX:=$(RGBDS)rgbfix
TCH:=tools/titchack/titchack.py
DD:=dd
# cgb builtin palette
palette:=0x9c

ROM:=sierpinskiboy
EXT:=cgb

.PHONY: build clean
build: $(ROM).$(EXT)

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $^

%.$(EXT): %.o
	$(LD) $(LDFLAGS) -o $@ -m $*.map -n $*.sym $^
	$(TCH) $@ '$$142' '$(palette)'
	$(FIX) -f h $@

%.smol.$(EXT): %.$(EXT)
	$(DD) if=$< of=$@ bs=1 count=$$((0x14E))

clean:
	$(RM) $(ROM).$(EXT) *.o *.sym *.map