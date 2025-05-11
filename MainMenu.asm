

MenuCreate				proto
LogoCreate				proto
DrawAreaCreate			proto
ToolsAreaCreate			proto
SizeAndColorToolCreate	proto
ExtraInfoAreaCreate		proto
CreateButton			proto		:BYTE, :DWORD, :DWORD ; procedure的定義，BYTE, DWORD, DWORD 是要傳進去的 arguments
ButtonCreate2			proto		:BYTE, :DWORD, :DWORD
SpecialButtonsCreate	proto
ColoredSquareCreate		proto		:DWORD, :DWORD, :DWORD
	
ClearPaint				proto

HorizontalBorderConstruct	proto	:DWORD, :DWORD, :DWORD
VerticalBorderConstruct		proto	:DWORD, :DWORD, :DWORD



.const
	; equ = equal (ex. label = value 與 label equ value 相等)
	WORKING_AREA_WIDTH		equ			120
	WORKING_AREA_HEIGHT		equ			40
	
	TOOLS_AREA_WIDTH		equ			32	; TOOLS_AREA_HEIGHT = WORKING_AREA_HEIGHT = 40
	
	
	
.data
	; db stand for define byte, 
	szProgramName			db			"CMD DRAWER aka CMDrawer", 0
	szToolsArea				db			"TOOLS", 0
	szClearButtonText		db			"Clear", 0
	szExportButtonText		db			"Export", 0
	szImportButtonText		db			"Import", 0
	szEraserButtonText      db			"Eraser", 0
	szPickerButtonText 		db			"Picker               ", 0
	szSquareButtonText		db			"Square", 0
	szCircleButtonText				db			"Circle", 0
	szSizeText				db			"SIZE:", 0
	szColorText				db			"COLORS:", 0
	szProgramVersion		db			"CMDrawer", 0
	szAuthor				db			"Changed by Our Team", 0
	szThreeSpaces			db			"   ", 0
	EraserBrush 			db 			' ', 0
	
	srect				SMALL_RECT		<0, 0, MAX_WIDTH, MAX_HEIGHT>	; For console buffer
	
	; dd stand for define double word
	interfaceFontColor			dd			cYellow ; define in main.inc
	interfaceBorderColor		dd			LightGray ; define in main.inc

	szEmptyLine				db		WORKING_AREA_WIDTH		dup(32), 0

.code
MenuCreate proc	uses ecx esi edi

	invoke crt_system, offset szClear
	invoke LogoCreate
	invoke DrawAreaCreate
	invoke ToolsAreaCreate
	invoke SizeAndColorToolCreate
	invoke ExtraInfoAreaCreate
	
	Ret
MenuCreate endp

LogoCreate proc uses ecx esi edi
	
	LOCAL hOut: DWORD ; a local variable hOut , type is DWORD; hOut stand for handle output
	
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOut, eax
	
	invoke HorizontalBorderConstruct, WORKING_AREA_WIDTH, 1, 0
	invoke HorizontalBorderConstruct, WORKING_AREA_WIDTH, 1, 2
	
	; Deleted for optimization
	;invoke VerticalBorderConstruct, 1, 0, 1
	;invoke VerticalBorderConstruct, 1, WORKING_AREA_WIDTH+1, 1
	
	invoke SetConsoleTextAttribute, hOut, interfaceFontColor
	invoke PutCursorToPos, 49, 1
	invoke crt_printf, offset szProgramName
	invoke SetConsoleTextAttribute, hOut, interfaceBorderColor
	
	Ret
LogoCreate endp

DrawAreaCreate proc uses ecx esi edi

	invoke VerticalBorderConstruct, WORKING_AREA_HEIGHT, 0, 1
	invoke VerticalBorderConstruct, WORKING_AREA_HEIGHT, WORKING_AREA_WIDTH+1, 1
	invoke HorizontalBorderConstruct, 120, 1, WORKING_AREA_HEIGHT+1
	
	Ret
DrawAreaCreate endp

ToolsAreaCreate proc uses ecx esi edi
	LOCAL hOut: DWORD
	
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOut, eax
	; 打造右邊的邊框
	invoke HorizontalBorderConstruct, 32, WORKING_AREA_WIDTH+2, 0
	invoke HorizontalBorderConstruct, 32, WORKING_AREA_WIDTH+2, 2
	invoke HorizontalBorderConstruct, TOOLS_AREA_WIDTH, WORKING_AREA_WIDTH+2, WORKING_AREA_HEIGHT+1
	invoke VerticalBorderConstruct, WORKING_AREA_HEIGHT, WORKING_AREA_WIDTH+TOOLS_AREA_WIDTH+2, 1
	
	invoke SetConsoleTextAttribute, hOut, interfaceFontColor
	invoke PutCursorToPos, 135, 1
	invoke crt_printf, offset szToolsArea
	invoke SetConsoleTextAttribute, hOut, interfaceBorderColor
	
	invoke ButtonCreate2, exclBrush, WORKING_AREA_WIDTH+3, 3
	invoke ButtonCreate2, quoteBrush, WORKING_AREA_WIDTH+8, 3
	invoke ButtonCreate2, sharpBrush, WORKING_AREA_WIDTH+13, 3
	invoke ButtonCreate2, dollarBrush, WORKING_AREA_WIDTH+18, 3
	invoke ButtonCreate2, comAndBrush, WORKING_AREA_WIDTH+23, 3
	invoke ButtonCreate2, zeroQuoteBrush, WORKING_AREA_WIDTH+28, 3	
	
	invoke ButtonCreate2, parenthOBrush, WORKING_AREA_WIDTH+3, 6
	invoke ButtonCreate2, parenthCBrush, WORKING_AREA_WIDTH+8, 6
	invoke ButtonCreate2, multiplBrush, WORKING_AREA_WIDTH+13, 6
	invoke ButtonCreate2, plusBrush, WORKING_AREA_WIDTH+18, 6
	invoke ButtonCreate2, commaBrush, WORKING_AREA_WIDTH+23, 6
	invoke ButtonCreate2, minusBrush, WORKING_AREA_WIDTH+28, 6

	invoke ButtonCreate2, MBrush, WORKING_AREA_WIDTH+3, 9
	invoke ButtonCreate2, slashBrush, WORKING_AREA_WIDTH+8, 9
	invoke ButtonCreate2, colonBrush, WORKING_AREA_WIDTH+13, 9
	invoke ButtonCreate2, semicolonBrush, WORKING_AREA_WIDTH+18, 9
	invoke ButtonCreate2, lessBrush, WORKING_AREA_WIDTH+23, 9
	invoke ButtonCreate2, equalBrush, WORKING_AREA_WIDTH+28, 9
	
	invoke ButtonCreate2, moreBrush, WORKING_AREA_WIDTH+3, 12
	invoke ButtonCreate2, questionBrush, WORKING_AREA_WIDTH+8, 12
	invoke ButtonCreate2, atBrush, WORKING_AREA_WIDTH+13, 12
	invoke ButtonCreate2, squareOBrush, WORKING_AREA_WIDTH+18, 12
	invoke ButtonCreate2, backSlashBrush, WORKING_AREA_WIDTH+23, 12
	invoke ButtonCreate2, squareCBrush, WORKING_AREA_WIDTH+28, 12
	
	invoke ButtonCreate2, birdBrush, WORKING_AREA_WIDTH+3, 15
	invoke ButtonCreate2, traitBrush, WORKING_AREA_WIDTH+8, 15
	invoke ButtonCreate2, braceOBrush, WORKING_AREA_WIDTH+13, 15
	invoke ButtonCreate2, directBrush, WORKING_AREA_WIDTH+18, 15
	invoke ButtonCreate2, braceCBrush, WORKING_AREA_WIDTH+23, 15
	invoke ButtonCreate2, tildaBrush, WORKING_AREA_WIDTH+28, 15

	invoke SpecialButtonsCreate
	Ret
ToolsAreaCreate endp

ExtraInfoAreaCreate proc uses ecx esi edi

	LOCAL hOut: DWORD
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOut, eax
	
	invoke SetConsoleTextAttribute, hOut, LightGray
	
	invoke PutCursorToPos, WORKING_AREA_WIDTH-7, WORKING_AREA_HEIGHT + 6
	invoke crt_printf, offset szAuthor
	
	invoke PutCursorToPos, WORKING_AREA_WIDTH-7, WORKING_AREA_HEIGHT + 7
	invoke crt_printf, offset szProgramVersion
	
	invoke SetConsoleTextAttribute, hOut, interfaceBorderColor
	Ret
ExtraInfoAreaCreate endp

HorizontalBorderConstruct proc uses ecx ebx esi edi count:DWORD, xCor: DWORD, yCor: DWORD
	
	mov ebx, 0
	.while ebx < count
	
		invoke PutCursorToPos, xCor, yCor
		fn crt_printf, "-"
		inc xCor
		inc ebx
		
	.endw
	
	Ret
HorizontalBorderConstruct endp

VerticalBorderConstruct proc uses ecx ebx esi edi count:DWORD, xCor: DWORD, yCor: DWORD

	mov ebx, 0
	.while ebx < count
	
		invoke PutCursorToPos, xCor, yCor
		fn crt_printf, "|" ; c runtime printf function imported from the C runtime library (msvcrt.dll or similar)
		inc yCor
		inc ebx
		
	.endw

	Ret
VerticalBorderConstruct endp

CreateButton proc uses ebx ecx esi edi chr:BYTE, xCor:DWORD, yCor:DWORD
	
	mov ebx, xCor
	mov ecx, yCor
	
	inc ebx
	invoke HorizontalBorderConstruct, 5, ebx, ecx
	
	add ecx, 4
	invoke HorizontalBorderConstruct, 5, ebx, ecx
	
	dec ebx
	sub ecx, 3
	invoke VerticalBorderConstruct, 3, ebx, ecx
	
	add ebx, 6
	invoke VerticalBorderConstruct, 3, ebx, ecx
	
	sub ebx, 3
	inc ecx
	invoke PutCursorToPos, ebx, ecx
	invoke crt_printf, addr chr

	Ret
CreateButton endp

ButtonCreate2 proc uses ebx ecx esi edi chr:BYTE, xCor:DWORD, yCor:DWORD
	
	mov ebx, xCor
	mov ecx, yCor
	
	inc ebx
	invoke HorizontalBorderConstruct, 3, ebx, ecx
	
	add ecx, 2
	invoke HorizontalBorderConstruct, 3, ebx, ecx
	
	dec ebx
	dec ecx
	invoke VerticalBorderConstruct, 1, ebx, ecx
	
	add ebx, 4
	invoke VerticalBorderConstruct, 1, ebx, ecx
	
	sub ebx, 2
	invoke PutCursorToPos, ebx, ecx
	invoke crt_printf, addr chr

	Ret
ButtonCreate2 endp

SpecialButtonsCreate proc uses ecx esi edi

	LOCAL hOut: DWORD
	
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOut, eax
	
	; Clear Button Creating
	invoke VerticalBorderConstruct, 1, WORKING_AREA_WIDTH+2, WORKING_AREA_HEIGHT-1
	invoke HorizontalBorderConstruct, 13, WORKING_AREA_WIDTH+3, WORKING_AREA_HEIGHT-2
	invoke VerticalBorderConstruct, 1, WORKING_AREA_WIDTH+16, WORKING_AREA_HEIGHT-1
	invoke HorizontalBorderConstruct, 13, WORKING_AREA_WIDTH+3, WORKING_AREA_HEIGHT
	
	invoke SetConsoleTextAttribute, hOut, interfaceFontColor
	invoke PutCursorToPos, 127, WORKING_AREA_HEIGHT-1
	invoke crt_printf, offset szClearButtonText
	invoke SetConsoleTextAttribute, hOut, interfaceBorderColor
	
	
	; Export Button Creating
	invoke VerticalBorderConstruct, 1, WORKING_AREA_WIDTH+18, WORKING_AREA_HEIGHT-1
	invoke HorizontalBorderConstruct, 13, WORKING_AREA_WIDTH+19, WORKING_AREA_HEIGHT-2
	invoke VerticalBorderConstruct, 1, WORKING_AREA_WIDTH+32, WORKING_AREA_HEIGHT-1
	invoke HorizontalBorderConstruct, 13, WORKING_AREA_WIDTH+19, WORKING_AREA_HEIGHT
	
	invoke SetConsoleTextAttribute, hOut, interfaceFontColor
	invoke PutCursorToPos, 142, WORKING_AREA_HEIGHT-1
	invoke crt_printf, offset szExportButtonText
	invoke SetConsoleTextAttribute, hOut, interfaceBorderColor
	
	; Import Button Creating
	invoke VerticalBorderConstruct, 1, WORKING_AREA_WIDTH+18, WORKING_AREA_HEIGHT-4
	invoke HorizontalBorderConstruct, 13, WORKING_AREA_WIDTH+19, WORKING_AREA_HEIGHT-5
	invoke VerticalBorderConstruct, 1, WORKING_AREA_WIDTH+32, WORKING_AREA_HEIGHT-4
	invoke HorizontalBorderConstruct, 13, WORKING_AREA_WIDTH+19, WORKING_AREA_HEIGHT-2
	
	invoke SetConsoleTextAttribute, hOut, interfaceFontColor
	invoke PutCursorToPos, 142, WORKING_AREA_HEIGHT-4
	invoke crt_printf, offset szImportButtonText
	invoke SetConsoleTextAttribute, hOut, interfaceBorderColor
	
	; Eraser Button Creating
	invoke VerticalBorderConstruct, 3, WORKING_AREA_WIDTH+2, WORKING_AREA_HEIGHT-6
	invoke HorizontalBorderConstruct, 6, WORKING_AREA_WIDTH+3, WORKING_AREA_HEIGHT-7
	invoke VerticalBorderConstruct, 3, WORKING_AREA_WIDTH+9, WORKING_AREA_HEIGHT-6
	invoke HorizontalBorderConstruct, 6, WORKING_AREA_WIDTH+3, WORKING_AREA_HEIGHT-3
	
	invoke SetConsoleTextAttribute, hOut, interfaceFontColor
	invoke PutCursorToPos, WORKING_AREA_WIDTH+3, WORKING_AREA_HEIGHT-5
	invoke crt_printf, offset szEraserButtonText
	invoke SetConsoleTextAttribute, hOut, interfaceBorderColor
	; Picker Button Creating

	invoke VerticalBorderConstruct, 3, WORKING_AREA_WIDTH+10, WORKING_AREA_HEIGHT-6
	invoke HorizontalBorderConstruct, 6, WORKING_AREA_WIDTH+11, WORKING_AREA_HEIGHT-7
	invoke VerticalBorderConstruct, 3, WORKING_AREA_WIDTH+17, WORKING_AREA_HEIGHT-6
	invoke HorizontalBorderConstruct, 6, WORKING_AREA_WIDTH+11, WORKING_AREA_HEIGHT-3
	
	invoke SetConsoleTextAttribute, hOut, interfaceFontColor
	invoke PutCursorToPos, WORKING_AREA_WIDTH+11, WORKING_AREA_HEIGHT-5
	invoke crt_printf, offset szPickerButtonText
	invoke SetConsoleTextAttribute, hOut, interfaceBorderColor

	; Square Button Creating
	invoke VerticalBorderConstruct, 3, 1, WORKING_AREA_HEIGHT+8
	invoke HorizontalBorderConstruct, 6, 2, WORKING_AREA_HEIGHT+7
	invoke VerticalBorderConstruct, 3, 8, WORKING_AREA_HEIGHT+8
	invoke HorizontalBorderConstruct, 6, 2, WORKING_AREA_HEIGHT+11
	
	invoke SetConsoleTextAttribute, hOut, interfaceFontColor
	invoke PutCursorToPos, 2, WORKING_AREA_HEIGHT+9
	invoke crt_printf, offset szSquareButtonText
	invoke SetConsoleTextAttribute, hOut, interfaceBorderColor

	; Square Button Creating
	invoke VerticalBorderConstruct, 3, 9, WORKING_AREA_HEIGHT+8
	invoke HorizontalBorderConstruct, 6, 10, WORKING_AREA_HEIGHT+7
	invoke VerticalBorderConstruct, 3, 16, WORKING_AREA_HEIGHT+8
	invoke HorizontalBorderConstruct, 6, 10, WORKING_AREA_HEIGHT+11
	
	invoke SetConsoleTextAttribute, hOut, interfaceFontColor
	invoke PutCursorToPos, 10, WORKING_AREA_HEIGHT+9
	invoke crt_printf, offset szCircleButtonText
	invoke SetConsoleTextAttribute, hOut, interfaceBorderColor


	Ret
SpecialButtonsCreate endp

SizeAndColorToolCreate proc uses ecx esi edi
	
	LOCAL hOut: DWORD
	
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOut, eax
		
	; Size Text Creating
	invoke SetConsoleTextAttribute, hOut, interfaceFontColor
	invoke PutCursorToPos, WORKING_AREA_WIDTH+23, 19
	invoke crt_printf, offset szSizeText
	; Colors Text Creating
	invoke SetConsoleTextAttribute, hOut, interfaceFontColor
	invoke PutCursorToPos, WORKING_AREA_WIDTH+7, 19
	invoke crt_printf, offset szColorText
	invoke SetConsoleTextAttribute, hOut, interfaceBorderColor
	
	invoke ButtonCreate2, '1', WORKING_AREA_WIDTH+18, 20
	invoke ButtonCreate2, '2', WORKING_AREA_WIDTH+23, 20
	invoke ButtonCreate2, '3', WORKING_AREA_WIDTH+28, 20
	
	invoke ButtonCreate2, '4', WORKING_AREA_WIDTH+18, 23
	invoke ButtonCreate2, '5', WORKING_AREA_WIDTH+23, 23
	invoke ButtonCreate2, '6', WORKING_AREA_WIDTH+28, 23
	
	invoke ButtonCreate2, '7', WORKING_AREA_WIDTH+18, 26
	invoke ButtonCreate2, '8', WORKING_AREA_WIDTH+23, 26
	invoke ButtonCreate2, '9', WORKING_AREA_WIDTH+28, 26
	
	invoke ColoredSquareCreate, WORKING_AREA_WIDTH + 2, 21, cBgBlue
	invoke ColoredSquareCreate, WORKING_AREA_WIDTH + 5, 21, cBgGreen
	invoke ColoredSquareCreate, WORKING_AREA_WIDTH + 8, 21, cBgCyan
	invoke ColoredSquareCreate, WORKING_AREA_WIDTH + 11, 21, cBgRed
	invoke ColoredSquareCreate, WORKING_AREA_WIDTH + 14, 21, cBgMagenta
	
	invoke ColoredSquareCreate, WORKING_AREA_WIDTH + 2, 23, cBgBrown
	invoke ColoredSquareCreate, WORKING_AREA_WIDTH + 5, 23, BgLightGray
	invoke ColoredSquareCreate, WORKING_AREA_WIDTH + 8, 23, BgDarkGray	
	invoke ColoredSquareCreate, WORKING_AREA_WIDTH + 11, 23, BgLightBlue
	invoke ColoredSquareCreate, WORKING_AREA_WIDTH + 14, 23, BgLightGreen
	
	invoke ColoredSquareCreate, WORKING_AREA_WIDTH + 2, 25, BgLightCyan
	invoke ColoredSquareCreate, WORKING_AREA_WIDTH + 5, 25, BgLightRed
	invoke ColoredSquareCreate, WORKING_AREA_WIDTH + 8, 25, BgLightMagenta
	invoke ColoredSquareCreate, WORKING_AREA_WIDTH + 11, 25, cBgYellow
	invoke ColoredSquareCreate, WORKING_AREA_WIDTH + 14, 25, cBgWhite
	
	Ret
SizeAndColorToolCreate endp

ColoredSquareCreate proc uses ebx esi edi xCor: DWORD, yCor: DWORD, color: DWORD
	
	invoke SetColor, color
	
	mov ebx, yCor
	
	invoke PutCursorToPos, xCor, ebx
	invoke crt_printf, offset szThreeSpaces
	
	inc ebx
	
	invoke PutCursorToPos, xCor, ebx
	invoke crt_printf, offset szThreeSpaces
	
	invoke SetColor, interfaceBorderColor
	
	Ret
ColoredSquareCreate endp

ClearPaint proc uses ebx esi edi

	mov ebx, 3
	.while ebx <= WORKING_AREA_HEIGHT
	
		invoke PutCursorToPos, 1, ebx
		invoke crt_printf, offset szEmptyLine
		inc ebx
	
	.endw

	Ret
ClearPaint endp