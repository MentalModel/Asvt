;----------------------------------------------------	
Str_to_byte proc
	push bp
	mov bp, sp
	
	push bx 
	push cx 
	push dx
	
	cld
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	
	lodsb						;al = first symbol

	sub al, 48					;al = digit
	mov dl, al					; res = first digit
	mov bl, 10		
	
	cycle:
		lodsb			
		cmp al, '$'				; next letter
		je @exit_convert  		
		sub al, 48				; al = next digit
		mov cl, al
		
		mov al, dl
		mul bl					; al = al * 10

		add al, cl				; al = al * 10 + next digit

		mov dl, al				; res = al * 10 + next digit
		jmp cycle

	@exit_convert:
		xor ax, ax
		mov al, dl
		
		pop dx 
		pop cx 
		pop bx 

		mov sp, bp
		pop bp
		ret	
Str_to_byte endp
;----------------------------------------------------	