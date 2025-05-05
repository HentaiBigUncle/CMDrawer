include main.inc
include MainMenu.asm	

.code
start:
	
	invoke SetConsoleTitle, offset szProgramVersion
	
	invoke SetWindowSize, MAX_WIDTH, MAX_HEIGHT
	
	invoke Main
	
	invoke ExitProcess, 0
	
Main proc	uses ebx ecx esi edi
	
	LOCAL hIn: DWORD
	LOCAL hOut: DWORD
	LOCAL nRead: DWORD
	LOCAL lpMode: DWORD
	
	mov byte ptr[szToDraw], 35
	
	invoke GetStdHandle, STD_INPUT_HANDLE
	mov hIn, eax
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOut, eax
	
	invoke GetConsoleWindow
	invoke ShowScrollBar, eax, SB_BOTH, FALSE
	invoke HideCursor
	
	invoke MenuCreate
	
	invoke SetConsoleMode, hIn, ENABLE_MOUSE_INPUT or ENABLE_EXTENDED_FLAGS or ENABLE_LINE_INPUT or ENABLE_ECHO_INPUT or ENABLE_PROCESSED_INPUT
	
	_DOLOOP:
	
		invoke ReadConsoleInput, hIn, offset ConsoleRecord, 1, addr nRead
		invoke KeyController, hIn, hOut
		
		jmp _DOLOOP
		
	Ret
Main endp

ClearBuffer proc uses ebx esi edi lpBuffer: DWORD, count: DWORD

	; It's neccessary to use this procedure VERY CAREFULLY !!! YOU CAN REWRITE YOUR DATA !!!
	
	mov esi, lpBuffer
	mov ebx, 0
	
	.while ebx < count
	
		mov byte ptr[esi], 0
		
		inc esi
		inc ebx
	
	.endw
	
	Ret
ClearBuffer endp

ClearLine proc uses ebx esi edi yCor: DWORD

	invoke PutCursorToPos, 0, yCor
	invoke crt_printf, offset szEmptyLine

	Ret
ClearLine endp

ClearLogArea proc uses ebx esi edi

	invoke ClearLine, WORKING_AREA_HEIGHT+2
	invoke ClearLine, WORKING_AREA_HEIGHT+3
	invoke ClearLine, WORKING_AREA_HEIGHT+4
	invoke ClearLine, WORKING_AREA_HEIGHT+5
	invoke ClearLine, WORKING_AREA_HEIGHT+6

	Ret
ClearLogArea endp

PutCursorToPos proc uses ebx esi edi xCor: DWORD, yCor: DWORD	
	
	mov ebx, yCor
	shl ebx, 16
	or ebx, xCor
	;-------------------------------
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	invoke SetConsoleCursorPosition, eax, ebx
	;------------------------------
	
	ret
PutCursorToPos endp

HideCursor proc uses ebx esi edi
	
	LOCAL ci: CONSOLE_CURSOR_INFO
	LOCAL hOut: DWORD
	
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOut, eax
	
	lea ebx, ci
	invoke GetConsoleCursorInfo, hOut, ebx
	
	mov ci.bVisible, 0
	
	invoke SetConsoleCursorInfo, hOut, ebx

	Ret
HideCursor endp

PlaySoundOnClick proc uses ecx esi edi lpFile:DWORD

	invoke PlaySound, lpFile, 0, SND_FILENAME or SND_ASYNC
	Ret
PlaySoundOnClick endp

SetWindowSize proc uses ebx esi edi wd:DWORD, ht:DWORD
	
	LOCAL hOut: DWORD
	
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOut, eax
	
	mov ebx, ht
	shl ebx, 16
	or ebx, wd
	
	invoke GetConsoleWindow
	invoke ShowWindow, eax,SW_MAXIMIZE
	
	invoke SetConsoleScreenBufferSize, hOut, ebx
	invoke SetConsoleWindowInfo, hOut, 1, offset srect
	
	Ret
SetWindowSize endp

DrawCell proc uses ebx ecx esi edi hOut: DWORD, dwCoord: DWORD
	
	invoke SetColor, dword ptr[drawColor]
	lea esi, szBrushBuffer
	mov ebx, 0
	
	mov cx, word ptr[dwCoord]
	
	.while ebx < drawSize && cx <= WORKING_AREA_WIDTH
	
		mov al, byte ptr[szToDraw]
		mov byte ptr[esi], al
		inc ebx
		inc esi
		inc cx
		
	.endw
	
	mov byte ptr[esi], 0
	mov ebx, 0
	mov cx, word ptr[dwCoord+2]
	
	.while ebx < drawSize && cx <= WORKING_AREA_HEIGHT
		
		push ecx
		invoke SetConsoleCursorPosition, hOut, dwCoord
		invoke crt_printf, offset szBrushBuffer
		pop ecx
		
		inc ebx
		inc cx
		add dwCoord, 65536
	
	.endw

	Ret
DrawCell endp

 DrawSquare proc uses ebx ecx esi edi hOut: DWORD, dwCoord: DWORD

	LOCAL localCoord: DWORD

	; 設定顏色
	invoke SetColor, dword ptr[drawColor]

	; 取得中心點座標 → 推算左上角的起始點
	mov eax, dwCoord
	mov ecx, eax
	and ecx, 0FFFFh       ; ECX = X
	mov edx, eax
	shr edx, 16           ; EDX = Y

	sub ecx, 2            ; X - 2
	sub edx, 2            ; Y - 2

	shl edx, 16
	or ecx, edx           ; 將 Y<<16 | X 組合成 DWORD
	mov localCoord, ecx   ; 存入起始座標


	; ===================
	; 橫向輸出一列字元
	; ===================

	lea esi, szBrushBuffer
	mov ebx, 0

	mov ecx, 0  ; 為了記錄 cx 寬度邊界比較

.while ebx < 5 && ecx < WORKING_AREA_WIDTH
	mov al, byte ptr[szToDraw]
	mov byte ptr[esi], al
	inc ebx
	inc esi
	inc ecx
.endw

	mov byte ptr[esi], 0   ; null terminator

	; ====================
	; 垂直列印多行字元列
	; ====================

	mov ebx, 0
	mov eax, localCoord

.while ebx < 5
	invoke SetConsoleCursorPosition, hOut, eax
	invoke crt_printf, offset szBrushBuffer

	add eax, 65536    ; Y++
	inc ebx
.endw

	ret
DrawSquare endp



KeyController proc uses ebx ecx esi edi hIn: DWORD, hOut: DWORD

	movzx eax, word ptr[ConsoleRecord.EventType]
				
	.if eax == 0
		
		fn crt_puts, "error"
		
	.endif
	
	.if eax == KEY_EVENT
		
	.elseif eax == MOUSE_EVENT
	
		mov eax, ConsoleRecord.MouseEvent.dwMousePosition
		mov ebx, eax
		shr ebx, 16		; Y coord
		cwde			; X coord in ax
	
		.if ConsoleRecord.MouseEvent.dwButtonState == FROM_LEFT_1ST_BUTTON_PRESSED
			
			mov	byte ptr[clickDone], 1
			
			.if ax > 0 && ax <= WORKING_AREA_WIDTH && bx > 2 && bx <= WORKING_AREA_HEIGHT
				
				;invoke DrawCell, hOut, dword ptr[ConsoleRecord.MouseEvent.dwMousePosition]
				invoke DrawSquare, hOut, dword ptr[ConsoleRecord.MouseEvent.dwMousePosition]

			.endif
			
		.elseif	byte ptr[clickDone] == 1
			
			mov byte ptr[clickDone], 0
			
			; FIRST ROW OF BRUSHES
			.if ax >= WORKING_AREA_WIDTH+3 && ax <= WORKING_AREA_WIDTH+6 && bx >= 3 && bx < 6
			
				invoke PlaySoundOnClick, offset szPlayOnClick			
				mov byte ptr[szToDraw], exclBrush
				
			.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+11 && bx >= 3 && bx < 6
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], quoteBrush
				
			.elseif ax >= WORKING_AREA_WIDTH+13 && ax <= WORKING_AREA_WIDTH+16 && bx >= 3 && bx < 6
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], sharpBrush
				
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx >= 3 && bx < 6
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], dollarBrush
				
			.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx >= 3 && bx < 6
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], comAndBrush	
				
			.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx >= 3 && bx < 6
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], zeroQuoteBrush	
			
			; SECOND ROW OF BRUSHES
				
			.elseif ax >= WORKING_AREA_WIDTH+3 && ax <= WORKING_AREA_WIDTH+6 && bx >= 6 && bx < 9
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], parenthOBrush
				
			.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+11 && bx >= 6 && bx < 9
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], parenthCBrush
				
			.elseif ax >= WORKING_AREA_WIDTH+13 && ax <= WORKING_AREA_WIDTH+16 && bx >= 6 && bx < 9
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], multiplBrush
				
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx >= 6 && bx < 9
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], plusBrush
				
			.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx >= 6 && bx < 9
			
				mov byte ptr[szToDraw], commaBrush	
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx >= 6 && bx < 9
			
				mov byte ptr[szToDraw], minusBrush
				invoke PlaySoundOnClick, offset szPlayOnClick	
				
				
			; THIRD ROW OF BRUSHES
			
			.elseif ax >= WORKING_AREA_WIDTH+3 && ax <= WORKING_AREA_WIDTH+6 && bx >= 9 && bx < 12
			
				mov byte ptr[szToDraw], dotBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+11 && bx >= 9 && bx < 12
			
				mov byte ptr[szToDraw], slashBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+13 && ax <= WORKING_AREA_WIDTH+16 && bx >= 9 && bx < 12
			
				mov byte ptr[szToDraw], colonBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx >= 9 && bx < 12
			
				mov byte ptr[szToDraw], semicolonBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx >= 9 && bx < 12
			
				mov byte ptr[szToDraw], lessBrush
				invoke PlaySoundOnClick, offset szPlayOnClick	
				
			.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx >= 9 && bx < 12
			
				mov byte ptr[szToDraw], equalBrush	
				invoke PlaySoundOnClick, offset szPlayOnClick			
			
			
			; FOURTH ROW OF BRUSHES
		
			.elseif ax >= WORKING_AREA_WIDTH+3 && ax <= WORKING_AREA_WIDTH+6 && bx >= 12 && bx < 15
			
				mov byte ptr[szToDraw], moreBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+11 && bx >= 12 && bx < 15
			
				mov byte ptr[szToDraw], questionBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+13 && ax <= WORKING_AREA_WIDTH+16 && bx >= 12 && bx < 15
			
				mov byte ptr[szToDraw], atBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx >= 12 && bx < 15
			
				mov byte ptr[szToDraw], squareOBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx >= 12 && bx < 15
			
				mov byte ptr[szToDraw], backSlashBrush
				invoke PlaySoundOnClick, offset szPlayOnClick	
				
			.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx >= 12 && bx < 15
			
				mov byte ptr[szToDraw], squareCBrush
				invoke PlaySoundOnClick, offset szPlayOnClick	
		
			
			; FIFTH ROW OF BRUSHES
		
			.elseif ax >= WORKING_AREA_WIDTH+3 && ax <= WORKING_AREA_WIDTH+6 && bx >= 15 && bx < 18
			
				mov byte ptr[szToDraw], birdBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+11 && bx >= 15 && bx < 18
			
				mov byte ptr[szToDraw], traitBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+13 && ax <= WORKING_AREA_WIDTH+16 && bx >= 15 && bx < 18
			
				mov byte ptr[szToDraw], braceOBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx >= 15 && bx < 18
			
				mov byte ptr[szToDraw], directBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx >= 15 && bx < 18
			
				mov byte ptr[szToDraw], braceCBrush
				invoke PlaySoundOnClick, offset szPlayOnClick	
				
			.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx >= 15 && bx < 18
			
				mov byte ptr[szToDraw], tildaBrush
				invoke PlaySoundOnClick, offset szPlayOnClick	
			
			
			; SIZE BUTTONS CHECKS
			
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx > 20 && bx < 23
			
				mov byte ptr[drawSize], 1
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx > 20 && bx < 23
			
				mov byte ptr[drawSize], 2
				invoke PlaySoundOnClick, offset szPlayOnClick	
				
			.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx > 20 && bx < 23
			
				mov byte ptr[drawSize], 3
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx > 23 && bx < 26
			
				mov byte ptr[drawSize], 4
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx > 23 && bx < 26
			
				mov byte ptr[drawSize], 5
				invoke PlaySoundOnClick, offset szPlayOnClick	
				
			.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx > 23 && bx < 26
			
				mov byte ptr[drawSize], 6
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx > 26 && bx < 29
			
				mov byte ptr[drawSize], 7
				invoke PlaySoundOnClick, offset szPlayOnClick
								
			.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx > 26 && bx < 29
			
				mov byte ptr[drawSize], 8
				invoke PlaySoundOnClick, offset szPlayOnClick
								
			.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx > 26 && bx < 29
			
				mov byte ptr[drawSize], 9
				invoke PlaySoundOnClick, offset szPlayOnClick
				
			
			; <<< ---------   COLOR BUTTONS CHECK   ------------- >>>
			
			.elseif ax >= WORKING_AREA_WIDTH+2 && ax <= WORKING_AREA_WIDTH+4 && bx >= 21 && bx <= 22
			
				mov eax, cBlue
				mov dword ptr[drawColor], eax
				
			.elseif ax >= WORKING_AREA_WIDTH+5 && ax <= WORKING_AREA_WIDTH+7 && bx >= 21 && bx <= 22
			
				mov eax, cGreen
				mov dword ptr[drawColor], eax
							
			.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+10 && bx >= 21 && bx <= 22
			
				mov eax, cCyan
				mov dword ptr[drawColor], eax
				
			.elseif ax >= WORKING_AREA_WIDTH+11 && ax <= WORKING_AREA_WIDTH+13 && bx >= 21 && bx <= 22
			
				mov eax, cRed
				mov dword ptr[drawColor], eax
								
			.elseif ax >= WORKING_AREA_WIDTH+14 && ax <= WORKING_AREA_WIDTH+16 && bx >= 21 && bx <= 22
			
				mov eax, cMagenta
				mov dword ptr[drawColor], eax
			
			; SECOND ROW
			
			.elseif ax >= WORKING_AREA_WIDTH+2 && ax <= WORKING_AREA_WIDTH+4 && bx >= 23 && bx <= 24
			
				mov eax, cBrown
				mov dword ptr[drawColor], eax
				
			.elseif ax >= WORKING_AREA_WIDTH+5 && ax <= WORKING_AREA_WIDTH+7 && bx >= 23 && bx <= 24
			
				mov eax, LightGray
				mov dword ptr[drawColor], eax
							
			.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+10 && bx >= 23 && bx <= 24
			
				mov eax, DarkGray
				mov dword ptr[drawColor], eax
				
			.elseif ax >= WORKING_AREA_WIDTH+11 && ax <= WORKING_AREA_WIDTH+13 && bx >= 23 && bx <= 24
			
				mov eax, LightBlue
				mov dword ptr[drawColor], eax
								
			.elseif ax >= WORKING_AREA_WIDTH+14 && ax <= WORKING_AREA_WIDTH+16 && bx >= 23 && bx <= 24
			
				mov eax, LightGreen
				mov dword ptr[drawColor], eax
				
			; THIRD ROW
			
			.elseif ax >= WORKING_AREA_WIDTH+2 && ax <= WORKING_AREA_WIDTH+4 && bx >= 25 && bx <= 26
			
				mov eax, LightCyan
				mov dword ptr[drawColor], eax
				
			.elseif ax >= WORKING_AREA_WIDTH+5 && ax <= WORKING_AREA_WIDTH+7 && bx >= 25 && bx <= 26
			
				mov eax, LightRed
				mov dword ptr[drawColor], eax
							
			.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+10 && bx >= 25 && bx <= 26
			
				mov eax, LightMagenta
				mov dword ptr[drawColor], eax
				
			.elseif ax >= WORKING_AREA_WIDTH+11 && ax <= WORKING_AREA_WIDTH+13 && bx >= 25 && bx <= 26
			
				mov eax, cYellow
				mov dword ptr[drawColor], eax
								
			.elseif ax >= WORKING_AREA_WIDTH+14 && ax <= WORKING_AREA_WIDTH+16 && bx >= 25 && bx <= 26
			
				mov eax, cWhite
				mov dword ptr[drawColor], eax
				
												
			; SPECIAL BUTTONS CHECKS
			
			; CLEAR	
			
			.elseif ax >= WORKING_AREA_WIDTH+3 && ax <= WORKING_AREA_WIDTH+16 && bx > WORKING_AREA_HEIGHT-3 && bx < WORKING_AREA_HEIGHT+1
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				invoke ClearPaint
				
			; EXPORT
			
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+31 && bx > WORKING_AREA_HEIGHT-3 && bx < WORKING_AREA_HEIGHT+1
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				invoke ExportImageEvent
				
			; IMPORT	
			
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+31 && bx > WORKING_AREA_HEIGHT-6 && bx < WORKING_AREA_HEIGHT-3
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				invoke ImportImageEvent
				
				invoke ClearBuffer, offset szBuffer2, 256
				
			; ERASER	
			
			.elseif ax >= WORKING_AREA_WIDTH+3 && ax <= WORKING_AREA_WIDTH+9 && bx >= WORKING_AREA_HEIGHT-6 && bx < WORKING_AREA_HEIGHT-3
		
				mov eax, cBlack
				mov dword ptr[drawColor], eax
				invoke PlaySoundOnClick, offset szPlayOnClick
					
			.endif
			
			
			;		invoke Sleep, densityBrush  Idea for regulation of brushes' density
			
		.endif
		
	.endif

	Ret
KeyController endp

SetColor proc uses ebx esi edi color: DWORD

	invoke SetConsoleTextAttribute, rv(GetStdHandle, STD_OUTPUT_HANDLE), color

	Ret
SetColor endp

ExportImageEvent proc uses ebx esi edi

	LOCAL hFileExport: DWORD
	LOCAL nRead: DWORD
	LOCAL hOut: DWORD

	invoke ClearLogArea
	
	invoke SetColor, cWhite
	invoke PutCursorToPos, 1, 42
	
	invoke ClearBuffer, offset szBuffer2, 256
	invoke GetInput, offset szGetFileName, offset szBuffer2	
		
	invoke CreateFile, offset szBuffer2, GENERIC_WRITE, FILE_SHARE_WRITE, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
	mov hFileExport, eax
	
	mov ebx, 030001h
	
	
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOut, eax
	
	fn ReadConsoleOutputCharacter, hOut, offset szBuffer2, WORKING_AREA_WIDTH, ebx, addr nRead
	invoke lstrcat, offset szBuffer2, offset szNewLine
	invoke WriteFile, hFileExport, offset szBuffer2, WORKING_AREA_WIDTH+2, addr nRead, 0
	add ebx, 010000h
	
	.while (ebx < 0290001h)
		
		fn ReadConsoleOutputCharacter, hOut, offset szBuffer2, WORKING_AREA_WIDTH, ebx, addr nRead
		
		invoke WriteFile, hFileExport, offset szBuffer2, WORKING_AREA_WIDTH+2, addr nRead, 0
	
		add ebx, 010000h
	.endw
	
	invoke CloseHandle, hFileExport
	
	invoke PutCursorToPos, 1, WORKING_AREA_HEIGHT+3
	
	invoke SetColor, cGreen
	invoke crt_printf, offset szPictureExported
	
	invoke Sleep, 1000
	
	invoke PutCursorToPos, 1, WORKING_AREA_HEIGHT+3
	invoke SetColor, DarkGray
	invoke crt_printf, offset szPictureExported
	
	Ret
ExportImageEvent endp

GetInput proc uses ebx esi edi, lpOutputText: DWORD, lpInputText: DWORD
	
	invoke crt_printf, lpOutputText
	invoke crt_gets, lpInputText

	Ret
GetInput endp

ImportImageEvent proc uses ebx esi edi

	LOCAL hFileImport: DWORD
	LOCAL nRead: DWORD
	LOCAL hOut: DWORD
		
	invoke ClearLogArea
	
	invoke SetColor, cWhite
	invoke PutCursorToPos, 1, 42
	
	invoke ClearBuffer, offset szBuffer2, 256
	invoke GetInput, offset szGetFileName, offset szBuffer2	
	
	invoke CreateFile, offset szBuffer2, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
	mov hFileImport, eax
	
	.if eax == INVALID_HANDLE_VALUE
	
		invoke ClearLine, WORKING_AREA_HEIGHT+3
	
		invoke PutCursorToPos, 1, WORKING_AREA_HEIGHT+3
		invoke SetColor, cRed
		invoke crt_printf, offset szFileNotFound
		
		jmp @@Ret
	
	.endif
	
	
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOut, eax
	
	mov ebx, 3
	
	invoke SetColor, drawColor
	
@@OuterLoop:
	
		mov esi, offset szBuffer2
		
		invoke PutCursorToPos, 1, ebx
		
		mov edi, 0
		
	@@InnerLoop:

		cmp edi, 120
		jne @F
		
		mov byte ptr[esi], 0
		
		invoke crt_printf, offset szBuffer2
		
		mov esi, offset szBuffer2
		
		.while byte ptr[esi] != 13 && dword ptr[nRead] != 0
		
			invoke ReadFile, hFileImport, esi, 1, addr nRead, 0
		
		.endw
		
		invoke ReadFile, hFileImport, esi, 1, addr nRead, 0
		
		mov byte ptr[esi], 0
		
		inc ebx
		
		jmp @@OuterLoop
		
	@@:
		invoke ReadFile, hFileImport, esi, 1, addr nRead, 0
		
		cmp dword ptr[nRead], 0
		je @@ExitLoop
		
		cmp byte ptr[esi], 13
		je @F
		
		inc esi
		inc edi
		
		jmp @@InnerLoop
		
	@@:
	
		mov byte ptr[esi], 0
		
		invoke ReadFile, hFileImport, offset szBuffer1, 1, addr nRead, 0	
	
		invoke crt_printf, offset szBuffer2
		
		inc ebx
		
		cmp ebx, 41
		je @@ExitDrawProcess
		
		jmp @@OuterLoop
		
@@ExitLoop:
	
	invoke crt_printf, offset szBuffer2
	
@@ExitDrawProcess:

	invoke CloseHandle, hFileImport
	
	invoke PutCursorToPos, 1, WORKING_AREA_HEIGHT+3
	fn crt_printf, "                                                                                                            "
	
	invoke PutCursorToPos, 1, WORKING_AREA_HEIGHT+3
	
	invoke SetColor, cGreen
	invoke crt_printf, offset szPictureImported
	
	invoke Sleep, 1000
	invoke PutCursorToPos, 1, WORKING_AREA_HEIGHT+3
	
	invoke SetColor, DarkGray
	invoke crt_printf, offset szPictureImported
	
@@Ret:
	Ret
ImportImageEvent endp

end start