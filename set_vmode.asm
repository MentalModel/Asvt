model tiny
cseg segment
assume CS:cseg
org 100h
.286

main:
	JMP start
		Mode_6 = 6 ; 640 X 200, 2 colors 
		Mode_13 = 0Dh ; 320 X 200, 16 colors 
		Mode_14 = 0Eh ; 640 X 200, 16 colors 
		Mode_15 = 0Fh ; 640 X 350, 2 colors 
		Mode_16 = 10h ; 640 X 350, 16 colors 
		Mode_17 = 11h ; 640 X 480, 2 colors 
		Mode_18 = 12h ; 640 X 480, 16 colors 
		Mode_19 = 13h ; 320 X 200, 256 colors 
		Mode_6A = 6Ah ; 800 X 600, 16 colors 
		
		saveMode db ?; Сохранить текущий видео режим
		Mode_16 = 10h ; 640 X 350, 16 colors 
		color db 10 ; номер цвета
		
		
		video_mode dw 0
		video_page dw 0
		temp dw 0
		
		arg1 db 5 dup(?)
		arg2 db 5 dup(?)
		arg3 db 0
		new_string db 13, 10, '$'
		tests db 'C88', '$'
		include Outint.inc
		
		
	start:	
	
		; Получить текущий видео режим
		mov ah, 0Fh
		int 10h
		mov saveMode, al
		cld
		mov cl, es:80h 		; get the length of PSP tail
		cmp cl, 0 			
		;je @error 			; program without keys
				
		mov si, 81h 
		call Miss_blank_symbols
		
		mov di, offset arg1
		push di
		call Read_number_from_console
		
		call Miss_blank_symbols
		
		mov di, offset arg2
		push di
		call Read_number_from_console
		
		mov temp, si
		;comment #
		mov di, offset arg1
		push di
		call Str_to_16
		;call OutInt
		mov video_mode, ax
		
		mov di, offset arg2
		push di
		call Str_to_16
		;call OutInt
		mov video_page, ax
		;jmp @exit
		mov si, temp
		;#
		call Miss_blank_symbols
		xor ax, ax
		lods byte ptr es:[si]
		;call OutInt
		cmp al, '-'
		je @wait_user
		;comment #
		xor ax, ax
		mov ah, 0  							; установка видео режима	
		mov al, byte ptr video_mode						; номер режима
		;call OutInt
		;mov al, 10h						; номер режима
		int 10h

		;mov ah, 05h
		;mov al, byte ptr video_page
		;mov al, 1
		;int 10h		
		
		; Ожидаем нажатия клавиши
		;mov ah, 0
		;int 16h
		
		; Возврат в прежний видео режим
		mov ah, 0h 			; установить видео режим 
		mov al, saveMode 	; сохраненный видео режим
		int 10h 
		
		jmp @exit

			
		@wait_user:

			mov ah, 0h 									; установка видео режима	
			mov al, byte ptr video_mode 				; номер режима
			int 10h

			mov ah, 05h
			mov al, byte ptr video_page
			int 10h		
			
			; Ожидаем нажатия клавиши
			mov ah, 0
			int 16h
			
			; Возврат в прежний видео режим
			;mov ah, 0h 			; установить видео режим 
			;mov al, saveMode 	; сохраненный видео режим
			;int 10h 
		;#
		jmp @exit	
		
;----------------------------------------------------	
Str_to_16 proc
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
	
	cmp al, 'A'
	jge @is_letter
	sub al, 48
	jmp miss
	
	@is_letter:
		sub al, '7'
	
	miss:
	mov dl, al					; res = first digit
	mov bx, 16		
	
	cycles:
		lodsb			
		
		cmp al, '$'				; next letter
		je @@exit_convert 
		
		cmp al, 'A'
		jge @parse_letters
		sub al, 48
		jmp miss2
		
		@parse_letters:
			sub al, '7'
		
		miss2:		
		mov cl, al
		mov ax, dx
		mul bx					; al = al * 16

		add ax, cx				; al = al * 16 + next digit

		mov dx, ax				; res = al * 16 + next digit
		jmp cycles

	@@exit_convert:
		xor ax, ax
		mov ax, dx
		
		pop dx 
		pop cx 
		pop bx 

		mov sp, bp
		pop bp
		ret	
Str_to_16 endp
;----------------------------------------------------


;----------------------------------------------------			
Miss_blank_symbols proc
	push bp
	mov bp, sp
	
	@read_blanks:
		lods byte ptr es:[si]
		cmp al, ' '
		je @read_blanks
		cmp al, 09h
		je @read_blanks
	
	dec si
	mov sp, bp
	pop bp
	ret		
Miss_blank_symbols endp
;----------------------------------------------------

;----------------------------------------------------		
Read_number_from_console proc

	; ds:si  ->  di:es
	push bp
	mov bp, sp
	xor ax, ax
	
	@cycle:
		lods byte ptr es:[si]
		cmp al, '0'
		jl @exit_proc
		cmp al, 'F'
		jg @exit_proc
		stosb
		jmp @cycle
	
	@exit_proc:
		
		dec si
		mov al, 24h
		stosb
		
		mov sp, bp
		pop bp
		ret
Read_number_from_console endp
;----------------------------------------------------	
		
	@error:
		jmp @exit
			
	@exit:
		; Выход из программы
		mov ax, 4c00h
		int 21h	
	ret
cseg ends
end main