include main.inc
include ownlib.inc
include ownlib.asm

.code
start:
	
	invoke Main
	
	invoke ExitProcess, 0
	fn crt_system, "pause"
	
Main proc	uses ebx ecx esi edi
	LOCAL hIn: DWORD
	LOCAL hOut: DWORD
	LOCAL nRead: DWORD
	LOCAL lpMode: DWORD
	
	mov byte ptr[szToDraw], 35
	fn crt_puts, "lmao test"
	
	invoke GetStdHandle, STD_INPUT_HANDLE
	mov hIn, eax
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOut, eax
	
	invoke SetConsoleMode, hIn, ENABLE_MOUSE_INPUT or ENABLE_EXTENDED_FLAGS or ENABLE_LINE_INPUT or ENABLE_ECHO_INPUT or ENABLE_PROCESSED_INPUT
	invoke GetConsoleMode, hOut, addr lpMode
	xor lpMode, 2
	invoke SetConsoleMode, hOut, lpMode
	invoke GetConsoleMode, hOut, addr lpMode
	
	invoke MenuCreate
	
	; CONSOLE_FULLSCREEN_MODE hOut
	
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
				invoke SetConsoleCursorPosition, hOut, dword ptr[ConsoleRecord.MouseEvent.dwMousePosition]
				fn crt_puts, offset szToDraw
			.endif
		.endif
		jmp _DOLOOP
	Ret
Main endp	

MenuCreate proc	uses ecx esi edi

	invoke crt_system, offset szClear
	invoke crt_puts, offset szHorizontalBorder
	
	;invoke cout, offset szVerticalBorder2
	;invoke cout, offset szVerticalBorder2
	
	invoke crt_puts, offset szHorizontalBorder
	
	invoke PutCursorToPos, 122, 1
	
	invoke cout, offset szVerticalBorder2
	invoke cout, offset szVerticalBorder2
	;fn crt_printf, offset szVerticalBorder2
	Ret
MenuCreate endp

PutCursorToPos proc uses ecx esi edi xCor: WORD, yCor: WORD	
	mov cx, yCor
	shl ecx, 16
	mov cx, xCor
	;-------------------------------
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	invoke SetConsoleCursorPosition, eax, ecx
	;------------------------------
	ret
PutCursorToPos endp

end start