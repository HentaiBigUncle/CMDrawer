.686
.model flat, stdcall
option casemap :none

include \masm32\include\kernel32.inc	; Basement
include \masm32\include\windows.inc		; API for console, etc
include \masm32\include\msvcrt.inc		; C-funcs (may be I will write mine instead)
include \masm32\include\winmm.inc		; multimedia lib
include \masm32\include\user32.inc
include	\masm32\include\masm32.inc
include \masm32\macros\macros.asm

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\msvcrt.lib
includelib \masm32\lib\winmm.lib
includelib \masm32\lib\user32.lib


PutCursorToPos					proto 			:DWORD, :DWORD
HideCursor						proto
MenuCreate						proto
Main							proto

SetWindowSize					proto		 	:DWORD, :DWORD
SetColor						proto		    :DWORD

PlaySoundOnClick				proto			:DWORD
DrawCell						proto  			:DWORD, :DWORD

SaveGoBack						proto  			:DWORD ;紀錄上一步做了什麼
GoBack							proto 			:DWORD, :DWORD
DoneGoBack						proto 		;當沒有儲存任何東西在UndoStackTop時，會到這裡
KeyController					proto			:DWORD, :DWORD
SaveCanvasSnapshot				proto
RedrawCanvas					proto			:DWORD, :DWORD
ExportImageEvent				proto
ImportImageEvent 				proto

ClearBuffer						proto			:DWORD, :DWORD
SaveToHistory					proto
UndoCanvas						proto
GetInput						proto			:DWORD, :DWORD
ClearLine						proto			:DWORD
ClearLogArea					proto
InitConsoleHandle				proto
ShowBrushStatus					proto 			
.const
	HORIZONTAL_BORDER_LENGTH	equ		123
	VERTICAL_BORDER_LENGTH		equ		81
	
	MAX_WIDTH				equ			150
	MAX_HEIGHT				equ			50

	WORKING_AREA_WIDTH		equ			120
	WORKING_AREA_HEIGHT		equ			40

	HISTORY_WIDTH     equ 120
	HISTORY_HEIGHT    equ 40
	HISTORY_SIZE      equ HISTORY_WIDTH * HISTORY_HEIGHT
	MAX_HISTORY_COUNT equ 100

	

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
	
;	BRUSHES: 			; 以下對照ASCII code 就可以知道數字代表啥

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
	
	MBrush equ 'M'   ; richen:將dotBrush他改成M

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

	; Undo
	MAX_UNDO_COUNT equ 100
.data?
	CanvasHistory     CHAR_INFO HISTORY_SIZE * MAX_HISTORY_COUNT dup(<>)
	HistoryCount      DWORD ?
	CurrentIndex      DWORD ?
	; console API handle
	hConsoleOutput    HANDLE ?
	; Temp buffer
	tempBuffer        CHAR_INFO HISTORY_SIZE dup(<>)
	
.data	
	ConsoleRecord			INPUT_RECORD	<>
	  
	hWnd		dd			0
	hFile		dd			0
	
	szClear						db			"cls", 0
	szPlayOnClick				db			"Audio/Click.wav", 0
	
	szGetFileName				db			"Enter file name: ", 0
	szPictureExportedOld		db			"Picture saved to image.txt. Be Careful, you can save ONLY 1 picture at the moment", 0
	szPictureExported			db			"Picture has been successfully saved! Be careful, you can rewrite existing files.", 0
	szPictureImported			db			"Picture has been successfully imported!", 0
	szFileNotFound 				db			"No .txt file with such name. Try again.", 0
	szClearLine					db			"          ", 0  ; 10 spaces
	
	szImage						db			"Image.txt", 0
	szTxt						db			".txt", 0
	szNewLine					db			13, 10, 0
	
	szBrushBuffer			db			16			dup(0)
	szBuffer1				db			64			dup(0)
	szBuffer2				db			256			dup(0)
		
	screenSize		RECT		<0,0,0,0>
	
	clickDone		db		0
	
	; DRAWING
	szToDraw	db		    2	dup(0)
	drawSize	dd			1
	drawColor	dd			cWhite
	; 迴車鑑
	prevButtonState dd 0	
	; 判斷是否為橡皮擦
	isEraser       dd  0
	strEraser		db "[Eraser]: Size %d ", 0
	fmtBrushStatus db  " [brush]: Size %d", 0