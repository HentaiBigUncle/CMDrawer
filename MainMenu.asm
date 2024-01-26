
MenuCreate			proto
SetWindowSize		proto		wt:DWORD, ht:DWORD
LogoCreate			proto
DrawAreaCreate		proto
ToolsAreaCreate		proto

HorizontalBorderConstruct	proto	:DWORD, :DWORD, :DWORD
VerticalBorderConstruct		proto	:DWORD, :DWORD, :DWORD

.const
	MAX_WIDTH				equ			150
	MAX_HEIGHT				equ			50
	
	WORKING_AREA_WIDTH		equ			120
	WORKING_AREA_HEIGHT		equ			40
	
	
.data
	szHorizontalBorder		db			" ------------------------------------------------------------------------------------------------------------------------ ", 0
	szVerticalBorder2		db			"|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, "|", 10, 0
	szVerticalChr			db			"|", 0
	szProgramName			db			"CMD DRAWER aka CMDrawer", 0
	srect				SMALL_RECT		<0, 0, MAX_WIDTH, MAX_HEIGHT>


.code
MenuCreate proc	uses ecx esi edi

	invoke crt_system, offset szClear
	invoke SetWindowSize, MAX_WIDTH, MAX_HEIGHT
	invoke LogoCreate
	invoke DrawAreaCreate
	
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
	
	invoke HorizontalBorderConstruct, 120, 1, 0
	invoke HorizontalBorderConstruct, 120, 1, 2
	invoke VerticalBorderConstruct, 1, 0, 1
	invoke VerticalBorderConstruct, 1, WORKING_AREA_WIDTH+1, 1
	
	invoke SetConsoleTextAttribute, hOut, LightMagenta
	invoke PutCursorToPos, 49, 1
	invoke crt_printf, offset szProgramName
	invoke SetConsoleTextAttribute, hOut, cWhite
	
	Ret
LogoCreate endp

DrawAreaCreate proc uses ebx esi edi

	invoke VerticalBorderConstruct, WORKING_AREA_HEIGHT, 0, 2
	invoke VerticalBorderConstruct, WORKING_AREA_HEIGHT, WORKING_AREA_WIDTH+1, 2
	invoke HorizontalBorderConstruct, 120, 1, WORKING_AREA_HEIGHT+1
	
	Ret
DrawAreaCreate endp

ToolsAreaCreate proc uses ebx esi edi
	
	

	Ret
ToolsAreaCreate endp

HorizontalBorderConstruct proc uses ebx esi edi count:DWORD, xCor: DWORD, yCor: DWORD
	
	mov ebx, 0
	.while ebx < count
	
		invoke PutCursorToPos, xCor, yCor
		fn crt_printf, "-"
		inc xCor
		inc ebx
		
	.endw
	
	Ret
HorizontalBorderConstruct endp

VerticalBorderConstruct proc uses ebx esi edi count:DWORD, xCor: DWORD, yCor: DWORD

	mov ebx, 0
	.while ebx < count
	
		invoke PutCursorToPos, xCor, yCor
		fn crt_printf, "|"
		inc yCor
		inc ebx
		
	.endw

	Ret
VerticalBorderConstruct endp