
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

ROM:=tinymirrorboy
EXT:=cgb

.PHONY: build clean
build: $(ROM).mirrored.$(EXT)

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $^

%.$(EXT): %.o
	$(LD) $(LDFLAGS) -o $@ -m $*.map -n $*.sym $^
	$(TCH) $@ '$$142' '$(palette)'
	$(FIX) -f h $@

%.smol.$(EXT): %.$(EXT)
	$(DD) if=$< of=$@ bs=1 skip=$$((0x100)) count=$$((0x40))

%.mirrored.$(EXT): %.smol.$(EXT)
	cat $< $< $< $< $< > $@

clean:
	$(RM) $(ROM).$(EXT) *.o *.sym *.map