@ main.S
@ main program for implementing a microbit pet
@ Written by Yuxuan Lin, 2022
.syntax unified 

// ------------------------ Module Interface -----------------------------
.global main, SysTick_Handler, GPIOTE_IRQHandler                                                                 

// ------------------------ Implementation -------------------------------
.type main, %function
main:
  bl audio_init

  @@@@ Configure interrupt priorities
  @ GPIO > Systick 
  @@ GPIOTE to priority 0
  ldr r0, =ADR_NVIC
  ldr r1, =OFS_NVIC_IPR1
  add r0, r1
  mov r1, 0
  mov r2, 21
  mov r3, 3
  bl copy_bits

  @@ Systick to priority 1
  ldr r0, =ADR_SCB_SHPR3
  mov r1, 1
  mov r2, 29
  mov r3, 3
  bl copy_bits

  @ Configure GPIOTE_CONFIG[0]
  @ mode = 1 (event), pin = 14 and port = 0 (P0.14 = Button A), polarity = 1 (LoToHi)
  ldr r0, =GPIOTE_CONFIG0
  ldr r1, =(1 | 14 << 8 | 0 << 13 | 1 << 16)
  str r1, [r0]
  
  @ Configure GPIOTE_CONFIG[1]
  @ mode = 1 (event), pin = 23 and port = 0 (P0.23 = Button B), polarity = 1 (LoToHi)
  ldr r0, =GPIOTE_CONFIG1
  ldr r1, =(1 | 23 << 8 | 0 << 13 | 1 << 16)
  str r1, [r0]

  @ Configure GPIOTE_CONFIG[2]
  @ mode = 1 (event), pin = 4 and port = 1 (P1.4 = LOGO), polarity = 1 (LoToHi)
  ldr r0, =GPIOTE_CONFIG2
  ldr r1, =(1 | 4 << 8 | 1 << 13 | 1 << 16)
  str r1, [r0]

  @ Enable Interrupt for GPIOTE[0], GPIOTE[1] and GPIOTE[2]
  ldr r0, =GPIOTE_INTENSET
  ldr r1, =0b111
  str r1, [r0]

  @ Enable GPIOTE (interrupt #6 = NVIC_GPIOTE_ID) in NVIC_ISER0
  ldr r0, =NVIC_ISER0
  ldr r1, =(1 << 6) @ set the 6th bit since NVIC_GPIOTE_ID = 6
  str r1, [r0]

  ldr r0,=ADR_SYST_CSR
  @ bit 0 ENABLE -> 1   
  @ bit 1 TICKINT -> 1   
  @ bit 2 CLKSOURCE -> 1 
  mov r1, 0b111
  str r1, [r0]

  @ countdown measurement
  ldr r0, =ADR_SYST_RVR 
  ldr r1, =RVR_QUARTER_SECOND
  str r1, [r0]

  mov r7, 250 @ default bytebeat VAR
  mov r8, 0 @ bytebeat parameter
  mov r9, 0 @ switch for HEART_I / HEART_II

main_loop:
  nop
  b main_loop
.size main, .-main

.type SysTick_Handler, %function
SysTick_Handler:
  push {lr}

  @ RE-Enable Interrupt for GPIOTE[0], GPIOTE[1] and GPIOTE[2]
  ldr r0, =GPIOTE_INTENSET
  ldr r1, =0b111
  str r1, [r0]

  ldr r0, =MICRO_PET
  ldr r1, [r0]
  cmp r1, 0
  beq frame_norm
  cmp r1, 1
  beq frame_hunger
  cmp r1, 2
  beq frame_eating
  cmp r1, 3
  beq frame_death

exit_SysTick_Handler:
  pop {lr}
  bx lr  

frame_norm:
  mov r3, 14
  bl microbit_random
  bl norm_cases
  mov r6, r0
  bl frame_n_bytebeat

  ldr r0, =MICRO_PET
  ldr r1, [r0]
  ldr r2, [r0, 4]
  ldr r3, [r0, 8]

routine_norm:
  @ hunger value + 1
  add r3, 1
  str r3, [r0, 8]
  @ if hunger value reaches 50, switch to hunger state; and halve the health value
  cmp r3, 50
  itttt eq
  moveq r1, 1
  moveq r2, 50
  streq r1, [r0]
  streq r2, [r0, 4]
  b exit_SysTick_Handler
  
frame_hunger:
  ldr r6, =SAD
  mov r7, 490 @ siren sound
  bl frame_n_bytebeat  

  ldr r0, =MICRO_PET
  ldr r1, [r0]
  ldr r2, [r0, 4]
  ldr r3, [r0, 8]

routine_hunger:
  @ health value - 2
  sub r2, 2
  str r2, [r0, 4]
  @ if health value decreases to 0, switch to death state
  cmp r2, 0
  itt eq
  moveq r1, 3
  streq r1, [r0]
  b exit_SysTick_Handler

frame_eating:
  cmp r9, 0
  ite eq
  ldreq r6, =HEART_I
  ldrne r6, =HEART_II
  bl frame_n_rising_beat

  ldr r0, =MICRO_PET
  ldr r1, [r0]
  ldr r2, [r0, 4]
  ldr r3, [r0, 8]

routine_eating:
  @ health value - 2
  sub r2, 2
  str r2, [r0, 4]
  @ if health value decreases to 0, switch to death state
  cmp r2, 0
  itt eq
  moveq r1, 3
  streq r1, [r0]
  b exit_SysTick_Handler

frame_death:
  ldr r6, =DEATH
  mov r7, 0
  bl frame_n_bytebeat
  b exit_SysTick_Handler
.size SysTick_Handler, .-SysTick_Handler

.type GPIOTE_IRQHandler, %function
GPIOTE_IRQHandler:
  push {lr}

  ldr r0, =GPIOTE_EVENTS_IN0
  ldr r1, [r0]
  cmp r1, 1
  beq BTN_A

  ldr r0, =GPIOTE_EVENTS_IN1
  ldr r1, [r0]
  cmp r1, 1
  beq BTN_B

  ldr r0, =GPIOTE_EVENTS_IN2
  ldr r1, [r0]
  cmp r1, 1
  beq LOGO

BTN_A:
  @ Disable channel 0
  ldr r0, =GPIOTE_INTENCLR
  ldr r1, =(1<<0)
  str r1, [r0]

  ldr r0, =MICRO_PET
  ldr r1, [r0]
  cmp r1, 0
  beq BTN_A_NORM
  cmp r1, 1
  beq BTN_HUNGER
  cmp r1, 2
  beq BTN_EATING
  cmp r1, 3
  beq BTN_DEATH

BTN_A_NORM:
  @ show left arrow
  ldr r6, =LEFT_ARROW

  @ modify bytebeat
  sub r7, 50
  cmp r7, 0
  it le
  movle r7,500

  b clear_event

BTN_B:
  @ Disable channel 1
  ldr r0, =GPIOTE_INTENCLR
  ldr r1, =(1<<1)
  str r1, [r0]

  ldr r0, =MICRO_PET
  ldr r1, [r0]
  cmp r1, 0
  beq BTN_B_NORM
  cmp r1, 1
  beq BTN_HUNGER
  cmp r1, 2
  beq BTN_EATING
  cmp r1, 3
  beq BTN_DEATH

BTN_B_NORM:
  @ show right arrow
  ldr r6, =RIGHT_ARROW

  @ modify bytebeat
  add r7, 50
  cmp r7, 500
  it gt
  movgt r7, 50

  b clear_event

BTN_HUNGER:
  b clear_event

BTN_EATING:
  @ toggle HEART_I / HEART_II
  cmp r9, 0
  ite eq
  moveq r9, 1
  movne r9, 0

  ldr r0, =MICRO_PET
  ldr r1, [r0]
  ldr r2, [r0, 4]
  ldr r3, [r0, 8]

  @ in eating state, press either button A or B to increase health value by 4
  add r2, 4
  str r2, [r0, 4]
  
  @ if health value is restored to 100, return to norm state
  cmp r2, 100
  bge restore_norm

  @ if health value is non-positive, proceed to death state
  cmp r2, 0
  ittt le
  movle r1, 3
  strle r1, [r0]
  ldrle r6, =SAD 

  b clear_event

BTN_DEATH:
  b clear_event

LOGO:
  @ Disable channel 2
  ldr r0, =GPIOTE_INTENCLR
  ldr r1, =(1<<2)
  str r1, [r0]

  ldr r0, =MICRO_PET
  ldr r1, [r0]
  cmp r1, 0
  beq LOGO_NORM
  cmp r1, 1
  beq LOGO_HUNGER
  cmp r1, 2
  beq LOGO_EATING
  cmp r1, 3
  beq LOGO_DEATH

LOGO_NORM:
  ldr r6, =GIGGLE
  b clear_event

LOGO_HUNGER:
  @ in hunger state, touch the LOGO to proceed to eating state
  ldr r0, =MICRO_PET
  mov r1, 2
  str r1, [r0]
  ldr r6, =YAWN
  b clear_event

LOGO_EATING:
  b clear_event

LOGO_DEATH:
  @ touch logo for resurgence of dead pet
  ldr r0, =MICRO_PET
  mov r1, 0
  mov r2, 100
  mov r3, 0
  str r1, [r0]
  str r2, [r0, 4]
  str r3, [r0, 8]

  ldr r6, =HAPPY @ Cheers!
  mov r7, 250 @ restore default bytebeat VAR as well
  
  b clear_event

restore_norm:
  mov r1, 0
  mov r2, 100
  mov r3, 0
  str r1, [r0]
  str r2, [r0, 4]
  str r3, [r0, 8]
  
  ldr r6, =HAPPY @ Cheers!
  mov r7, 250 @ restore default bytebeat VAR as well
  
clear_event:
  @ Clear events in case they were pending
  @ Clear GPIOTE event 0
  ldr r0, =GPIOTE_EVENTS_IN0
  ldr r1, =0
  str r1, [r0]
  
  @ Clear GPIOTE event 1
  ldr r0, =GPIOTE_EVENTS_IN1
  ldr r1, =0
  str r1, [r0]

  @ Clear GPIOTE event 2
  ldr r0, =GPIOTE_EVENTS_IN2
  ldr r1, =0
  str r1, [r0]

  @ Clear NVIC
  ldr r0, =NVIC_ICPR0
  ldr r1, =(1 << 6) @ set the 6th bit since NVIC_GPIOTE_ID = 6
  str r1, [r0]

  pop {lr}
  bx lr
.size GPIOTE_IRQHandler, .-GPIOTE_IRQHandler

.type norm_cases, %function
norm_cases:
  tbb [pc, r0]
branchtable:
  .byte (case0 - branchtable)/2
  .byte (case1 - branchtable)/2
  .byte (case2 - branchtable)/2
  .byte (case3 - branchtable)/2
  .byte (case4 - branchtable)/2
  .byte (case5 - branchtable)/2
  .byte (case6 - branchtable)/2
  .byte (case7 - branchtable)/2
  .byte (case8 - branchtable)/2
  .byte (case9 - branchtable)/2
  .byte (case10 - branchtable)/2
  .byte (case11 - branchtable)/2
  .byte (case12 - branchtable)/2
  .byte (case13 - branchtable)/2
  .align
case0:
  ldr r0, =NORM0
  b exit_norm_cases
case1:
  ldr r0, =NORM1
  b exit_norm_cases
case2:
  ldr r0, =NORM2
  b exit_norm_cases
case3:
  ldr r0, =NORM3
  b exit_norm_cases
case4:
  ldr r0, =HAPPY
  b exit_norm_cases
case5:
  ldr r0, =NORM5
  b exit_norm_cases
case6:
  ldr r0, =NORM6
  b exit_norm_cases
case7:
  ldr r0, =NORM7
  b exit_norm_cases
case8:
  ldr r0, =NORM8
  b exit_norm_cases
case9:
  ldr r0, =YAWN
  b exit_norm_cases
case10:
  ldr r0, =NORM4
  b exit_norm_cases
case11:
  ldr r0, =NORM4
  b exit_norm_cases
case12:
  ldr r0, =NORM4
  b exit_norm_cases
case13:
  ldr r0, =NORM4
  b exit_norm_cases

exit_norm_cases:
  bx lr
.size norm_cases, .-norm_cases


// ------------------------ Constant & Variable --------------------------
.data

MICRO_PET:
  .word 0   @ state index: 0 for normal, 1 for hunger, 2 for eating, 3 for death 
  .word 100 @ health value (0~100)
  .word 0   @ hunger value (0~50)

@ this constant keeps a frame as roughly 1/4 second
.set RVR_QUARTER_SECOND, 16000000

@ GPIOTE Constants
.set GPIOTE_EVENTS_IN0, 0x40006100
.set GPIOTE_EVENTS_IN1, 0x40006104
.set GPIOTE_EVENTS_IN2, 0x40006108
.set GPIOTE_INTENSET, 0x40006304
.set GPIOTE_INTENCLR, 0x40006308
.set GPIOTE_CONFIG0, 0x40006510
.set GPIOTE_CONFIG1, 0x40006514
.set GPIOTE_CONFIG2, 0x40006518

@ NVIC Constants
.set NVIC_ISER0, 0xE000E100
.set NVIC_ICPR0, 0xE000E280

NORM0:
  .word 1,0,1,0,0
  .word 0,0,0,0,0
  .word 1,1,1,0,0
  .word 0,0,0,0,0
  .word 0,0,0,0,0

NORM1:
  .word 0,1,0,1,0
  .word 0,0,0,0,0
  .word 0,1,1,1,0
  .word 0,0,0,0,0
  .word 0,0,0,0,0

NORM2:
  .word 0,0,1,0,1
  .word 0,0,0,0,0
  .word 0,0,1,1,1
  .word 0,0,0,0,0
  .word 0,0,0,0,0

NORM3:
  .word 0,0,0,0,0
  .word 1,0,1,0,0
  .word 0,0,0,0,0
  .word 1,1,1,0,0
  .word 0,0,0,0,0

NORM4:
  .word 0,0,0,0,0
  .word 0,1,0,1,0
  .word 0,0,0,0,0
  .word 0,1,1,1,0
  .word 0,0,0,0,0

NORM5:
  .word 0,0,0,0,0
  .word 0,0,1,0,1
  .word 0,0,0,0,0
  .word 0,0,1,1,1
  .word 0,0,0,0,0

NORM6:
  .word 0,0,0,0,0
  .word 0,0,0,0,0
  .word 1,0,1,0,0
  .word 0,0,0,0,0
  .word 1,1,1,0,0

NORM7:
  .word 0,0,0,0,0
  .word 0,0,0,0,0
  .word 0,1,0,1,0
  .word 0,0,0,0,0
  .word 0,1,1,1,0

NORM8:
  .word 0,0,0,0,0
  .word 0,0,0,0,0
  .word 0,0,1,0,1
  .word 0,0,0,0,0
  .word 0,0,1,1,1

SAD:
  .word 0,0,0,0,0
  .word 0,1,0,1,0
  .word 0,0,0,0,0
  .word 0,1,1,1,0
  .word 1,0,0,0,1

HEART_I:
  .word 0,0,0,0,0
  .word 0,1,0,1,0
  .word 0,1,1,1,0
  .word 0,0,1,0,0
  .word 0,0,0,0,0

HEART_II:
  .word 0,1,0,1,0
  .word 1,1,1,1,1
  .word 1,1,1,1,1
  .word 0,1,1,1,0
  .word 0,0,1,0,0

HAPPY:
  .word 0,0,0,0,0
  .word 0,1,0,1,0
  .word 0,0,0,0,0
  .word 1,0,0,0,1
  .word 0,1,1,1,0

GIGGLE:
  .word 0,1,0,1,0
  .word 0,0,0,0,0
  .word 0,0,1,0,0
  .word 0,1,0,1,0
  .word 0,0,1,0,0

YAWN:
  .word 0,0,0,0,0
  .word 1,1,0,1,1
  .word 0,0,0,0,0
  .word 0,1,1,1,0
  .word 0,0,0,0,0

DEATH:
  .word 0,1,1,1,0
  .word 1,0,1,0,1
  .word 1,1,1,1,1
  .word 0,1,1,1,0
  .word 0,1,1,1,0

LEFT_ARROW:
  .word 0,0,1,0,0
  .word 0,1,0,0,0
  .word 1,1,1,1,1
  .word 0,1,0,0,0
  .word 0,0,1,0,0

RIGHT_ARROW:
  .word 0,0,1,0,0
  .word 0,0,0,1,0
  .word 1,1,1,1,1
  .word 0,0,0,1,0
  .word 0,0,1,0,0

// ------------------------ The End ! ------------------------------------