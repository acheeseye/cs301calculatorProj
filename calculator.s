;CS301 Assembly Language Project 1
;Assembly Calculator
;Jason Hsi & Frank Cline
;Rough draft
;Due: 10/04/2017

;	Description: 	A calculator program that takes an infix expression
;			and calculates the result by rearranging expression
;			into postfix.

;	v0.0: 	Currently supports infix translation into postfix for + - and * operators
;			Undefined operators are set to *
;			Undefined characters (<0x30 or >0x39) are set to 0x30

;			***1+2*(4+3*2-1) SOMEHOW PRINTS arr[5] TWICE??? The values store are
;			correct, but somehow arr[5] gets included twice***

;			***SOLVED: larray_print should only print 10***

;			(10/03/2017)JH

;Rules followed:
;	1. Print operands as they arrive.
;	2. If the top of the stack is empty or occupied by operator '(' then push onto stack
;	3. If incoming operator is '(' then push onto stack.
;	4. If incoming operator is ')' then pop stack until operator '(' is found. Exclude
;		printing '(' and ')'.
;	5. If incoming operator has higher precedence than the operator at the top of the stack,
;		push the incoming operator.
;	6. If incoming operator has equal precedence with the operator at the top of the stack,
;		pop stack to print then push incoming operator (association is left to right).
;	7. If incoming operator has lower precedence than the operator at the top of the stack,
;		pop stack to print then push incoming operator.
;	8. Pop any remaining operators at the end in normal popping order.

;Sources:
;http://csis.pace.edu/~wolf/CS122/infix-postfix.htm
;http://scriptasylum.com/tutorials/infix_postfix/algorithms/postfix-evaluation/



extern getchar
extern malloc
extern larray_print



;====================================================
;Quick chart for ascii/decimal/hex conversion
;====================================================
;48 ~ 57 is 0 ~ 9 is 0x30 ~ 0x39
;40 ( 0x28
;41 ) 0x29
;42 * 0x2a
;43 + 0x2b
;45 - 0x2d
;****************************************************



;====================================================
;Calculates the number of characters (MAGIC)
;====================================================
mov rdi,QWORD[rdi]
push rdi

mov rcx,0
mov rax,0
not rcx
cld
repne scasb
not rcx
dec rcx
mov r11,rcx ;r11 is number of characters
;****************************************************



;====================================================
;malloc twice for storage (r9 & rax)
;====================================================
;r9 is pointer to first string
;rax is pointer to second string
;r11 is character count
;2 size r11 mallocs generated

push r11

mov rdi,r11 ;rdi is parameter for malloc 
call malloc

push rax
pop r11
push r11

mov rdi,r11
call malloc ;rax is pointer to second string of same size

pop r9 ;pointer to first string
pop r11
pop rdi
;****************************************************


;====================================================
;Takes input and stores to 1st string (r9 head)
;====================================================
;rcx is the loop counter
;rdx is intermediate translator
;rdi is pointer to beginning of input string

mov rcx,0
mov rdx,0 ;clear the high bits of rdx
storeStringToMalloc:
	;check for no input
	mov dl,BYTE[rdi]
	mov QWORD[r9 + rcx * 8], rdx
	add rdi,1
	add rcx,1
	cmp rcx,r11
	jl storeStringToMalloc
;****************************************************
	


;====================================================
;Rearranges values from infix to postfix (rax head)
;====================================================
;rcx is the loop counter
;rsi is a counter separate from rcx so the system increments correctly
;	when an operator stores a value into rax string
;	(when loop goes into storeOp, rsi doesn't NEED to increment,
;	only when the stack is popped and data is stored to rax str)
;r10 assists with knowing where rsp began; we need this for:
;	always pushing operator when stack is blank
;	making sure to pop all the non-popped operators
;rdx is intermediate translator holding characters of input string

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
;Printing and exit statement
;====================================================
;rax is pointer to second string (postfix)
;r11 is string size

allPopped:

;mov rdi,rax
;mov rsi,r11
;call larray_print

mov rcx,0
evaluate:
	mov rsi,[rax + rcx * 8]
	add rcx,1
	
	cmp rsi,0x30
	jl useOp
	
	sub rsi,0x30
	push rsi
	
backToCheckSize:
	cmp rcx,r11
	jl evaluate
	
	pop rax
	ret
;****************************************************
;*******************End of system********************
;****************************************************



;====================================================
;Operator evaluation (useOp loop)
;====================================================
useOp:
	cmp rsi,0x2a
	je multiply
	
	cmp rsi,0x2b
	je addition
	
	cmp rsi,0x2d
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
;rdx is intermediate translator holding characters of input string


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
	sub r11,2
	pop rdi
	
	popThemAll:
	mov QWORD[rax + rsi * 8], rdi
	add rsi,1
	pop rdi
	cmp rdi,0x28
	jne popThemAll
	
	jmp backFromHandleOp
	
storeOp:
	;no operators in stack (pointer location)
	cmp rsp,r10
	je pushOp
	
	;( operator on top (rsp value)
	mov r8,QWORD[rsp]
	cmp r8,0x28
	je pushOp
	
	;current operator is (
	cmp rdx,0x28
	je pushOp
	
	;current operator is )
	cmp rdx,0x29
	je closeParenOp
	
	;current operator is *
	cmp rdx,0x2b
	jl incomingIsMult
	
	;current operator is + or -
	cmp rdx,0x2b
	jge incomingIsAddOrSub
	
	jmp invalidOp
	
invalidInt:
	mov rdx,0x30
	
invalidOp:
	mov rdx,0x2a
;****************************************************

