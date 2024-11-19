/*** asmFmax.s   ***/
#include <xc.h>
.syntax unified

@ Declare the following to be in data memory
.data  

@ Define the globals so that the C code can access them

.global f1,f2,fMax,signBitMax,biasedExpMax,expMax,mantMax
.type f1,%gnu_unique_object
.type f2,%gnu_unique_object
.type fMax,%gnu_unique_object
.type signBitMax,%gnu_unique_object
.type biasedExpMax,%gnu_unique_object
.type expMax,%gnu_unique_object
.type mantMax,%gnu_unique_object

.global sb1,sb2,biasedExp1,biasedExp2,exp1,exp2,mant1,mant2
.type sb1,%gnu_unique_object
.type sb2,%gnu_unique_object
.type biasedExp1,%gnu_unique_object
.type biasedExp2,%gnu_unique_object
.type exp1,%gnu_unique_object
.type exp2,%gnu_unique_object
.type mant1,%gnu_unique_object
.type mant2,%gnu_unique_object
 
.align
@ use these locations to store f1 values
f1: .word 0
sb1: .word 0
biasedExp1: .word 0  /* the unmodified 8b exp value extracted from the float */
exp1: .word 0
mant1: .word 0
 
@ use these locations to store f2 values
f2: .word 0
sb2: .word 0
exp2: .word 0
biasedExp2: .word 0  /* the unmodified 8b exp value extracted from the float */
mant2: .word 0
 
@ use these locations to store fMax values
fMax: .word 0
signBitMax: .word 0
biasedExpMax: .word 0
expMax: .word 0
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
    output: initializes all f1*, f2*, and *Max varibales to 0
********************************************************************/
.global initVariables
 .type initVariables,%function
initVariables:
    /* YOUR initVariables CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {r4-r11, LR}

    MOV r4, 0
    
    LDR r5, =f1
    STR r4, [r5]
    LDR r5, =sb1
    STR r4, [r5]
    LDR r5, =biasedExp1
    STR r4, [r5]
    LDR r5, =exp1
    STR r4, [r5]
    LDR r5, =mant1
    STR r4, [r5]

    LDR r5, =f2
    STR r4, [r5]
    LDR r5, =sb2
    STR r4, [r5]
    LDR r5, =biasedExp2
    STR r4, [r5]
    LDR r5, =exp2
    STR r4, [r5]
    LDR r5, =mant2
    STR r4, [r5]

    LDR r5, =fMax
    STR r4, [r5]
    LDR r5, =signBitMax
    STR r4, [r5]
    LDR r5, =biasedExpMax
    STR r4, [r5]
    LDR r5, =expMax
    STR r4, [r5]
    LDR r5, =mantMax
    STR r4, [r5]
    
    POP {r4-r11, LR}
    MOV PC, LR
    
    /* YOUR initVariables CODE ABOVE THIS LINE! Don't forget to push and pop! */

    
/********************************************************************
 function name: getSignBit
    input:  r0: address of mem containing 32b float to be unpacked
            r1: address of mem to store sign bit (bit 31).
                Store a 1 if the sign bit is negative,
                Store a 0 if the sign bit is positive
                use sb1, sb2, or signBitMax for storage, as needed
    output: [r1]: mem location given by r1 contains the sign bit
********************************************************************/
.global getSignBit
.type getSignBit,%function
getSignBit:
    /* YOUR getSignBit CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {r4-r11, LR}
    
    /* sign bit is stored in the 31st bit of the register. We will extract the bit using bitwise operators */
    LDR r4, [r0] /*this puts the number to be unpacked in r4*/
    MOV r5, 0x8000000
    AND r6, r4, r5 /*this puts the value of the sign bit in r6 as the 31st bit */
    CMP r6, 0
    MOVNE r6, 1 /*this puts 1 in r6 if our 31st bit was 1. We don't worry about 0 since the and operation would have produced 0 in r6 */

    STR r6, [r1]
    
    POP {r4-r11, LR}
    MOV PC, LR
    
    /* YOUR getSignBit CODE ABOVE THIS LINE! Don't forget to push and pop! */
    

    
/********************************************************************
 function name: getExponent
    input:  r0: address of mem containing 32b float to be unpacked
            r1: address of mem to store BIASED
                bits 23-30 (exponent) 
                BIASED means the unpacked value (range 0-255)
                use exp1, exp2, or expMax for storage, as needed
            r2: address of mem to store unpacked and UNBIASED 
                bits 23-30 (exponent) 
                UNBIASED means the unpacked value - 127
                use exp1, exp2, or expMax for storage, as needed
    output: [r1]: mem location given by r1 contains the unpacked
                  original (biased) exponent bits, in the lower 8b of the mem 
                  location
            [r2]: mem location given by r2 contains the unpacked
                  and UNBIASED exponent bits, in the lower 8b of the mem 
                  location
********************************************************************/
.global getExponent
.type getExponent,%function
getExponent:
    /* YOUR getExponent CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {r4-r11, LR}
    
    /* We need to extract bits 23-30. We will do this using an AND operation, then moving
     the result down to the right side of the register */
    LDR r4, [r0]
    MOV r5, 0x7F800000
    
    AND r6, r4, r5
    LSR r6, r6, 23
    
    /*At this point, we have our biased exponent in r6. We can load it into 
     memory, and also subtract the bias to get our unbiased value */
    STR r6, [r1]
    CMP r6, 0
    MOVEQ r6, -126
    SUB r6, r6, 127
    STR r6, [r2]
    
    POP {r4-r11, LR}
    MOV PC, LR
    
    
    /* YOUR getExponent CODE ABOVE THIS LINE! Don't forget to push and pop! */
   

    
/********************************************************************
 function name: getMantissa
    input:  r0: address of mem containing 32b float to be unpacked
            r1: address of mem to store unpacked bits 0-22 (mantissa) 
                of 32b float. 
                Use mant1, mant2, or mantMax for storage, as needed
    output: [r1]: mem location given by r1 contains the unpacked
                  mantissa bits
********************************************************************/
.global getMantissa
.type getMantissa,%function
getMantissa:
    /* YOUR getMantissa CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {r4-r11, LR}
    
    /* Mantissa is in the lowest 23 bits. We will do the same bitmasking from
     before to get it. Plus, we will add the implied zero to it */
    LDR r8, [r0]
    
    MOVW r4, 0xFFFF
    MOVT r4, 0x007F
    MOV r5, 0x00800000
    AND r6, r4, r8
    ORR r7, r6, r5
     
    /* Now we store the value */
    STR r7, [r1]
    
    POP {r4-r11, LR}
    MOV PC, LR
    /* YOUR getMantissa CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
function name: asmFmax
function description:
     max = asmFmax ( f1 , f2 )
     
where:
     f1, f2 are 32b floating point values passed in by the C caller
     max is the ADDRESS of fMax, where the greater of (f1,f2) must be stored
     
     if f1 equals f2, return either one
     notes:
        "greater than" means the most positive numeber.
        For example, -1 is greater than -200
     
     The function must also unpack the greater number and update the 
     following global variables prior to returning to the caller:
     
     signBitMax: 0 if the larger number is positive, otherwise 1
     expMax:     The UNBIASED exponent of the larger number
                 i.e. the BIASED exponent - 127
     mantMax:    the lower 23b unpacked from the larger number
     
     SEE LECTURE SLIDES FOR EXACT REQUIREMENTS on when and how to adjust values!


********************************************************************/    
.global asmFmax
.type asmFmax,%function
asmFmax:   

    /* Note to Profs: Solution used to test c code is located in Canvas:
     *    Files -> Lab Files and Coding Examples -> Lab 11 Float Solution
     */

    /* YOUR asmFmax CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */
    PUSH {r4-r11, LR}
    
    /* First, we set all the values in memory to 0 for a fresh start */
    BL initVariables
    
    /* First, we store the r0 input into f1 and likewise with r1 */
    LDR r4, =f1
    STR r0, [r4]
    LDR r5, =f2
    STR r1, [r5]
    
    /* Since we have functions setup already we simply set the r0-r3 to 
    the correct inputs then call the functions. */
    /*Sign bit function first */
    LDR r0, =f1
    LDR r1, =sb1
    BL getSignBit
    
    LDR r0, =f2
    LDR r1, =sb1
    BL getSignBit
    
    /* Now the get exponent function */
    LDR r0, =f1
    LDR r1, =biasedExp1
    LDR r2, =exp1
    BL getExponent
    
    LDR r0, =f2
    LDR r1, =biasedExp2
    LDR r2, =exp2
    BL getExponent
    
    /* Now the mantissa */
    LDR r0, =f1
    LDR r1, =mant1
    BL getMantissa
    
    LDR r0, =f2
    LDR r1, =mant2
    BL getMantissa
    
    /* Now we can do a comparison easily, since our values are in memory */
    /* First comparisons involve NaN and infinity. If either is NaN, we branch
     to our NaN instructions */
    LDR r0, =f1
    LDR r1, =f2
    LDR r2, [r0]
    LDR r3, [r1]
    
    CMP r2, 0xff800000
    BEQ store_NaN_1
    CMP r3, 0xff800000
    BEQ store_NaN_2
    
    /* Start with the sign bit */
    LDR r0, =sb1
    LDR r1, =sb2
    LDR r0, [r0]
    LDR r1, [r1]
    CMP r0, r1
    BHI store_f1
    BCC store_f2
    
    /* Now compare exponent */
    LDR r0, =biasedExp1
    LDR r1, =biasedExp2
    LDR r0, [r0]
    LDR r1, [r1]
    BHI store_f1
    BCC store_f2
    
    /* Finally, we compare the mantissa */
    LDR r0, =mant1
    LDR r1, =mant2
    LDR r0, [r0]
    LDR r1, [r1]
    BHI store_f1
    BCC store_f2
    
store_f1:
    /* This function stores the f1 values as the max */
    LDR r0, =f1
    LDR r0, [r0]
    LDR r1, =sb1
    LDR r1, [r1]
    LDR r2, =biasedExp1
    LDR r2, [r2]
    LDR r3, =exp1
    LDR r3, [r3]
    LDR r4, =mant1
    LDR r4, [r4]
    
    LDR r5, =fMax
    LDR r6, =signBitMax
    LDR r7, =biasedExpMax
    LDR r8, =expMax
    LDR r9, =mantMax
    
    STR r0, [r5]
    STR r1, [r6]
    STR r2, [r7]
    STR r3, [r8]
    STR r4, [r9]
    
    B done
    
store_f2:
    /* This function stores the f2 values as the max */
    LDR r0, =f2
    LDR r0, [r0]
    LDR r1, =sb2
    LDR r1, [r1]
    LDR r2, =biasedExp2
    LDR r2, [r2]
    LDR r3, =exp2
    LDR r3, [r3]
    LDR r4, =mant2
    LDR r4, [r4]
    
    LDR r5, =fMax
    LDR r6, =signBitMax
    LDR r7, =biasedExpMax
    LDR r8, =expMax
    LDR r9, =mantMax
    
    STR r0, [r5]
    STR r1, [r6]
    STR r2, [r7]
    STR r3, [r8]
    STR r4, [r9]
    
    B done

store_NaN_1:
    /* This directive is for the NaN case if f1 is NaN.*/
    MOV r0, 0x7FFFFFFF
    MOV r1, 0
    MOV r2, 0xFF
    MOV r3, 0x80
    MOVW r4, 0xFFFF
    MOVT r4, 0x007F
    
    LDR r5, =fMax
    LDR r6, =signBitMax
    LDR r7, =biasedExpMax
    LDR r8, =expMax
    LDR r9, =mantMax
    
    STR r0, [r5]
    STR r1, [r6]
    STR r2, [r7]
    STR r3, [r8]
    STR r4, [r9]
    
    B done
    
store_NaN_2:
    /* This directive is for the NaN case if f2 is NaN.*/
    MOV r0, 0x7FFFFFFF
    MOV r1, 0
    MOV r2, 0xFF
    MOV r3, 0x80
    MOVW r4, 0xFFFF
    MOVT r4, 0x007F
    
    LDR r5, =fMax
    LDR r6, =signBitMax
    LDR r7, =biasedExpMax
    LDR r8, =expMax
    LDR r9, =mantMax
    
    STR r0, [r5]
    STR r1, [r6]
    STR r2, [r7]
    STR r3, [r8]
    STR r4, [r9]
    
    B done
     
done:
    LDR r0, =fMax
    
    POP {r4-r11, LR}
    MOV PC, LR
    
    /* YOUR asmFmax CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */

   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           




