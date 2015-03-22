model tiny
.code
org 100h
.386
ENV:
	jmp main

ivector	dd ?

hook proc
	jmp dword ptr cs:[ivector] 
hook endp

main:
	data db 20h, 00h, 00h, 01h, 00h, 'n', 00h
	
	mov ax, cs:[2ch]
	;mov es, ax
	push ax
	pop es
	mov ah,49h
	int 21h

	mov bl, 1h
	mov ah,48h
	int 21h

	mov cs:[2ch], ax
	mov cl, 7h
	mov si, offset data
	;mov es, ax
	xor di, di
	rep movsb
	
	mov	ax,3521h
	int	21h
		
	mov	word ptr ivector, bx
	mov	word ptr ivector + 2, es
		
	mov	ah, 25h
	lea	dx, hook
	int	21h

	lea dx, main
	int 27h

end ENV