#![cfg_attr(target_os = "none", no_std)]
#![no_main]

extern crate alloc;
use alloc::string::{String, ToString};

cfg_if::cfg_if! {
    if #[cfg(target_os = "none")] {
        use platform::println;
    } else {
        use std::println;

        // Force platform linkage to ensure musl's pthread functions are available
        // (needed by libgcc.a's unwind code for pthread_mutex_lock/unlock/once)
        #[allow(unused_imports)]
        use platform;
    }
}

fn int_to_string(n: i32) -> String {
    n.to_string()
}

/// Main entry point - works for both std and no_std modes.
#[no_mangle]
fn main() -> ! {
    debug::writeln!("[BOOT] main");
    let num = 42;
    let s = int_to_string(num);
    debug::writeln!("[BOOT] int_to_string({}) = {}", num, s);
    println!("int_to_string({}) = {}", num, s);
    debug::writeln!("[BOOT] Test PASSED!");
    platform::exit(0)
}
