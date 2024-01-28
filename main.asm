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
		movzx eax, word ptr[ConsoleRecord.EventType]
		
		.if eax == 0
			
			fn crt_puts, "error"
			
		.endif
		
		.if eax == KEY_EVENT
			
		.elseif eax == MOUSE_EVENT
		
			.if ConsoleRecord.MouseEvent.dwButtonState == FROM_LEFT_1ST_BUTTON_PRESSED
			
				mov eax, ConsoleRecord.MouseEvent.dwMousePosition
				mov ebx, eax
				shr ebx, 16		; Y coord
				cwde			; X coord in ax
				
				.if ax > 0 && ax < WORKING_AREA_WIDTH+1 && bx > 2 && bx < WORKING_AREA_HEIGHT+1
					
					invoke SetConsoleCursorPosition, hOut, dword ptr[ConsoleRecord.MouseEvent.dwMousePosition]
					fn crt_puts, offset szToDraw
					;invoke DrawCell, hOut, dword ptr[ConsoleRecord.MouseEvent.dwMousePosition]
					
				.elseif ax >= WORKING_AREA_WIDTH+3 && ax <= WORKING_AREA_WIDTH+6 && bx > 3 && bx < 6
				
					mov byte ptr[szToDraw], exclBrush
					invoke PlaySoundOnClick, offset szPlayOnClick
					
				.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+11 && bx > 3 && bx < 6
				
					mov byte ptr[szToDraw], quoteBrush
					invoke PlaySoundOnClick, offset szPlayOnClick
					
				.elseif ax >= WORKING_AREA_WIDTH+13 && ax <= WORKING_AREA_WIDTH+16 && bx > 3 && bx < 6
				
					mov byte ptr[szToDraw], sharpBrush
					invoke PlaySoundOnClick, offset szPlayOnClick
					
				.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx > 3 && bx < 6
				
					invoke PlaySoundOnClick, offset szPlayOnClick
					mov byte ptr[szToDraw], dollarBrush
					
				.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx > 3 && bx < 6
				
					invoke PlaySoundOnClick, offset szPlayOnClick
					mov byte ptr[szToDraw], comAndBrush	
					
				.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx > 3 && bx < 6
				
					invoke PlaySoundOnClick, offset szPlayOnClick
					mov byte ptr[szToDraw], zeroQuoteBrush	
									
					
				; SPECIAL BUTTONS CHECKS
				
				; CLEAR	
				.elseif ax >= WORKING_AREA_WIDTH+3 && ax <= WORKING_AREA_WIDTH+16 && bx > WORKING_AREA_HEIGHT-3 && bx < WORKING_AREA_HEIGHT+1
				
					invoke PlaySoundOnClick, offset szPlayOnClick
					invoke MenuCreate
					invoke SetConsoleMode, hIn, ENABLE_MOUSE_INPUT or ENABLE_EXTENDED_FLAGS or ENABLE_LINE_INPUT or ENABLE_ECHO_INPUT or ENABLE_PROCESSED_INPUT
					
				; EXPORT
				.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+31 && bx > WORKING_AREA_HEIGHT-3 && bx < WORKING_AREA_HEIGHT+1
				
					invoke PlaySoundOnClick, offset szPlayOnClick
				
				; IMPORT	
				.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+31 && bx > WORKING_AREA_HEIGHT-6 && bx < WORKING_AREA_HEIGHT-3
				
					invoke PlaySoundOnClick, offset szPlayOnClick
				
				; ERASER	
				.elseif ax >= WORKING_AREA_WIDTH+3 && ax <= WORKING_AREA_WIDTH+9 && bx >= WORKING_AREA_HEIGHT-6 && bx < WORKING_AREA_HEIGHT-3
					
					mov byte ptr[szToDraw], eraseBrush
					invoke PlaySoundOnClick, offset szPlayOnClick
						
				.endif
				
				;		invoke Sleep, densityBrush  Idea for regulation of brushes' density
				
			.endif
			
		.endif
		jmp _DOLOOP
	Ret
Main endp

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


ImportActionProc proc uses ecx esi edi



	Ret
ImportActionProc endp

ExportActionProc proc uses ecx esi edi



	Ret
ExportActionProc endp

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
	
	LOCAL xCor: DWORD
	LOCAL yCor: DWORD
	
	mov eax, dwCoord
	mov ecx, dwCoord
	shl eax, 16
	shr eax, 16
	shr ecx, 16
	
	mov xCor, eax
	mov yCor, ecx
	
	lea esi, szBrushBuffer
	mov ebx, 0
	
	.while ebx < drawSize
	
		invoke lstrcat, offset szBrushBuffer, offset szToDraw
		inc ebx
		
	.endw
	
	mov ebx, 0
	.while ebx < drawSize
	
		invoke crt_puts, offset szBrushBuffer
		inc ebx
	
	.endw

	Ret
DrawCell endp

end start