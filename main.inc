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

PutCursorToPos		proto 	:DWORD, :DWORD
HideCursor			proto
MenuCreate			proto
Main				proto

.const
	HORIZONTAL_BORDER_LENGTH	equ		123
	VERTICAL_BORDER_LENGTH		equ		81
	
	; COLORS
	cBlack				= 0
	cBlue				= 1
	cGreen				= 2
	cCyan				= 3
	cRed				= 4
	cMagenta			= 5
	cBrown				= 6
	LightGray			= 7
	DarkGray			= 8
	LightBlue			= 9
	LightGreen			= 10
	LightCyan			= 11
	LightRed			= 12
	LightMagenta		= 13
	cYellow				= 14
	cWhite				= 15
	
;	BRUSHES:
	sharpBrush		equ		35
	eraseBrush  	equ		32		; space
	dollarBrush		equ		36
	

.data	
	ConsoleRecord			INPUT_RECORD	<>

	;hIn			dd			0
	;hOut		dd			0
	;nRead		dd			0
	
	szClear					db			"cls", 0
	szTitle					db			"CMDrawer v0.2.", 0
	; DRAWING
	szToDraw	db		    5	dup(0)