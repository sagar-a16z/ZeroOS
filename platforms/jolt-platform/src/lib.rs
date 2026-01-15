//! Jolt zkVM Platform for ZeroOS
//!
//! This platform integrates ZeroOS with the Jolt RISC-V zkVM.
//!
//! ## Key Differences from Spike Platform
//!
//! 1. **Communication**: Uses ECALL-based I/O instead of HTIF
//! 2. **Exit**: For no-std uses `j .` (infinite loop), for std uses SYS_EXIT syscall
//! 3. **CSR Handling**: Privileged CSR operations delegated via ECALL
//! 4. **Tracing**: All application code is traced for ZK proof generation

#![cfg_attr(not(feature = "std"), no_std)]

mod boot;
pub mod ecall;

extern crate zeroos;

// jolt_print, jolt_println, println, eprintln are exported via #[macro_export] in ecall.rs

// Platform ABI symbols:
// - Mandatory:
//   - `__platform_bootstrap()` (in `boot.rs`): platform init hook called by jolt-sdk boot.
//   - `platform_exit(..)`: used by `foundation::kfn::kexit` / platform `exit()`.
// - Optional:
//   - `__debug_write(..)`: only required when the `debug` crate is enabled/linked.
//   - `jolt_syscall(..)`: only for std mode (os-linux feature) to route syscalls.

cfg_if::cfg_if! {
    if #[cfg(feature = "std")] {
        pub use std::{eprintln, println};

        pub fn exit(code: i32) -> ! {
            std::process::exit(code)
        }
    } else {
        // println and eprintln are macros exported via #[macro_export]
        pub use ecall::putchar;

        pub fn exit(code: i32) -> ! {
            platform_exit(code)
        }

        #[cfg(all(feature = "memory", target_os = "none"))]
        #[global_allocator]
        static ALLOCATOR: zeroos::alloc::System = zeroos::alloc::System;

        #[cfg(target_os = "none")]
        #[panic_handler]
        fn panic(info: &core::panic::PanicInfo) -> ! {
            eprintln!("PANIC: {}", info);
            exit(1)
        }
    }
}

/// Exit the program.
///
/// For std mode (with os-linux): Uses SYS_EXIT syscall which is handled by the
/// trap handler and routed through ZeroOS's syscall infrastructure.
///
/// For no-std mode: Enters an infinite loop (`j .`) which the Jolt emulator
/// detects via PC stall (prev_pc == pc) and treats as clean termination.
#[no_mangle]
pub extern "C" fn platform_exit(_code: i32) -> ! {
    cfg_if::cfg_if! {
        if #[cfg(feature = "os-linux")] {
            // std mode: use SYS_EXIT syscall, handled by trap handler
            const SYS_EXIT: usize = 93;
            unsafe {
                core::arch::asm!(
                    "ecall",
                    in("a7") SYS_EXIT,
                    in("a0") _code,
                    options(noreturn)
                );
            }
        } else {
            // no-std mode: infinite loop for clean termination
            // The Jolt emulator detects this via PC stall (prev_pc == pc)
            unsafe {
                core::arch::asm!(
                    "j .",
                    options(noreturn)
                );
            }
        }
    }
}

#[no_mangle]
/// # Safety
/// - `msg` must be either null (in which case nothing is written) or a valid pointer to `len`
///   bytes of readable memory.
pub unsafe extern "C" fn __debug_write(msg: *const u8, len: usize) {
    if !msg.is_null() && len > 0 {
        let slice = core::slice::from_raw_parts(msg, len);
        for &byte in slice {
            ecall::putchar(byte);
        }
    }
}

/// Syscall handler for Jolt guests.
///
/// This function is called by jolt-sdk's trap_handler to route syscalls
/// through ZeroOS's Linux syscall infrastructure. The syscall dispatch
/// is proven as part of the guest execution.
///
/// # Arguments
/// * `a0`-`a5` - Syscall arguments
/// * `nr` - Syscall number
///
/// # Returns
/// The syscall return value (negative values indicate errors)
#[cfg(feature = "os-linux")]
#[no_mangle]
pub extern "C" fn jolt_syscall(
    a0: usize,
    a1: usize,
    a2: usize,
    a3: usize,
    a4: usize,
    a5: usize,
    nr: usize,
) -> isize {
    zeroos::os::linux::linux_handle(a0, a1, a2, a3, a4, a5, nr)
}
