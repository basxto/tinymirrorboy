
.SUFFIXES:

RGBDS:=

AS=$(RGBDS)rgbasm
ASFLAGS=--halt-without-nop
LD=$(RGBDS)rgblink
LDFLAGS=
FIX:=$(RGBDS)rgbfix
CHA:=tools/checkha/checkha.py
BPS:=flips
DD:=dd
# cgb builtin palette
palette:=0x9c

ROM:=tinymirrorboy
EXT:=cgb

.PHONY: build clean
build: $(ROM).64b.$(EXT) $(ROM).mirrored.384b.$(EXT) $(ROM).mirrored.16k.$(EXT) $(ROM).mirrored.32k.$(EXT)

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $^

%.$(EXT): %.o
	$(LD) $(LDFLAGS) -o $@ -m $*.map -n $*.sym $^
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

%.mirrored.32k.$(EXT): %.mirrored.16k.$(EXT)
	cat $< $< > $@

%.zip: $(ROM).64b.$(EXT) $(ROM).mirrored.384b.$(EXT) $(ROM).mirrored.16k.$(EXT) $(ROM).mirrored.32k.$(EXT)
	zip -r $@ $^ Makefile README.md FILE_ID.DIZ $(ROM).png $(ROM).mp4

# place the original roms in ori/
%.bps: ori/% %
	$(BPS) --create $^ $@

clean:
	$(RM) $(ROM).$(EXT) *.o *.sym *.map