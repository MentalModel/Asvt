model tiny
cseg segment
assume CS:cseg
org 100h

main:
	JMP start
		data db 13, 10, '$'
	start:	
		mov cx, 16
		loopa:
			; Ожидаем нажатия клавиши
			inside:
				mov ah, 0
				int 16h
				mov dl, bl
				mov ah, 02h
                int 21h
				inc bl
				and bl, 0fh
			jnz inside
			mov ah, 9h
			mov dx, offset data
			int 21h
		loop loopa
	ret
cseg ends
end main