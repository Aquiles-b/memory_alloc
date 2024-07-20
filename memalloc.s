.section .data
.global original_brk
.global current_brk

original_brk: .quad 0
current_brk: .quad 0

.section .text
.global setup_brk
.global dismiss_brk
.global memory_free
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
    pushq %rbp
    movq %rsp, %rbp
    movq original_brk, %r8
    movq %r8, current_brk
    popq %rbp
    ret

memory_free:
    pushq %rbp
    movq %rsp, %rbp
    subq $9, %rdi
    movb $0, (%rdi)

    popq %rbp
    ret

memory_alloc:
    pushq %rbp
    movq %rsp, %rbp

    movq %rdi, %rbx
    call find_biggest_block_free
    cmpq $0, %rax
    jne _TRY_BREAK_BLOCK

    call sbrk
    jmp _VALIDATE_BLOCK

    _TRY_BREAK_BLOCK:


    _VALIDATE_BLOCK:
    movb $1, (%rax)
    addq $1, %rax
    movq %rbx, (%rax)
    addq $8, %rax

    popq %rbp
    ret

# Retorna o endereco do maior bloco livre >= %rdi.
# Retorna 0 se nao houver nenhum.
find_biggest_block_free:
    pushq %rbp
    movq %rsp, %rbp

    movq original_brk, %r8
    movq $0, %rax
    movq $0, %r11
    _FIND_WORST_FIT_LOOP:
        # Verifica se chegou ao final da lista
        cmpq %r8, current_brk
        je _END_FIND_WORST_FIT_LOOP

        movb (%r8), %r9b
        addq $1, %r8
        movq (%r8), %r10
        cmpb $0, %r9b
        jne _NEXT_BLOCK
        # Verifica se o bloco é maior ou igual a requisicao
        cmpq %rdi, %r10
        jl _NEXT_BLOCK
        # Verifica se o bloco livre eh maior que o bloco anterior
        cmpq %r11, %r10
        jle _NEXT_BLOCK
        _SELECT_NEW_BIGGEST_BLOCK:
        movq %r8, %rax
        subq $1, %rax
        movq %r10, %r11
        _NEXT_BLOCK:
        # Pula para o proximo bloco
        addq $8, %r8
        addq %r10, %r8
        jmp _FIND_WORST_FIT_LOOP
    _END_FIND_WORST_FIT_LOOP:
    popq %rbp
    ret
