.686
.model flat, stdcall
option casemap :none

include \masm32\include\kernel32.inc	; Basement
include \masm32\include\msvcrt.inc		; C-funcs (may be I will write mine instead)
include \masm32\include\windows.inc		; API for console, etc

include \masm32\macros\macros.asm

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\msvcrt.lib

PutCursorToPos		proto xCor:WORD, yCor:WORD

.data
	ConsoleRecord			INPUT_RECORD	<>
	hIn			dd			0
	hOut		dd			0
	nRead		dd			0
	szToDraw	db		    5	dup(0)