# cs301calculatorProj

## Description: 	
A calculator program that takes an infix expression and calculates the result by rearranging expression into postfix.

## Rules followed:
1. Print operands as they arrive.
2. If the top of the stack is empty or occupied by operator '(' then push onto stack
3. If incoming operator is '(' then push onto stack.
4. If incoming operator is ')' then pop stack until operator '(' is found. Exclude printing '(' and ')'.
5. If incoming operator has higher precedence than the operator at the top of the stack, push the incoming operator.
6. If incoming operator has equal precedence with the operator at the top of the stack, pop stack to print then push incoming operator (association is left to right).
7. If incoming operator has lower precedence than the operator at the top of the stack, pop stack to print then push incoming operator.
8. Pop any remaining operators at the end in normal popping order.

## v0.0:
- Currently supports infix translation into postfix for '+' '-' and '\*' operators
- Undefined operators are set to '\*'
- Undefined characters (<0x30 or >0x39) are set to 0x30
- 1+2\*(4+3\*2-1) SOMEHOW PRINTS arr[5] TWICE??? The values store are correct, but somehow arr[5] gets included twice
	- SOLVED: larray_print should only print 10
- (10/03/2017 JH)

## v1.0:
- Explanation of loops and new comments added
- Updated constant hex values to characters represented
- (10/12/2017 JH)

## Sources:
- [Guidelines followed](http://csis.pace.edu/~wolf/CS122/infix-postfix.htm)
- [How to evaluate the postfix](http://scriptasylum.com/tutorials/infix_postfix/algorithms/postfix-evaluation/)
- NEED: origin of repne scasb
