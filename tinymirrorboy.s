include "include/hardware.inc/hardware.inc"

SECTION "HeaderFree1", ROM0[$100]
	; 4 bytes
start:
	ld	l, LOW(rLCDC)
	jr	afterLogo
	; we could fall through and run the logo
SECTION "HeaderLogo", ROM0[$104]
	; This is the first half of the nintendo logo (cgb doesn't need more)
	; Expressed as assembly
	; This can't be changed and for 64B 
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
	;db %11100100,%01001111 ; L
	;db %01101001,%10010110 ; O
	;db %01010101,%01010010 ; V
	;db %01111110,%01000111 ; E
	;db %01100001,%00100111 ; 2
	;db %01100001,%00100111 ; 2
	;db %01100001,%00100111 ; 2
	db %01100001,%00100111 ; 2
	db %01111110,%01000111 ; E
	db %01010101,%01010010 ; V
	db %01101001,%10010110 ; O
	db %01000100,%01001111 ; L

afterLogo:
	dec	h
	push hl
	; disable display
	ld	[hl], b
	; we start at $40 and do +$52
	ld 	h, HIGH(_SCRN0)-1;9800
.cpy:
	ld	a, $D+5  ; we need sth in c
.cpystr:
	dec a
	ld 	[hl+], a
	inc	hl
	dec	e
	jr	nz, .cpystr
	ld 	[hl+], a
	ld	e, 6	
	add hl, de
	dec e
	dec	b
	jr	nz, .cpy
	pop hl
	ld	[hl], h
.loop:

	jr .loop
SECTION "ChecksumFix", ROM0[$13F]
	; needed to fix checksum, which is set at 0x10D
	db	 $6 ; checkha fixes this
SECTION "End64b", ROM0[$140]
	; Is here to generate warnings
	; Will be cut off
	rst $38
	;checksum is $0134-014C
SECTION "HeaderCgb", ROM0[$142]
	; Needed for "hacking" the title checksum
	nop
	; We avoid jumping if this is nop
	nop ; Can be any opcode <$80

SECTION "HeaderFree3", ROM0[$144]
	; 3 bytes
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