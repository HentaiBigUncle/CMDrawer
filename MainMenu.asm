
MenuCreate			proto
SetWindowSize		proto		wt:DWORD, ht:DWORD
LogoCreate			proto
DrawAreaCreate		proto
ToolsAreaCreate		proto
CreateButton		proto		:BYTE, :DWORD, :DWORD

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
	srect				SMALL_RECT		<0, 0, MAX_WIDTH, MAX_HEIGHT>	; For console buffer
	
	interfaceFontColor			dd			LightCyan
	interfaceBorderColor		dd			cWhite

.code
MenuCreate proc	uses ecx esi edi

	invoke crt_system, offset szClear
	invoke SetWindowSize, MAX_WIDTH, MAX_HEIGHT
	invoke LogoCreate
	invoke DrawAreaCreate
	invoke ToolsAreaCreate
	
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
	
	;invoke HorizontalBorderConstruct, 4, WORKING_AREA_WIDTH+4, 4+3
	;invoke HorizontalBorderConstruct, 4, WORKING_AREA_WIDTH+4, 3
	;invoke VerticalBorderConstruct, 3, WORKING_AREA_WIDTH+3, 4
	;invoke VerticalBorderConstruct, 3, WORKING_AREA_WIDTH+3+4+1, 4
	
	invoke CreateButton, sharpBrush, WORKING_AREA_WIDTH+3, 3
	invoke CreateButton, eraseBrush, WORKING_AREA_WIDTH+10, 3
	
	Ret
ToolsAreaCreate endp

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