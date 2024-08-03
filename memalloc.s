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

    movq original_brk, %rdi
    movq %rdi, current_brk
    call brk

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

    movq %rbx, %rdi
    addq $9, %rdi
    call sbrk
    addq $9, current_brk
    addq %rbx, current_brk
    movb $1, (%rax)
    addq $1, %rax
    movq %rbx, (%rax)
    jmp _RETURN_MEMORY_ALLOC_F

    _TRY_BREAK_BLOCK:
    movq %rax, %r12
    movq %rax, %rdi
    movq %rbx, %rsi
    call try_break_block
    movq %r12, %rax
    movb $1, (%rax)
    addq $1, %rax

    _RETURN_MEMORY_ALLOC_F:
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

# Tenta quebrar o bloco apontando por %rdi em dois, 
# um com %rsi bytes e outro com o restante.
try_break_block:
    pushq %rbp
    movq %rsp, %rbp
    
    addq $1, %rdi
    movq (%rdi), %r9
    subq %rsi, %r9
    # Verifica se o bloco eh grande o suficiente
    cmpq $9, %r9
    jle _END_TRY_BREAK_BLOCK
    movq %rsi, (%rdi)
    addq $8, %rdi
    addq %rsi, %rdi
    movb $0, (%rdi)
    addq $1, %rdi
    subq $9, %r9
    movq %r9, (%rdi)
    _END_TRY_BREAK_BLOCK:
    popq %rbp
    ret
