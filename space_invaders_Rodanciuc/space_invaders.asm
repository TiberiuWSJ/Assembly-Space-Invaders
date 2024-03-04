.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Exemplu proiect desenare",0
area_width EQU 640
area_height EQU 480
area DD 0

counter DD 0 ; numara evenimentele de tip timer

temp1 dd 0
temp2 dd 0
zero dd 0

ship_x dd 320
ship_y dd 450

check_bullet dd 0
bullet_y dd 430
bullet_x dd 0
tempbullet dd 0

game_over_you dd 0
game_over_invaders dd 0
button_x EQU 400
button_y EQU 160
button_size EQU 80


invader struct
	x dd 0
	y dd 0
	is_alive dd 0
   ;score dd 0
invader ends

invaders invader {100,120,1},{140,120,1},{180,120,1}, {220, 120,1},
				 {100,140,1}, {140,140,1}, {180, 140,1},{220, 140,1},
				 {100, 160,1}, {140, 160,1}, {180, 160,1}, {220, 160,1}
				 

number_invaders dd 12
jump_inv dd 0
check_invor dd 0
bounce_flag_l dd 0
bounce_flag_r dd 0
count_increase dd 0
number_of_fadd dd 0
number_of_badd dd 0
invaders_left dd 12
			 
			 
arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20
check_shipor dd 0 ; 0 - dreapta, 1-stanga

score dd 0

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
include ship.inc
include delete_ship.inc
include bullet.inc
include alien.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat

	cmp eax, '*'
	je draw_alien
	cmp eax, '&'
	je draw_bullet
	cmp eax, '$'
	je draw_ship
	cmp eax, '!'
	je draw_no_ship
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_ship:
	sub eax, '$'
	lea esi, ship
	jmp draw_text
	
draw_no_ship:
	sub eax, '!'
	lea esi, delete_ship
	jmp draw_text
	
draw_bullet:
	sub eax, '&'
	lea esi, bullet
	jmp draw_text
	
draw_alien:
	sub eax, '*'
	lea esi, alien



	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 1
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

horizontal_line macro x,y,len,color
local bucla_line
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	mov ecx, len
bucla_line:
	mov dword ptr[eax], color
	add eax, 4
	loop bucla_line
endm

vertical_line macro x,y,len,color
local bucla_line
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	mov ecx, len
bucla_line:
	mov dword ptr[eax], color
	add eax, area_width* 4
	loop bucla_line
endm

print_alien_f macro number, flagf, display
local flag_on, cnt, change_m_flag, over
	lea esi, invaders[number]
	
	
	mov edi, 4
	make_text_macro '!', area, [esi], [esi+edi]
	mov eax, [esi]
	mov ebx, [esi+edi]
	add eax, 10
	mov [esi], eax
	cmp flagf, 1
	jne cnt
	
	flag_on:
	inc number_of_fadd
	add ebx, 50
	mov [esi+edi], ebx
	
	cmp number_of_fadd, 12
	je change_m_flag
	jmp cnt
	
	change_m_flag:
	dec bounce_flag_l
	
	cnt:
	mov ecx, display
	cmp ecx, 0
	je over
	make_text_macro '*', area, [esi], [esi+edi]
	over:
endm

print_alien_b macro number, flag, display
local flag_on, cnt, change_m_flag, over
	lea esi, invaders[number]
	mov edi, 4
	make_text_macro '!', area, [esi], [esi+edi]
	mov eax, [esi]
	mov ebx, [esi+edi]
	sub eax, 10
	mov [esi], eax
	cmp flag, 1
	jne cnt
	
	flag_on:
	inc number_of_badd
	add ebx, 50
	mov [esi+edi], ebx
	
	cmp number_of_badd, 12
	je change_m_flag
	jmp cnt
	
	change_m_flag:
	dec bounce_flag_r
	
	cnt:
	mov ecx, display
	cmp ecx, 0
	je over
	make_text_macro '*', area, [esi], [esi+edi]
	over:
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	

	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0 ; fereastra neagra
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
evt_click:
	
	
	
	
	mov esi, check_bullet
	cmp esi, 1
	je evt_timer
	
	mov esi, ship_x
	mov bullet_x, esi
	
	make_text_macro '&', area, bullet_x, bullet_y
	mov check_bullet, 1

	
	
	
evt_timer:

	cmp invaders_left,0
	je ending
	jmp step
	
	
	
	ending:
	mov game_over_you, 1
	jmp afisare_litere
	
	step:
	cmp game_over_invaders, 1
	je afisare_litere
	
	mov ecx, number_invaders ;contor pentru loop de afisare invaders
	mov edx,0 ; folosesc edx ca sa trec de la structura unui alien la altul
	mov edi, 4 ; edi pentru a accesa campul y
	mov ebx, 0
	mov count_increase, edx

	;########################### INVADERS #########################
	print_invaders:

	lea esi, invaders[edx]
	mov ebx, [esi] ; X
	
	mov eax, [esi+4] ; Y
	
	;collision
	mov ecx, eax
	add ecx, 5
	cmp bullet_y,ecx
	jle check_x
	jmp after_collision
	
	check_x:

	mov ecx, ebx
	add ecx, 19
	cmp bullet_x, ecx
	jle check_further
	jmp after_collision
	
	check_further:
	mov ecx, ebx
	sub ecx, 19
	cmp bullet_x, ecx
	jge delete_inv
	jmp after_collision
	
	delete_inv:
	
	
	mov ecx, [esi+8]
	cmp ecx, 0
	je after_collision
	
	inc score 
	dec invaders_left
	make_text_macro '!', area,  bullet_x, bullet_y
	mov bullet_y, 430
	mov check_bullet,0
	mov ecx, 0
	mov [esi+8], ecx

	
	after_collision:
	
	
	check_x_ending:
	mov eax, [esi+4] ; Y
	cmp eax, 420
	jge check_ending_inv
	jmp step_over
	
	check_ending_inv:
	;cmp invaders_left,0
	;jg ending_inv
	;jmp step_over
	
	ending_inv:
	mov game_over_invaders, 1
	jmp afisare_litere
	
	
	step_over:
	cmp edx, 0
	je check_x_inc
	jmp cont_check
	
	
	check_x_inc:
	cmp ebx, 40
	je change_dir_inc
	
	check_x_dec:
	cmp ebx, 480
	je change_dir_dec
	
	jmp cont_check
	
	change_dir_dec:
	inc bounce_flag_r
	inc check_invor
	jmp cont_check
	
	change_dir_inc:
	inc bounce_flag_l
	dec check_invor
	
	cont_check:
	cmp check_invor, 0
	je increase
	
	decrease:
	inc count_increase
	print_alien_b edx, bounce_flag_r, [esi+8]
	add edx, 12
	jmp cnt
	
	increase:
	inc count_increase
	print_alien_f edx, bounce_flag_l, [esi+8]
	add edx, 12
	
	cnt:

	cmp count_increase, 12
	jl print_invaders
	mov number_of_fadd, 0
	mov number_of_badd, 0
	
	
	;############################ BULLET ############################
	move_bullet:
	mov esi, check_bullet
	cmp esi, 1
	je advance_bullet
	cmp esi, 0
	je moving_ship
	
	advance_bullet:	
	
	
	make_text_macro '!', area, bullet_x, bullet_y
	
	mov esi, bullet_y
	cmp esi, 10
	jle stop_bullet
	
	
	
	
	mov eax, bullet_y
	sub eax, 20
	mov bullet_y, eax
	
	make_text_macro '&', area, bullet_x, bullet_y
	jmp moving_ship
	
	
	stop_bullet:
	
	mov bullet_y, 430
	mov check_bullet, 0
	
	
	
	
	;################################# SHIP #############################
 	moving_ship:
	mov eax, ship_x
	mov esi, check_shipor ;variabila care verifica in care sens trebuie sa mearga ship-ul
	make_text_macro '!', area, ship_x, 450 ; sterge ultima afisare a shipului
	
	cmp esi, 0
	je adauga
	cmp esi, 1
	je scade
	
	
	
	adauga:
	
	cmp eax, 616
	je creste_or
	
	
	mov ebx, ship_x
	add ebx, 8
	mov ship_x, ebx
	

	
	make_text_macro '$', area, ship_x, 450
	jmp afisare_litere
	
	
	scade:
	
	cmp eax, 16
	je scade_or
	
	mov ebx, ship_x
	sub ebx, 8
	mov ship_x, ebx
	
	
	make_text_macro '$', area, ship_x, 450
	jmp afisare_litere

	creste_or:
	inc check_shipor
	jmp afisare_litere
	
	scade_or:
	dec check_shipor
	

	
	
	
afisare_litere:
	
	cmp game_over_you, 1
	je end_game_you
	jmp next_check
	
	end_game_you:
	make_text_macro 'G', area, 290, 180
	make_text_macro 'A', area, 300, 180
	make_text_macro 'M', area, 310, 180
	make_text_macro 'E', area, 320, 180
	make_text_macro 'O', area, 290, 200
	make_text_macro 'V', area, 300, 200
	make_text_macro 'E', area, 310, 200
	make_text_macro 'R', area, 320, 200
	
	make_text_macro 'Y', area, 270, 250
	make_text_macro 'O', area, 280, 250
	make_text_macro 'U', area, 290, 250
	make_text_macro 'W', area, 320, 250
	make_text_macro 'I', area, 330, 250
	make_text_macro 'N', area, 340, 250
	
	next_check:
	cmp game_over_invaders, 1
	je end_game_inv
	jmp skip
	
	end_game_inv:
	make_text_macro 'G', area, 290, 180
	make_text_macro 'A', area, 300, 180
	make_text_macro 'M', area, 310, 180
	make_text_macro 'E', area, 320, 180
	make_text_macro 'O', area, 290, 200
	make_text_macro 'V', area, 300, 200
	make_text_macro 'E', area, 310, 200
	make_text_macro 'R', area, 320, 200
	
	make_text_macro 'I', area, 250, 250
	make_text_macro 'N', area, 260, 250
	make_text_macro 'V', area, 270, 250
	make_text_macro 'A', area, 280, 250
	make_text_macro 'D', area, 290, 250
	make_text_macro 'E', area, 300, 250
	make_text_macro 'R', area, 310, 250
	make_text_macro 'S', area, 320, 250
	make_text_macro 'W', area, 340, 250
	make_text_macro 'I', area, 350, 250
	make_text_macro 'N', area, 360, 250
	


	skip:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, score
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 90, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 80, 10

	
	;scriem un mesaj
	make_text_macro 'S', area, 10, 10
	make_text_macro 'C', area, 20, 10
	make_text_macro 'O', area, 30, 10
	make_text_macro 'R', area, 40, 10
	make_text_macro 'E', area, 50, 10
	 
	
	make_text_macro 'R', area, 540, 10
	make_text_macro 'O', area, 550, 10
	make_text_macro 'D', area, 560, 10
	make_text_macro 'A', area, 570, 10
	make_text_macro 'N', area, 580, 10
	make_text_macro 'C', area, 590, 10
	make_text_macro 'I', area, 600, 10
	make_text_macro 'U', area, 610, 10
	make_text_macro 'C', area, 620, 10

	
	
	
	


final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
