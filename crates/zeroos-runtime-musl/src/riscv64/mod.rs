mod bootstrap;

#[cfg(feature = "bootstrap")]
pub use bootstrap::bootstrap_impl::{__runtime_bootstrap, _fini, _init};
