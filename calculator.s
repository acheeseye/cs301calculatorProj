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

;*************************************************************************
;WE ASSUME VALID INPUTS ARE PASSED--ERROR HANDLING RETURNS INVALID VALUES*
;*************************************************************************
;INTEGERS 0x7FFFFFFFFFFFFFFB ~ 0x7FFFFFFFFFFFFFFF ARE USED FOR OPERATORS**
;*************************************************************************

;=======================================================================
;Quick chart for ascii/decimal/hex/our-version conversion (respectively)
;=======================================================================
;48 ~ 57 		'0' ~ '9' 			0x30 ~ 0x39	
;-----------------------------------------------------------------------
;40 			'(' 				0x28			0x7FFFFFFFFFFFFFFB
;-----------------------------------------------------------------------
;41 			')' 				0x29			0x7FFFFFFFFFFFFFFC
;-----------------------------------------------------------------------
;42 			'*' 				0x2a			0x7FFFFFFFFFFFFFFD
;-----------------------------------------------------------------------
;43 			'+' 				0x2b			0x7FFFFFFFFFFFFFFE
;-----------------------------------------------------------------------
;45 			'-' 				0x2d			0x7FFFFFFFFFFFFFFF
;***********************************************************************

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
mov rcx,0
mov rax,0
not	rcx
cld
repne scasb
not	rcx
dec	rcx
mov rbx,rcx

; Allocate bytes equal to the length of the string * 8
; r14 holds the values of the initial string with multi digit values
; Since there can be zero multi digit values, r14 needs to be as long as the initial string
mov rdi,rbx
imul rdi,8
call malloc
push rax

mov rdi,rbx
imul rdi,8
call malloc
push rax

pop r14 ; empty for storing condensed version
pop r9	; empty for storing postfix

; Loop that takes the string and combines sequential digits into 1 number
mov rdx,0 ; loop counter
mov rcx,0 ; index of r14
string_to_multi_digit:

	; If (loop counter >= length of string) allocate the final string
	cmp rdx,rbx
	jge end_multi_digit_conversion
	
	; Put the next character of the initial input into rax
	mov rax,0
	mov al,BYTE[r15+rdx]
	add rdx,1
	
	; If first loop, insert rax as first element
	cmp rdx,1
	je is_first_element
	
	; Determine if rax is a digit
	cmp rax,'0'
	jl is_not_digit
	cmp rax,'9'
	jg is_not_digit
	jmp is_digit
	
	; if rax is not a digit add it to array and loop again
	is_not_digit:
		cmp rax,'('
		cmove rax,[OPEN_PAREN]
		cmp rax,')'
		cmove rax,[CLOSED_PAREN]
		cmp rax,'*'
		cmove rax,[MUL_OP]
		cmp rax,'+'
		cmove rax,[ADD_OP]
		cmp rax,'-'
		cmove rax,[SUB_OP]
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
		; Also, the operator must be '(' to be valid input.
		first_is_operator:
			mov rax,[OPEN_PAREN]
			mov QWORD[r14+rcx*8],rax
			mov BYTE[previous_is_number],0
			jmp string_to_multi_digit

; rcx is the last index of r14
; add 1 to rcx so that rcx is now the length of r14, then store the length in rbx
end_multi_digit_conversion:
	add rcx,1
	mov rbx,rcx

;since we are using stack space, return these
;before pushing the values
mov rdi,r14
pop r14
pop r15

;the results are stored on the stack because malloc gets angry
mov rcx,0
storeToStack:
	mov rax,QWORD[rdi + rcx * 8]
	add rcx,1
	push rax
	cmp rcx,rbx
	jl storeToStack
	
mov r11,rbx  ; r11 is the length of the condensed string

;====================================================
;Iterate the string
;====================================================
;Looks at the values of multi-digit-considered values
;on the stack. If the values are operators (largest 5), 
;then it moves to the storeOp loop that pushes and
;pops operators according to Guidelines Followed
;(see README). Otherwise, the values are assumed to
;be integers and stored as so in r9 (malloc'ed in
;the multi-digit-analyzing stage because of some
;malloc error). The string at r9 is then
;pushed on to the stack for evaluation and leaves the
;loop by jumping to allPopped.
;====================================================
;rcx is the loop counter
;rsi is a counter separate from rcx so the system 
;	increments correctly when an operator stores a 
;	value into rax string (when loop goes into 
;	storeOp, rsi doesnt NEED to increment, only 
;	when the stack is popped and data is stored to 
;	rax str)
;r10 assists with knowing where rsp began; we need 
;	this for: always pushing operator when stack is 
;	blank and making sure to pop all the non-popped 
;	operators
;rdx is intermediate translator holding characters 
;	of input string
;rbx is the size of the reduced string considering
;	multi-digits
;====================================================

push r12
push r13

mov r13,0
mov r12,rdi
mov rsi,0
mov rcx,0
mov r10,rsp

rearrange:
	mov rdx,QWORD[r12 + rcx * 8]
	cmp rdx,QWORD[OPEN_PAREN] ; OPEN_PAREN is the smallest operator constant
	jge storeOp
	
	mov QWORD[r9 +  rsi * 8],rdx ; ELEMENT ADDED
	add rsi,1
	
backFromHandleOp:
	add rcx,1
	cmp rcx,r11
	jl rearrange
	
popTheRest:	
	cmp r10,rsp
	je allPopped
	
	pop rdi
	mov QWORD[r9 + rsi * 8], rdi
	add rsi,1
	
	cmp r10,rsp
	jg popTheRest
;****************************************************

;====================================================
;Evaluation
;====================================================
;The postfix array goes through the evaluate loop
;to evaluate the desired output.
;====================================================
;r9 is pointer to second string (postfix)
;r11 is string size, subtracted by r13 which accounts
;	for usage of parentheses (not included in
;	postfix notation)
;====================================================

allPopped:

sub r11,r13

pop r13
pop r12 ;return r12

mov rcx,0
evaluate:
	mov rsi,[r9 + rcx * 8]
	add rcx,1
	
	cmp rsi,QWORD[OPEN_PAREN]
	jge useOp
	
	push rsi
	
backToCheckSize:
	cmp rcx,r11
	jl evaluate

pop rax
mov rcx,0
popStuff:
	pop rdx
	add rcx,1
	cmp rcx,rbx
	jl popStuff

pop rbx
	
	push rax
	mov rdi,r9
	call free
	pop rax
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
	cmp rsi,QWORD[MUL_OP]
	je multiply
	
	cmp rsi,QWORD[ADD_OP]
	je addition
	
	cmp rsi,QWORD[SUB_OP]
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
;rdi is scratch register holding no important value 
;	(string has already been copied)
;rdx is intermediate translator holding characters 
;	of input string
;====================================================
incomingIsMult:
	mov rdi,QWORD[rsp]
	cmp rdx,rdi
	jl pushOp
	
	jmp popThenPush
	
incomingIsAdd:
	mov rdi,QWORD[rsp]
	cmp rdx,rdi
	jge popThenPush
	
	jmp pushOp

incomingIsSub:
	sub rdx,1 ;make the minus into plus
	push rcx
	push r12
	add rcx,1
	imul rcx,8
	add r12,rcx
	mov rdi,[r12];make the value it is attached to negative
	imul rdi,-1
	mov QWORD[r12],rdi
	pop r12
	pop rcx
	jmp incomingIsAdd
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
	mov QWORD[r9 + rsi * 8], rdi
	push rdx
	add rsi,1
	jmp backFromHandleOp

pushOpOpen:
	push rdx
	jmp backFromHandleOp	
	
closeParenOp:
	add r13,2
	pop rdi
	
	popThemAll:
	mov rax,rsp
	mov QWORD[r9 + rsi * 8], rdi
	add rsi,1
	pop rdi
	cmp rdi,QWORD[OPEN_PAREN]
	jne popThemAll
	
	jmp backFromHandleOp
;----------------------------------------------------
	
storeOp:
	;no operators in stack (pointer location)
	cmp rsp,r10
	je pushOp
	
	;( operator on top (rsp value)
	mov r8,QWORD[rsp]
	cmp r8,QWORD[OPEN_PAREN]
	je pushOp
	
	;current operator is (
	cmp rdx,QWORD[OPEN_PAREN]
	je pushOpOpen
	
	;current operator is )
	cmp rdx,QWORD[CLOSED_PAREN]
	je closeParenOp
	
	;current operator is *
	cmp rdx,QWORD[MUL_OP]
	je incomingIsMult
	
	;current operator is +
	cmp rdx,QWORD[ADD_OP]
	je incomingIsAdd
	
	;current operator is -
	cmp rdx,QWORD[SUB_OP]
	je incomingIsSub
	
	jmp invalidOp
	
invalidInt:
	mov rdx,'0'
	
invalidOp:
	mov rdx,'*'

ret
;****************************************************

section .data
;***********************************************************************************
; The five largest signed 64 bit values (0x7fffFfffFfffFffB to 0x7fffFfffFfffFffF)
; are reserved as constants for operators.
;***********************************************************************************
OPEN_PAREN:
	dq 0x7fffFfffFfffFffB
CLOSED_PAREN:
	dq 0x7fffFfffFfffFffC
MUL_OP:
	dq 0x7fffFfffFfffFffD
ADD_OP:
	dq 0x7fffFfffFfffFffE
SUB_OP:
	dq 0x7fffFfffFfffFffF
;***********************************************************************
; Holds the previous number in case it is multi digit
previous_number:
	dq 0
	
; Flag for whether the last character was a number or not
; 0 is false
; 1 is true
previous_is_number:
	db 0


