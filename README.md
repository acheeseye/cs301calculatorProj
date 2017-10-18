# CS 301 PROJECT1: CALCULATOR PROGRAM

## Description: 	
- A calculator program that takes an infix expression and calculates the result by rearranging the expression into postfix. 
- The system is limited to PERFECT input and only uses `+`, `-`, `*`, `(`, and `)` operators.  
- The range of possible in/outputs are limited to 32 bit integers, excluding 0x7FFFFFFB ~ 0x7FFFFFFF as they are used for the five operators.  
- There are likely unconsidered cases which will result in a crash or incorrect output.

## Guidelines followed:
1. Print operands as they arrive.
2. If the top of the stack is empty or occupied by operator `(` then push onto stack
3. If incoming operator is `(` then push onto stack.
4. If incoming operator is `)` then pop stack until operator `(` is found. Exclude printing `(` and `)`.
5. If incoming operator has higher precedence than the operator at the top of the stack, push the incoming operator.
6. If incoming operator has equal precedence with the operator at the top of the stack, pop stack to print then push incoming operator (association is left to right).
7. If incoming operator has lower precedence than the operator at the top of the stack, pop stack to print then push incoming operator.
8. Pop any remaining operators at the end in normal popping order.  
(Refer to Sources for source)

### Additional Guidelines for correct output:
9. If incoming operator is `-`, make the next integer negative and the incoming operator `+`. This makes sure that a negative sign does not carry through to other operations.

## v0.0:
- Currently supports infix translation into postfix for `+` `-` and `*` operators
- Undefined operators are set to `*`
- Undefined characters (<0x30 or >0x39) are set to 0x30
- 1+2\*(4+3\*2-1) SOMEHOW PRINTS arr[5] TWICE??? The values store are correct, but somehow arr[5] gets included twice
	- SOLVED: larray_print should only print 10
- (10/03/2017 JH)

## v1.0:
- Explanation of loops and new comments added
- Updated constant hex values to characters represented
- (10/12/2017 JH)

## v2.0:
- Resolved the issue of using parentheses
- Attempting to implement multi-digited input feature
- (10/15/2017 JH)

## v3.0:
- Sucessful implementation of multi-digited input feature
	- STILLNEEDS: code correction for expressions beginning with parentheses
- Resolved the issue of incorrect outputs due to negative values paired with `-` operator
- (10/17/2017 JH)

## v3.1:
- STILLNEED resolved?

## Sources:
- [Guidelines followed](http://csis.pace.edu/~wolf/CS122/infix-postfix.htm)
- [How to evaluate the postfix](http://scriptasylum.com/tutorials/infix_postfix/algorithms/postfix-evaluation/)
- NEED: origin of repne scasb
