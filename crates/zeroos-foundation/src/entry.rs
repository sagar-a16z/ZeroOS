// Entry point for calling the user's main() function.
//
// `__main_entry` is a weak symbol so platforms/SDKs can override it with their own
// implementation if they have different main() signature requirements.
// Default implementation is `__default_main_entry`, following the same pattern as
// `_trap_handler` -> `_default_trap_handler` in arch-riscv.

use core::arch::global_asm;

cfg_if::cfg_if! {
    if #[cfg(feature = "libc-main")] {
        extern "C" {
            fn main(argc: i32, argv: *const *const u8, envp: *const *const u8) -> i32;
        }

        #[no_mangle]
        #[inline(never)]
        /// # Safety
        /// The caller must provide `argv` and `envp` pointers that are valid per the platform ABI
        /// (or null), and remain valid for the duration of the call.
        pub unsafe extern "C" fn __default_main_entry(argc: i32, argv: *const *const u8, envp: *const *const u8) -> i32 {
            main(argc, argv, envp)
        }
    } else {
        // Rust-style main (must call exit, never return)
        extern "Rust" {
            fn main() -> !;
        }

        #[no_mangle]
        #[inline(never)]
        pub extern "C" fn __default_main_entry(_argc: i32, _argv: *const *const u8, _envp: *const *const u8) -> i32 {
            debug::writeln!("[BOOT] __main_entry argc={} argv=0x{:x}", _argc, _argv as usize);

            unsafe {
                main()
                // Never returns - main() must call exit()
            }
        }
    }
}

// Define __main_entry as a weak alias to __default_main_entry.
// Platforms/SDKs can provide their own strong __main_entry to override this.
global_asm!(
    ".weak __main_entry",
    ".set __main_entry, __default_main_entry",
);
