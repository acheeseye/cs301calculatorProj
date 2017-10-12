;CS301 Assembly Language Project 1
;Assembly Calculator
;Jason Hsi & Frank Cline
;Rough draft
;Due: 10/04/2017



extern getchar
extern malloc
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
;Creates two mallocs for storing strings. r9 for the
;first string and rax for the second string. r9 will
;store the input expression as given and rax will
;store the postfix version on the input.
;====================================================
;r9 is pointer to first string
;rax is pointer to second string
;r11 is character count
;====================================================

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
;====================================================

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
;Iterate the string
;====================================================
;Looks at the characters of the unaltered stored
;string. If the value is '0' ~ '9', then it is stored
;to rax (;ELEMENT ADDED). Otherwise, it is assumed
;the incoming character is an operator and moves it
;to the storeOp loop. The string at rax is then
;pushed on to the stack for evaluation.
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
;to evaluate the desired output.
;====================================================
;rax is pointer to second string (postfix)
;r11 is string size
;====================================================

allPopped:

;mov rdi,rax
;mov rsi,r11
;call larray_print

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
	
	pop rax
	ret
;****************************************************
;*******************End of system********************
;****************************************************



;====================================================
;Operator evaluation (foundOp loop)
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
;values.
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
	sub r11,2
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

