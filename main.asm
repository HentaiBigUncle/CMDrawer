include main.inc
include MainMenu.asm

.code
start:
	
	fn SetConsoleTitle, "CMDrawer v1.0.0"
	
	invoke Main
	
	invoke ExitProcess, 0
	fn crt_system, "pause"
	
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
	
	
	invoke MenuCreate
	
	invoke HideCursor
	invoke SetConsoleMode, hIn, ENABLE_MOUSE_INPUT or ENABLE_EXTENDED_FLAGS or ENABLE_LINE_INPUT or ENABLE_ECHO_INPUT or ENABLE_PROCESSED_INPUT
	
	_DOLOOP:
	
		invoke ReadConsoleInput, hIn, offset ConsoleRecord, 1, addr nRead
		movzx eax, word ptr[ConsoleRecord.EventType]
		
		.if eax == 0
			
			fn crt_puts, "error"
			
		.endif
		
		.if eax == KEY_EVENT
		
			.if ConsoleRecord.KeyEvent.bKeyDown
			
				mov byte ptr[szToDraw], '1'
				
			.endif
			
		.elseif eax == MOUSE_EVENT
		
			.if ConsoleRecord.MouseEvent.dwButtonState == FROM_LEFT_1ST_BUTTON_PRESSED
			
				mov eax, ConsoleRecord.MouseEvent.dwMousePosition
				mov ebx, eax
				shr ebx, 16		; Y coord
				cwde			; X coord in ax
				
				.if ax > 0 && ax < WORKING_AREA_WIDTH+1 && bx > 2 && bx < WORKING_AREA_HEIGHT+1
					
					invoke SetConsoleCursorPosition, hOut, dword ptr[ConsoleRecord.MouseEvent.dwMousePosition]
					fn crt_puts, offset szToDraw
					
				.endif
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

end start