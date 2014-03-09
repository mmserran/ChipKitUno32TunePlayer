/* Mark Anthony Serrano (mmserran@ucsc.edu)
 * CMPE 12 - Fall 2012
 * Lab6.s
 */

 
/* Push a register*/
.macro  push reg
sw      \reg, ($sp)
addi    $sp, $sp, -4
.endm

/* Pop a register*/
.macro  pop reg
addi    $sp, $sp, 4
lw      \reg, ($sp)
.endm
	
#include <WProgram.h>

/* Jump to our customized routine by placing a jump at the vector 4 interrupt vector offset */
.section .vector_4,"xaw"
	j T1_ISR
	nop

/* The .global will export the symbols so that the subroutines are callable from main.cpp */
.global PlayNote
.global SetupPort
.global SetupTimer 

/* This starts the program code */
.text
/* We do not allow instruction reordering in our lab assignments. */
.set noreorder

	

/*********************************************************************
 * myprog()
 * This is where the PIC32 start-up code will jump to after initial
 * set-up.
 ********************************************************************/
.ent myprog

/* 
 * This should set up Port D pin 9 for digital output 
 */
SetupPort:
	/* store registers to stack */
	push $ra
	push $s0    /* mask register */
	push $s1    /* address register */

    /* Set up Port D pin 9 (pin 51 = RD3) for digital output */
	li		$s0, 0x8		/* RD3 */
	lui 	$s1, 0xBF88
	addiu   $s1,$s1, 0x60C0 /* address of Port D */
	
	/* CLEAR (offset +4) to configure I/O Port D as output */
	sw		$s0, 4($s1)
	
	/* restore registers from stack */
	pop $s1
	pop $s0
	pop $ra
	
	jr $ra
	nop

/*
 * This should configure Timer 1 and the corresponding interrupts,
 * but it should not enable the timer.
 */
SetupTimer:	
	/* store registers to stack */
	push $ra
	push $s0    /* mask register */
	push $s1    /* address register */

	/* Clear T1CON[15] - put it in known state */
	jal		DisableTimer
	nop
	
	/* Set T1CKPS[1:0] - set the prescaler to 1:256 (0b11 for type A)*/
	li		$s0, 0x30       /* bits [5:4] */
	lui 	$s1, 0xBF80
	addiu   $s1,$s1, 0x0600 /* address of T1CON */
	sw		$s0, 8($s1)

	/*** SETTING UP TIMER1 CORRESPONDING INTERRUPTS *****************/
	/* a) Clear T1IF - clear any prior interrupt */
	li		$s0, 0x010       /* bit [4] */
	lui 	$s1, 0xBF88
	addiu   $s1,$s1, 0x1030 /* address of IFS0 */
	sw		$s0, 4($s1)
	
	/* b) Set 0b100 to T1IP[2:0] - set the interrupt priority */
    li		$s0, 0x010       /* bit [4] */
    lui 	$s1, 0xBF88
    addiu   $s1,$s1, 0x10A0 /* address of IPC1 */
    sw		$s0, 8($s1)

	li		$s0, 0xC      /* bit [3:2] */
    lui 	$s1, 0xBF88
    addiu   $s1,$s1, 0x10A0 /* address of IPC1 */
    sw		$s0, 4($s1)
	/* ISR priority should now be 4 */
	
	/* c) Enable T1IE - enable the interrupts */
    li		$s0, 0x10       /* bit [4] */
    lui 	$s1, 0xBF88
    addiu   $s1,$s1, 0x1060 /* address of IEC0 */
    sw		$s0, 8($s1)
	/****************************************************************/
	
	/* DO NOT TURN ON THE TIMER HERE (T1CON[15]) */
	
	/* restore registers from stack */
	pop $s1
	pop $s0
	pop $ra
	
	jr $ra
	nop

	
/* This should take the following arguments:
*  $a0 = tone frequency
*  $a1 = tone duration
*  $a2 = full note duration ($a2 - $a1 is the amount of silence after the tone)
*/
PlayNote:
	/* store registers to stack */
	push $ra
	push $s0
	push $s1
	
	/* Check if frequency is 0 Hz */
	blez	$a0, SkipThisNote
	
	/*** Calculate Tone Period **************************************/
	/* original formula: Period = (80/256)*(1/2)*(1/freq)*1000 */
	/* implemented as:			= (40000/256*freq) */
	
	/* make divisor: $s0 = 256*frequency */
	li		$s1, 256
	multu	$s1, $a0
	mflo	$s0
	
	/* divide dividend by divisor: $s0 = 40,000/$s0 */
	li		$s1, 40000000
	divu	$s1, $s0
	mflo	$s0
	
	/* Set PR1 - set the period */
	lui 	$s1, 0xBF80
	addiu   $s1,$s1, 0x0620 /* address of PR1 */
	sw		$s0, ($s1)
	/****************************************************************/
	
	/*** Tone Duration **********************************************/
	/* enable Timer1 */
	jal		EnableTimer
	nop
	
	SkipThisNote:
		/* tone duration delay */
		move	$a0, $a1
		jal		delay
		nop
	
	/* disable Timer1 */
	jal		DisableTimer
	nop
	/****************************************************************/
	
	/*** Silence Duration *******************************************/
	/* calculate the amount of silence after tone */
	SUB		$a0, $a2, $a1
	
	/* use delay subroutine from Timer0 */
	jal		delay
	nop
	/****************************************************************/

    /* restore registers to stack */
	pop $s1
	pop $s0
	pop	$ra
	
	jr $ra
	nop
	
/* This procedure is not required, but I found it easier this way. It is not called from main.cpp. */
/* This turns on the timer to start counting */	
EnableTimer:
	/* store registers to stack */
	push $ra
	push $s0
	push $s1

	/* Set the ON bit of Timer1*/
	li		$s0, 0x8000     /* bit [15] */
	lui 	$s1, 0xBF80
	addiu   $s1,$s1, 0x0600 /* address of T1CON */
	sw		$s0, 8($s1)
	
	/* restore registers to stack */
	pop $s1
	pop $s0
	pop $ra
	
	jr $ra
	nop
	
/* This procedure is not required, but I found it easier this way. It is not called from main.cpp. */
/* This turns off the timer from counting */
DisableTimer:
	/* store registers to stack */
	push $ra
	push $s0
	push $s1

	/* Clear the ON bit of Timer1*/
	li		$s0, 0x8000     /* bit [15] */
	lui 	$s1, 0xBF80
	addiu   $s1,$s1, 0x0600 /* address of T1CON */
	sw		$s0, 4($s1)
	
	/* Clear TMR1 value - clear the count if it was used */
	li		$s0, 0xFFFF     /* bits [15:0] */
	lui 	$s1, 0xBF80
	addiu   $s1,$s1, 0x0610 /* address of TMR1 */
	sw		$s0, 4($s1)

	/* restore registers to stack */
	pop $s1
	pop $s0
	pop $ra
	
	jr $ra
	nop
	
	
/* The ISR should toggle the speaker output value and then clear and re-enable the interrupts. */
T1_ISR:
	
	/* Your program will go to ISR everytime an interrupt occurs, no matter which part you are */
	/* So be careful because it may overwrite your registers. So, OBEY REGISTER CALLING CONVENTIONS */
	/* Save including t0-t9 */

	/* store registers to stack */
	push		$ra
    push		$t0
    push		$t1
    push		$t2
    push		$t3
    push		$t4
    push		$t5
    push		$t6
    push		$t7
    push		$t8
    push		$t9
	push		$s0
	push		$s1
	push		$s2
	push		$s3
	push		$s4
	push		$s5
	push		$s6
	push		$s7
	push		$a0
	push		$a1
	push		$a2
	push		$a3
	push		$v0
	push		$v1
	push		$k0
	push		$k1
	push		$gp
	push		$sp
	push		$fp
	
	/* ISR body here */
	/* offset +12 to invert I/O Port D bit 3 to opposite position*/
	li		$s0, 0x8
	la		$s1, PORTD
	sw		$s0, 12($s1)
	
	/* Clear T1IF - clear any prior iterrupt */
	li		$s0, 0x10       /* bit [4] */
	lui 	$s1, 0xBF88
	addiu   $s1,$s1, 0x1030 /* address of IFS0 */
	sw		$s0, 4($s1)
	
	/* c) Enable T1IE - enable the interrupts */
    li		$s0, 0x10       /* bit [4] */
    lui 	$s1, 0xBF88
    addiu   $s1,$s1, 0x1060 /* address of IEC0 */
    sw		$s0, 8($s1)
	
	/* restore registers from stack */
	pop		$fp
	pop		$sp
	pop		$gp
	pop		$k1
	pop		$k0
	pop		$v1
	pop		$v0
	pop		$a3
	pop		$a2
	pop		$a1
	pop		$a0
	pop		$s7
	pop		$s6
	pop		$s5
	pop		$s4
	pop		$s3
	pop		$s2
	pop		$s1
	pop		$s0
    pop		$t9
    pop		$t8
    pop		$t7
    pop		$t6
    pop		$t5
    pop		$t4
    pop		$t3
    pop		$t2
    pop		$t1
    pop		$t0
	pop		$ra
	
	/* ERET is return instruction */
	eret

.end myprog /* directive that marks end of 'myprog' function and registers
           * size in ELF output
           */

