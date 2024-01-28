.686
.model flat, stdcall
option casemap :none

include \masm32\include\kernel32.inc	; Basement
include \masm32\include\windows.inc		; API for console, etc
include \masm32\include\msvcrt.inc		; C-funcs (may be I will write mine instead)
include \masm32\include\winmm.inc
include \masm32\include\user32.inc

include \masm32\macros\macros.asm

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\msvcrt.lib
includelib \masm32\lib\winmm.lib
includelib \masm32\lib\user32.lib


DrawCell				proto   :DWORD, :DWORD

PutCursorToPos		proto 	:DWORD, :DWORD
HideCursor			proto
MenuCreate			proto
Main				proto

ImportActionProc	proto
ExportActionProc	proto

SetWindowSize			proto		wt:DWORD, ht:DWORD

PlaySoundOnClick	proto	:DWORD


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
	eraseBrush  	equ		32		; space
	
	exclBrush		equ		33
	quoteBrush      equ		34
	sharpBrush		equ		35
	dollarBrush		equ		36
	; percentBrush	equ		37
	comAndBrush		equ		38
	zeroQuoteBrush	equ		39
	
	
	szBrushBuffer			db			16			dup(0)
	
	MAX_WIDTH				equ			150
	MAX_HEIGHT				equ			50	

.data	
	ConsoleRecord			INPUT_RECORD	<>

	;hIn			dd			0
	;hOut		dd			0
	;nRead		dd			0
	hWnd		dd			0
	
	
	szClear						db			"cls", 0
	szPlayOnClick				db			"Audio/Click.wav", 0
	
	screenSize		RECT		<0,0,0,0>
	
	
	; DRAWING
	szToDraw	db		    2	dup(0)
	drawSize	dd			1
	drawColor	dd			cWhite