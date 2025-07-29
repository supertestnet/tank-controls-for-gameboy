;;;;;;;;;;;; BOILERPLATE ;;;;;;;;;;;;

include "hardware.inc"  ; Include hardware definitions so we can use nice names for things

; Define a section that starts at the point the bootrom execution ends
SECTION "Start", ROM0[$0100]
    jp EntryPoint       ; Jump past the header space to our actual code

    ds $150-@, 0        ; Allocate space for RGBFIX to insert our ROM header by allocating
                        ;  the number of bytes from our current location (@) to the end of the
                        ;  header ($150)

EntryPoint:
    ; Turn off the LCD when it's safe to do so (during VBlank)
.waitVBlank
    ldh a, [rLY]        ; Read the LY register to check the current scanline
    cp SCRN_Y           ; Compare the current scanline to the first scanline of VBlank
    jr c, .waitVBlank   ; Loop as long as the carry flag is set
    ld a, 0             ; Once we exit the loop we're safely in VBlank
    ldh [rLCDC], a      ; Disable the LCD (must be done during VBlank to protect the LCD)

;;;;;;;;;;;; DRAW THE SCREEN ;;;;;;;;;;;;

    ; Copy the tile data
    ld de, Tiles
    ld hl, $8800
    ld bc, TilesEnd - Tiles
    call Memcopy

    ; This code fills the tilemap with the background tile
    ld hl, _SCRN0       ; Point HL to the first tile of the screen ($9800)
    ld bc, $400         ; Load the size of the screen into BC (32x32=1024, or $400)
    ld d, 128           ; Load the background tile into D, you will fill the screen with this
.clearLoop
    ld [hl], d          ; Load the tile in D into the tile of the screen pointed to by HL
    inc hl              ; Increment the destination pointer in HL
    dec bc              ; Decrement the loop counter in BC
    ld a, b             ; Load the value in B into A
    or c                ; Logical OR the value in A (from B) with C
    jr nz, .clearLoop   ; If B and C are both zero, OR C will be zero, otherwise keep looping

    ; Copy the player tile
    ld de, Player
    ld hl, $8a40
    ld bc, PlayerEnd - Player
    call Memcopy

    ; Prepare to clear _OAMRAM, then clear it
    ld a, 0
    ld b, 160
    ld hl, _OAMRAM
ClearOam:
    ld [hli], a
    dec b
    jp nz, ClearOam

    ; Setup palettes and scrolling
    ld a, %11100100     ; Define a 4-shade palette from darkest (11) to lightest (00)
    ldh [rBGP], a       ; Set background palette
    ldh [rOBP0], a      ; Set object palette 0
    ld a, %00000000     ; Define an alternative palette
    ldh [rOBP1], a      ; Set object palette 1

    ; The first sprite is the player; put him in the bottom-left corner of the screen and use object palette 0
    ld hl, _OAMRAM      ; Load the destination address in OAMRAM into HL
    ld a, 128 + 16      ; Load the value 128 + 16 into the A register
    ld [hli], a         ; Set the Y coordinate (plus 16) for the sprite in OAMRAM, increment HL
    ld a, 16 + 8        ; Load the value 16 + 8 into the A register
    ld [hli], a         ; Set the X coordinate (plus 8) for the sprite in OAMRAM, increment HL
    ld a, 164           ; Load the tile at index 62 into the A register
    ld [hli], a         ; Set the tile index for the sprite in OAMRAM, increment HL
    xor a               ; Set A to zero so that I use palette 0 for the player
    ld [hli], a         ; Set the attributes (flips and palette) for the sprite in OAMRAM, increment HL

    ; The next sprites are three counters; put them in the bottom-right corner of the screen
    ; and use object palette 0
    ld a, 128 + 16      ; Load the value 128 + 16 into the A register
    ld [hli], a         ; Set the Y coordinate (plus 16) for the sprite in OAMRAM, increment HL
    ld a, 120 + 8       ; Load the value 120 + 8 into the A register
    ld [hli], a         ; Set the X coordinate (plus 8) for the sprite in OAMRAM, increment HL
    ld a, 143           ; Load the tile at index 143 into the A register
    ld [hli], a         ; Set the tile index for the sprite in OAMRAM, increment HL
    ld a, OAMF_PAL1     ; Load into A the flags to use OBP1 for this sprite
    ld [hli], a         ; Set the attributes (flips and palette) for the sprite in OAMRAM, increment HL

    ld a, 128 + 16      ; Load the value 128 + 16 into the A register
    ld [hli], a         ; Set the Y coordinate (plus 16) for the sprite in OAMRAM, increment HL
    ld a, 130 + 8       ; Load the value 120 + 8 into the A register
    ld [hli], a         ; Set the X coordinate (plus 8) for the sprite in OAMRAM, increment HL
    ld a, 143           ; Load the tile index 143 into the AB register
    ld [hli], a         ; Set the tile index for the sprite in OAMRAM, increment HL
    ld a, OAMF_PAL1     ; Load into A the flags to use OBP1 for this sprite
    ld [hli], a         ; Set the attributes (flips and palette) for the sprite in OAMRAM, increment HL

    ld a, 128 + 16      ; Load the value 128 + 16 into the A register
    ld [hli], a         ; Set the Y coordinate (plus 16) for the sprite in OAMRAM, increment HL
    ld a, 140 + 8       ; Load the value 120 + 8 into the A register
    ld [hli], a         ; Set the X coordinate (plus 8) for the sprite in OAMRAM, increment HL
    ld a, 143           ; Load the tile index 143 into the A register
    ld [hli], a         ; Set the tile index for the sprite in OAMRAM, increment HL
    ld a, OAMF_PAL1     ; Load into A the flags to use OBP1 for this sprite
    ld [hli], a         ; Set the attributes (flips and palette) for the sprite in OAMRAM, increment HL

    ld a, 0             ; Load zero into the register A
    ldh [rSCX], a       ; Set the background scroll registers to show the top-left
    ldh [rSCY], a       ; Set the corner of the background in the top-left corner of the screen

;;;;;;;;;;;; DISPLAY WHAT YOU DREW ;;;;;;;;;;;;

    ; Combine flag constants defined in hardware.inc into a single value with logical ORs and load it into A
    ; Note that some of these constants (LCDCF_WINOFF) are zero, but are included for clarity
    ld a, LCDCF_ON | LCDCF_BG8000 | LCDCF_BGON | LCDCF_OBJON | LCDCF_WINOFF
    ldh [rLCDC], a      ; Enable and configure the LCD to show the background and object

;;;;;;;;;;;; INITIALIZE GLOBAL VARIABLES ;;;;;;;;;;;;

    ld a, 0
    ld [wFrameCounter], a
    ld [pAngle], a
    ld [wCurKeys], a
    ld [wNewKeys], a
    ld [FailMove], a
    ld a, 143
    ld [PlayerNextX], a
    ld a, 24
    ld [PlayerNextY], a
    ld a, 151
    ld [WallOneXOne], a
    ld a, 18
    ld [WallOneXTwo], a
    ld a, 10
    ld [WallOneYOne], a
    ld [WallOneYTwo], a

;;;;;;;;;;;; MAIN LOOP ;;;;;;;;;;;;

Main:
    ld a, [rLY]
    cp 144
    jp nc, Main
WaitVBlank2:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank2

    ; Increment the frame counter
    ld a, [wFrameCounter]
    inc a
    ld [wFrameCounter], a

    ; Reset the frame counter
    call ResetFrameCounter

    ; Check the current keys every frame and move left or right.
    call UpdateKeys

    ; Do raycasting
    ; call CastRays

    ; Check if the right button is pressed.
CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, CheckLeft
Right:
    ; Rotate the player clockwise.
    ld a, [pAngle]
    add a, 2
    ld [pAngle], a
    jp CheckUp

    ; Check if the left button is pressed.
CheckLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jp z, CheckDown
Left:
    ; Rotate the player counterclockwise.
    ld a, [pAngle]
    sub a, 2
    ld [pAngle], a
    jp CheckUp

CheckDown:
    ld a, [wCurKeys]
    and a, PADF_DOWN
    jp z, CheckUp
Down:
    ; Clear FailMove.
    call SetFailToZero
    jp CheckUp

    ; Check if the up button is pressed.
CheckUp:
    ld a, [wCurKeys]
    and a, PADF_UP
    jp z, Main
Up:
    ; Skip movement usually
    ld a, [wFrameCounter]
    cp 6
    jp c, Main
    ; Set the player's next X and Y coordinates per the pAngle
    ld a, [pAngle]
    ; if pAngle is less than 20, set up+up
    cp 20
    jp c, MoveUpUp
    ; if pAngle is less than 39, set up+up+right
    cp 39
    jp c, MoveUpUpRight
    ; if pAngle is less than 59, set up+right+right
    cp 59
    jp c, MoveUpRightRight
    ; if pAngle is less than 79, set right+right
    cp 79
    jp c, MoveRightRight
    ; if pAngle is less than 98, set right+right+down
    cp 98
    jp c, MoveRightRightDown
    ; if pAngle is less than 118, set right+down+down
    cp 118
    jp c, MoveRightDownDown
    ; if pAngle is less than 138, set down+down
    cp 138
    jp c, MoveDownDown
    ; if pAngle is less than 158, set down+down+left
    cp 158
    jp c, MoveDownDownLeft
    ; if pAngle is less than 177, set down+left+left
    cp 177
    jp c, MoveDownLeftLeft
    ; if pAngle is less than 196, set left+left
    cp 196
    jp c, MoveLeftLeft
    ; if pAngle is less than 217, set left+left+up
    cp 217
    jp c, MoveLeftLeftUp
    ; if pAngle is less than 236, set left+up+up
    cp 236
    jp c, MoveLeftUpUp
    ; if pAngle is greater than or equal to 236, set up+up
    jp MoveUpUp
MoveUpUp:
    ; Move the player two pixels up.
    ld a, [_OAMRAM]
    dec a
    dec a
    ld [PlayerNextX], a
    ld a, [_OAMRAM + 1]
    ld [PlayerNextY], a
    jp PerformEdgeDetection
MoveUpUpRight:
    ; Move the player two pixels up, one pixel right.
    ld a, [_OAMRAM]
    dec a
    dec a
    ld [PlayerNextX], a
    ld a, [_OAMRAM + 1]
    inc a
    ld [PlayerNextY], a
    jp PerformEdgeDetection
MoveUpRightRight:
    ; Move the player one pixel up, two pixels right.
    ld a, [_OAMRAM]
    dec a
    ld [PlayerNextX], a
    ld a, [_OAMRAM + 1]
    inc a
    inc a
    ld [PlayerNextY], a
    jp PerformEdgeDetection
MoveRightRight:
    ; Move the player two pixels right.
    ld a, [_OAMRAM + 1]
    inc a
    inc a
    ld [PlayerNextY], a
    ld a, [_OAMRAM]
    ld [PlayerNextX], a
    jp PerformEdgeDetection
MoveRightRightDown:
    ; Move the player two pixels right, one pixel down.
    ld a, [_OAMRAM + 1]
    inc a
    inc a
    ld [PlayerNextY], a
    ld a, [_OAMRAM]
    inc a
    ld [PlayerNextX], a
    jp PerformEdgeDetection
MoveRightDownDown:
    ; Move the player one pixel right, two pixels down.
    ld a, [_OAMRAM + 1]
    inc a
    ld [PlayerNextY], a
    ld a, [_OAMRAM]
    inc a
    inc a
    ld [PlayerNextX], a
    jp PerformEdgeDetection
MoveDownDown:
    ; Move the player two pixels down.
    ld a, [_OAMRAM]
    inc a
    inc a
    ld [PlayerNextX], a
    ld a, [_OAMRAM + 1]
    ld [PlayerNextY], a
    jp PerformEdgeDetection
MoveDownDownLeft:
    ; Move the player two pixels down, one pixel left.
    ld a, [_OAMRAM]
    inc a
    inc a
    ld [PlayerNextX], a
    ld a, [_OAMRAM + 1]
    dec a
    ld [PlayerNextY], a
    jp PerformEdgeDetection
MoveDownLeftLeft:
    ; Move the player two pixels down, one pixel left.
    ld a, [_OAMRAM]
    inc a
    ld [PlayerNextX], a
    ld a, [_OAMRAM + 1]
    dec a
    dec a
    ld [PlayerNextY], a
    jp PerformEdgeDetection
MoveLeftLeft:
    ; Move the player two pixels left.
    ld a, [_OAMRAM + 1]
    dec a
    dec a
    ld [PlayerNextY], a
    ld a, [_OAMRAM]
    ld [PlayerNextX], a
    jp PerformEdgeDetection
MoveLeftLeftUp:
    ; Move the player two pixels left and one pixel up.
    ld a, [_OAMRAM + 1]
    dec a
    dec a
    ld [PlayerNextY], a
    ld a, [_OAMRAM]
    dec a
    ld [PlayerNextX], a
    jp PerformEdgeDetection
MoveLeftUpUp:
    ; Move the player one pixel left and two pixels up.
    ld a, [_OAMRAM + 1]
    dec a
    ld [PlayerNextY], a
    ld a, [_OAMRAM]
    dec a
    dec a
    ld [PlayerNextX], a
    jp PerformEdgeDetection

;;;;;;;;;;;; FUNCTIONS ;;;;;;;;;;;;

ResetFrameCounter:
    ; Do nothing if we are below frame 9
    ld a, [wFrameCounter]
    cp 9
    jp c, ReturnImmediately

    ; reset framecounter to 0
    xor a
    ld [wFrameCounter], a
    ret

ReturnImmediately:
    ret

SetDisplayToOne:
    ld b, a
    ld a, 155
    ld [_OAMRAM + 2 + 4 + 4 + 4], a
    ld a, b
    ret

SetDisplayToZero:
    ld b, a
    ld a, 143
    ld [_OAMRAM + 2 + 4 + 4 + 4], a
    ld a, b
    ret

SetFailToZero:
    ; the next two lines set FailMove to 1
    ; ld a, 1
    ; ld [FailMove], a
    ; the remaining lines set it to 0
    ld b, a
    xor a
    ld [FailMove], a
    ld a, b
    ret

UserIsGood:
    ; call SetFailToZero
    ld a, [PlayerNextY]
    ld [_OAMRAM + 1], a
    ld a, [PlayerNextX]
    ld [_OAMRAM], a
    jp Main

CastRays:
    ld a, [PlayerNextY]
    ld b, a
    ld a, [PlayerNextX]
    sub a, 8
    ld hl, $FE00 + 4    ; Load the destination address in OAMRAM into HL
    ld [hli], a         ; Set the Y coordinate (plus 16) for the sprite in OAMRAM, increment HL
    ld a, b             ; Load the wall's X coordinate into A
    ld [hli], a         ; Set the X coordinate (plus 8) for the sprite in OAMRAM, increment HL
    ld a, 164           ; Load the tile at index 62 into the A register
    ld [hli], a         ; Set the tile index for the sprite in OAMRAM, increment HL
    xor a               ; Set A to zero so that I use palette 0 for the wall
    ld [hli], a         ; Set the attributes (flips and palette) for the sprite in OAMRAM, increment HL
    ret

PerformEdgeDetection:
    ; Check if player will be below WallOne's high Y coordinate
    ld a, [PlayerNextY]
    ld b, a
    ld a, [WallOneYOne]
    cp b
    ; If the user passed this test, set Fail to zero and save the new coordinates.
    jp c, UserIsGood
    ; Otherwise, do the next test.
    ; Check if player will be at or above WallOne's low Y coordinate
    ld a, [PlayerNextY]
    ld b, a
    ld a, [WallOneYTwo]
    cp b
    ; If the user passed this test, set Fail to zero and save the new coordinates
    jp c, UserIsGood
    ; Otherwise, do the next test
    ; Check if player will be below WallOne's high X coordinate.
    ld a, [PlayerNextX]
    ld b, a
    ld a, [WallOneXOne]
    cp b
    ; If the user passed this test, set Fail to zero and save the new coordinates.
    jp c, UserIsGood
    ; Otherwise, check if player will be at or above WallOne's low X coordinate.
    ld a, [PlayerNextX]
    ld b, a
    ld a, [WallOneXTwo]
    cp b
    ; If the user failed this test, display a wall and go to Main.
    jp c, Main
    ; Otherwise, set Fail to zero and save the new coordinates.
    jp UserIsGood

UpdateKeys:
  ; Poll half the controller
  ld a, P1F_GET_BTN
  call .onenibble
  ld b, a ; B7-4 = 1; B3-0 = unpressed buttons

  ; Poll the other half
  ld a, P1F_GET_DPAD
  call .onenibble
  swap a ; A7-4 = unpressed directions; A3-0 = 1
  xor a, b ; A = pressed buttons + directions
  ld b, a ; B = pressed buttons + directions

  ; And release the controller
  ld a, P1F_GET_NONE
  ldh [rP1], a

  ; Combine with previous wCurKeys to make wNewKeys
  ld a, [wCurKeys]
  xor a, b ; A = keys that changed state
  and a, b ; A = keys that changed to pressed
  ld [wNewKeys], a
  ld a, b
  ld [wCurKeys], a
  ret

.onenibble
  ldh [rP1], a ; switch the key matrix
  call .knownret ; burn 10 cycles calling a known ret
  ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
  ldh a, [rP1]
  ldh a, [rP1] ; this read counts
  or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
.knownret
  ret

; Copy bytes from one area to another.
; @param de: Source
; @param hl: Destination
; @param bc: Length
Memcopy:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, Memcopy
    ret

;;;;;;;;;;;; DATA STORAGE ;;;;;;;;;;;;

; Our tile data in 2bpp planar format (https://gbdev.io/pandocs/Tile_Data.html)
Tiles:
    REPT 8
    dw `11111111
    ENDR
        ; A
    dw `10000111
    dw `00000011
    dw `00110011
    dw `00000011
    dw `00000011
    dw `00110011
    dw `00110011
    dw `00110011
    ; B
    dw `00000111
    dw `00000011
    dw `00110011
    dw `00000111
    dw `00000011
    dw `00110011
    dw `00110011
    dw `00000111
    ; C
    dw `11100011
    dw `11000011
    dw `10011111
    dw `00111111
    dw `00111111
    dw `10011111
    dw `11000011
    dw `11100011
    ; D
    dw `00001111
    dw `00000111
    dw `00110011
    dw `00110011
    dw `00110011
    dw `00110011
    dw `00000111
    dw `00001111
    ; E
    dw `00000011
    dw `00111111
    dw `00111111
    dw `00000011
    dw `00111111
    dw `00111111
    dw `00000011
    dw `00000011
    ; F
    dw `00000011
    dw `00111111
    dw `00111111
    dw `00000011
    dw `00111111
    dw `00111111
    dw `00111111
    dw `00111111
    ; G
    dw `11000011
    dw `10000011
    dw `10011111
    dw `00110001
    dw `00111001
    dw `10010011
    dw `11000011
    dw `11100111
    ; H
    dw `00110011
    dw `00110011
    dw `00110011
    dw `00000011
    dw `00000011
    dw `00110011
    dw `00110011
    dw `00110011
    ; I
    dw `00000011
    dw `00000011
    dw `11001111
    dw `11001111
    dw `11001111
    dw `11001111
    dw `00000011
    dw `00000011
    ; J
    dw `10000001
    dw `10000001
    dw `11111001
    dw `11111001
    dw `10001001
    dw `10001001
    dw `10011001
    dw `11000011
    ; K
    dw `00111001
    dw `00110011
    dw `00100111
    dw `00011111
    dw `00001111
    dw `00100111
    dw `00110011
    dw `00111001
    ; L
    dw `00111111
    dw `00111111
    dw `00111111
    dw `00111111
    dw `00111111
    dw `00111111
    dw `00000011
    dw `00000011
    ; M
    dw `10010011
    dw `00010001
    dw `00101001
    dw `00101001
    dw `00101001
    dw `00101001
    dw `00101001
    dw `00101001
    ; N
    dw `00111001
    dw `00011001
    dw `00011001
    dw `00101001
    dw `00100001
    dw `00110001
    dw `00111001
    dw `00111001
    ; O
    dw `11000011
    dw `11000011
    dw `10011001
    dw `10011001
    dw `10011001
    dw `10011001
    dw `11000011
    dw `11000011
    ; P
    dw `00000111
    dw `00111001
    dw `00111001
    dw `00000011
    dw `00000111
    dw `00111111
    dw `00111111
    dw `00111111
    ; Q
    dw `11000011
    dw `11000011
    dw `10011001
    dw `10011001
    dw `10001001
    dw `10010001
    dw `11000011
    dw `11001001
    ; R
    dw `00000111
    dw `00111001
    dw `00111001
    dw `00000011
    dw `00001111
    dw `00100111
    dw `00110011
    dw `00111001
    ; S
    dw `10000001
    dw `00000001
    dw `00111111
    dw `10000011
    dw `10000001
    dw `11111001
    dw `00000001
    dw `00000001
    ; T
    dw `00000011
    dw `00000011
    dw `11001111
    dw `11001111
    dw `11001111
    dw `11001111
    dw `11001111
    dw `11001111
    ; U
    dw `10011001
    dw `10011001
    dw `10011001
    dw `10011001
    dw `10011001
    dw `10011001
    dw `11000011
    dw `11000011
    ; V
    dw `10011001
    dw `10011001
    dw `10011001
    dw `10011001
    dw `10011001
    dw `10011001
    dw `11000011
    dw `11100111
    ; W
    dw `00101001
    dw `00101001
    dw `00101001
    dw `00101001
    dw `00101001
    dw `00101001
    dw `00010001
    dw `10010011
    ; X
    dw `00111001
    dw `00110011
    dw `10010011
    dw `11000111
    dw `11001111
    dw `10010011
    dw `00110011
    dw `00111001
    ; Y
    dw `00111001
    dw `00110011
    dw `10010011
    dw `11000111
    dw `11001111
    dw `11001111
    dw `11001111
    dw `11001111
    ; Z
    dw `00000001
    dw `00000001
    dw `11110001
    dw `11100011
    dw `11000111
    dw `10001111
    dw `00000001
    dw `00000001
    ; 1
    dw `11000011
    dw `10000011
    dw `11100111
    dw `11100111
    dw `11100111
    dw `11100111
    dw `10000001
    dw `10000001
    ; 2
    dw `11000011
    dw `10011001
    dw `10011001
    dw `11110011
    dw `11100111
    dw `11001111
    dw `10000001
    dw `10000001
    ; 3
    dw `00000111
    dw `11110011
    dw `11110011
    dw `00000111
    dw `11110011
    dw `11110011
    dw `00000011
    dw `00000111
    ; 4
    dw `10011001
    dw `10011001
    dw `10011001
    dw `10011001
    dw `11000001
    dw `11111001
    dw `11111001
    dw `11111001
    ; 5
    dw `10000001
    dw `10000001
    dw `10011111
    dw `10000011
    dw `10000001
    dw `11111001
    dw `10000001
    dw `10000011
    ; 6
    dw `11000001
    dw `10000011
    dw `10011111
    dw `10000011
    dw `10000001
    dw `10011001
    dw `10000001
    dw `11000011
    ; 7
    dw `00000001
    dw `00000001
    dw `11110001
    dw `11100011
    dw `11000111
    dw `10001111
    dw `00011111
    dw `00111111
    ; 8
    dw `11000001
    dw `10011001
    dw `10011001
    dw `11000011
    dw `10000001
    dw `10011001
    dw `10011001
    dw `11000011
    ; 9
    dw `11000011
    dw `10000001
    dw `10011001
    dw `10000001
    dw `11000001
    dw `11111001
    dw `10000001
    dw `11000011
TilesEnd:

Player:
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00033000
    dw `00033000
    dw `00000000
    dw `00000000
    dw `00000000
PlayerEnd:

SECTION "Counter", WRAM0
wFrameCounter: db
pAngle: db

SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db

SECTION "Player's Next Coordinates", WRAM0
PlayerNextX: db
PlayerNextY: db
FailMove: db

SECTION "Walls", WRAM0
WallOneXOne: db
WallOneXTwo: db
WallOneYOne: db
WallOneYTwo: db
