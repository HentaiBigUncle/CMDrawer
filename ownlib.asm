

cout				proto	:DWORD
lens				proto	:DWORD


.code
cout proc uses ebx esi edi lpStrToOutput:DWORD
	LOCAL hOut
	LOCAL nRead
	LOCAL strLen
    ;-------------------------
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov hOut, eax		;hOut
    ;-------------------------
    mov esi, lpStrToOutput   ;Pointer to str
    ;-------------------------
    push esi
    call lens
    mov strLen, eax
    ;-------------------------
	invoke WriteConsoleA, hOut, esi, strLen, addr nRead, 0
    ;------------------------
    ret
cout endp

lens proc uses ebx esi edi lpStrToGetLen:DWORD
    ;-------------------------
    mov esi, lpStrToGetLen	 ; Adress of the string
    ;-------------------------
    xor ecx, ecx
    ;-------------------------
@@while:

    cmp byte ptr[esi+ecx], 0
    je @@end_while    ;Conditional jump
    ;-------------------------
    inc ecx
    jmp @@while          ;Unconditional jump
    ;-------------------------
@@end_while:
    mov eax, ecx
    ;-------------------------
    ret
lens endp
