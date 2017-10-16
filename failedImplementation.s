;CS301 Assembly Language Project 1
;Assembly Calculator
;Jason Hsi & Frank Cline
;Rough draft
;Due: 10/04/2017

push rbx
mov rbx,0

extern getchar
extern malloc
extern free
extern larray_print


;*************************************************************************
;*************************************************************************
;WE ASSUME VALID INPUTS ARE PASSED--ERROR HANDLING RETURNS INVALID VALUES*
;*************************************************************************
;*************************************************************************



;====================================================
;Quick chart for ascii/decimal/hex conversion
;====================================================
;48 ~ 57 		'0' ~ '9' 			0x30 ~ 0x39
;----------------------------------------------------
;40 			'(' 				0x28
;----------------------------------------------------
;41 			')' 				0x29
;----------------------------------------------------
;42 			'*' 				0x2a
;----------------------------------------------------
;43 			'+' 				0x2b
;----------------------------------------------------
;45 			'-' 				0x2d
;****************************************************

; =============================================================================
; * Take the input and turn sequential numeric values into multi digit values *
; =============================================================================

; push preserved registers for later use
push r15
push r14

; String magic to find the length of the input string
; r15 holds the initial string
; rbx holds the length of the string
mov rdi,QWORD[rdi]
mov r15,rdi
sub	rcx, rcx
sub	al, al
not	rcx
cld
repne scasb
not	rcx
dec	rcx
mov rbx,rcx

; Allocate bytes equal to the length of the string
; r14 holds the values of the initial string with multi digit values
; Since there can be zero multi digit values, r14 needs to be as long as the initial string
mov rdi,rbx
call malloc
mov r14,rax

; Loop that takes the string and combines sequential digits into 1 number
mov rdx,0 ; loop counter
mov rcx,0 ; index of r14
string_to_multi_digit:

	; If (loop counter >= length of string) allocate the final string
	cmp rdx,rbx
	jge end_multi_digit_conversion
	
	; Put the next character of the initial input into rax
	mov rax,0 ; zero out high bits
	mov al,BYTE[r15+rdx]
	add rdx,1
	
	; If (previous_number == the intial value) insert rax as first element
	cmp QWORD[previous_number],0xFfffFfffFfffFfff
	je is_first_element
	
	; Determine if rax is a digit
	cmp rax,'0'
	jl is_not_digit
	cmp rax,'9'
	jg is_not_digit
	jmp is_digit
	
	; if rax is not a digit add it to array and loop again
	is_not_digit:
		add rcx,1
		mov QWORD[r14+rcx*8],rax
		mov BYTE[previous_is_number],0
		jmp string_to_multi_digit
			
	; if rax is a digit then check if the previous character is also a digit	
	is_digit:
		; Convert rax to number from 0-9
		sub rax,'0'
		
		; If previous is not a number, just insert the current number
		cmp BYTE[previous_is_number],0
		je insert_number
		
		; if previous character is a digit, add rax to 10*previous
		mov rsi,QWORD[previous_number]
		imul rsi,10
		add rsi,rax
		mov QWORD[r14+rcx*8],rsi
		mov QWORD[previous_number],rsi
		jmp string_to_multi_digit
		
		; if previous character is an operator, add the current number to array
		insert_number:
			add rcx,1
			mov QWORD[r14+rcx*8],rax
			mov QWORD[previous_number],rax 
			mov BYTE[previous_is_number],1
			jmp string_to_multi_digit
	
	is_first_element:
		; if the first element is not a digit, add it to the array
		cmp rax,'0'
		jl first_is_operator
		cmp rax,'9'
		jg first_is_operator
		
		; If the first element is a digit, set previous_number and add to array
		first_is_digit:
			sub rax,'0' ; convert rax to digit from 0-9
			mov QWORD[r14+rcx*8],rax
			mov QWORD[previous_number],rax
			mov BYTE[previous_is_number],1
			jmp string_to_multi_digit
		; If the first element is not a digit, set previous_is_number to false
		; Then add the operarto to the array
		first_is_operator:
			mov QWORD[r14+rcx*8],rax
			mov BYTE[previous_is_number],0
			jmp string_to_multi_digit

; rcx is the last index of r14
; add 1 to rcx so that rcx is now the length of r14, then store the length in rbx
end_multi_digit_conversion:
	add rcx,1
	mov rbx,rcx
	; For now print contents of r14
	mov rdi,r14
	mov rsi,rbx
	call larray_print

mov rdi,rbx
call malloc  ; rax holds string for postfix
mov r9,r14   ; r9 holds string in infix notation
mov r11,rbx  ; r11 is the length of r9 and rax

; Restore preserved registers
pop r14
pop r15

;====================================================
;Iterate the string
;====================================================
;Looks at the characters of the unaltered stored
;string. If the value is '0' ~ '9', then it is stored
;to rax (;ELEMENT ADDED). Otherwise, it is assumed
;the incoming character is an operator and moves it
;to the storeOp loop. The string at rax is then
;pushed on to the stack for evaluation and leaves the
;loop by jumping to allPopped.
;====================================================
;rcx is the loop counter
;rsi is a counter separate from rcx so the system 
;	increments correctly when an operator stores a 
;	value into rax string (when loop goes into 
;	storeOp, rsi doesn't NEED to increment, only 
;	when the stack is popped and data is stored to 
;	rax str)
;r10 assists with knowing where rsp began; we need 
;	this for: always pushing operator when stack is 
;	blank and making sure to pop all the non-popped 
;	operators
;rdx is intermediate translator holding characters 
;	of input string
;====================================================

mov rsi,0
mov rcx,0
mov r10,rsp

rearrange:
	mov rdx,QWORD[r9 + rcx * 8]
	cmp rdx,0x30
	jl storeOp
	cmp rdx,0x39
	jg invalidInt
	
	mov QWORD[rax +  rsi * 8],rdx ;ELEMENT ADDED
	add rsi,1
	
backFromHandleOp:

	add rcx,1
	cmp rcx,r11
	jl rearrange
	
popTheRest:
	cmp r10,rsp
	je allPopped
	
	pop rdi
	mov QWORD[rax + rsi * 8], rdi
	add rsi,1
	
	cmp r10,rsp
	jg popTheRest
;****************************************************



;====================================================
;Printing and evaluation
;====================================================
;Printing the postfix array can be done here.
;The postfix array goes through the evaluate loop
;to evaluate the desired output. Integers are handled
;by subtraction of 0x30 and operators are handled
;separately in the useOp loop.
;====================================================
;rax is pointer to second string (postfix)
;r11 is string size
;====================================================

allPopped:

;mov rdi,rax
;mov rsi,r11
;sub rsi,rbx
;call larray_print

sub r11,rbx

mov rcx,0
evaluate:
	mov rsi,[rax + rcx * 8]
	add rcx,1
	
	cmp rsi,'0'
	jl useOp
	
	sub rsi,0x30
	push rsi
	
backToCheckSize:
	cmp rcx,r11
	jl evaluate
	
	; Free rax and r9
	push r9
	mov rdi,rax
	call free
	pop rdi
	call free
	
	pop rax
	pop rbx
	ret
;****************************************************
;*******************End of system********************
;****************************************************



;====================================================
;Operator evaluation (useOp loop)
;====================================================
;When an operator is found on the stack, it is used
;on the two following integers on the stack.
;This is guarenteed due to the nature of postfix.
;====================================================
;rsi is the current element on the stack
;rdx is scratch register holding no important value
;	used for popping
;====================================================

useOp:
	cmp rsi,'*'
	je multiply
	
	cmp rsi,'+'
	je addition
	
	cmp rsi,'-'
	je subtraction
	
	jmp invalidOp
	
multiply:
	pop rdx
	pop rsi
	imul rsi,rdx
	push rsi
	jmp backToCheckSize

addition:
	pop rdx
	pop rsi
	add rsi,rdx
	push rsi
	jmp backToCheckSize

subtraction:
	pop rdx
	pop rsi
	sub rsi,rdx
	push rsi
	jmp backToCheckSize
;****************************************************
	
	
	
;====================================================
;Operator storing order (storeOp loop)
;====================================================
;This loop is reached when the input string's char
;is below 48, or 0x30, or int 0. All the operators
;are located on those values (see Quick chart).
;Instructions follow the 1~8 guideline located in
;the readme file.
;====================================================
;rdi is scratch register holding no important value 
;	(string has already been copied)
;rdx is intermediate translator holding characters 
;	of input string
;====================================================

;----------------------------------------------------
;We arrive here when the operator is greater than 42,
;or 0x2a, or '*', because '+' and '-' are both larger
;values ('+' == 43, '-' == 45).
;----------------------------------------------------
incomingIsMult:
	mov rdi,QWORD[rsp]
	cmp rdx,rdi
	jl pushOp
	
	jmp popThenPush
	
incomingIsAddOrSub:
	mov rdi,QWORD[rsp]
	cmp rdx,rdi
	jge popThenPush
	
	jmp pushOp
;----------------------------------------------------

;----------------------------------------------------
;According to the guidelines in readme, this is how
;each operator is handled in order to guarentee the
;evaluation loop will compute in the correct order.
;----------------------------------------------------
pushOp:
	push rdx
	jmp backFromHandleOp

popThenPush:
	pop rdi
	mov QWORD[rax + rsi * 8], rdi
	push rdx
	add rsi,1
	jmp backFromHandleOp
	
closeParenOp:
	;sub r11,2
	add rbx,2
	pop rdi
	
	popThemAll:
	mov QWORD[rax + rsi * 8], rdi
	add rsi,1
	pop rdi
	cmp rdi,'('
	jne popThemAll
	
	jmp backFromHandleOp
;----------------------------------------------------
	
storeOp:
	;no operators in stack (pointer location)
	cmp rsp,r10
	je pushOp
	
	;( operator on top (rsp value)
	mov r8,QWORD[rsp]
	cmp r8,'('
	je pushOp
	
	;current operator is (
	cmp rdx,'('
	je pushOp
	
	;current operator is )
	cmp rdx,')'
	je closeParenOp
	
	;current operator is *
	cmp rdx,'+'
	jl incomingIsMult
	
	;current operator is + or -
	cmp rdx,'+'
	jge incomingIsAddOrSub
	
	jmp invalidOp
	
invalidInt:
	mov rdx,'0'
	
invalidOp:
	mov rdx,'*'
;****************************************************

section .data

; Holds the previous number in case it is multi digit
previous_number:
	dq 0xFfffFfffFfffFfff
	
; Flag for whether the last character was a number or not
; 0 is false
; 1 is true
previous_is_number:
	db 0


