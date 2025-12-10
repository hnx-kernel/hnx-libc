# HNX libc - Custom C Standard Library for HNX Kernel

A minimal, custom C standard library implementation for the HNX hybrid kernel (aarch64 architecture), designed to provide basic POSIX-compatible system call interfaces.

## 🎯 Project Status

**Current Status**: Foundation established, basic system calls working
- ✅ Cross-compilation toolchain configured
- ✅ Core type system and headers in place
- ✅ Basic system call interface (`write`, `read`, `open`)
- ✅ Test framework operational
- ✅ Build system with automatic source discovery
- 🔄 More system calls in development

## 📁 Project Structure

```
hnx-libc/
├── Makefile              # Build system with automatic source discovery
├── test.sh              # Comprehensive test and verification script
├── linker.ld            # Linker script for aarch64 targets
├── include/             # HNX-specific headers
│   └── sys/
│       └── syscall.h    # System call number definitions
├── sysroot/             # Musl-derived headers (reference)
│   └── aarch64/include/
│       ├── bits/        # Architecture-specific definitions
│       └── ...          # Standard C headers
└── src/
    ├── syscall/         # System call implementation layer
    │   ├── aarch64/     # Architecture-specific assembly
    │   │   └── syscall.S # System call entry point (svc instruction)
    │   └── generic/     # Architecture-agnostic C wrappers
    │       ├── write.c  # write() implementation
    │       ├── read.c   # read() implementation
    │       └── open.c   # open() implementation
    └── tests/           # Test programs
        ├── hello.c      # Basic "Hello World" test
        └── hello.elf    # Linked test executable (generated)
```

## 🛠️ Build Requirements

- **Compiler**: Clang/LLVM with aarch64 support
- **Linker**: rust-lld (or ld.lld)
- **Tools**: llvm-ar, llvm-ranlib
- **System**: macOS/Linux with standard build tools

## 🚀 Quick Start

### 1. Clone and Setup
```bash
# Clone libc project
git clone https://github.com/hnx-kernel/hnx-libc.git
cd hnx-libc
```

### 2. Build the Library
```bash
make clean
make
```
This will produce `libhnxc.a` containing the compiled C library.

### 3. Run Tests
```bash
./test.sh
```
The test script will:
- Verify toolchain availability
- Build the library
- Compile a test program
- Link everything together
- Validate the output ELF file

## 🔧 Implementation Details

### System Call Interface
The library uses a direct mapping to HNX kernel system calls:
- `__NR_write` = 1 (maps to HNX's `SYS_WRITE`)
- `__NR_read` = 2 (maps to HNX's `SYS_READ`)
- `__NR_open` = 3 (maps to HNX's `SYS_OPEN`)
- ... and 450+ more reserved positions for future expansion

### Architecture Support
- **Target**: `aarch64-hnx-ohlink` (custom target triple)
- **ABI**: Follows ARM AAPCS64 calling convention
- **System Call Mechanism**: `svc #0` instruction with parameters in registers x0-x5

### Header Organization
- **sysroot/**: Musl-derived headers for standard C types and definitions
- **include/**: HNX-specific headers with system call mappings
- **Automatic inclusion**: Build system handles include paths automatically

## 📚 Adding New System Calls

### 1. Add System Call Number
Edit `include/sys/syscall.h` to define the new system call number:
```c
#define __NR_newcall 14  // Next available number
```

### 2. Implement the Wrapper
Create `src/syscall/generic/newcall.c`:
```c
#include <sys/syscall.h>

extern long __syscall(long number, ...);

int newcall(int arg1, const char* arg2) {
    return (int)__syscall(__NR_newcall, arg1, arg2);
}
```

### 3. Update the Kernel
Ensure your HNX kernel has a corresponding handler in `kernel/src/syscall/mod.rs`:
```rust
pub const SYS_NEWCALL: u32 = 14;

pub fn dispatch(num: u32, a0: usize, a1: usize, a2: usize, a3: usize) -> isize {
    match num {
        SYS_NEWCALL => {
            // Implementation here
        }
        // ... other system calls
    }
}
```

### 4. Rebuild and Test
```bash
make clean && make
./test.sh
```

## 🧪 Testing with HNX Kernel

### Manual Integration Test
```rust
// In your HNX kernel code
extern "C" {
    fn write(fd: i32, buf: *const u8, count: usize) -> isize;
}

fn test_libc_integration() {
    let msg = b"Testing libc from kernel!\n";
    unsafe {
        let result = write(1, msg.as_ptr(), msg.len());
        println!("write() returned: {}", result);
    }
}
```

### QEMU Test (if supported)
```bash
qemu-system-aarch64 -machine virt -cpu cortex-a72 \
    -kernel tests/hello.elf -nographic
```

## 🔄 Development Workflow

1. **Add new system call** to kernel and update `syscall.h`
2. **Implement wrapper** in `src/syscall/generic/`
3. **Run test suite**: `./test.sh`
4. **Integrate with kernel** and verify functionality
5. **Iterate** based on testing results

## 🐛 Troubleshooting

### Common Issues

1. **`undefined symbol: __syscall`**
   - Ensure `src/syscall/aarch64/syscall.S` exists and is compiled
   - Check `llvm-ar t libhnxc.a` includes `syscall.o`

2. **Type errors during compilation**
   - Verify `sysroot/aarch64/include/bits/` contains all necessary headers
   - Check include paths in `Makefile`

3. **Linking failures**
   - Ensure linker script (`linker.ld`) has correct memory addresses
   - Verify entry point (`_start`) is defined in test programs

4. **Toolchain issues**
   - Confirm `clang --target=aarch64-unknown-none` works
   - Check `rust-lld --version` shows expected version

### Debug Commands
```bash
# Check library contents
llvm-ar t libhnxc.a
llvm-nm libhnxc.a

# Inspect generated binaries
file tests/hello.elf
llvm-objdump -d tests/hello.elf | head -30

# Manual compilation test
clang --target=aarch64-unknown-none -nostdlib -ffreestanding \
    -I./sysroot/aarch64/include -c test.c -o test.o
```

## 📈 Future Development

### Short-term Goals
- [ ] Implement `exit()` system call wrapper
- [ ] Add `close()` and basic file operations
- [ ] Implement `brk()` for memory management
- [ ] Create more comprehensive test suite

### Medium-term Goals
- [ ] Add `stdio` functions (`printf`, `fopen`, etc.)
- [ ] Implement `stdlib` functions (`malloc`, `free`, etc.)
- [ ] Add `string` and `ctype` functions
- [ ] Support for dynamic linking

### Long-term Vision
- [ ] Full POSIX compliance for essential functions
- [ ] Thread-local storage support
- [ ] C++ runtime support
- [ ] Optimization for HNX kernel specific features

## 📄 License
This project is licensed under the [MIT License](LICENSE).

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit a pull request

## 🙏 Acknowledgments

- **Musl libc** for clean header structure reference
- **FreeBSD libc** for system call interface patterns
- **LLVM/Clang** project for excellent cross-compilation tools
- **HNX Kernel** team for the underlying kernel infrastructure

---

*This library is under active development for the HNX kernel project. APIs may change as the kernel evolves.*