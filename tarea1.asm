org 100h
jmp start

; ===================== CONSTANTES =====================
MAX_ALUMNOS  equ 15
NAME_W       equ 40
NOTE_MAX     equ 20
NAME_MAX     equ 80

; ===================== DATOS =====================
NAMES        db MAX_ALUMNOS*NAME_W dup(0)
NAME_LEN     db MAX_ALUMNOS dup(0)
NOTAS_LO     dw MAX_ALUMNOS dup(0)
NOTAS_HI     dw MAX_ALUMNOS dup(0)
COUNT        db 0

VAL_LO       dw 0
VAL_HI       dw 0
TMP_LO       dw 0
TMP_HI       dw 0
FRAC_LO      dw 0
FRAC_HI      dw 0

VISTO_P      db 0
DEC_CNT      db 0
ANYDIG       db 0

NOTE_BUF     db NOTE_MAX, 0, NOTE_MAX dup(0)
NAME_BUF     db NAME_MAX, 0, NAME_MAX dup(0)

DIGITS       db 12 dup(0)
FRACDIG      db 5 dup(0)

CRLF         db 13,10,'$'
MENU         db 13,10,'=== MENU ===',13,10,'$'
MENU2        db '1) Ingresar estudiante',13,10,'$'
MENU3        db '2) Mostrar estadisticas (prom/max/min + aprob/reprob)',13,10,'$'
MENU4        db '3) Buscar estudiante por indice',13,10,'$'
MENU5        db '4) Ordenar',13,10,'$'
MENU6        db '5) Salir',13,10,'$'
MENU7        db 'Opcion: $'

MSG_WAIT     db 13,10,'<Presione una tecla para continuar>','$'
PROMPT_N     db 13,10,'Nombre (max 40): $'
PROMPT_V     db 'Nota (0..100, hasta 5 decimales): $'
FULLMSG      db 13,10,'[!] Tabla llena (max 15).$'
INVMSG       db 13,10,'[!] Entrada invalida.$'
OKMSG        db ' -> Guardado en indice $'
NODATA       db 13,10,'[!] No hay alumnos guardados.$'
HDR          db 13,10,'Idx  Nombre                                 Nota',13,10
             db '---- ---------------------------------------- -----------',13,10,'$'
IDX_LBL      db 'Idx ', '$'

MSG_IDX1     db 13,10,'Indice (0..', '$'
MSG_IDX2     db '): $'

STATS_TTL    db 13,10,'--- ESTADISTICAS ---',13,10,'$'
LBL_PROM     db 'Promedio general: $'
LBL_APROB    db 13,10,'Aprobados (>=70): $'
LBL_REPRO    db 13,10,'Reprobados (<70): $'
LBL_MAX      db 13,10,'Max: $'
LBL_MIN      db 13,10,'Min: $'
TXT_DE       db ' de $'
TXT_ARROW    db '  ->  $'

SUM_LO       dw 0
SUM_HI       dw 0
MAX_LO       dw 0
MAX_HI       dw 0
MIN_LO       dw 0
MIN_HI       dw 0
IDX_MAX      db 0
IDX_MIN      db 0
Q_LO         dw 0
Q_HI         dw 0
TH_LO        dw 0        ; umbral 70*100000
TH_HI        dw 0
APROB_CNT    db 0
REPRO_CNT    db 0

; --- Buffers para ordenar ---
TMP_NAME     db NAME_W dup(0)

ORD_MENU     db 13,10,'--- ORDENAR ---',13,10
             db '1) Ascendente (menor a mayor)',13,10
             db '2) Descendente (mayor a menor)',13,10
             db '3) Cancelar',13,10
             db 'Opcion: $'

SORTMSG_ASC  db 13,10,'[OK] Ordenado (ascendente: menor nota primero).',13,10,'$'
SORTMSG_DESC db 13,10,'[OK] Ordenado (descendente: mayor nota primero).',13,10,'$'

; ---------- Sin datos ----------
no_datos:
    mov dx, offset NODATA
    call PrintStr
    jmp main_menu

; ===================== CODIGO =====================
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
    je  opt_mostrar
    cmp al, '3'    
    je  opt_buscar
    cmp al, '4'    
    je  opt_ordenar
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

    ; validar/ajustar longitud (1..40)
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

    ; DI = &NAMES[idx*40]
    mov ax, bx
    mov dx, ax
    shl ax, 5
    shl dx, 3
    add ax, dx              ; AX = idx*40
    mov di, offset NAMES
    add di, ax

    ; copiar nombre (len) y rellenar a 40 con 0
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
    shl bx, 1               ; *2
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

; ---------- Opcion 2: Mostrar ESTADISTICAS ----------
opt_mostrar:
    mov al, [COUNT]
    cmp al, 0
    je  no_datos

    mov dx, offset STATS_TTL
    call PrintStr

    ; THRESHOLD = 70 * 100000 (calcular una vez)
    mov ax, 70
    xor dx, dx
    mov cx, 5
thr_build:
    call Mul10_DXAX
    loop thr_build
    mov [TH_LO], ax
    mov [TH_HI], dx

    ; SUM=0 ; contadores = 0
    mov word ptr [SUM_LO], 0
    mov word ptr [SUM_HI], 0
    mov byte ptr [APROB_CNT], 0
    mov byte ptr [REPRO_CNT], 0

    ; inicializar con elemento 0
    mov di, 0
    mov ax, [NOTAS_LO+di]
    mov dx, [NOTAS_HI+di]
    mov [MAX_LO], ax
    mov [MAX_HI], dx
    mov [MIN_LO], ax
    mov [MIN_HI], dx
    mov byte ptr [IDX_MAX], 0
    mov byte ptr [IDX_MIN], 0

    ; SUM += nota0
    mov bx, [SUM_LO]
    add bx, ax
    mov [SUM_LO], bx
    mov bx, [SUM_HI]
    adc bx, dx
    mov [SUM_HI], bx

    ; contar aprobado/reprobado para nota0
    mov bx, [TH_HI]
    cmp dx, bx
    ja  first_aprob
    jb  first_reprob
    mov bx, [TH_LO]
    cmp ax, bx
    jae first_aprob
first_reprob:
    inc byte ptr [REPRO_CNT]
    jmp after_first_count
first_aprob:
    inc byte ptr [APROB_CNT]
after_first_count:

    ; i=1 ; di=2 (offset palabras)
    mov si, 1
    mov di, 2

stats_loop:
    mov bl, [COUNT]
    xor bh, bh
    cmp si, bx
    jae stats_done

    ; AX:DX = nota[i]
    mov ax, [NOTAS_LO+di]
    mov dx, [NOTAS_HI+di]

    ; SUM += nota[i]
    mov bx, [SUM_LO]
    add bx, ax
    mov [SUM_LO], bx
    mov bx, [SUM_HI]
    adc bx, dx
    mov [SUM_HI], bx

    ; MAX ?  (DX:AX > MAX_HI:MAX_LO)
    mov bx, [MAX_HI]
    cmp dx, bx
    ja  upd_max
    jb  chk_min
    mov bx, [MAX_LO]
    cmp ax, bx
    jbe chk_min
upd_max:
    mov [MAX_LO], ax
    mov [MAX_HI], dx
    mov ax, si
    mov [IDX_MAX], al

chk_min:
    ; MIN ?  (DX:AX < MIN_HI:MIN_LO)
    mov bx, [MIN_HI]
    cmp dx, bx
    jb  upd_min
    ja  count_aprep
    mov bx, [MIN_LO]
    cmp ax, bx
    jae count_aprep
upd_min:
    mov [MIN_LO], ax
    mov [MIN_HI], dx
    mov ax, si
    mov [IDX_MIN], al

count_aprep:
    ; contar aprobado/reprobado vs TH
    mov bx, [TH_HI]
    cmp dx, bx
    ja  cnt_ap
    jb  cnt_rep
    mov bx, [TH_LO]
    cmp ax, bx
    jae cnt_ap
cnt_rep:
    inc byte ptr [REPRO_CNT]
    jmp next_i
cnt_ap:
    inc byte ptr [APROB_CNT]

next_i:
    add di, 2
    inc si
    jmp stats_loop

stats_done:
    ; PROMEDIO = SUM / COUNT  (32 / 8)
    mov ax, [SUM_LO]
    mov dx, [SUM_HI]
    mov [VAL_LO], ax
    mov [VAL_HI], dx
    mov bl, [COUNT]
    call DivValByU8

    mov dx, offset LBL_PROM
    call PrintStr
    call PrintScaled32
    call PrintCRLF

    ; ====== Aprobados ======
    mov dx, offset LBL_APROB
    call PrintStr
    mov al, [APROB_CNT]
    call PrintDec8
    mov dx, offset TXT_DE
    call PrintStr
    mov al, [COUNT]
    call PrintDec8
    mov dx, offset TXT_ARROW
    call PrintStr

    ; VAL = (APROB_CNT * 10,000,000) / COUNT
    mov word ptr [VAL_LO], 0
    mov word ptr [VAL_HI], 0
    mov cl, [APROB_CNT]
build_ap_percent:
    cmp cl, 0
    je  end_build_ap_percent
    mov ax, [VAL_LO]
    add ax, 09680h
    mov [VAL_LO], ax
    mov ax, [VAL_HI]
    adc ax, 0098h
    mov [VAL_HI], ax
    dec cl
    jmp build_ap_percent
end_build_ap_percent:
    mov bl, [COUNT]
    call DivValByU8
    call PrintScaled32
    mov dl, '%'
    mov ah, 02h
    int 21h
    call PrintCRLF

    ; ====== Reprobados ======
    mov dx, offset LBL_REPRO
    call PrintStr
    mov al, [REPRO_CNT]
    call PrintDec8
    mov dx, offset TXT_DE
    call PrintStr
    mov al, [COUNT]
    call PrintDec8
    mov dx, offset TXT_ARROW
    call PrintStr

    mov word ptr [VAL_LO], 0
    mov word ptr [VAL_HI], 0
    mov cl, [REPRO_CNT]
build_rep_percent:
    cmp cl, 0
    je  end_build_rep_percent
    mov ax, [VAL_LO]
    add ax, 09680h
    mov [VAL_LO], ax
    mov ax, [VAL_HI]
    adc ax, 0098h
    mov [VAL_HI], ax
    dec cl
    jmp build_rep_percent
end_build_rep_percent:
    mov bl, [COUNT]
    call DivValByU8
    call PrintScaled32
    mov dl, '%'
    mov ah, 02h
    int 21h
    call PrintCRLF

    ; ===== Mostrar MAX =====
    mov dx, offset LBL_MAX
    call PrintStr

    xor si, si
    mov al, [IDX_MAX]
    cbw
    mov si, ax

    mov dx, offset IDX_LBL
    call PrintStr
    mov ax, si
    call PrintDec16

    mov dl, ' '
    mov ah, 02h
    int 21h
    int 21h

    mov ax, si
    mov dx, ax
    shl ax, 5
    shl dx, 3
    add ax, dx
    mov bx, offset NAMES
    add bx, ax

    mov cl, [NAME_LEN+si]
    mov ch, 0
    jcxz max_pad_name
max_print_name:
    mov dl, [bx]
    mov ah, 02h
    int 21h
    inc bx
    loop max_print_name
max_pad_name:
    mov al, [NAME_LEN+si]
    xor ah, ah
    mov cx, NAME_W
    sub cx, ax
    jcxz max_after_name_spaces
    mov dl, ' '
    mov ah, 02h
max_name_space_loop:
    int 21h
    loop max_name_space_loop
max_after_name_spaces:
    mov dl, ' '
    mov ah, 02h
    int 21h
    int 21h

    mov ax, [MAX_LO]
    mov dx, [MAX_HI]
    mov [VAL_LO], ax
    mov [VAL_HI], dx
    call PrintScaled32
    call PrintCRLF

    ; ===== Mostrar MIN =====
    mov dx, offset LBL_MIN
    call PrintStr

    xor si, si
    mov al, [IDX_MIN]
    cbw
    mov si, ax

    mov dx, offset IDX_LBL
    call PrintStr
    mov ax, si
    call PrintDec16

    mov dl, ' '
    mov ah, 02h
    int 21h
    int 21h

    mov ax, si
    mov dx, ax
    shl ax, 5
    shl dx, 3
    add ax, dx
    mov bx, offset NAMES
    add bx, ax

    mov cl, [NAME_LEN+si]
    mov ch, 0
    jcxz min_pad_name
min_print_name:
    mov dl, [bx]
    mov ah, 02h
    int 21h
    inc bx
    loop min_print_name
min_pad_name:
    mov al, [NAME_LEN+si]
    xor ah, ah
    mov cx, NAME_W
    sub cx, ax
    jcxz min_after_name_spaces
    mov dl, ' '
    mov ah, 02h
min_name_space_loop:
    int 21h
    loop min_name_space_loop
min_after_name_spaces:
    mov dl, ' '
    mov ah, 02h
    int 21h
    int 21h

    mov ax, [MIN_LO]
    mov dx, [MIN_HI]
    mov [VAL_LO], ax
    mov [VAL_HI], dx
    call PrintScaled32
    call PrintCRLF

    jmp main_menu

; ---------- Opcion 3: Buscar por indice ----------
opt_buscar:
    mov al, [COUNT]
    cmp al, 0
    je  no_datos

    mov dx, offset MSG_IDX1
    call PrintStr
    mov al, [COUNT]
    dec al
    call PrintDec8
    mov dx, offset MSG_IDX2
    call PrintStr

    mov dx, offset NOTE_BUF
    mov ah, 0Ah
    int 21h
    call PrintCRLF

    mov si, offset NOTE_BUF
    mov cl, [si+1]
    cmp cl, 0
    je  buscar_inval
    add si, 2
    xor ax, ax

buscar_parse_loop:
    mov bl, [si]
    cmp bl, '0'
    jb  buscar_inval
    cmp bl, '9'
    ja  buscar_inval
    shl ax, 1
    mov dx, ax
    shl ax, 2
    add ax, dx
    sub bl, '0'
    xor bh, bh
    add ax, bx
    inc si
    dec cl
    jnz buscar_parse_loop

    mov bl, [COUNT]
    xor bh, bh
    cmp ax, bx
    jae buscar_inval

    mov si, ax

    mov dx, offset IDX_LBL
    call PrintStr
    mov ax, si
    call PrintDec16

    mov dl, ' '
    mov ah, 02h
    int 21h
    int 21h

    mov ax, si
    mov dx, ax
    shl ax, 5
    shl dx, 3
    add ax, dx
    mov bx, offset NAMES
    add bx, ax

    mov cl, [NAME_LEN+si]
    mov ch, 0
    jcxz buscar_pad_name
buscar_print_name:
    mov dl, [bx]
    mov ah, 02h
    int 21h
    inc bx
    loop buscar_print_name
buscar_pad_name:
    mov al, [NAME_LEN+si]
    xor ah, ah
    mov cx, NAME_W
    sub cx, ax
    jcxz buscar_after_name_spaces
    mov dl, ' '
    mov ah, 02h
buscar_name_space_loop:
    int 21h
    loop buscar_name_space_loop
buscar_after_name_spaces:
    mov dl, ' '
    mov ah, 02h
    int 21h
    int 21h

    mov di, si
    shl di, 1
    mov ax, [NOTAS_LO+di]
    mov dx, [NOTAS_HI+di]
    mov [VAL_LO], ax
    mov [VAL_HI], dx
    call PrintScaled32
    call PrintCRLF
    jmp main_menu

buscar_inval:
    mov dx, offset INVMSG
    call PrintStr
    jmp main_menu

; ---------- Opcion 4: Ordenar ----------
opt_ordenar:
    mov al, [COUNT]
    cmp al, 0
    je  no_datos

    ; mostrar submenu
    call PrintCRLF
    mov dx, offset ORD_MENU
    call PrintStr

    mov ah, 01h
    int 21h

    cmp al, '1'
    je  ordenar_asc
    cmp al, '2'
    je  ordenar_desc
    cmp al, '3'
    je  main_menu
    jmp opt_ordenar

ordenar_asc:
    mov al, 0          ; 0 = ascendente
    call BubbleSort
    mov dx, offset SORTMSG_ASC
    call PrintStr
    call ShowTable      ; mostrar tabla ordenada
    jmp main_menu

ordenar_desc:
    mov al, 1          ; 1 = descendente
    call BubbleSort
    mov dx, offset SORTMSG_DESC
    call PrintStr
    call ShowTable      ; mostrar tabla ordenada
    jmp main_menu

; ---------- Salir ----------
bye:
    mov ax, 4C00h
    int 21h

; ===================== UTILIDADES DE IMPRESION =====================
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

; ===================== 32-BIT Y FORMATO x100000 =====================
Mul10_DXAX proc near           ; (DX:AX) = (DX:AX) * 10
    push bx
    push cx
    mov bx, ax
    mov cx, dx
    ; x2 en TMP
    mov ax, bx
    mov dx, cx
    shl ax, 1
    rcl dx, 1
    mov [TMP_LO], ax
    mov [TMP_HI], dx
    ; x8 en (DX:AX)
    mov ax, bx
    mov dx, cx
    shl ax, 1
    rcl dx, 1
    shl ax, 1
    rcl dx, 1
    shl ax, 1
    rcl dx, 1
    ; x8 + x2
    add ax, [TMP_LO]
    adc dx, [TMP_HI]
    pop cx
    pop bx
    ret
Mul10_DXAX endp

DivMod10_Val proc near          ; VAL /= 10, resto -> AL
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

PrintScaled32 proc near         ; imprime VAL como entero.fffff
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

; ===================== DIVISION 32/8 =====================
DivValByU8 PROC NEAR           ; VAL_HI:VAL_LO / BL -> VAL_HI:VAL_LO
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov ax, [VAL_LO]
    mov dx, [VAL_HI]
    xor si, si
    mov word ptr [Q_LO], 0
    mov word ptr [Q_HI], 0
    xor bh, bh
    mov cx, 32
dv_loop:
    shl si, 1
    test dx, 8000h
    jz  dv_no_inj
    inc si
dv_no_inj:
    shl ax, 1
    rcl dx, 1
    shl word ptr [Q_LO], 1
    rcl word ptr [Q_HI], 1
    mov di, si
    cmp si, bx
    jb  dv_no_sub
    sub si, bx
    inc word ptr [Q_LO]
    jnz dv_after_add
    inc word ptr [Q_HI]
dv_after_add:
    jmp dv_after_cmp
dv_no_sub:
    mov si, di
dv_after_cmp:
    loop dv_loop
    mov ax, [Q_LO]
    mov dx, [Q_HI]
    mov [VAL_LO], ax
    mov [VAL_HI], dx
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DivValByU8 ENDP

; ===================== PARSER DE NOTA =====================
ParseNota proc near             ; 0..100 con hasta 5 decimales -> VAL=x100000
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
    add si, 2
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
    cmp byte ptr [ANYDIG], 0
    je  p_err
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

; ===================== BUBBLE SORT =====================
; Ordena NOTAS_HI/LO y NAMES (con NAME_LEN) según modo
; AL = 0 -> ASCENDENTE (menor a mayor)
; AL = 1 -> DESCENDENTE (mayor a menor)

BubbleSort proc near
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    ; Guardar modo de ordenamiento
    mov [SORT_MODE], al

    mov bl, [COUNT]
    cmp bl, 1
    jbe bs_done
    xor bh, bh
    mov bp, bx
    dec bp              ; outer passes = N-1

bs_outer:
    mov cx, bp          ; comparaciones de esta pasada
    mov si, 0           ; índice j

bs_inner:
    cmp cx, 0
    je  bs_after_inner

    ; --- calcular offsets en palabras ---
    mov bx, si
    shl bx, 1           ; BX = j*2
    mov di, bx
    add di, 2           ; DI = (j+1)*2

    ; --- Comparar las notas completas (HI:LO) ---
    mov ax, [NOTAS_HI+bx]    ; AX = nota[j].HI
    mov dx, [NOTAS_HI+di]    ; DX = nota[j+1].HI

    ; Primero comparar parte alta
    cmp ax, dx
    ja nota_j_mayor
    jb nota_j_menor
    
    ; Si parte alta es igual, comparar parte baja
    mov ax, [NOTAS_LO+bx]    ; AX = nota[j].LO
    mov dx, [NOTAS_LO+di]    ; DX = nota[j+1].LO
    cmp ax, dx
    ja nota_j_mayor
    jb nota_j_menor
    jmp bs_no_swap          ; son iguales, no swap

nota_j_mayor:
    ; nota[j] > nota[j+1]
    mov al, [SORT_MODE]
    cmp al, 0
    je bs_do_swap       ; ASCENDENTE: swap si j > j+1
    jmp bs_no_swap      ; DESCENDENTE: no swap si j > j+1

nota_j_menor:
    ; nota[j] < nota[j+1]
    mov al, [SORT_MODE]
    cmp al, 0
    je bs_no_swap       ; ASCENDENTE: no swap si j < j+1
    jmp bs_do_swap      ; DESCENDENTE: swap si j < j+1

bs_no_swap:
    inc si
    dec cx
    jmp bs_inner

bs_do_swap:
    ; ---- swap NOTAS (LO/HI) ----
    mov ax, [NOTAS_LO+bx]
    mov dx, [NOTAS_HI+bx]
    xchg ax, [NOTAS_LO+di]
    xchg dx, [NOTAS_HI+di]
    mov [NOTAS_LO+bx], ax
    mov [NOTAS_HI+bx], dx

    ; ---- swap NAME_LEN ----
    mov al, [NAME_LEN+si]
    mov dl, [NAME_LEN+si+1]
    mov [NAME_LEN+si], dl
    mov [NAME_LEN+si+1], al

    ; ---- swap NAMES (40 bytes) ----
    ; Calcular offsets en bytes
    push cx
    push si
    
    mov ax, si
    mov dx, ax
    shl ax, 5           ; ax = si * 32
    shl dx, 3           ; dx = si * 8  
    add ax, dx          ; AX = si*40
    
    mov dx, si
    inc dx
    mov bx, dx
    shl dx, 5           ; dx = (si+1) * 32
    shl bx, 3           ; bx = (si+1) * 8
    add dx, bx          ; DX = (si+1)*40

    ; TMP_NAME <- NAMES[j]
    mov si, offset NAMES
    add si, ax
    mov di, offset TMP_NAME
    mov cx, NAME_W
    cld
    rep movsb

    ; NAMES[j] <- NAMES[j+1]
    mov si, offset NAMES
    add si, dx
    mov di, offset NAMES
    add di, ax
    mov cx, NAME_W
    cld
    rep movsb

    ; NAMES[j+1] <- TMP_NAME
    mov si, offset TMP_NAME
    mov di, offset NAMES
    add di, dx
    mov cx, NAME_W
    cld
    rep movsb

    pop si
    pop cx

    ; --- siguiente par ---
    inc si
    dec cx
    jmp bs_inner

bs_after_inner:
    dec bp
    jnz bs_outer

bs_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
BubbleSort endp

SORT_MODE    db 0    ; 0 = ascendente, 1 = descendente

; ===================== MOSTRAR TABLA =====================
ShowTable proc near
    mov al, [COUNT]
    cmp al, 0
    je  st_no_datos

    mov dx, offset HDR
    call PrintStr

    mov si, 0          ; índice del alumno
    mov di, 0          ; offset en NOTAS (palabras)

show_loop:
    mov bl, [COUNT]
    xor bh, bh
    cmp si, bx
    jae show_done

    ; imprimir índice
    mov dx, offset IDX_LBL
    call PrintStr
    mov ax, si
    call PrintDec16
    mov dl, ' '
    mov ah, 02h
    int 21h
    int 21h

    ; imprimir nombre
    mov ax, si
    mov dx, ax
    shl ax, 5
    shl dx, 3
    add ax, dx
    mov bx, offset NAMES
    add bx, ax
    mov cl, [NAME_LEN+si]
    mov ch, 0
    jcxz name_pad
print_name:
    mov dl, [bx]
    mov ah, 02h
    int 21h
    inc bx
    loop print_name
name_pad:
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
    mov dl, ' '
    mov ah, 02h
    int 21h
    int 21h

    ; imprimir nota
    mov ax, [NOTAS_LO+di]
    mov dx, [NOTAS_HI+di]
    mov [VAL_LO], ax
    mov [VAL_HI], dx
    call PrintScaled32
    call PrintCRLF

    add di, 2
    inc si
    jmp show_loop

show_done:
    ret

st_no_datos:
    mov dx, offset NODATA
    call PrintStr
    ret
ShowTable endp