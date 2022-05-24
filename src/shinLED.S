@ shinLED.S
@ function library for controlling microbit LED
@ Written by Yuxuan Lin, 2022
.syntax unified 

// ------------------------ Module Interface -----------------------------
.global set_bit, set_DIR_row, set_DIR_col, set_OUT_row
.global clear_bit, clear_DIR_col, clear_OUT_row       
.global copy_bits                                           

// ------------------------ Implementation -------------------------------
/*
  This function sets a specific bit at an offset from a base address.
  
  Parameters
  ----------
    r1 : The base address.
    r2 : The offset.
    r3 : The bit index.
  
  Returns
  -------
    None
 */
.type set_bit, %function
set_bit:
  push {r0-r4, lr}
  mov r4, 0b1
  ldr r0, [r1, r2]
  lsl r3, r4, r3
  orr r0, r3
  str r0, [r1, r2]
  pop {r0-r4, lr}
  bx lr
.size set_bit, .-set_bit

/*
  This function clears a specific bit at an offset from a base address.
  
  Parameters
  ----------
    r1 : The base address.
    r2 : The offset.
    r3 : The bit index.
  
  Returns
  -------
    None
 */
.type clear_bit, %function
clear_bit:
  push {r0-r4, lr}
  mov r4, 0b1
  ldr r0, [r1, r2]
  lsl r3, r4, r3
  bic r0, r3
  str r0, [r1, r2]
  pop {r0-r4, lr}
  bx lr
 .size clear_bit, .-clear_bit

/*
  This function sets DIR for all the rows.
  
  Parameters
  ----------
    r1 : Port number (P0 by default).
  
  Returns
  -------
    None
 */
.type set_DIR_row, %function
set_DIR_row:
  push {r4-r5, lr}

  ldr r2, =DIR
  mov r4, 0 @ counter for set_DIR_row_loop

set_DIR_row_loop:
  mov r0, 4
  mul r0, r4
  ldr r5, =rows
  ldr r3, [r5, r0]
  bl set_bit

  add r4, 1
  cmp r4, 5
  blt set_DIR_row_loop

  pop {r4-r5, lr}
  bx lr
.size set_DIR_row, .-set_DIR_row

/*
  This function sets DIR for the current col.
  
  Parameters
  ----------
    r1 : Port number (P0 by default).
    r5 : The counter for col_loop.
  
  Returns
  -------
    None
 */
.type set_DIR_col, %function
set_DIR_col:
  push {r1, lr}

  @ col 4 is in P1
  cmp r5, 4
  it eq
  ldreq r1, =PORT_1 
  
  @ set DIR for the current col
  sub r0, r5, 1
  mov r2, 4
  mul r0, r2
  ldr r2, =cols
  ldr r3, [r2, r0]
  ldr r2, =DIR
  bl set_bit 

  pop {r1, lr}
  bx lr
.size set_DIR_col, .-set_DIR_col

/*
  This function clears DIR for the current col.
  
  Parameters
  ----------
    r1 : Port number (P0 by default).
    r5 : The counter for col_loop.
  
  Returns
  -------
    None
 */
.type clear_DIR_col, %function
clear_DIR_col:
  push {r1, lr}

  @ col 4 is in P1
  cmp r5, 4
  it eq
  ldreq r1, =PORT_1 
  
  @ set DIR for the current col
  sub r0, r5, 1
  mov r2, 4
  mul r0, r2
  ldr r2, =cols
  ldr r3, [r2, r0]
  ldr r2, =DIR
  bl clear_bit 

  pop {r1, lr}
  bx lr
.size clear_DIR_col, .-clear_DIR_col

/*
  This function sets OUT for rows within the current col.
  
  Parameters
  ----------
    r1 : Port number (P0 by default).
    r5 : The counter for col_loop.
    r6 : The LED on/off status array for the current frame. 
  
  Returns
  -------
    None
 */
.type set_OUT_row, %function
set_OUT_row:
  push {r4-r8, lr}
  
  sub r0, r5, 1
  mov r2, 4
  mul r0, r2
  ldr r2, =OUT

  mov r4, 0 @ counter for set_OUT_row_loop

set_OUT_row_loop:
  mov r5, 20
  mla r8, r4, r5, r0
  
  ldr r5, =rows
  mov r7, 4
  mul r7, r4
  ldr r3, [r6, r8]
  cmp r3, 1
  itt eq
  ldreq r3, [r5, r7]
  bleq set_bit

  add r4, 1
  cmp r4, 5
  blt set_OUT_row_loop

  pop {r4-r8, lr}
  bx lr
.size set_OUT_row, .-set_OUT_row

/*
  This function clears OUT for rows within the current col.
  
  Parameters
  ----------
    r1 : Port number (P0 by default).
    r5 : The counter for col_loop.
    r6 : The LED on/off status array for the current frame. 
  
  Returns
  -------
    None
 */
.type clear_OUT_row, %function
clear_OUT_row:
  push {r4-r8, lr}
  
  sub r0, r5, 1
  mov r2, 4
  mul r0, r2
  ldr r2, =OUT

  mov r4, 0 @ counter for clear_OUT_row_loop

clear_OUT_row_loop:
  mov r5, 20
  mla r8, r4, r5, r0
  
  ldr r5, =rows
  mov r7, 4
  mul r7, r4
  ldr r3, [r6, r8]
  cmp r3, 1
  itt eq
  ldreq r3, [r5, r7]
  bleq clear_bit

  add r4, 1
  cmp r4, 5
  blt clear_OUT_row_loop

  pop {r4-r8, lr}
  bx lr
.size clear_OUT_row, .-clear_OUT_row

.type copy_bits, %function
@@ the code is from COMP2300 2022 lib util.S
@ --parameters--
@ r0: address (base + offset)
@ r1: bits to copy
@ r2: least significant bit index
@ r3: width
copy_bits:
  push {r4}
  orn r4, 0
  lsl r4, r3
  orr r3, r4, r1  @ r3 = 0xff..f:bits
  rsb r2, 32
  ror r3, r2      @ r3 = 0xf..f:bits:f..f
  ror r1, r2      @ r1 = 0x0..0:bits:0..0
  ldr r4, [r0]
  orr r4, r1
  and r4, r3
  str r4, [r0]
  pop {r4}
  bx lr
.size copy_bits, .-copy_bits

// ------------------------ Constant & Variable --------------------------
.data                                                                 

.set PORT_0, 0x50000000
  .set ROW_1, 21
  .set ROW_2, 22
  .set ROW_3, 15
  .set ROW_4, 24
  .set ROW_5, 19
  .set COL_1, 28
  .set COL_2, 11
  .set COL_3, 31
  .set COL_5, 30

.set PORT_1, 0x50000300
  .set COL_4, 5

.set DIR, 0x514 
.set OUT, 0x504    

.set DELAY_INDEX, 0x4399 @ this constant keeps a frame as roughly 1 second 

.set SAMPLE_RATE, 48000 @ audio sample rate

cols:
  .word COL_1, COL_2, COL_3, COL_4, COL_5

rows:
  .word ROW_1, ROW_2, ROW_3, ROW_4, ROW_5

// ------------------------ The End ! ------------------------------------