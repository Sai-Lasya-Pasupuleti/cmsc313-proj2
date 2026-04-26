# =============================================================================
# double.s  –  Read a number from stdin, double it, print the result
#
# Target:   x86-64 Linux (UMBC GL server)
# Assembler: GAS (GNU Assembler, AT&T syntax)
#
# Assemble:  as -o double.o double.s
# Link:      ld -o double double.o
# Run:       echo "21" | ./double
#            ./double            (then type a number and press Enter)
# =============================================================================

    .section .data
msg:        .ascii "The double is: "
msg_len =   . - msg                 # compile-time length (no null byte counted)

    .section .bss
inbuf:      .space 32               # buffer for raw stdin input
outbuf:     .space 32               # buffer for ASCII-converted output

    .section .text
    .globl _start

_start:
    # ------------------------------------------------------------------
    # 1) Read from stdin  (sys_read, syscall #0)
    # ------------------------------------------------------------------
    movq    $0, %rax                # syscall: read
    movq    $0, %rdi                # fd:      stdin (0)
    leaq    inbuf(%rip), %rsi       # buffer address
    movq    $32, %rdx               # max bytes to read
    syscall

    # ------------------------------------------------------------------
    # 2) Parse ASCII digit string → integer in %rbx  (hand-rolled atoi)
    # ------------------------------------------------------------------
    leaq    inbuf(%rip), %rsi
    xorq    %rbx, %rbx              # rbx = 0  (running total)

.atoi_loop:
    movzbl  (%rsi), %eax            # load next byte, zero-extend into rax
    cmpb    $'0', %al               # below '0'? → done
    jl      .atoi_done
    cmpb    $'9', %al               # above '9'? → done
    jg      .atoi_done
    imulq   $10, %rbx               # shift accumulator left one decimal place
    andq    $0xFF, %rax             # keep only the low byte
    subq    $'0', %rax              # ASCII digit → numeric value (0-9)
    addq    %rax, %rbx              # add to accumulator
    incq    %rsi                    # advance to next character
    jmp     .atoi_loop

.atoi_done:

    # ------------------------------------------------------------------
    # 3) Double the number  (logical left-shift by 1  ≡  ×2)
    # ------------------------------------------------------------------
    shlq    $1, %rbx                # rbx = input × 2

    # ------------------------------------------------------------------
    # 4) Convert integer in %rbx → ASCII digits in outbuf
    #    Strategy: build the string right-to-left (last byte = '\n')
    # ------------------------------------------------------------------
    leaq    outbuf(%rip), %rdi
    addq    $31, %rdi               # point at the last byte of the buffer
    movb    $'\n', (%rdi)           # store newline terminator
    decq    %rdi

    movq    %rbx, %rax              # working copy of the doubled value

    cmpq    $0, %rax                # special case: value is exactly 0
    jne     .itoa_loop
    movb    $'0', (%rdi)
    decq    %rdi
    jmp     .itoa_done

.itoa_loop:                         # repeated divide-by-10; remainder → digit
    xorq    %rdx, %rdx              # zero rdx before divq (rdx:rax / rcx)
    movq    $10, %rcx
    divq    %rcx                    # rax = quotient,  rdx = remainder (0-9)
    addb    $'0', %dl               # remainder → ASCII digit
    movb    %dl, (%rdi)             # store digit (right-to-left)
    decq    %rdi
    testq   %rax, %rax              # more digits?
    jnz     .itoa_loop

.itoa_done:
    incq    %rdi                    # rdi now points to the FIRST digit character

    # Save start-of-number pointer and compute total length
    movq    %rdi, %r12              # r12 = start of numeric string
    leaq    outbuf(%rip), %rax
    addq    $32, %rax               # one-past-end of outbuf
    subq    %rdi, %rax              # length = end − start  (includes '\n')
    movq    %rax, %r13              # r13 = length of numeric string

    # ------------------------------------------------------------------
    # 5) Write "The double is: " to stdout  (sys_write, syscall #1)
    # ------------------------------------------------------------------
    movq    $1, %rax                # syscall: write
    movq    $1, %rdi                # fd:      stdout (1)
    leaq    msg(%rip), %rsi         # address of label string
    movq    $msg_len, %rdx          # length of label string
    syscall

    # ------------------------------------------------------------------
    # 6) Write the doubled number (+ newline) to stdout
    # ------------------------------------------------------------------
    movq    $1, %rax                # syscall: write
    movq    $1, %rdi                # fd:      stdout (1)
    movq    %r12, %rsi              # start of numeric string
    movq    %r13, %rdx              # length
    syscall

    # ------------------------------------------------------------------
    # 7) Exit cleanly  (sys_exit, syscall #60)
    # ------------------------------------------------------------------
    movq    $60, %rax               # syscall: exit
    xorq    %rdi, %rdi              # exit code 0
    syscall
