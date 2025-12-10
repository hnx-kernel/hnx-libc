# libc/Makefile (修正版)
CC = clang
AS = clang
AR = llvm-ar
RANLIB = llvm-ranlib
ARCH = aarch64

# 问题2: --target 参数格式错误
CFLAGS = \
	--target=$(ARCH)-unknown-none \
	-nostdlib \
	-nostdinc \
	-fno-builtin \
	-ffreestanding \
	-I./sysroot/$(ARCH)/include \
	-O2 \
	-mgeneral-regs-only \
	-fno-stack-protector \
	-Wall -Wextra

ASFLAGS = $(CFLAGS)

OBJS = src/syscall/$(ARCH)/syscall.o \
       src/syscall/generic/write.o

TARGET = libhnxc.a

all: $(TARGET)

$(TARGET): $(OBJS)
	$(AR) rcs $@ $(OBJS)
	$(RANLIB) $@  # 为静态库建立索引，有时是必须的

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(AS) $(ASFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean