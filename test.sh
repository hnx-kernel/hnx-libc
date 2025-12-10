#!/bin/bash
# hnx-libc 测试脚本
# 用途：编译 libhnxc.a，创建测试程序并链接，验证工具链

set -e  # 遇到错误立即退出

echo "=== HNX libc 测试脚本 ==="
echo "当前目录: $(pwd)"
echo ""

# ==================== 1. 环境检查 ====================
echo "[1/5] 检查必要工具..."
command -v clang >/dev/null 2>&1 || { echo "错误: 未找到 clang"; exit 1; }
command -v rust-lld >/dev/null 2>&1 || { echo "错误: 未找到 rust-lld"; exit 1; }
command -v llvm-ar >/dev/null 2>&1 || { echo "错误: 未找到 llvm-ar"; exit 1; }

echo "✓ clang 版本: $(clang --version | head -1)"
echo "✓ rust-lld 版本: $(rust-lld --version 2>/dev/null || echo 'unknown')"
echo ""

# ==================== 2. 清理旧文件 ====================
echo "[2/5] 清理旧构建文件..."
make clean >/dev/null 2>&1 || true
rm -f tests/hello.o tests/hello.elf
echo "✓ 清理完成"
echo ""

# ==================== 3. 编译 libhnxc.a ====================
echo "[3/5] 编译 libhnxc.a..."
if ! make -j$(sysctl -n hw.ncpu 2>/dev/null || echo 4) 2>&1; then
    echo "✗ 编译失败"
    exit 1
fi

# 验证静态库是否生成
if [ ! -f "libhnxc.a" ]; then
    echo "✗ 未生成 libhnxc.a"
    exit 1
fi

# 显示库内容
echo "✓ 编译成功，库包含以下目标文件:"
llvm-ar t libhnxc.a 2>/dev/null || ar t libhnxc.a
echo ""

# ==================== 4. 创建测试程序 ====================
echo "[4/5] 编译测试程序..."

# 创建测试目录
mkdir -p tests

# 创建测试程序源码
cat > tests/hello.c << 'EOF'
#include <unistd.h>

void _start() {
    const char msg[] = "Hello from HNX libc!\n";
    write(1, msg, sizeof(msg) - 1);
    
    // 暂时死循环，等待实现 exit
    while (1) {}
}
EOF

# 编译测试程序
echo "编译 hello.c..."
clang --target=aarch64-unknown-none \
    -nostdlib -nostdinc -ffreestanding \
    -I./sysroot/aarch64/include \
    -c tests/hello.c -o tests/hello.o 2>&1 || {
    echo "✗ 编译测试程序失败"
    exit 1
}

# 验证目标文件
if [ ! -f "tests/hello.o" ]; then
    echo "✗ 未生成 tests/hello.o"
    exit 1
fi

echo "✓ 测试程序编译成功"
file tests/hello.o
echo ""

# ==================== 5. 链接测试程序 ====================
echo "[5/5] 链接测试程序..."

# 创建链接器脚本（如果需要）
if [ ! -f "linker.ld" ]; then
    cat > linker.ld << 'EOF'
/* 最小链接器脚本 for HNX */
ENTRY(_start)
SECTIONS
{
    . = 0x40080000;
    
    .text : {
        *(.text*)
    }
    
    .rodata : {
        *(.rodata*)
    }
    
    .data : {
        *(.data*)
    }
    
    .bss : {
        *(.bss*)
        *(COMMON*)
    }
    
    /DISCARD/ : {
        *(.comment*)
        *(.note*)
        *(.eh_frame*)
    }
}
EOF
    echo "已创建默认 linker.ld"
fi

# 尝试链接
echo "尝试链接..."
if rust-lld -flavor gnu -nostdlib -T linker.ld tests/hello.o libhnxc.a -o tests/hello.elf 2>&1; then
    echo "✓ 链接成功！"
else
    echo "使用默认链接器脚本失败，尝试无脚本链接..."
    if rust-lld -flavor gnu -nostdlib tests/hello.o libhnxc.a -o tests/hello.elf 2>&1; then
        echo "✓ 链接成功（无链接器脚本）"
    else
        echo "✗ 链接失败"
        exit 1
    fi
fi

# ==================== 6. 验证结果 ====================
echo ""
echo "=== 验证结果 ==="
echo "生成的文件:"
ls -lh tests/hello.elf 2>/dev/null || ls -lh tests/hello.o

echo ""
echo "ELF 文件信息:"
file tests/hello.elf 2>/dev/null || file tests/hello.o

echo ""
echo "入口点地址:"
if [ -f "tests/hello.elf" ]; then
    # 尝试多种 readelf 命令变体
    aarch64-elf-readelf -h tests/hello.elf 2>/dev/null | grep Entry || \
    aarch64-none-elf-readelf -h tests/hello.elf 2>/dev/null | grep Entry || \
    readelf -h tests/hello.elf 2>/dev/null | grep Entry || \
    echo "无法读取ELF头，请安装对应的工具链"
fi

echo ""
echo "反汇编前几行（验证代码生成）:"
if [ -f "tests/hello.elf" ]; then
    # 尝试多种 objdump 命令变体
    aarch64-elf-objdump -d tests/hello.elf 2>/dev/null | head -30 || \
    aarch64-none-elf-objdump -d tests/hello.elf 2>/dev/null | head -30 || \
    objdump -d tests/hello.elf 2>/dev/null | head -30 || \
    echo "无法反汇编，请安装对应的工具链"
fi

echo ""
echo "=== 测试完成 ==="
echo "下一步：将 tests/hello.elf 加载到你的 HNX 内核中运行"
echo "如果内核支持，可通过以下方式快速测试："
echo "  qemu-system-aarch64 -machine virt -cpu cortex-a72 -kernel tests/hello.elf -nographic"
echo ""