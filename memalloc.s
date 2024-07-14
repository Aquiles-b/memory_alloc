.section .data
.global original_brk
.global current_brk

original_brk: .quad 0
current_brk: .quad 0

.section .text
.global setup_brk
.global dismiss_brk
.global memory_alloc

setup_brk:
    pushq %rbp
    movq %rsp, %rbp
    movq $0, %rdi
    call sbrk
    movq %rax, original_brk
    movq %rax, current_brk
    popq %rbp
    ret

dismiss_brk:

memory_alloc:
    pushq %rbp
    movq %rsp, %rbp

    call find_biggest_block_free

; Encontra o maior bloco livre. Retorna 0 se nao houver nenhum bloco livre.
find_biggest_block_free:
    pushq %rbp
    movq %rsp, %rbp

    movq original_brk, %r8
    movq $0, %rax
    movq $0, %r11
    _FIND_WORST_FIT:
        ; Verifica se chegou ao final da lista
        cmpq %r8, current_brk
        je _END_FIND_BLOCK_FREE

        movb (%r8), %r9b
        addq $8, %r8
        movq (%r8), %r10
        cmpb $0, %r9b
        jne _NEXT_BLOCK
        ; Verifica se ja existe um bloco livre maior
        cmpq $0, %rax
        je _SELECT_NEW_BIGGEST_BLOCK
        ; Verifica se o bloco livre eh o maior
        cmpq %r11, %r10
        jle _NEXT_BLOCK
        _SELECT_NEW_BIGGEST_BLOCK:
        movq %r8, %rax
        subq $8, %rax
        movq %r10, %r11
        _NEXT_BLOCK:
        ; Pula para o proximo bloco
        addq $r10, %r8
        jmp _FIND_WORST_FIT
    _END_FIND_BLOCK_FREE:
    popq %rbp
    ret
