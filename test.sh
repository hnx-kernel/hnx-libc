#!/bin/bash
# hnx-libc test script
# Purpose: Build libhnxc.a, create and link test program, verify toolchain

set -e  # Exit on any error


echo "=== HNX libc Test Script ==="
echo "Working directory: $(pwd)"
echo ""

# ==================== 1. Toolchain Check ====================
echo "[1/6] Checking required tools..."
command -v clang >/dev/null 2>&1 || { echo "ERROR: clang not found"; exit 1; }
command -v rust-lld >/dev/null 2>&1 || { echo "ERROR: rust-lld not found"; exit 1; }
command -v llvm-ar >/dev/null 2>&1 || { echo "ERROR: llvm-ar not found"; exit 1; }
command -v find >/dev/null 2>&1 || { echo "ERROR: find command not found (needed for Makefile)"; exit 1; }

echo "✓ clang version: $(clang --version | head -1)"
echo "✓ rust-lld version: $(rust-lld --version 2>/dev/null || echo 'unknown')"
echo "✓ find version: $(find --version 2>/dev/null | head -1 || echo 'available')"
echo ""

# ==================== 2. Directory Structure Check ====================
echo "[2/6] Verifying directory structure..."
REQUIRED_DIRS=("src/syscall/aarch64" "src/syscall/generic" "include/sys" "tests")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    fi
done

REQUIRED_FILES=("src/syscall/aarch64/syscall.S" "src/syscall/generic/write.c" "include/sys/syscall.h")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "WARNING: $file not found"
    fi
done
echo "✓ Directory check completed"
echo ""

# ==================== 3. Clean Previous Builds ====================
echo "[3/6] Cleaning previous builds..."
make clean >/dev/null 2>&1 || true
rm -f tests/hello.o tests/hello.elf tests/linker.ld
echo "✓ Cleanup done"
echo ""

# ==================== 4. Build libhnxc.a ====================
echo "[4/6] Building libhnxc.a..."
echo "Finding source files..."
C_SRCS=$(find src -name "*.c" 2>/dev/null || echo "")
ASM_SRCS=$(find src -name "*.S" 2>/dev/null || echo "")

if [ -z "$C_SRCS" ] && [ -z "$ASM_SRCS" ]; then
    echo "ERROR: No source files found in src/"
    echo "Please ensure at least syscall.S and write.c exist"
    exit 1
fi

echo "C sources: $(echo "$C_SRCS" | wc -l) files"
echo "ASM sources: $(echo "$ASM_SRCS" | wc -l) files"

if ! make -j$(sysctl -n hw.ncpu 2>/dev/null || echo 4) 2>&1; then
    echo "ERROR: Build failed"
    echo "Last 10 lines of make output:"
    make 2>&1 | tail -10
    exit 1
fi

if [ ! -f "libhnxc.a" ]; then
    echo "ERROR: libhnxc.a not generated"
    exit 1
fi

echo "✓ Build successful, library contains:"
llvm-ar t libhnxc.a 2>/dev/null || ar t libhnxc.a
echo ""

# ==================== 5. Create and Build Test Program ====================
echo "[5/6] Building test program..."

cat > tests/hello.c << 'EOF'
#include <unistd.h>

void _start() {
    const char msg[] = "Hello from HNX libc!\n";
    write(1, msg, sizeof(msg) - 1);
    
    // TODO: Replace with exit() once implemented
    while (1) {}
}
EOF

echo "Compiling hello.c..."
clang --target=aarch64-unknown-none \
    -nostdlib -nostdinc -ffreestanding \
    -I./sysroot/aarch64/include \
    -I./include \
    -c tests/hello.c -o tests/hello.o 2>&1 || {
    echo "ERROR: Failed to compile test program"
    exit 1
}

if [ ! -f "tests/hello.o" ]; then
    echo "ERROR: tests/hello.o not generated"
    exit 1
fi

echo "✓ Test program compiled successfully"
file tests/hello.o
echo ""

# ==================== 6. Link Test Program ====================
echo "[6/6] Linking test program..."

if [ ! -f "linker.ld" ]; then
    cat > tests/linker.ld << 'EOF'
/* Minimal linker script for HNX */
ENTRY(_start)
SECTIONS
{
    . = 0x40080000;
    
    .text : {
        *(.text*)
        *(.text.*)
    }
    
    .rodata : {
        *(.rodata*)
        *(.rodata.*)
    }
    
    .data : {
        *(.data*)
        *(.data.*)
    }
    
    .bss : {
        *(.bss*)
        *(.bss.*)
        *(COMMON*)
    }
    
    /DISCARD/ : {
        *(.comment*)
        *(.note*)
        *(.eh_frame*)
        *(.eh_frame_hdr*)
    }
}
EOF
    LINKER_SCRIPT="tests/linker.ld"
    echo "Created default linker.ld in tests/"
else
    LINKER_SCRIPT="linker.ld"
    echo "Using existing linker.ld"
fi

echo "Linking with $LINKER_SCRIPT..."
if rust-lld -flavor gnu -nostdlib -T "$LINKER_SCRIPT" tests/hello.o libhnxc.a -o tests/hello.elf 2>&1; then
    echo "✓ Linking successful!"
else
    echo "First attempt failed, trying without linker script..."
    if rust-lld -flavor gnu -nostdlib tests/hello.o libhnxc.a -o tests/hello.elf 2>&1; then
        echo "✓ Linking successful (no linker script)"
    else
        echo "ERROR: Linking failed"
        echo "Last error:"
        rust-lld -flavor gnu -nostdlib tests/hello.o libhnxc.a -o tests/hello.elf 2>&1 | tail -5
        exit 1
    fi
fi

# ==================== 7. Verification ====================
echo ""
echo "=== Verification Results ==="
echo "Generated files:"
ls -lh tests/hello.elf tests/hello.o 2>/dev/null | grep -v "cannot access" || true

echo ""
echo "ELF file info:"
if [ -f "tests/hello.elf" ]; then
    file tests/hello.elf
    echo ""
    
    echo "Entry point address:"
    # Try multiple readelf variants
    if command -v readelf >/dev/null 2>&1; then
        readelf -h tests/hello.elf 2>/dev/null | grep Entry || true
    fi
    
    echo ""
    echo "Symbol table (first 10 entries):"
    if command -v llvm-nm >/dev/null 2>&1; then
        llvm-nm tests/hello.elf 2>/dev/null | head -10 || true
    elif command -v nm >/dev/null 2>&1; then
        nm tests/hello.elf 2>/dev/null | head -10 || true
    fi
    
    echo ""
    echo "Disassembly of _start (first 20 instructions):"
    if command -v llvm-objdump >/dev/null 2>&1; then
        llvm-objdump -d tests/hello.elf 2>/dev/null | grep -A 20 "<_start>:" || true
    elif command -v objdump >/dev/null 2>&1; then
        objdump -d tests/hello.elf 2>/dev/null | grep -A 20 "<_start>:" || true
    fi
else
    file tests/hello.o
fi

echo ""
echo "=== Test Completed Successfully ==="
echo "Next steps:"
echo "1. Load tests/hello.elf into your HNX kernel"
echo "2. Test QEMU: qemu-system-aarch64 -machine virt -cpu cortex-a72 -kernel tests/hello.elf -nographic"
echo "3. Add more system calls: read.c, open.c, exit.c"
echo "4. Run './test.sh' again to verify changes"
echo ""