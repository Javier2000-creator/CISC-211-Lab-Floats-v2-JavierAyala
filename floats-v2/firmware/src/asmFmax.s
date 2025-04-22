/*** asmFmax.s   ***/
#include <xc.h>
.syntax unified

@ Declare the following to be in data memory
.data  
.align

@ Define the globals so that the C code can access them

/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Javier Ayala"  
 
 
.align

/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global f0,f1,fMax,signBitMax,storedExpMax,realExpMax,mantMax
.type f0,%gnu_unique_object
.type f1,%gnu_unique_object
.type fMax,%gnu_unique_object
.type sbMax,%gnu_unique_object
.type storedExpMax,%gnu_unique_object
.type realExpMax,%gnu_unique_object
.type mantMax,%gnu_unique_object

.global sb0,sb1,storedExp0,storedExp1,realExp0,realExp1,mant0,mant1
.type sb0,%gnu_unique_object
.type sb1,%gnu_unique_object
.type storedExp0,%gnu_unique_object
.type storedExp1,%gnu_unique_object
.type realExp0,%gnu_unique_object
.type realExp1,%gnu_unique_object
.type mant0,%gnu_unique_object
.type mant1,%gnu_unique_object
 
.align
@ use these locations to store f0 values
f0: .word 0
sb0: .word 0
storedExp0: .word 0  /* the unmodified 8b exp value extracted from the float */
realExp0: .word 0
mant0: .word 0
 
@ use these locations to store f1 values
f1: .word 0
sb1: .word 0
realExp1: .word 0
storedExp1: .word 0  /* the unmodified 8b exp value extracted from the float */
mant1: .word 0
 
@ use these locations to store fMax values
fMax: .word 0
sbMax: .word 0
storedExpMax: .word 0
realExpMax: .word 0
mantMax: .word 0

.global nanValue 
.type nanValue,%gnu_unique_object
nanValue: .word 0x7FFFFFFF            

@ Tell the assembler that what follows is in instruction memory    
.text
.align

/********************************************************************
 function name: initVariables
    input:  none
    output: initializes all f0*, f1*, and *Max varibales to 0
********************************************************************/
.global initVariables
 .type initVariables,%function
initVariables:
    /* YOUR initVariables CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {lr}                      @ This saves LR so I can return later
    LDR r0, =f0                    @ I start at f0
    MOV r1, #0                     @ This is where I write zero
    MOV r2, #15                    @ I have 15 words total
init_loop:
    STR r1, [r0], #4               @ I store 0 and advance the pointer
    SUBS r2, r2, #1                @ I decrease the count
    BNE init_loop                  @ I loop until I've zeroed 15 words
    POP {lr}                       @ I restore LR
    BX lr                          @ Returns to caller
    
    
    /* YOUR initVariables CODE ABOVE THIS LINE! Don't forget to push and pop! */

    
/********************************************************************
 function name: getSignBit
    input:  r0: address of mem containing 32b float to be unpacked
            r1: address of mem to store sign bit (bit 31).
                Store a 1 if the sign bit is negative,
                Store a 0 if the sign bit is positive
                use sb0, sb1, or signBitMax for storage, as needed
    output: [r1]: mem location given by r1 contains the sign bit
********************************************************************/
.global getSignBit
.type getSignBit,%function
getSignBit:
    /* YOUR getSignBit CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {lr}                      @ I save LR
    LDR r2, [r0]                   @ Loads the 32-bit pattern
    LSR r2, r2, #31                @ Shift sign bit into bit0
    STR r2, [r1]                   @ Now I store that bit
    POP {lr}                       @ Restores LR
    BX lr                          @ I return
    /* YOUR getSignBit CODE ABOVE THIS LINE! Don't forget to push and pop! */
    

    
/********************************************************************
 function name: getExponent
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the unpacked original STORED exponent bits,
                shifted into the lower 8b of the register. Range 0-255.
            r1: always contains the REAL exponent, equal to r0 - 127.
                It is a signed 32b value. This function doesn't
                check for +/-Inf or +/-0, so r1 always contains
                r0 - 127.
                
********************************************************************/
.global getExponent
.type getExponent,%function
getExponent:
    /* YOUR getExponent CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {lr}                      @ Saves LR
    LDR r2, [r0]                   @ This loads float bits
    LSR r0, r2, #23                @ I shift exponent to low bits
    AND r0, r0, #0xFF              @ masks to 8 bits rawExp
    CMP r0, #0                     @ checks for subnormal
    MOVEQ r1, #-126                @ I set realExp=-126 for denormals
    SUBNE r1, r0, #127             @ else realExp = rawExp - 127
    POP {lr}                       @ Restores LR
    BX lr                        
    /* YOUR getExponent CODE ABOVE THIS LINE! Don't forget to push and pop! */
   

    
/********************************************************************
 function name: getMantissa
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the mantissa WITHOUT the implied 1 bit added
                to bit 23. The upper bits must all be set to 0.
            r1: contains the mantissa WITH the implied 1 bit added
                to bit 23. Upper bits are set to 0. 
********************************************************************/
.global getMantissa
.type getMantissa,%function
getMantissa:
    /* YOUR getMantissa CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {lr}                      @ saves LR
    LDR r2, [r0]                   @ loads float bits
    AND r0, r2, #0x007FFFFF        @ masks out mantissa bits
    LSR r3, r2, #23                @ gets raw exponent bits
    AND r3, r3, #0xFF              @ masks to 8 bits
    CMP r3, #0                     @ checks for subnormal
    BEQ no_implied                 @ I skip if subnormal
    CMP r3, #255                   @ I check for Inf/NaN
    BEQ no_implied                 @ skips if special
    ORR r1, r0, #0x00800000        @ I set the implied 1 bit
    B done_mant                    @ I skip the no_implied code
no_implied:
    MOV r1, r0                     @ I keep raw mantissa for denormals/specials
done_mant:
    POP {lr}                       @ I restore LR
    BX lr                   
    /* YOUR getMantissa CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
 function name: asmIsZero
    input:  r0: address of mem containing 32b float to be checked
                for +/- 0
      
    output: r0:  0 if floating point value is NOT +/- 0
                 1 if floating point value is +0
                -1 if floating point value is -0
      
********************************************************************/
.global asmIsZero
.type asmIsZero,%function
asmIsZero:
    /* YOUR asmIsZero CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {lr}                      @ saves LR
    LDR r1, [r0]                   @ loads float bits
    MOV r2, r1                     @ makes a copy
    LSL r2, r2, #1                 @ drops the sign bit
    CMP r2, #0                     @ I see if rest is zero
    BNE not_zero                   @ branches out if not zero
    LSR r1, r1, #31                @ this extracts sign bit
    CMP r1, #0                     @ I check sign
    MOVEQ r0, #1                   @ says +0 if sign=0
    MOVNE r0, #-1                  @ says -0 if sign=1
    B done_zero
not_zero:
    MOV r0, #0                     
done_zero:
    POP {lr}                     
    BX lr                        


    /* YOUR asmIsZero CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
 function name: asmIsInf
    input:  r0: address of mem containing 32b float to be checked
                for +/- infinity
      
    output: r0:  0 if floating point value is NOT +/- infinity
                 1 if floating point value is +infinity
                -1 if floating point value is -infinity
      
********************************************************************/
.global asmIsInf
.type asmIsInf,%function
asmIsInf:
    /* YOUR asmIsInf CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {lr}                      @ saves LR
    LDR r1, [r0]                   @ loads float bits
    LSR r2, r1, #23                @ shifts exp bits
    AND r2, r2, #0xFF              @ masks to 8 bits
    CMP r2, #255                   @ checks for all 1s
    BNE not_inf                    @ branches if exp!=255
    LSL r1, r1, #9                 @ drops sign+exp bits
    CMP r1, #0                     @ this checks mantissa bits
    BNE not_inf                    @ I branch if mantissa!=0
    LDR r1, [r0]                   @ reloads float bits
    LSR r1, r1, #31                @ extracts sign bit
    CMP r1, #0                     @ checks sign
    MOVEQ r0, #1                   @ says +Inf
    MOVNE r0, #-1                  @ says -Inf
    B done_inf
not_inf:
    MOV r0, #0                    
done_inf:
    POP {lr}                       
    BX lr                        
    /* YOUR asmIsInf CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
function name: asmFmax
function description:
     max = asmFmax ( f0 , f1 )
     
where:
     f0, f1 are 32b floating point values passed in by the C caller
     max is the ADDRESS of fMax, where the greater of (f0,f1) must be stored
     
     if f0 equals f1, return either one
     notes:
        "greater than" means the most positive number.
        For example, -1 is greater than -200
     
     The function must also unpack the greater number and update the 
     following global variables prior to returning to the caller:
     
     signBitMax: 0 if the larger number is positive, otherwise 1
     realExpMax: The REAL exponent of the max value, adjusted for
                 (i.e. the STORED exponent - (127 o 126), see lab instructions)
                 The value must be a signed 32b number
     mantMax:    The lower 23b unpacked from the larger number.
                 If not +/-INF and not +/- 0, the mantissa MUST ALSO include
                 the implied "1" in bit 23! (So the student's code
                 must make sure to set that bit).
                 All bits above bit 23 must always be set to 0.     

********************************************************************/    
.global asmFmax
.type asmFmax,%function
asmFmax:   

    /* YOUR asmFmax CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */
    PUSH {r4-r11, lr}              @ I save my used registers

    @ store the two inputs
    LDR r4, [r0]                   @ I copy f0 bits into r4
    STR r4, =f0                    @ I write it into memory
    LDR r5, [r1]                   @ I copy f1 bits into r5
    STR r5, =f1                    @ I write it into memory

    @ unpack f0 into sb0/storedExp0/realExp0/mant0
    MOV r0, r4                     @ I put the bits into r0 for helper
    BL getSignBit                  @ I get sign into sb0
    MOV r0, r4                     @ I reload bits into r0
    BL getExponent                 @ I get exponents into storedExp0/realExp0
    STR r0, =storedExp0
    STR r1, =realExp0
    MOV r0, r4                     @ I reload for mantissa
    BL getMantissa                 @ I get mantissa into mant0
    STR r1, =mant0

    @ unpack f1 similarly
    MOV r0, r5
    BL getSignBit
    MOV r0, r5
    BL getExponent
    STR r0, =storedExp1
    STR r1, =realExp1
    MOV r0, r5
    BL getMantissa
    STR r1, =mant1

    @ check for infinities first
    MOV r0, r4
    BL asmIsInf
    CMP r0, #1
    BEQ return_f0                  @ I pick f0 if +Inf
    MOV r0, r5
    BL asmIsInf
    CMP r0, #1
    BEQ return_f1                  @ I pick f1 if +Inf
    MOV r0, r4
    BL asmIsInf
    CMP r0, #-1
    BEQ return_f1                  @ I pick f1 if f0 is -Inf
    MOV r0, r5
    BL asmIsInf
    CMP r0, #-1
    BEQ return_f0                  @ I pick f0 if f1 is -Inf

    @ now compare sign bits
    LDR r6, =sb0
    LDR r6, [r6]                   @ I load sign0
    LDR r7, =sb1
    LDR r7, [r7]                   @ I load sign1
    CMP r6, r7                     @ I check if signs differ
    BNE diff_sign

    @ same sign, compare realExp0 vs realExp1
    LDR r8, =realExp0
    LDR r8, [r8]
    LDR r9, =realExp1
    LDR r9, [r9]
    CMP r8, r9
    BNE cmp_exp

    @ same exponent, compare mant0 vs mant1
    LDR r10, =mant0
    LDR r10, [r10]
    LDR r11, =mant1
    LDR r11, [r11]
    CMP r10, r11
    BLT return_f1
    B    return_f0

diff_sign:
    CMP r6, #0
    BEQ return_f0                 @ I pick f0 if f0 positive & f1 negative
    B    return_f1                @ else I pick f1

cmp_exp:
    CMP r6, #0                     @ I check sign of both (same sign)
    BEQ exp_pos                  
    BLT return_f0                 @ if both negative, smaller exp is larger
    B    return_f1                
exp_pos:
    BGT return_f0                 @ if both positive, larger exp is larger
    B    return_f1

return_f0:
    LDR r0, =f0
    LDR r1, =fMax
    LDR r2, [r0]
    STR r2, [r1]                   @ I copy f0 bits to fMax
    LDR r1, =sb0                  @ I copy sb0 to sbMax
    STR r6, =sbMax
    LDR r1, =storedExp0           @ I copy storedExp0
    STR r8, =storedExpMax
    LDR r1, =realExp0             @ I copy realExp0
    STR r8, =realExpMax
    LDR r1, =mant0                @ I copy mant0
    STR r10, =mantMax
    B done_fmax

return_f1:
    LDR r0, =f1
    LDR r1, =fMax
    LDR r2, [r0]
    STR r2, [r1]                   @ I copy f1 bits to fMax
    LDR r1, =sb1                  @ I copy sb1
    STR r7, =sbMax
    LDR r1, =storedExp1           @ I copy storedExp1
    STR r9, =storedExpMax
    LDR r1, =realExp1             @ I copy realExp1
    STR r9, =realExpMax
    LDR r1, =mant1                @ I copy mant1
    STR r11, =mantMax

done_fmax:
    POP {r4-r11, lr}              @ I restore registers and return
    BX lr

    /* YOUR asmFmax CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */

   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           



