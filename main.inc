.686
.model flat, stdcall
option casemap :none

include \masm32\include\kernel32.inc	; Basement
include \masm32\include\msvcrt.inc		; C-funcs (may be I will write mine instead)
include \masm32\include\windows.inc		; API for console, etc

include \masm32\macros\macros.asm

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\msvcrt.lib

cout				proto	:DWORD
lens				proto	:DWORD

PutCursorToPos		proto 	xCor:WORD, yCor:WORD
MenuCreate			proto
Main				proto

.const
	HORIZONTAL_BORDER_LENGTH	equ		123
	VERTICAL_BORDER_LENGTH		equ		81

.data
	ConsoleRecord			INPUT_RECORD	<>

	;hIn			dd			0
	;hOut		dd			0
	;nRead		dd			0
	
	; SCREEN MANIPULATION
	szHorizontalBorder		db			" ------------------------------------------------------------------------------------------------------------------------ ", 0
	szVerticalBorder2		db			"|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, 0
	szVerticalChr			db			"|", 0
	szClear					db			"cls", 0
	szTitle					db			"CMDrawer v0.2.", 0
	; DRAWING
	szToDraw	db		    5	dup(0)