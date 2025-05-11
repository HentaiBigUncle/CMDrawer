include main.inc
include MainMenu.asm	


.code
start:
	
	invoke SetConsoleTitle, offset szProgramVersion
	
	invoke SetWindowSize, MAX_WIDTH, MAX_HEIGHT
	
	invoke Main
	
	invoke ExitProcess, 0
	
Main proc  uses ebx ecx esi edi
	
	LOCAL hIn: DWORD
	LOCAL hOut: DWORD
	LOCAL nRead: DWORD
	LOCAL lpMode: DWORD
	
	mov byte ptr[szToDraw], 35
	
	invoke GetStdHandle, STD_INPUT_HANDLE
	mov hIn, eax
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOut, eax
	invoke InitConsoleHandle
	invoke GetConsoleWindow
	invoke ShowScrollBar, eax, SB_BOTH, FALSE
	invoke HideCursor
	
	invoke MenuCreate
	
	invoke SetConsoleMode, hIn, ENABLE_MOUSE_INPUT or ENABLE_EXTENDED_FLAGS or ENABLE_LINE_INPUT or ENABLE_ECHO_INPUT or ENABLE_PROCESSED_INPUT
	invoke ShowBrushStatus
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

; 初始化 console handle
InitConsoleHandle PROC
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov hConsoleOutput, eax
    ret
InitConsoleHandle ENDP

; 儲存畫面區塊到 CanvasHistory[HistoryCount]
SaveToHistory PROC
    LOCAL bufferSize: COORD
    LOCAL bufferCoord: COORD
    LOCAL readRegion: SMALL_RECT
    LOCAL offsetDest: DWORD

    cmp HistoryCount, MAX_HISTORY_COUNT
    jge ExitSave

    ; 設定讀取區塊大小與位置
    mov bufferSize.x, HISTORY_WIDTH + 1
    mov bufferSize.y, HISTORY_HEIGHT + 1
    mov bufferCoord.x, 1
    mov bufferCoord.y, 3

    ; 設定從 Console 左上角區塊 (0,0)-(9,4)
    mov readRegion.Left, 1
    mov readRegion.Top, 3
    mov readRegion.Right, HISTORY_WIDTH + 2
    mov readRegion.Bottom, HISTORY_HEIGHT + 4

    ; 讀取目前畫面
	
    invoke ReadConsoleOutput, hConsoleOutput, addr tempBuffer, DWORD PTR bufferSize, DWORD PTR bufferCoord, addr readRegion

    ; 複製到 CanvasHistory[HistoryCount]
    mov eax, HistoryCount
    imul eax, HISTORY_SIZE
    imul eax, SIZEOF CHAR_INFO
    mov offsetDest, eax
    lea edi, CanvasHistory
    add edi, offsetDest
    lea esi, tempBuffer
    mov ecx, HISTORY_SIZE
copyloop:
    mov eax, [esi]
    mov [edi], eax
    add esi, SIZEOF CHAR_INFO
    add edi, SIZEOF CHAR_INFO
    loop copyloop

    ; 更新紀錄
    inc HistoryCount
    mov eax, HistoryCount
    mov CurrentIndex, eax

ExitSave:
    ret
SaveToHistory ENDP

; 從 CanvasHistory 還原畫面
UndoCanvas PROC
    LOCAL bufferSize: COORD
    LOCAL bufferCoord: COORD
    LOCAL writeRegion: SMALL_RECT
    LOCAL offsetSrc: DWORD

    cmp HistoryCount, 0
    jle ExitUndo

    dec CurrentIndex
    dec HistoryCount

    ; 從 CanvasHistory[CurrentIndex] 複製到 tempBuffer
    mov eax, CurrentIndex
    imul eax, HISTORY_SIZE
    imul eax, SIZEOF CHAR_INFO
    mov offsetSrc, eax
    lea esi, CanvasHistory
    add esi, offsetSrc
    lea edi, tempBuffer
    mov ecx, HISTORY_SIZE
copyback:
    mov eax, [esi]
    mov [edi], eax
    add esi, SIZEOF CHAR_INFO
    add edi, SIZEOF CHAR_INFO
    loop copyback

    ; 設定寫入區塊大小與位置
    mov bufferSize.x, HISTORY_WIDTH +1
    mov bufferSize.y, HISTORY_HEIGHT + 1
    mov bufferCoord.x, 1
    mov bufferCoord.y, 3

    mov writeRegion.Left, 1
    mov writeRegion.Top, 3
    mov writeRegion.Right, HISTORY_WIDTH + 2
    mov writeRegion.Bottom, HISTORY_HEIGHT + 4

    ; 寫入畫面
    invoke WriteConsoleOutput, hConsoleOutput, addr tempBuffer, DWORD PTR bufferSize, DWORD PTR bufferCoord, addr writeRegion

ExitUndo:
    ret
UndoCanvas ENDP


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


DrawSquare proc uses ebx ecx edx esi edi,
    hOut: DWORD, dwCoord: DWORD

    LOCAL startX: WORD
    LOCAL startY: WORD
    LOCAL squareWidth: DWORD
    LOCAL squareHeight: DWORD
    LOCAL curCoord: DWORD

    ;=======================
    ; 計算方形寬高
    ;=======================
    movzx eax, byte ptr [drawSize]
    mov ecx, eax
    shl eax, 1                 ; 寬 = drawSize * 2
    mov squareWidth, eax
    mov squareHeight, ecx     ; 高 = drawSize

    ;=======================
    ; 拆解 dwCoord（左上角）
    ;=======================
    mov eax, dwCoord
    mov ecx, eax
    and ecx, 0FFFFh            ; ECX = X
    mov edx, eax
    shr edx, 16                ; EDX = Y

    mov word ptr [startX], cx
    mov word ptr [startY], dx

    ;=======================
    ; 設定顏色
    ;=======================
    invoke SetColor, dword ptr [drawColor]

    ;=======================
    ; 畫 上邊 & 下邊
    ;=======================
    mov ebx, 0
draw_horizontal:
    ; 上邊
    movzx eax, word ptr [startY]
    shl eax, 16
    movzx ecx, word ptr [startX]
    add ecx, ebx
    or eax, ecx
    invoke SetConsoleCursorPosition, hOut, eax
    invoke crt_printf, offset szToDraw

    ; 下邊
    movzx eax, word ptr [startY]
    add eax, squareHeight
    dec eax                  ; Y + height - 1
    shl eax, 16
    movzx ecx, word ptr [startX]
    add ecx, ebx
    or eax, ecx
    invoke SetConsoleCursorPosition, hOut, eax
    invoke crt_printf, offset szToDraw

    inc ebx
    cmp ebx, squareWidth
    jl draw_horizontal

    ;=======================
    ; 畫 左邊 & 右邊
    ;=======================
    mov ebx, 1                         ; 不重畫上下邊
draw_vertical:
    ; 左邊
    movzx eax, word ptr [startY]
    add eax, ebx
    shl eax, 16
    movzx ecx, word ptr [startX]
    or eax, ecx
    invoke SetConsoleCursorPosition, hOut, eax
    invoke crt_printf, offset szToDraw

    ; 右邊
    movzx eax, word ptr [startY]
    add eax, ebx
    shl eax, 16
    movzx ecx, word ptr [startX]
    add ecx, squareWidth
    dec ecx                          ; width - 1
    or eax, ecx
    invoke SetConsoleCursorPosition, hOut, eax
    invoke crt_printf, offset szToDraw

    inc ebx
    cmp ebx, squareHeight
    jl draw_vertical

    ret
DrawSquare endp

DrawCircle proc uses ebx ecx edx esi edi,

DrawCircle endp



ShowBrushStatus proc uses eax ebx ecx edx

    LOCAL coord: COORD
    LOCAL written: DWORD
    LOCAL buffer[64]: BYTE
	LOCAL hOut: DWORD

	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOut, eax

    ; 設定游標到 (1,1)
    mov coord.x, 1
    mov coord.y, 1
    invoke SetConsoleCursorPosition, hOut, DWORD PTR coord
    ; 顯示根據狀態
    .if isEraser == 1
        ; 用白色顯示 Eraser
        invoke SetColor, LightGray
        invoke crt_sprintf, addr buffer, offset strEraser, drawSize
		invoke WriteConsoleA, hOut, addr buffer, 18, addr written, 0
	
	.elseif isPicker == 1
        invoke SetColor, LightGray
        invoke crt_printf, offset szPickerButtonText

	.elseif isSquare == 1
        invoke SetColor, LightGray
        invoke crt_printf, offset szSquareButtonText
		invoke crt_printf, offset szDClearLine
	.elseif isCircle == 1
		invoke SetColor, LightGray
		invoke crt_printf, offset szCircleButtonText
		invoke crt_printf, offset szDClearLine
	.elseif isReturn == 1
		invoke SetColor, LightGray
        invoke crt_printf, offset strReturn
    .else
        ; 顏色的brush
		invoke SetColor, dword ptr[drawColor]
		invoke WriteConsole, hOut, addr szToDraw , 1, addr written, 0

        ; 顯示 Size 字樣
        invoke SetColor, LightGray ; 還原白色
        invoke crt_sprintf, addr buffer, offset fmtBrushStatus, drawSize
		invoke WriteConsoleA, hOut, addr buffer, 17, addr written, 0
    .endif

	invoke SetColor, dword ptr[drawColor]  ; 把顏色變回原來畫畫的顏色
    ret
ShowBrushStatus endp




KeyController proc uses ebx ecx esi edi hIn: DWORD, hOut: DWORD
	;picker用; === 取得指定位置的背景顏色 ===
	LOCAL coord: COORD
	LOCAL attr: WORD
	LOCAL readed: DWORD
	LOCAL chi: CHAR_INFO
	LOCAL bufferSize: COORD
	LOCAL bufferCoord: COORD
	LOCAL readRegion: SMALL_RECT
	;picker用
	movzx eax, word ptr[ConsoleRecord.EventType]
	.if eax == 0
		
		fn crt_puts, "error"
		
	.endif
	
	.if eax == KEY_EVENT
		movzx eax, byte ptr ConsoleRecord.KeyEvent + 0Ah ; Get the ASCII character from KeyEvent.uChar.AsciiChar
		; 迴車鍵
		.if ConsoleRecord.KeyEvent.bKeyDown && ConsoleRecord.KeyEvent.wRepeatCount == 1
		.if al == 'z'
			invoke UndoCanvas
			mov isReturn, 1
			mov isEraser, 0
			mov isPicker, 0
		; FIRST ROW OF BRUSHES
		.elseif al == '!'
			invoke PlaySoundOnClick, offset szPlayOnClick			
				mov byte ptr[szToDraw], exclBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
		mov isEraser, 0
		mov isPicker, 0
		.elseif al == '"'
			invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], quoteBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
		mov isEraser, 0
		mov isPicker, 0
		.elseif al == '#'
			invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], sharpBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
		mov isEraser, 0
		mov isPicker, 0
		.elseif al == '$'
			invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], dollarBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
		mov isEraser, 0
		mov isPicker, 0
		.elseif al == '&'
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], comAndBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
		mov isEraser, 0
		mov isPicker, 0
		.elseif al == zeroQuoteBrush
			invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], zeroQuoteBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
		mov isEraser, 0
		mov isPicker, 0
		; SECOND ROW OF BRUSHES
			.elseif al == '('
					mov isEraser, 0
					mov isPicker, 0
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], parenthOBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
				
			.elseif  al == ')'
					mov isEraser, 0
					mov isPicker, 0
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], parenthCBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
				
			.elseif  al == '*'
					mov isEraser, 0
					mov isPicker, 0
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], multiplBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
				
			.elseif  al == '+'
					mov isEraser, 0
					mov isPicker, 0
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], plusBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
				
			.elseif  al == ','
					mov isEraser, 0
					mov isPicker, 0
				mov byte ptr[szToDraw], commaBrush	
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
				
			.elseif  al == '-'
					mov isEraser, 0
					mov isPicker, 0
				mov byte ptr[szToDraw], minusBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax	
		; THIRD ROW OF BRUSHES
		.elseif al == 'M'
			
				mov byte ptr[szToDraw], MBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif  al == '/'
			
				mov byte ptr[szToDraw], slashBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif  al == ':'
			
				mov byte ptr[szToDraw], colonBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif  al == ';'
			
				mov byte ptr[szToDraw], semicolonBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif  al == '<'
			
				mov byte ptr[szToDraw], lessBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax	
						mov isEraser, 0
						mov isPicker, 0
			.elseif  al == '='
					mov isEraser, 0
					mov isPicker, 0
				mov byte ptr[szToDraw], equalBrush	
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax	
		; FORTH ROW OF BRUSHES
		.elseif  al == '>'
			
				mov byte ptr[szToDraw], moreBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif  al == '?'
			
				mov byte ptr[szToDraw], questionBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif  al == '@'
			
				mov byte ptr[szToDraw], atBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif  al == '['
			
				mov byte ptr[szToDraw], squareOBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif  al == '\'
			
				mov byte ptr[szToDraw], backSlashBrush
				invoke PlaySoundOnClick, offset szPlayOnClick	
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif  al == ']'
					mov isEraser, 0
					mov isPicker, 0
				mov byte ptr[szToDraw], squareCBrush
				invoke PlaySoundOnClick, offset szPlayOnClick	
				mov eax, cWhite
				mov dword ptr[drawColor], eax
		; FIFTH ROW OF BRUSHES
		.elseif  al == '^'
			
				mov byte ptr[szToDraw], birdBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif  al == '_'
			
				mov byte ptr[szToDraw], traitBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif  al == '{'
			
				mov byte ptr[szToDraw], braceOBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif  al == '|'
			
				mov byte ptr[szToDraw], directBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif  al == '}'
			
				mov byte ptr[szToDraw], braceCBrush
				invoke PlaySoundOnClick, offset szPlayOnClick	
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif  al == '~'
			
				mov byte ptr[szToDraw], tildaBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax	
						mov isEraser, 0
						mov isPicker, 0
		; SIZE BUTTONS CHECKS
			
			.elseif al == '1'
			
				mov byte ptr[drawSize], 1
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov isPicker, 0
			.elseif al == '2'
			
				mov byte ptr[drawSize], 2
				invoke PlaySoundOnClick, offset szPlayOnClick	
				mov isPicker, 0
			.elseif al == '3'
			
				mov byte ptr[drawSize], 3
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov isPicker, 0
			.elseif al == '4'
			
				mov byte ptr[drawSize], 4
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov isPicker, 0
			.elseif al == '5'
			
				mov byte ptr[drawSize], 5
				invoke PlaySoundOnClick, offset szPlayOnClick	
				mov isPicker, 0
			.elseif al == '6'
			
				mov byte ptr[drawSize], 6
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov isPicker, 0
			.elseif al == '7'
			
				mov byte ptr[drawSize], 7
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov isPicker, 0				
			.elseif al == '8'
			
				mov byte ptr[drawSize], 8
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov isPicker, 0				
			.elseif al == '9'
				mov isPicker, 0
				mov byte ptr[drawSize], 9
				invoke PlaySoundOnClick, offset szPlayOnClick
			; SPECIAL BUTTONS CHECKS
			
			; CLEAR	
			
			.elseif al == 'c'

				invoke PlaySoundOnClick, offset szPlayOnClick
				invoke ClearPaint
			; EXPORT
			
			.elseif al == 'x'
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				invoke ExportImageEvent
			; IMPORT	
			
			.elseif al == 'i'
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				invoke ImportImageEvent
				
				invoke ClearBuffer, offset szBuffer2, 256
			; ERASER	
			.elseif al == 'E' || al == 'e'
				mov isEraser, 1
				mov isPicker, 0
				mov byte ptr[szToDraw], ' '         ; 設定要畫的字為空白
				mov eax, interfaceBorderColor       ; 回復成預設邊框色

				mov dword ptr[drawColor], eax
				invoke PlaySoundOnClick, offset szPlayOnClick
			
				invoke ShowBrushStatus
			.elseif al == 'P' || al == 'p'
				mov isPicker, 1
				mov isEraser, 0
				invoke PlaySoundOnClick, offset szPlayOnClick
			.elseif al == 'Q' || al == 'q'
				invoke ExitProcess, 0

		.endif
				invoke ShowBrushStatus
				mov isReturn, 0
		.endif
		.elseif eax == MOUSE_EVENT
		mov eax, ConsoleRecord.MouseEvent.dwMousePosition ; 讀取滑鼠的位置到eax
		mov ebx, eax
		shr ebx, 16		; Y coord 把eax的最高四個位元移到ebx的bx
		cwde			; X coord in ax
		.if ConsoleRecord.MouseEvent.dwButtonState == FROM_LEFT_1ST_BUTTON_PRESSED
			
			mov	byte ptr[clickDone], 1
			.if ax > 0 && ax <= WORKING_AREA_WIDTH && bx > 2 && bx <= WORKING_AREA_HEIGHT
				.if	isPicker == 1	
					mov isEraser, 0				
					mov word ptr[coord], ax       ; coord.X
					mov word ptr[coord+2], bx 
					mov bufferSize.x, 1
					mov bufferSize.y, 1
					mov bufferCoord.x, 0
					mov bufferCoord.y, 0

					mov readRegion.Left, ax
					mov readRegion.Top, bx
					mov readRegion.Right, ax
					mov readRegion.Bottom, bx
					invoke ReadConsoleOutput, hOut, addr chi, DWORD PTR bufferSize, DWORD PTR bufferCoord, addr readRegion
					movzx eax, chi.Attributes
					and eax, 0Fh
					mov dword ptr[drawColor], eax
					mov isPicker, 0
					
					invoke ShowBrushStatus
				.else	
					.if prevButtonState == 0
						mov prevButtonState, 1
						invoke SaveToHistory
					.endif
				.if isSquare == 1
					invoke DrawSquare, hOut, dword ptr[ConsoleRecord.MouseEvent.dwMousePosition]
					mov isSquare, 0
				.elseif isCircle == 1
					invoke DrawCircle, hOut, dword ptr[ConsoleRecord.MouseEvent.dwMousePosition]
					mov isCircle, 0
				.else
					invoke DrawCell, hOut, dword ptr[ConsoleRecord.MouseEvent.dwMousePosition]
				.endif
				.endif
			.endif
		
		.elseif	byte ptr[clickDone] == 1
			
			mov byte ptr[clickDone], 0
			
			; FIRST ROW OF BRUSHES
			.if ax >= WORKING_AREA_WIDTH+3 && ax <= WORKING_AREA_WIDTH+6 && bx >= 3 && bx < 6
			
				invoke PlaySoundOnClick, offset szPlayOnClick			
				mov byte ptr[szToDraw], exclBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+11 && bx >= 3 && bx < 6
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], quoteBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+13 && ax <= WORKING_AREA_WIDTH+16 && bx >= 3 && bx < 6
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], sharpBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx >= 3 && bx < 6
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], dollarBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx >= 3 && bx < 6
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], comAndBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx >= 3 && bx < 6
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], zeroQuoteBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
					mov isEraser, 0
					mov isPicker, 0
			; SECOND ROW OF BRUSHES
				
			.elseif ax >= WORKING_AREA_WIDTH+3 && ax <= WORKING_AREA_WIDTH+6 && bx >= 6 && bx < 9
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], parenthOBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+11 && bx >= 6 && bx < 9
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], parenthCBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+13 && ax <= WORKING_AREA_WIDTH+16 && bx >= 6 && bx < 9
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], multiplBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx >= 6 && bx < 9
			
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov byte ptr[szToDraw], plusBrush
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx >= 6 && bx < 9
			
				mov byte ptr[szToDraw], commaBrush	
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx >= 6 && bx < 9
			
				mov byte ptr[szToDraw], minusBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax	
						mov isEraser, 0
						mov isPicker, 0
			; THIRD ROW OF BRUSHES
			
			.elseif ax >= WORKING_AREA_WIDTH+3 && ax <= WORKING_AREA_WIDTH+6 && bx >= 9 && bx < 12
			
				mov byte ptr[szToDraw], MBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+11 && bx >= 9 && bx < 12
			
				mov byte ptr[szToDraw], slashBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+13 && ax <= WORKING_AREA_WIDTH+16 && bx >= 9 && bx < 12
			
				mov byte ptr[szToDraw], colonBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx >= 9 && bx < 12
			
				mov byte ptr[szToDraw], semicolonBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx >= 9 && bx < 12
			
				mov byte ptr[szToDraw], lessBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax	
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx >= 9 && bx < 12
			
				mov byte ptr[szToDraw], equalBrush	
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax			
					mov isEraser, 0
					mov isPicker, 0
			; FOURTH ROW OF BRUSHES
		
			.elseif ax >= WORKING_AREA_WIDTH+3 && ax <= WORKING_AREA_WIDTH+6 && bx >= 12 && bx < 15
			
				mov byte ptr[szToDraw], moreBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+11 && bx >= 12 && bx < 15
			
				mov byte ptr[szToDraw], questionBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+13 && ax <= WORKING_AREA_WIDTH+16 && bx >= 12 && bx < 15
			
				mov byte ptr[szToDraw], atBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx >= 12 && bx < 15
			
				mov byte ptr[szToDraw], squareOBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx >= 12 && bx < 15
			
				mov byte ptr[szToDraw], backSlashBrush
				invoke PlaySoundOnClick, offset szPlayOnClick	
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx >= 12 && bx < 15
			
				mov byte ptr[szToDraw], squareCBrush
				invoke PlaySoundOnClick, offset szPlayOnClick	
				mov eax, cWhite
				mov dword ptr[drawColor], eax
				mov isEraser, 0
				mov isPicker, 0
			
			; FIFTH ROW OF BRUSHES
		
			.elseif ax >= WORKING_AREA_WIDTH+3 && ax <= WORKING_AREA_WIDTH+6 && bx >= 15 && bx < 18
			
				mov byte ptr[szToDraw], birdBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+11 && bx >= 15 && bx < 18
			
				mov byte ptr[szToDraw], traitBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+13 && ax <= WORKING_AREA_WIDTH+16 && bx >= 15 && bx < 18
			
				mov byte ptr[szToDraw], braceOBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx >= 15 && bx < 18
			
				mov byte ptr[szToDraw], directBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx >= 15 && bx < 18
			
				mov byte ptr[szToDraw], braceCBrush
				invoke PlaySoundOnClick, offset szPlayOnClick	
				mov eax, cWhite
				mov dword ptr[drawColor], eax
						mov isEraser, 0
						mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx >= 15 && bx < 18
			
				mov byte ptr[szToDraw], tildaBrush
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax	
					mov isEraser, 0
					mov isPicker, 0
			; SIZE BUTTONS CHECKS
			
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx > 20 && bx < 23
			
				mov byte ptr[drawSize], 1
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx > 20 && bx < 23
			
				mov byte ptr[drawSize], 2
				invoke PlaySoundOnClick, offset szPlayOnClick	
				mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx > 20 && bx < 23
			
				mov byte ptr[drawSize], 3
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx > 23 && bx < 26
			
				mov byte ptr[drawSize], 4
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx > 23 && bx < 26
			
				mov byte ptr[drawSize], 5
				invoke PlaySoundOnClick, offset szPlayOnClick	
				mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx > 23 && bx < 26
			
				mov byte ptr[drawSize], 6
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+18 && ax <= WORKING_AREA_WIDTH+21 && bx > 26 && bx < 29
			
				mov byte ptr[drawSize], 7
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov isPicker, 0				
			.elseif ax >= WORKING_AREA_WIDTH+23 && ax <= WORKING_AREA_WIDTH+26 && bx > 26 && bx < 29
			
				mov byte ptr[drawSize], 8
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov isPicker, 0				
			.elseif ax >= WORKING_AREA_WIDTH+28 && ax <= WORKING_AREA_WIDTH+31 && bx > 26 && bx < 29
			
				mov byte ptr[drawSize], 9
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov isPicker, 0
			
			; <<< ---------   COLOR BUTTONS CHECK   ------------- >>>
			; bx = height
			.elseif ax >= WORKING_AREA_WIDTH+2 && ax <= WORKING_AREA_WIDTH+4 && bx >= 21 && bx <= 22

				invoke PlaySoundOnClick, offset szPlayOnClick	
				mov eax, cBlue
				mov dword ptr[drawColor], eax
				mov isEraser, 0
				mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+5 && ax <= WORKING_AREA_WIDTH+7 && bx >= 21 && bx <= 22
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cGreen
				mov dword ptr[drawColor], eax
							mov isEraser, 0
							mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+10 && bx >= 21 && bx <= 22
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cCyan
				mov dword ptr[drawColor], eax
				mov isEraser, 0
				mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+11 && ax <= WORKING_AREA_WIDTH+13 && bx >= 21 && bx <= 22
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cRed
				mov dword ptr[drawColor], eax
							mov isEraser, 0	
							mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+14 && ax <= WORKING_AREA_WIDTH+16 && bx >= 21 && bx <= 22
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cMagenta
				mov dword ptr[drawColor], eax
			mov isEraser, 0
			mov isPicker, 0
			; SECOND ROW
			
			.elseif ax >= WORKING_AREA_WIDTH+2 && ax <= WORKING_AREA_WIDTH+4 && bx >= 23 && bx <= 24
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cBrown
				mov dword ptr[drawColor], eax
				mov isEraser, 0
				mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+5 && ax <= WORKING_AREA_WIDTH+7 && bx >= 23 && bx <= 24
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, LightGray
				mov dword ptr[drawColor], eax
							mov isEraser, 0
							mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+10 && bx >= 23 && bx <= 24
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, DarkGray
				mov dword ptr[drawColor], eax
				mov isEraser, 0
				mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+11 && ax <= WORKING_AREA_WIDTH+13 && bx >= 23 && bx <= 24
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, LightBlue
				mov dword ptr[drawColor], eax
								mov isEraser, 0
								mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+14 && ax <= WORKING_AREA_WIDTH+16 && bx >= 23 && bx <= 24
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, LightGreen
				mov dword ptr[drawColor], eax
				mov isEraser, 0
				mov isPicker, 0
			; THIRD ROW
			
			.elseif ax >= WORKING_AREA_WIDTH+2 && ax <= WORKING_AREA_WIDTH+4 && bx >= 25 && bx <= 26
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, LightCyan
				mov dword ptr[drawColor], eax
				mov isEraser, 0
				mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+5 && ax <= WORKING_AREA_WIDTH+7 && bx >= 25 && bx <= 26
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, LightRed
				mov dword ptr[drawColor], eax
							mov isEraser, 0
							mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+8 && ax <= WORKING_AREA_WIDTH+10 && bx >= 25 && bx <= 26
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, LightMagenta
				mov dword ptr[drawColor], eax
				mov isEraser, 0
				mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+11 && ax <= WORKING_AREA_WIDTH+13 && bx >= 25 && bx <= 26
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cYellow
				mov dword ptr[drawColor], eax
								mov isEraser, 0
								mov isPicker, 0
			.elseif ax >= WORKING_AREA_WIDTH+14 && ax <= WORKING_AREA_WIDTH+16 && bx >= 25 && bx <= 26
				invoke PlaySoundOnClick, offset szPlayOnClick
				mov eax, cWhite
				mov dword ptr[drawColor], eax
				mov isEraser, 0
				mov isPicker, 0								
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
		  	  mov isEraser, 1
				mov isPicker, 0
				mov byte ptr[szToDraw], ' '
				mov eax, interfaceBorderColor
				mov dword ptr[drawColor], eax
				invoke PlaySoundOnClick, offset szPlayOnClick
			; Picker

			.elseif ax >= WORKING_AREA_WIDTH+11 && ax <= WORKING_AREA_WIDTH+17 && bx >= WORKING_AREA_HEIGHT-6 && bx < WORKING_AREA_HEIGHT-3
				mov isPicker, 1
				mov isEraser, 0

				invoke PlaySoundOnClick, offset szPlayOnClick
			; SQUARE

			.elseif ax >= 2 && ax <= 8 && bx >= WORKING_AREA_HEIGHT+8 && bx < WORKING_AREA_HEIGHT+11
				.if isEraser == 1
				mov byte ptr[szToDraw], MBrush
				.endif
				mov isSquare, 1
				mov isEraser, 0
				mov isPicker, 0
				invoke PlaySoundOnClick, offset szPlayOnClick

			; CIRCLE

			.elseif ax >= 10 && ax <= 16 && bx >= WORKING_AREA_HEIGHT+8 && bx < WORKING_AREA_HEIGHT+11
				.if isEraser == 1
				mov byte ptr[szToDraw], MBrush
				.endif
				mov isCircle, 1
				mov isEraser, 0
				mov isPicker, 0
				invoke PlaySoundOnClick, offset szPlayOnClick
			.endif
				 ; 儲存本次狀態供下次比對
    			mov prevButtonState, 0
				mov isReturn, 0
				invoke ShowBrushStatus
				
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