# 工具链配置
CROSS_COMPILE = aarch64-none-elf-
CC = $(CROSS_COMPILE)gcc
AR = $(CROSS_COMPILE)ar
RANLIB = $(CROSS_COMPILE)ranlib

# 目录
PICOLIBC_DIR = third_party/picolibc
SRC_DIR = src
BUILD_DIR = build
SYSROOT = sysroot

# 编译选项
CFLAGS = -ffreestanding -nostdlib -fno-builtin -fno-stack-protector
CFLAGS += -I$(SYSROOT)/usr/include -Iinclude
CFLAGS += -DPICOLIBC_INTERNAL -D_HAVE_LONG_DOUBLE -D_POSIX_MONOTONIC_CLOCK

# 目标
TARGET = libhnxc.a
LIBC_TARGET = $(SYSROOT)/usr/lib/libc.a
CRT_TARGETS = $(SYSROOT)/usr/lib/crt0.o

# 源文件
CRT_SRCS = $(wildcard src/crt/*.S src/crt/*.c)
SYSCALL_SRCS = $(wildcard src/syscall/**/*.c src/syscall/**/*.S)
ADAPTER_SRCS = $(wildcard src/picolibc-adapter/*.c)

# 构建规则
all: $(SYSROOT) $(LIBC_TARGET) $(TARGET)

# 配置 picolibc
$(SYSROOT)/usr/include:
	mkdir -p $(SYSROOT)/usr
	cd $(PICOLIBC_DIR) && \
	meson setup build \
		-Dprefix=/usr \
		-Dincludedir=include \
		-Dlibdir=lib \
		-Dspecsdir=none \
		-Dmultilib=false \
		-Dpicocrt=false \
		-Dthread-local-storage=false \
		-Dtarget-optspace=true \
		--cross-file scripts/cross-aarch64-none-elf.txt
	cd $(PICOLIBC_DIR) && ninja -C build
	cd $(PICOLIBC_DIR) && DESTDIR=$(abspath $(SYSROOT)) ninja -C build install

# 构建 HNX libc
$(TARGET): $(CRT_SRCS) $(SYSCALL_SRCS) $(ADAPTER_SRCS)
	$(CC) $(CFLAGS) -c $(CRT_SRCS) -o $(BUILD_DIR)/crt.o
	$(CC) $(CFLAGS) -c $(SYSCALL_SRCS) $(ADAPTER_SRCS) -o $(BUILD_DIR)/syscalls.o
	$(AR) rcs $@ $(BUILD_DIR)/*.o
	cp $@ $(SYSROOT)/usr/lib/

# 创建 sysroot 结构
$(SYSROOT):
	mkdir -p $(SYSROOT)/usr/lib
	mkdir -p $(SYSROOT)/usr/include
	mkdir -p $(BUILD_DIR)

# 测试
test: all
	$(CC) $(CFLAGS) -L$(SYSROOT)/usr/lib -I$(SYSROOT)/usr/include \
		tests/hello.c -lhnxc -o tests/hello.elf

clean:
	rm -rf $(BUILD_DIR) $(SYSROOT)/usr/lib/libhnxc.a
	cd $(PICOLIBC_DIR) && rm -rf build

.PHONY: all clean test