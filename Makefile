# libc/Makefile
CC = clang
AS = clang
AR = llvm-ar
RANLIB = llvm-ranlib
ARCH = aarch64

CFLAGS = \
	--target=$(ARCH)-unknown-none \
	-nostdlib \
	-nostdinc \
	-fno-builtin \
	-ffreestanding \
	-I./sysroot/$(ARCH)/include \
	-I./include \
	-O2 \
	-mgeneral-regs-only \
	-fno-stack-protector \
	-Wall -Wextra

ASFLAGS = $(CFLAGS)

# 自动发现源文件
C_SRCS = $(shell find src -name "*.c")
ASM_SRCS = $(shell find src -name "*.S")
OBJS = $(C_SRCS:.c=.o) $(ASM_SRCS:.S=.o)

TARGET = libhnxc.a

all: $(TARGET)

$(TARGET): $(OBJS)
	$(AR) rcs $@ $(OBJS)
	$(RANLIB) $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(AS) $(ASFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean