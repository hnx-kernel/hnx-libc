# libc/Makefile (修正版)
CC = clang
AS = clang
LD = rust-lld
AR = llvm-ar
RANLIB = llvm-ranlib

CFLAGS = \
	--target=aarch64-unknown-none \
	-nostdlib \
	-nostdinc \
	-fno-builtin \
	-ffreestanding \
	-I./include \
	-O2 \
	-mgeneral-regs-only \
	-fno-stack-protector \
	-Wall -Wextra

ASFLAGS = $(CFLAGS)

OBJS = src/syscall/aarch64/syscall.o \
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