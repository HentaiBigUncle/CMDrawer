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


PutCursorToPos					proto 			:DWORD, :DWORD
HideCursor						proto
MenuCreate						proto
Main							proto

SetWindowSize					proto		 	wt:DWORD, ht:DWORD
SetColor						proto			:DWORD

PlaySoundOnClick				proto			:DWORD
DrawCell						proto  			:DWORD, :DWORD

KeyController					proto				:DWORD, :DWORD

ExportImageEvent				proto
ImportImageEvent 				proto


.const
	HORIZONTAL_BORDER_LENGTH	equ		123
	VERTICAL_BORDER_LENGTH		equ		81
	
	MAX_WIDTH				equ			150
	MAX_HEIGHT				equ			50
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
	
	cBgBlue				= 10h
	cBgGreen			= 20h
	cBgCyan				= 30h
	cBgRed				= 40h
	cBgMagenta			= 50h
	cBgBrown			= 60h
	BgLightGray			= 70h
	BgDarkGray			= 80h
	BgLightBlue			= 90h
	BgLightGreen		= 0a0h
	BgLightCyan			= 0b0h
	BgLightRed			= 0c0h
	BgLightMagenta		= 0d0h
	cBgYellow			= 0e0h
	cBgWhite			= 0f0h
	
;	BRUSHES:
	eraseBrush  	equ		32		; space
	
	exclBrush		equ		33
	quoteBrush      equ		34
	sharpBrush		equ		35
	dollarBrush		equ		36
	comAndBrush		equ		38
	zeroQuoteBrush	equ		39
	
	parenthOBrush	equ		40
	parenthCBrush	equ		41
	multiplBrush	equ		42
	plusBrush		equ		43
	commaBrush		equ		44
	minusBrush		equ		45
	
	dotBrush		equ		46
	slashBrush		equ		47
	colonBrush		equ		58
	semicolonBrush	equ		59
	lessBrush		equ		60
	equalBrush		equ		61
	
	moreBrush 		equ		62
	questionBrush	equ		63
	atBrush			equ		64
	squareOBrush	equ		91
	backSlashBrush	equ		92
	squareCBrush	equ		93
	
	birdBrush		equ		94
	traitBrush		equ		95
	braceOBrush		equ		123
	directBrush		equ		124
	braceCBrush		equ		125
	tildaBrush		equ		126
	
	

.data	
	ConsoleRecord			INPUT_RECORD	<>
	
	hWnd		dd			0
	hFile		dd			0
	
	szClear						db			"cls", 0
	szPlayOnClick				db			"Audio/Click.wav", 0
	
	szImage						db			"Image.txt", 0
	szTxt						db			".txt", 0
	szNewLine					db			13, 10, 0
	
	szBrushBuffer			db			16			dup(0)
	szBuffer1				db			64			dup(0)
	szBuffer2				db			128			dup(0)
		
	screenSize		RECT		<0,0,0,0>
	
	; DRAWING
	szToDraw	db		    2	dup(0)
	drawSize	dd			1
	drawColor	dd			cWhite
	
	
	