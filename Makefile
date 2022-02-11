
.SUFFIXES:

RGBDS:=

AS=$(RGBDS)rgbasm
ASFLAGS=--halt-without-nop
LD=$(RGBDS)rgblink
LDFLAGS=
FIX:=$(RGBDS)rgbfix
TCH:=tools/titchack/titchack.py
CHA:=tools/checkha/checkha.py
DD:=dd
# cgb builtin palette
palette:=0x9c

ROM:=tinymirrorboy
EXT:=cgb

.PHONY: build clean
build: $(ROM).64b.$(EXT) $(ROM).mirrored.384b.$(EXT) $(ROM).mirrored.16k.$(EXT)

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $^

%.$(EXT): %.o
	$(LD) $(LDFLAGS) -o $@ -m $*.map -n $*.sym $^
	$(TCH) $@ '$$142' '$(palette)'
#	$(FIX) -f h $@
	$(CHA) $@ '$$13F'

%.64b.$(EXT): %.$(EXT)
	$(DD) if=$< of=$@ bs=1 skip=$$((0x100)) count=$$((0x40))

%.mirrored.384b.$(EXT): %.64b.$(EXT)
	cp $< $@
	for i in $$(seq 5); do cat $< >> $@; done

%.mirrored.16k.$(EXT): %.mirrored.384b.$(EXT) %.64b.$(EXT)
	cp $< $@
	for i in $$(seq 41); do cat $< >> $@; done
	for i in $$(seq 4); do cat $*.64b.$(EXT) >> $@; done

clean:
	$(RM) $(ROM).$(EXT) *.o *.sym *.map