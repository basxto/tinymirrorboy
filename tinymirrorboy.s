include "include/hardware.inc/hardware.inc"

SECTION "HeaderFree1", ROM0[$100]
	; 3+1 bytes
	; on mirrored 64B this also acts as header:
	; last 3B of title/manufacturer code (could be used to hack the title checksum)
	; CGB byte (&0x80==1 is CGB mode; &0x83!=0 is PGB mode aka broken)
start:
	ld	l, LOW(rLCDC)
	jr	afterLogo
	; we could fall through and run the logo
SECTION "HeaderLogo", ROM0[$104]
	; This is the first half of the nintendo logo (cgb doesn't need more)
	; Expressed as assembly
	; This can't be changed and for 64B it sets header
	adc  a, $ED     ; New licensee (unimportant)
	ld   h, [hl]    ; sets SGB to $66 / no SGB ; hl is usually $007C
	ld   h, [hl]    ; cartridge Type $66 unknown
	; v== ROM size $CC unknown; RAM size $0D unknown
	call z, $000D   ; destination Japanese ; @$108
	dec  bc         ; use old licensee code
	inc  bc         ; rom version $03
	ld   [hl], e    ; header checksum $73 (has to be fixed else where)
	nop             ; global checksum:    00
	add  e          ;                  $83
	nop
	inc  c
	nop
	dec  c
	nop
	ld   [$1F11], sp
	adc  b          ; @ $118
	adc  c
	nop
	;ld   c, <next byte>
	db   $0E
SECTION "HeaderFree2", ROM0[$11C]
	; This is being used for copying 4x4 images
	; CGB bootrom upscales this to 8x8
	db %01100001,%00100111 ; 2 ; ld h,c;daa
	db %01111110,%01000111 ; E ; ld a,[hl];ld b,a
	db %01010101,%01010010 ; V ; ld d,l;ld d,d (special debug break for BGB)
	db %01101001,%10010110 ; O ; ld l,c;sub [hl]
	db %10001000,%10001111 ; L ; adc b;adc a

afterLogo:
	dec	h
	; store address for later reenabling
	push hl
	; disable display
	ld	[hl], b	; @$128 ; b is 0 on cgb / 1 on agb
	; we start at $40 and do +8 once, then +5 254(cgb)/255(agb) times
	ld 	h, HIGH(_SCRN0)-1;9800
.cpy: ; loop copy all over the screen
	ld	a, $D+5  ; we need sth in c
.cpystr: ; copy str "L O V E B Y T E 2 2             "
	dec a
	ld 	[hl+], a
	inc	hl ; ' '
	dec	e ; (after boot) e is 8 (happens offscreen)
	jr	nz, .cpystr
	ld 	[hl+], a
	ld	e, a
	add hl, de ; d is 0 ; so we add $D
	ld	e, 5
	inc	b; (after boot) b is 0 on cgb / 1 on agb
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