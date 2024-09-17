#!/bin/bash

BOLD=$(tput bold)
RESET=$(tput sgr0)
YELLOW=$(tput setaf 3)
# Logo

echo     "*********************************************"
echo     "Githuh: https://github.com/ToanBm"
echo     "X: https://x.com/buiminhtoan1985"
echo -e "\e[0m"

print_command() {
  echo -e "${BOLD}${YELLOW}$1${RESET}"
}

print_command "Updating System Packages..."
sudo apt update
sudo apt upgrade -y
sudo apt install build-essential -y

print_command "Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
npm install -g pnpm

print_command "Installing Rust and Cargo..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"
rustup target add wasm32-unknown-unknown

print_command "Installing Rust Project..."
cargo new --lib greeting
cd greeting

print_command "Configure Rust Project..."
cat <<EOF > Cargo.toml
[package]
edition = "2021"
name = "greeting"
version = "0.1.0"

[dependencies]
alloy-sol-types = {version = "0.7.4", default-features = false}
fluentbase-sdk = {git = "https://github.com/fluentlabs-xyz/fluentbase", default-features = false , branch = "dev2"}

[lib]
crate-type = ["cdylib", "staticlib"] # For accessing the C lib
path = "src/lib.rs"

[profile.release]
lto = true
opt-level = 'z'
panic = "abort"
strip = true

[features]
default = []
std = [
  "fluentbase-sdk/std",
]
EOF

print_command "Writing Rust Smart Contract..."
cat <<EOF > src/lib.rs
#![cfg_attr(target_arch = "wasm32", no_std)]
extern crate alloc;
extern crate fluentbase_sdk;

use alloc::string::{String, ToString};
use fluentbase_sdk::{
    basic_entrypoint,
    derive::{router, signature},
    SharedAPI,
};

#[derive(Default)]
struct ROUTER;

pub trait RouterAPI {
    fn greeting<SDK: SharedAPI>(&self) -> String;
}

#[router(mode = "solidity")]
impl RouterAPI for ROUTER {
    #[signature("function greeting() external returns (string)")]
    fn greeting<SDK: SharedAPI>(&self) -> String {
        "Hello".to_string()
    }
}

impl ROUTER {
    fn deploy<SDK: SharedAPI>(&self) {
        // any custom deployment logic here
    }
}
basic_entrypoint!(ROUTER);
EOF

