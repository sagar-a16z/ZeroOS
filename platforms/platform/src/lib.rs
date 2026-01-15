#![cfg_attr(not(feature = "std"), no_std)]

use zeroos_macros::require_exactly_one_feature;

require_exactly_one_feature!("with-spike", "with-jolt");

#[cfg(feature = "with-spike")]
pub use spike_platform::*;

#[cfg(feature = "with-jolt")]
pub use jolt_platform::*;
