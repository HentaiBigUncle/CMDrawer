

SetWindowSize			proto		wt:DWORD, ht:DWORD

MenuCreate				proto
LogoCreate				proto
DrawAreaCreate			proto
ToolsAreaCreate			proto
ExtraInfoAreaCreate		proto
CreateButton			proto		:BYTE, :DWORD, :DWORD
ButtonCreate2			proto		:BYTE, :DWORD, :DWORD
SpecialButtonsCreate	proto

HorizontalBorderConstruct	proto	:DWORD, :DWORD, :DWORD
VerticalBorderConstruct		proto	:DWORD, :DWORD, :DWORD



.const

	MAX_WIDTH				equ			150
	MAX_HEIGHT				equ			50
	
	WORKING_AREA_WIDTH		equ			120
	WORKING_AREA_HEIGHT		equ			40
	
	TOOLS_AREA_WIDTH		equ			32	; TOOLS_AREA_HEIGHT = WORKING_AREA_HEIGHT
	
	
	
.data

	szProgramName			db			"CMD DRAWER aka CMDrawer", 0
	szToolsArea				db			"TOOLS", 0
	szClearButtonText		db			"Clear", 0
	szExportButtonText		db			"Export", 0
	szEraserButtonText      db			"Eraser", 0
	szProgramVersion		db			"CMDrawer Version 1.2.0", 0
	szAuthor				db			"Created by Michael Budnikov aka Mishanya00", 0
	
	srect				SMALL_RECT		<0, 0, MAX_WIDTH, MAX_HEIGHT>	; For console buffer
	
	interfaceFontColor			dd			cYellow
	interfaceBorderColor		dd			cWhite




.code
MenuCreate proc	uses ecx esi edi

	invoke crt_system, offset szClear
	invoke SetWindowSize, MAX_WIDTH, MAX_HEIGHT
	invoke LogoCreate
	invoke DrawAreaCreate
	invoke ToolsAreaCreate
	invoke ExtraInfoAreaCreate
	
	Ret
MenuCreate endp

SetWindowSize proc uses ebx esi edi wd:DWORD, ht:DWORD
	
	LOCAL hOut: DWORD
	
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOut, eax
	
	mov ebx, ht
	shl ebx, 16
	or ebx, wd
	
	invoke SetConsoleScreenBufferSize, hOut, ebx
	invoke SetConsoleWindowInfo, hOut, 1, offset srect
	
	Ret
SetWindowSize endp

LogoCreate proc uses ebx esi edi
	
	LOCAL hOut: DWORD
	
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

DrawAreaCreate proc uses ebx esi edi

	invoke VerticalBorderConstruct, WORKING_AREA_HEIGHT, 0, 1
	invoke VerticalBorderConstruct, WORKING_AREA_HEIGHT, WORKING_AREA_WIDTH+1, 1
	invoke HorizontalBorderConstruct, 120, 1, WORKING_AREA_HEIGHT+1
	
	Ret
DrawAreaCreate endp

ToolsAreaCreate proc uses ebx esi edi
	LOCAL hOut: DWORD
	
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOut, eax
	
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

	invoke SpecialButtonsCreate
	Ret
ToolsAreaCreate endp

ExtraInfoAreaCreate proc uses ebx esi edi

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
		fn crt_printf, "|"
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

SpecialButtonsCreate proc uses ebx esi edi

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
	invoke PutCursorToPos, 143, WORKING_AREA_HEIGHT-1
	invoke crt_printf, offset szExportButtonText
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
	
		
	Ret
SpecialButtonsCreate endp