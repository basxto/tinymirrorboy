include "include/hardware.inc/hardware.inc"

SECTION "TL2MP", ROM0[$0]
	; draws 1bpp tile at (de)
	; to map starting at (hl)
	; converts a bit to a byte
	; covers an 8x8 area
	; l+8 has to be <= $FF
tile2map::
	ld	b, 8
.oloop:
	ld	a, [de]
	inc	de
	; skip the second byte since 1bpp
	inc	de
	ld	c, 8
.iloop:
	rlca
	jr	C, .nz
	ld	[hl], 0
	jr	.z
.nz:
	; nonzero tile hardcoded
	ld	[hl], 26
.z:
	inc l
	dec c
	jr NZ, .iloop
	; we just draw 1/4 of the row
	ld	a, $18
	add	a, l
	ld	l, a
	dec	b
	jr NZ, .oloop
	; restore de
	ld	a, e
	sub	a, 16
	ld	e, a
	ld	a, d
	sbc a, b
	ld	d, a

	ret

;	de ; X Y
;	bc ; index and counter
;	hl ; OAM address
rendertext::
.spriteloop:
	ld	a, e
	ld	[hl+], a
	;	Y+=12
	add	a, 12
	ld	e, a
	ld	a, d
	ld	[hl+], a
	;	X+=6
	add	a, 6
	ld	d, a
	ld	a, b
	ld	[hl+], a
	inc b
	; switch to OBJ1
	; only has to be $10, but emulator compatibility...
	ld a, $11
	ld	[hl+], a
	dec c
	jr NZ, .spriteloop
	ret

vmove::
	ld hl, rSCY
	inc [hl]
	; also use rDIV for music
	ldh	a, [rDIV]
	;rrca
	ldh [rNR14], a

	reti


SECTION "VBLANK", ROM0[$40]
	ldh	a, [rDIV]
	and a,$12
	jr Z, vmove
	reti


SECTION "HBLANK", ROM0[$48]

	ldh	a, [rLY]
	inc a
	ld	b, a
	ldh	a, [rSCY]
	add	a, b
	; do sprite flashing
	ldh [rOBP1], a
	; change offset every 8 scanlines
	and	a, 8
	rrca
	; add general X offset
	add	a, 150
	ldh [rSCX], a

	; define background "image"
	ld	a, b
	inc a
	and	a, $FD
	or	a, $80
	ldh [rBGP], a
	reti

;SECTION "Main", ROM0[$61]

main::
	ldh [rLCDC], a

	ld	a, $08
	ld hl, $81A0
	ld b, l
	call sierpinski

	; load sierpinski tile
	; as a tilemap
	ld	de, $81A0
	ld	hl, $980C
	call	tile2map

	inc	h
	ld	l,  $08
	call	tile2map
	ld	l,  $10
	call	tile2map

	inc	h
	ld	l,  $04
	call	tile2map
	ld	l,  $14
	call	tile2map

	inc	h
	ld	l,  b
	call	tile2map
	ld	l,  $08
	call	tile2map
	ld	l,  $10
	call	tile2map
	ld	l,  $18
	call	tile2map

	; show "text"
	ld	de, $3420 ; X Y
	ld	bc, $0D0A ; index and counter
	ld	hl, _OAMRAM
	call rendertext
	ld	de, $683E ; X Y
	ld	bc, $1501 ; index and counter
	call rendertext
	ld	bc, $1702 ; index and counter
	call rendertext

	; enable display again
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_OBJON
	ldh [rLCDC], a

	ld	a, STATF_MODE00 | STATF_MODE01
	ldh	[rSTAT], a
	ld	a, IEF_LCDC | IEF_VBLANK
	ldh	[rIE], a
	; set hl for use in interrupt  handler
	ld	hl, rSCX
	; enable interrupts
	ei
infloop::
	halt
	jr infloop

	; Should be copied to any custom section
	; We have some header overhang, we have to keep in mind
	; Removes header size from 256B section
	assert WARN, @ < 256-LOW(HeaderEnd), "Main section is too big"

SECTION "HeaderFree1", ROM0[$100]
	; 4 bytes
	xor a
	jp main
	; we could fall through and run the logo
SECTION "HeaderLogo", ROM0[$104]
	; This is the first half of the nintendo logo (cgb doesn't need more)
	; Expressed as assembly
	adc  a, $ED
	ld   h, [hl] ; usually $007D
	ld   h, [hl]
	call z, $000D
	dec  bc
	inc  bc
	ld   [hl], e
	nop
	add  e
	nop
	inc  c
	nop
	dec  c
	nop
	ld   [$1F11], sp
	adc  b
	adc  c
	nop
	;ld   c, <next byte>
	db   $0E
SECTION "HeaderFree2", ROM0[$11C]
	; This is being used for copying 4x4 images
	db %11100101,%01100101 ; R
	db %01111110,%01000111 ; E
	db %01010101,%01010010 ; V
	db %01110010,%00100111 ; I
	db %00110100,%00010110 ; S
	db %01110010,%00100111 ; I
	db %01101001,%10010110 ; O
	db %10011101,%10111001 ; N
	db %01100001,%00100111 ; 2
	db %00100110,%00100111 ; 1
	db %01110100,%00010110 ; 5
	db %01110100,%01110111 ; 6
afterHeader:

sierpinski::
	; We start in the center
	; and move  to the left
	bit 0, b
	jr NZ, .odd
	rlca
.odd:
    ; write as 1BPP
    ld [hl+], a ; 1
    ld [hl+], a ; 1
    ld d, a
	; triangle grows to the right
    rrca
    xor a, d
    dec b ; 1
    ; loop while b != 0
	jr NZ, sierpinski ; 2
	ret


SECTION "HeaderCgb", ROM0[$142]
	; Needed for "hacking" the title checksum
	nop
	; We avoid jumping if this is nop
	nop ; Can be any opcode <$80

SECTION "HeaderFree3", ROM0[$144]
	; 3 bytes
	; This is just a placeholder
	nop
	nop
	nop

SECTION "HeaderCartridge", ROM0[$147]
	; 3 bytes
	; Could have other values, but those are the safest
	; MBC should be able to handle ld [$1F11], sp and ld [hl], e
	nop ; no MBC
	nop ; 0 rom banks
	nop ; 0 ram banks

SECTION "HeaderFree4", ROM0[$14A]
	; 1 bytes
	nop

SECTION "HeaderCheck", ROM0[$14B]
	; We have to pretend being nintendo
	; This allows us to select palettes
	db	$1
	; ROM mask version
	; can freely use this
	nop
	; Will be fixed by rgbfix
	db	$86

SECTION "HeaderEnd", ROM0[$14E]
HeaderEnd::
	; Is here to generate warnings
	; Will be cut off
	rst $38