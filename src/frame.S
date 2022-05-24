@ frame.S
@ function library for showing sound and light for a frame
@ Written by Yuxuan Lin, 2022
.syntax unified 

// ------------------------ Module Interface -----------------------------
.global frame_n_bytebeat, frame_n_rising_beat, bytebeat, rising_beat

// ------------------------ Implementation -------------------------------
/*
  This function enlightens a frame of image and plays bytebeat music 
  using LEDs and speaker on micro:bit.
  
  Parameters
  ----------
    r6 : The LED on/off status array for the current frame. 
    r8 : The counter for bytebeat music loops.
  
  Returns
  -------
    None
 */
.type frame_n_bytebeat, %function
frame_n_bytebeat:
  push {lr}

init_row: 
  ldr r1, =PORT_0 @ all rows are in P0
  bl set_DIR_row @ set DIR for all the rows
  mov r4, 0 @ counter for init_col

init_col:
  @ keep the time of a frame constant
  ldr r2, =DELAY_INDEX
  add r4, 1
  cmp r4, r2
  bgt end_frame

  mov r5, 1 @ counter for col_loop

col_loop:
  ldr r1, =PORT_0 @ col 1,2,3,5 are in P0
  bl set_DIR_col @ set DIR for the current col
  bl set_OUT_row @ set OUT for rows within the current col.
  bl clear_DIR_col @ clear DIR for the current col
  bl clear_OUT_row @ clear OUT for rows within the current col.

  bl bytebeat @ play the bytebeat

  @ loop until all the cols have been passed, and repeat the whole process continuously
  add r5, 1
  cmp r5, 6
  beq init_col 
  b col_loop 

end_frame:
  pop {lr}
  bx lr
.size frame_n_bytebeat, .-frame_n_bytebeat

/*
  This function enlightens a frame of image and plays rising beat music 
  using LEDs and speaker on micro:bit.
  
  Parameters
  ----------
    r6 : The LED on/off status array for the current frame. 
    r8 : The counter for rising beat music loops.
  
  Returns
  -------
    None
 */
.type frame_n_rising_beat, %function
frame_n_rising_beat:
  push {lr}

init_row_: 
  ldr r1, =PORT_0 @ all rows are in P0
  bl set_DIR_row @ set DIR for all the rows
  mov r4, 0 @ counter for init_col_

init_col_:
  @ keep the time of a frame constant
  ldr r2, =DELAY_INDEX
  add r4, 1
  cmp r4, r2
  bgt end_frame_

  mov r5, 1 @ counter for colo_loop_

colo_loop_:
  ldr r1, =PORT_0 @ col 1,2,3,5 are in P0
  bl set_DIR_col @ set DIR for the current col
  bl set_OUT_row @ set OUT for rows within the current col.
  bl clear_DIR_col @ clear DIR for the current col
  bl clear_OUT_row @ clear OUT for rows within the current col.

  bl rising_beat @ play the rising beat

  @ loop until all the cols have been passed, and repeat the whole process continuously
  add r5, 1
  cmp r5, 6
  beq init_col_ 
  b colo_loop_ 

end_frame_:
  pop {lr}
  bx lr
.size frame_n_rising_beat, .-frame_n_rising_beat

/*
  This function uses the following expression to produce a loop of bytebeat music sound.
  
  t >> 8 & t * VAR | t >> 4
  
  Parameters
  ----------
    r7 : Bytebeat VAR.
    r8 : The counter for bytebeat music loops.
  
  Returns
  -------
    None
 */
.type bytebeat, %function
bytebeat:
  push {r0-r3, lr}
  add r8, 1
  mov r1, 8
  lsr r1, r8, r1
  mov r2, r7
  mul r2, r8
  mov r3, 4
  lsr r3, r8, r3
  and r0, r1, r2
  orr r0, r0, r3
  bl audio_play_sample
  pop {r0-r3, lr}     
  bx lr
.size bytebeat, .-bytebeat

/*
  Rising beat sound.
  
  Parameters
  ----------
    r8 : The counter for bytebeat music loops.
  
  Returns
  -------
    None
 */
.type rising_beat, %function
rising_beat:
  push {r0-r3, lr}
  add r8, 1
  lsr r0, r8, 8
  mul r0, r0, r8
  bl audio_play_sample
  pop {r0-r3, lr}  
  bx lr
.size rising_beat, .-rising_beat

// ------------------------ Constant & Variable --------------------------
.data

.set PORT_0, 0x50000000

.set DELAY_INDEX, 0x1024 @ this constant keeps frame time consistent 

@ initial LED status
LED_INIT:
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0

// ------------------------ The End ! ------------------------------------