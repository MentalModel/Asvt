model tiny
text segment 'code'
assume cs:text, ds:text, es:text
org 100h

main proc
	jmp init

	vector2Fh dd 0
	vector21h dd 0

;---------------------------------------------
handler21h proc
	jmp cs:vector21h
handler21h endp
;---------------------------------------------

;---------------------------------------------
handler_2fh proc
	cmp ah, 0f1h 				; check the No of multiplexing interruption
	jne exit_2fh 				; if its another function -> exit
	cmp al, 00h 				; if we want to check the presence of our resident
	je tsr_already_installed 		
	cmp al, 01h 				; subfunction of uninstalling ?
	je uninstall 				
	jmp exit_2fh 				; unrecognized subfunction -> exit
	tsr_already_installed: 
		mov al, 0ffh 			
		iret
	exit_2fh:
		jmp cs:vector2Fh 		; go to next element of chain tsr of 2Fh
	
	; delete our TSR from memory and restore of the TSR which were catched by it
	uninstall: 
		push ds
		push es
		push dx
		
		; restore vector 21h
		mov ax, 2521h 				; install 21h
		lds dx, cs:vector21h 		; ds:dx
		int 21h
		
		; restore vector 2fh
		mov ax, 252fh
		lds dx, cs:vector2Fh
		int 21h
		
		; get PSP address of our ENVIRONMENT and delete it
		mov es, cs:2ch 			; es <- ENV
		mov ah, 49h 			; function of deleting block of memory
		int 21h
		
		; delete the TSR itself
		push cs					
		pop es					; es <- segment address of PSP
		mov ah, 49h
		int 21h
		
		pop dx
		pop es
		pop ds
	iret
handler_2fh endp 	

end_res = $ 	
main endp


	flag db 0 			; Флаг требования выгрузки
	keys db 'iukhs'
	lbls dw @illegal_key, @lbl_status, @lbl_help, @lbl_kill, @lbl_uninstall, @lbl_install

init proc
	mov cl, es:80h 		; get the length of PSP tail
	cmp cl, 0 			
	je @help_me 			; program without keys
	
	cmp cl, 2 			
	jle @illegal_key 			; program without keys
	
	xor ch, ch 			
	mov si, 81h 		
	read_console:		
		lodsb
		cmp	al, ' '							; miss blank symbols
		je read_console
		cmp	al, 9h							; miss TAB symbols
		je read_console
		cmp	al, '/'			
		jne	@illegal_key						; if no symbol / -> error
		lodsb
		cmp	al, 'u'
		jne miss
		inc flag
		miss:
		mov cl, 6
		lea di, keys
		repne scasb
		shl cx, 1
		mov di, cx
		jmp lbls[di]
	
	
	@help_me:
		mov dx, offset try_to_use_help
		jmp	@print_and_quit	
		
	@illegal_key:
		mov	dx, offset error_input
		jmp	@print_and_quit	

	@lbl_help:
		mov	dx, offset help
		jmp	@print_and_quit		
	
	@lbl_kill:

			; save vector 21h
			mov ax, 3521h 						; get vector 21h
			int 21h
			mov word ptr cs:vector21h, bx		; function to install new vector 2fh
			mov word ptr cs:vector21h + 2, es	; offset of our handler
			
			mov	dx, es					; dx <----- segment of old vector
			mov	ax, bx					; ax <----- offset  of old vector
			push ds
			pop	es						; es <-- ds
			mov	di, offset o21
			call h8
			
			; send into the first residental copy of program to uninstall itself
			mov ax, 0f101h 							; (our f + subf to delete tsr)
			int 2fh 
			
			; save vector 21h
			mov ax, 3521h 						; get vector 21h
			int 21h
			mov word ptr cs:vector21h, bx		; function to install new vector 2fh
			mov word ptr cs:vector21h + 2, es	; offset of our handler
			
			
			mov	dx, es					; dx <----- segment of old vector
			mov	ax, bx					; ax <----- offset  of old vector
			push ds
			pop	es						; es <-- ds
			mov	di, offset n21
			call h8
			
			
			mov	dx, offset o21			; "xxxx:yyyy->zzzz:aaaa"
			mov	ah, 9
			int	21h

		mov ah, 09h
		lea dx, tsr_has_been_uninstalled
		int 21h
		
		mov	dx, offset killed
		jmp	@print_and_quit	
		
	@lbl_status:
		mov ah, 0f1h 	; install our function
		mov al, 0 		; and sub function to check if our TSR is already installed
		int 2fh
		cmp al, 0ffh 	; Has TSR been installed ?
		je status_is_installed
		
		mov ah, 09h 								
		lea dx, no_resident 							
		int 21h
		jmp exit
		
		status_is_installed:
		
			mov ah, 09h 								
			lea dx, already_installed 							
			int 21h
				
		; save vector 21h
		mov ax, 3521h 						; get vector 21h
		int 21h
		
		mov	dx, es					; dx <----- segment of old vector
		mov	ax, bx					; ax <----- offset  of old vector
		push ds
		pop	es						; es <-- ds
		mov	di, offset n21
		call h8
		
		mov	dx, offset n21			; "xxxx:yyyy->zzzz:aaaa"
		mov	ah, 9
		int	21h
		

		exit:
			mov ax, 4c01h 								; exit
			int 21h
	
	@print_and_quit:						
		mov	ah, 09h
		int	21h
		ret
	
	@lbl_install: 
		mov ah, 0f1h 	; install our function
		mov al, 0 		; and sub function to check if our TSR is already installed
		int 2fh
		cmp al, 0ffh 	; Has TSR been installed ?
		je installed
		
		; save vector 2fh
		mov ax, 352fh 	; get vector 2fh
		int 21h
		
		mov word ptr cs:vector2Fh, bx 		; offset of old 2fh
		mov word ptr cs:vector2Fh + 2, es 	; segment of old 2fh
		;call get_address
		
		

		; Put our new vector 2fh
		mov ax, 252fh 						; function to install new vector 2fh
		mov dx, offset handler_2fh 			; offset of our handler
		int 21h
		
		; save vector 21h
		mov ax, 3521h 						; get vector 21h
		int 21h
		mov word ptr cs:vector21h, bx		; function to install new vector 21h
		mov word ptr cs:vector21h + 2, es	; offset of our handler
		call get_address
		
		; Put our new vector 21h
		mov ax, 2521h 						; function to install new vector 21h
		mov dx, offset handler21h 			; offset of our handler
		int 21h
 
		mov ah, 09h
		lea dx, tsr_has_been_installed 				; ds:dx
		int 21h
		
		; exit and stay resident
		mov ax, 3100h 
		mov dx, (end_res - main + 10fh) / 16 	; paragraph size
		int 21h
		
	installed:
		cmp flag, 1 							; Do we want to uninstall TSR ?
		je uninstall_tsr
		
	mov ah, 09h 								
	lea dx, already_installed 							
	int 21h

	mov ax, 4c01h 								; exit
	int 21h
	
	@lbl_uninstall:
		mov ah, 0f1h 	; install our function
		mov al, 0 		; and sub function to check if our TSR is already installed
		int 2fh
		cmp al, 0ffh 	; Has TSR been installed ?
		je uninstall_tsr
		
		mov ah, 09h 								
		lea dx, no_resident 							
		int 21h
		jmp exit_last


			
		uninstall_tsr:
	
			mov ah, 09h
			lea dx, tsr_has_been_uninstalled
			int 21h
			
			; save vector 21h
			mov ax, 3521h 						; get vector 21h
			int 21h
			mov word ptr cs:vector21h, bx		; function to install new vector 2fh
			mov word ptr cs:vector21h + 2, es	; offset of our handler
			
			mov	dx, es					; dx <----- segment of old vector
			mov	ax, bx					; ax <----- offset  of old vector
			push ds
			pop	es						; es <-- ds
			mov	di, offset o21
			call h8
			
			; send into the first residental copy of program to uninstall itself
			mov ax, 0f101h 							; (our f + subf to delete tsr)
			int 2fh 
			
			; save vector 21h
			mov ax, 3521h 						; get vector 21h
			int 21h
			mov word ptr cs:vector21h, bx		; function to install new vector 2fh
			mov word ptr cs:vector21h + 2, es	; offset of our handler
			
			
			mov	dx, es					; dx <----- segment of old vector
			mov	ax, bx					; ax <----- offset  of old vector
			push ds
			pop	es						; es <-- ds
			mov	di, offset n21
			call h8
			
			
			mov	dx, offset o21			; "xxxx:yyyy->zzzz:aaaa"
			mov	ah, 9
			int	21h

		exit_last:	
			mov ax, 4c00h 							; exit
			int 21h
	
	o21							db	'    :     -> '
	n21							db	'    :    ', 13, 10, '$'
	
	no_resident					db 	'Our resident has not been installed !', 13, 10, '$'
	try_to_use_help				db 	'Try to use help with key /h', 13, 10, '$'
	already_installed			db	'TSR has been already installed...', 13, 10, '$'
	tsr_has_been_uninstalled	db	'TSR has been uninstalled !',13,10,'$'
	killed						db  'All TSRs have been killed!', 13, 10, '$'
	tsr_has_been_installed		db  'TSR has been installed!', 13, 10, '$'
	error_input					db 	'There were errors in your input !', 13, 10, '$'
	want_to_uninstall			db	0
	help 						db	'/h Help ', 13, 10, '/i To install TSR', 13, 10, '/u To uninstall TSR', 13, 10, '/k To kill TSR', 13, 10, '$'
	

proc get_address	
	;-------------------------------------------------------------------------------		
	mov	dx, es					; dx <----- segment of old vector
	mov	ax, bx					; ax <----- offset  of old vector
	push ds
	pop	es						; es <-- ds
	mov	di, offset o21
	call h8
	mov	dx, cs					; dx <----- segment of new vector
	mov	ax, offset handler21h	; ax <--- new offset of vector
	mov	di, offset n21
	call h8
	
	mov	dx, offset o21			; "xxxx:yyyy->zzzz:aaaa"
	mov	ah, 9
	int	21h
	ret
get_address endp
	;-------------------------------------------------------------------------------	
	
h8:		push	ax		; dx:ax (es:di up)
		mov	ax,dx
		call	h4
		mov	al,':'
		stosb
		pop	ax
h4:		push	ax		; ax (es:di up)
		mov	al,ah
		call	h2
		pop	ax
h2:		push	ax		; al (es:di up)
		push	cx
		mov	cl,4
		shr	al,cl
		call	h1
		pop	cx
		pop	ax
h1:		push	ax
		and	al,0Fh
		add	al,90h
		daa
		adc	al,40h
		daa
		stosb
		pop	ax
		ret
		
init endp
text ends
end main