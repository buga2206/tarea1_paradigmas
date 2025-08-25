org 100h
jmp start

MAX_ALUMNOS  equ 15
NAME_W       equ 40

; ---- almacenamiento ----
NAMES        db MAX_ALUMNOS*NAME_W dup(0) ; 15 x 40 bytes
NAME_LEN     db MAX_ALUMNOS dup(0)        ; longitud de cada nombre
NOTAS_LO     dw MAX_ALUMNOS dup(0)
NOTAS_HI     dw MAX_ALUMNOS dup(0)
COUNT        db 0

; ---- trabajo 32 bits ----
VAL_LO       dw 0
VAL_HI       dw 0
TMP_LO       dw 0
TMP_HI       dw 0
FRAC_LO      dw 0
FRAC_HI      dw 0

; ---- auxiliares parser ----
VISTO_P      db 0
DEC_CNT      db 0
ANYDIG       db 0

; ---- buffers entrada ----
NOTE_MAX     equ 20
NOTE_BUF     db NOTE_MAX, 0, NOTE_MAX dup(0)

NAME_MAX     equ 80
NAME_BUF     db NAME_MAX, 0, NAME_MAX dup(0)

; ---- buffers impresion ----
DIGITS       db 12 dup(0)
FRACDIG      db 5 dup(0)

; ---- textos ----
CRLF         db 13,10,'$'
MENU         db 13,10,'=== MENU ===',13,10,'$'
MENU2        db '1) Ingresar alumno (Nombre + Nota)',13,10,'$'
; (solo agrego opciones del txt sin cambiar tu logica)
MENU3        db '2) Mostrar estadisticas',13,10,'$'
MENU4        db '3) Buscar estudiante por posicion (indice)',13,10,'$'
MENU5        db '4) Ordenar calificaciones (asc/desc)',13,10,'$'
MENU6        db '5) Salir',13,10,'$'
MENU7        db 'Opcion: $'

MSG_WAIT     db 13,10,'<Presione una tecla para continuar>','$'

PROMPT_N     db 13,10,'Nombre (max 40): $'
PROMPT_V     db 'Nota (0..100, hasta 5 decimales): $'

FULLMSG      db 13,10,'[!] Tabla llena (max 15).$'
INVMSG       db 13,10,'[!] Entrada invalida. Intente de nuevo.$'
OKMSG        db ' -> Guardado en indice $'
NODATA       db 13,10,'[!] No hay alumnos guardados.$'

HDR          db 13,10,'Idx  Nombre                                 Nota',13,10
             db '---- ---------------------------------------- -----------',13,10,'$'
IDX_LBL      db 'Idx ', '$'

; ===================================================
start:
    push cs
    pop  ds

main_menu:
    mov dx, offset MENU
    call PrintStr
    mov dx, offset MENU2
    call PrintStr
    mov dx, offset MENU3
    call PrintStr
    mov dx, offset MENU4
    call PrintStr
    mov dx, offset MENU5
    call PrintStr
    mov dx, offset MENU6
    call PrintStr
    mov dx, offset MENU7
    call PrintStr

    mov ah, 01h
    int 21h

    cmp al, '1'
    je  opt_ingresar
    cmp al, '2'
    je  opt_mostrar          ; (mantiene tu mostrar actual)
    cmp al, '3'
    je  opt_buscar           ; (stub agregado)
    cmp al, '4'
    je  opt_ordenar          ; (stub agregado)
    cmp al, '5'
    je  bye
    jmp main_menu

; ---------- Opcion 1: Ingresar ----------
opt_ingresar:
    mov al, [COUNT]
    cmp al, MAX_ALUMNOS
    jae tabla_llena

    ; leer nombre
    mov dx, offset PROMPT_N
    call PrintStr
    mov dx, offset NAME_BUF
    mov ah, 0Ah
    int 21h
    call PrintCRLF

    ; validar/ajustar longitud
    mov si, offset NAME_BUF
    mov cl, [si+1]
    cmp cl, 0
    je  entrada_invalida
    cmp cl, NAME_W
    jbe name_len_ok
    mov cl, NAME_W
name_len_ok:
    mov bl, [COUNT]
    xor bh, bh
    mov [NAME_LEN+bx], cl

    ; calcular destino &NAMES[idx*40]
    mov ax, bx
    mov dx, ax
    shl ax, 5
    shl dx, 3
    add ax, dx              ; AX = idx*40
    lea di, NAMES
    add di, ax              ; DI = &NAMES[idx*40]

    ; copiar nombre y rellenar con ceros
    mov si, offset NAME_BUF+2
    push ds
    pop  es
    cld

    mov ch, 0
    mov al, cl
    mov cl, al
    rep movsb               ; copia len

    mov al, NAME_W
    sub al, [NAME_LEN+bx]
    mov cl, al
    jz  ask_nota
    xor ax, ax              ; AL=0
    rep stosb

ask_nota:
    ; leer nota
    mov dx, offset PROMPT_V
    call PrintStr
    mov dx, offset NOTE_BUF
    mov ah, 0Ah
    int 21h
    call PrintCRLF

    ; parsear a VAL (x100000)
    call ParseNota
    jc  entrada_invalida

    ; guardar nota
    mov bl, [COUNT]
    xor bh, bh
    shl bx, 1               ; *2 (indice word)
    mov ax, [VAL_LO]
    mov dx, [VAL_HI]
    mov [NOTAS_LO+bx], ax
    mov [NOTAS_HI+bx], dx

    ; confirmar
    mov dx, offset OKMSG
    call PrintStr
    mov al, [COUNT]
    call PrintDec8
    call PrintCRLF

    inc byte ptr [COUNT]
    jmp main_menu

entrada_invalida:
    mov dx, offset INVMSG
    call PrintStr
    jmp main_menu

tabla_llena:
    mov dx, offset FULLMSG
    call PrintStr
    jmp main_menu

; ---------- Opcion 2: Mostrar (tu misma funcionalidad) ----------
opt_mostrar:
    mov al, [COUNT]
    cmp al, 0
    je  no_datos

    mov dx, offset HDR
    call PrintStr

    xor si, si              ; si = indice
    xor di, di              ; di = offset notas (*2)

show_loop:
    ; FIX: recargar COUNT cada vuelta (BX se usa luego como puntero)
    mov bl, [COUNT]
    xor bh, bh
    cmp si, bx
    jae show_done

    ; cargar nota a VAL
    mov ax, [NOTAS_LO+di]
    mov dx, [NOTAS_HI+di]
    mov [VAL_LO], ax
    mov [VAL_HI], dx

    ; "Idx "
    mov dx, offset IDX_LBL
    call PrintStr

    ; idx con ancho 2
    mov ax, si
    cmp ax, 10
    jae idx_two
    mov dl, ' '
    mov ah, 02h
    int 21h
idx_two:
    mov ax, si
    call PrintDec16

    ; dos espacios
    mov dl, ' '
    mov ah, 02h
    int 21h
    int 21h

    ; BX = &NAMES[si*40]
    mov ax, si
    mov dx, ax
    shl ax, 5
    shl dx, 3
    add ax, dx              ; AX = si*40
    lea bx, NAMES
    add bx, ax

    ; CL = longitud real
    mov cl, [NAME_LEN+si]
    mov ch, 0
    jcxz pad_name

print_name_loop:
    mov al, [bx]
    mov dl, al
    mov ah, 02h
    int 21h
    inc bx
    dec cl
    jnz print_name_loop

pad_name:
    ; imprimir (40 - len) espacios
    mov al, [NAME_LEN+si]
    xor ah, ah
    mov cx, NAME_W
    sub cx, ax
    jcxz after_name_spaces
    mov dl, ' '
    mov ah, 02h
name_space_loop:
    int 21h
    loop name_space_loop
after_name_spaces:

    ; dos espacios y la nota
    mov dl, ' '
    mov ah, 02h
    int 21h
    int 21h

    call PrintScaled32
    call PrintCRLF

    add di, 2
    inc si
    jmp show_loop

show_done:
    jmp main_menu

no_datos:
    mov dx, offset NODATA
    call PrintStr
    jmp main_menu

; ---------- Opcion 3: Buscar (SOLO MENU/STUB, sin cambiar logica) ----------
opt_buscar:
    mov dx, offset MSG_WAIT
    call PrintStr
    mov ah, 01h
    int 21h
    jmp main_menu

; ---------- Opcion 4: Ordenar (SOLO MENU/STUB, sin cambiar logica) ----------
opt_ordenar:
    mov dx, offset MSG_WAIT
    call PrintStr
    mov ah, 01h
    int 21h
    jmp main_menu

; ---------- Salir ----------
bye:
    mov ax, 4C00h
    int 21h

; =================== Utilidades impresion ===================
PrintStr proc near
    mov ah, 09h
    int 21h
    ret
PrintStr endp

PrintCRLF proc near
    mov dx, offset CRLF
    mov ah, 09h
    int 21h
    ret
PrintCRLF endp

PrintDec8 proc near
    xor ah, ah
    call PrintDec16
    ret
PrintDec8 endp

PrintDec16 proc near
    push ax
    push bx
    push si
    push dx
    mov si, 0
    cmp ax, 0
    jne pd16_loop
    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp pd16_done
pd16_loop:
    xor dx, dx
    mov bx, 10
    div bx
    add dl, '0'
    mov [DIGITS+si], dl
    inc si
    cmp ax, 0
    jne pd16_loop
pd16_out:
    dec si
    mov dl, [DIGITS+si]
    mov ah, 02h
    int 21h
    cmp si, 0
    jne pd16_out
pd16_done:
    pop dx
    pop si
    pop bx
    pop ax
    ret
PrintDec16 endp

; ================= Aritmetica 32b y formato x100000 =================

; (DX:AX) = (DX:AX) * 10
Mul10_DXAX proc near
    push bx
    push cx
    mov bx, ax
    mov cx, dx

    mov ax, bx
    mov dx, cx
    shl ax, 1
    rcl dx, 1
    mov [TMP_LO], ax
    mov [TMP_HI], dx

    mov ax, bx
    mov dx, cx
    shl ax, 1
    rcl dx, 1
    shl ax, 1
    rcl dx, 1
    shl ax, 1
    rcl dx, 1

    add ax, [TMP_LO]
    adc dx, [TMP_HI]
    pop cx
    pop bx
    ret
Mul10_DXAX endp

; VAL /= 10, resto -> AL
DivMod10_Val proc near
    push bx
    push cx
    mov bx, 10

    mov ax, [VAL_HI]
    xor dx, dx
    div bx
    mov cx, ax

    mov ax, [VAL_LO]
    div bx

    mov [VAL_HI], cx
    mov [VAL_LO], ax
    mov al, dl

    pop cx
    pop bx
    ret
DivMod10_Val endp

; imprime VAL como entero.fffff
PrintScaled32 proc near
    push ax
    push bx
    push cx
    push dx
    push si

    mov ax, [VAL_LO]
    mov dx, [VAL_HI]
    mov [TMP_LO], ax
    mov [TMP_HI], dx

    mov cx, 5
    mov si, 0
ps_frac:
    mov ax, [TMP_LO]
    mov dx, [TMP_HI]
    mov [VAL_LO], ax
    mov [VAL_HI], dx
    call DivMod10_Val
    mov [FRACDIG+si], al
    mov ax, [VAL_LO]
    mov dx, [VAL_HI]
    mov [TMP_LO], ax
    mov [TMP_HI], dx
    inc si
    loop ps_frac

    mov ax, [TMP_LO]
    mov dx, [TMP_HI]
    or  ax, dx
    jne ps_print_int

    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp ps_after_int

ps_print_int:
    mov [VAL_LO], ax
    mov [VAL_HI], dx
    mov si, 0
ps_int_loop:
    call DivMod10_Val
    add al, '0'
    mov [DIGITS+si], al
    inc si
    mov ax, [VAL_LO]
    mov dx, [VAL_HI]
    or  ax, dx
    jne ps_int_loop
ps_int_out:
    dec si
    mov dl, [DIGITS+si]
    mov ah, 02h
    int 21h
    cmp si, 0
    jne ps_int_out

ps_after_int:
    mov dl, '.'
    mov ah, 02h
    int 21h

    mov si, 5
ps_frac_out:
    dec si
    mov dl, [FRACDIG+si]
    add dl, '0'
    mov ah, 02h
    int 21h
    cmp si, 0
    jne ps_frac_out

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintScaled32 endp

; ================= Parser: NOTE_BUF -> VAL (x100000) =================
; Acepta: 0..100, hasta 5 decimales. Requiere al menos 1 digito total.
ParseNota proc near
    push ax
    push bx
    push cx
    push dx
    push si
    push bp

    mov word ptr [VAL_LO],  0
    mov word ptr [VAL_HI],  0
    mov word ptr [FRAC_LO], 0
    mov word ptr [FRAC_HI], 0
    mov byte ptr [VISTO_P], 0
    mov byte ptr [DEC_CNT], 0
    mov byte ptr [ANYDIG],  0

    mov si, offset NOTE_BUF
    mov cl, [si+1]
    cmp cl, 0
    je  p_err
    xor ch, ch
    lea si, [si+2]
    xor bx, bx

p_loop:
    cmp cx, 0
    je  p_end

    lodsb
    dec cx

    cmp al, '.'
    je  p_dot

    cmp al, '0'
    jb  p_err
    cmp al, '9'
    ja  p_err
    mov byte ptr [ANYDIG], 1

    cmp byte ptr [VISTO_P], 0
    jne p_frac

    ; parte entera: BX = BX*10 + digito
    sub al, '0'
    xor ah, ah
    mov bp, ax

    mov ax, bx
    mov dx, bx
    shl ax, 1
    shl dx, 3
    add ax, dx
    mov bx, ax

    add bx, bp

    cmp bx, 100
    jbe p_next
    jmp p_err

p_frac:
    mov dl, [DEC_CNT]
    cmp dl, 5
    jae p_err

    sub al, '0'
    xor ah, ah
    mov bp, ax

    mov ax, [FRAC_LO]
    mov dx, [FRAC_HI]
    call Mul10_DXAX

    add ax, bp
    adc dx, 0
    mov [FRAC_LO], ax
    mov [FRAC_HI], dx

    inc byte ptr [DEC_CNT]
    jmp p_next

p_dot:
    cmp byte ptr [VISTO_P], 0
    jne p_err
    cmp byte ptr [ANYDIG], 0
    je  p_err
    mov byte ptr [VISTO_P], 1
    jmp p_next

p_next:
    jmp p_loop

p_end:
    ; debe existir al menos un digito
    cmp byte ptr [ANYDIG], 0
    je  p_err

    ; normalizar fraccion a 5
    mov al, [DEC_CNT]
    cmp al, 5
    je  frac_ok

    mov ah, 0
    mov cx, 5
    sub cx, ax
    mov ax, [FRAC_LO]
    mov dx, [FRAC_HI]
p_pad:
    call Mul10_DXAX
    loop p_pad
    mov [FRAC_LO], ax
    mov [FRAC_HI], dx

frac_ok:
    cmp bx, 100
    ja  p_err
    cmp bx, 100
    jne ok_int

    mov ax, [FRAC_LO]
    mov dx, [FRAC_HI]
    or  ax, dx
    jne p_err

ok_int:
    xor dx, dx
    mov ax, bx
    mov [VAL_LO], ax
    mov [VAL_HI], dx

    mov cx, 5
mul_100k:
    mov ax, [VAL_LO]
    mov dx, [VAL_HI]
    call Mul10_DXAX
    mov [VAL_LO], ax
    mov [VAL_HI], dx
    loop mul_100k

    mov ax, [VAL_LO]
    mov dx, [VAL_HI]
    add ax, [FRAC_LO]
    adc dx, [FRAC_HI]
    mov [VAL_LO], ax
    mov [VAL_HI], dx

    clc
    jmp p_exit

p_err:
    stc
p_exit:
    pop bp
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ParseNota endp
