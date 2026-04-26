# double.s: Assembly "Double a Number" Program

Reads an integer from stdin, doubles it, and prints `The double is: <result>`.

Written in x86-64 GAS (AT&T syntax) using raw Linux syscalls — no C runtime required.

---

## Files

| File | Description |
|------|-------------|
| `double.s` | Assembly source |
| `README.md` | This file |

---

## Requirements

| Tool | Purpose |
|------|---------|
| `as` | GNU Assembler (GAS) — already on GL server |
| `ld` | GNU Linker — already on GL server |

---

## Build & Run (GL Server)

### Step 1: Assemble
```bash
as -o double.o double.s
```

### Step 2: Link
```bash
ld -o double double.o
```

### Step 3: Run

**Option A: pipe input:**
```bash
echo "21" | ./double
```

**Option B: heredoc:**
```bash
./double <<< "42"
```

**Option C: interactive (type number, press Enter):**
```bash
./double
```

---

## Example Output

```
$ echo "21" | ./double
The double is: 42

$ echo "0" | ./double
The double is: 0

$ echo "100" | ./double
The double is: 200
```

---

## How It Works

| Step | What happens |
|------|-------------|
| `sys_read` (syscall 0) | Reads the number as a raw ASCII string from stdin |
| atoi loop | Parses ASCII digits into an integer held in `%rbx` |
| `shlq $1, %rbx` | Left-shifts by 1 bit — equivalent to multiplying by 2 |
| itoa loop | Divides by 10 repeatedly, building the result string right-to-left in a buffer |
| `sys_write` (syscall 1) | Writes the label, then the result string, to stdout |
| `sys_exit` (syscall 60) | Exits with code 0 |

---

## Notes

- Input must be a non-negative integer.
- Max safe input is roughly 4.6 × 10¹⁸ (fits in a 64-bit unsigned register).
- No external libraries are used; the binary uses only Linux kernel syscalls.
