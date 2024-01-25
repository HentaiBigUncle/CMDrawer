include main.inc


.code
start:
	
	mov byte ptr[szToDraw], 31
	fn crt_puts, "lmao test"

	
	invoke GetStdHandle, STD_INPUT_HANDLE
	mov hIn, eax
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOut, eax
	invoke SetConsoleMode, hIn, ENABLE_MOUSE_INPUT or ENABLE_EXTENDED_FLAGS
	_DOLOOP:
		invoke ReadConsoleInput, hIn, offset ConsoleRecord, 1, offset nRead
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
		
	invoke ExitProcess, 0
	fn crt_system, "pause"
	
PutCursorToPos proc uses ecx esi edi xCor: WORD, yCor: WORD	
	mov cx, yCor
	shl ecx, 16
	mov cx, xCor
	;-------------------------------
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	invoke SetConsoleCursorPosition, eax, ecx
	;------------------------------
	ret 8
PutCursorToPos endp
end start