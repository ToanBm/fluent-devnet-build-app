#!/bin/bash
BOLD=$(tput bold)
RESET=$(tput sgr0)
YELLOW=$(tput setaf 3)

# Logo
curl -s https://raw.githubusercontent.com/ToanBm/user-info/main/logo.sh | bash
sleep 3

print_command() {
  echo -e "${BOLD}${YELLOW}$1${RESET}"
}

# 1.0 System Updates and Installation of Required Tools
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
# Check version:
rustc --version
cargo --version

npm install dotenv

# 1.1 Set Up the Rust Project with gblend
print_command "Choose Rust"
cargo install gblend
gblend init

# 1.2 Write the Rust Smart Contract with Fluentbase SDK
mkdir src

cat <<'EOL' > src/lib.rs
#![cfg_attr(target_arch = "wasm32", no_std)]
extern crate alloc;

use alloc::string::{String, ToString};
use fluentbase_sdk::{
    basic_entrypoint,
    derive::{function_id, router, Contract},
    SharedAPI,
    U256,    // alloy Solidity type for uint256
    I256,    // alloy Solidity type for int256
    Address, // alloy Solidity type for address
    address, // alloy Solidity marco to define values for type Address
    Bytes,   // alloy Solidity type for bytes
    B256,    // alloy Solidity type for bytes32
    b256     // alloy Solidity marco to define values for type B256
};

#[derive(Contract)]
struct ROUTER<SDK> {
    sdk: SDK,
}

pub trait RouterAPI {
    // Make sure type interfaces are defined here or else there will be a compiler error.
    fn rustString(&self) -> String;
    fn rustUint256(&self) -> U256;
    fn rustInt256(&self) -> I256;
    fn rustAddress(&self) -> Address;
    fn rustBytes(&self) -> Bytes;
    fn rustBytes32(&self) -> B256;
    fn rustBool(&self) -> bool;
}

#[router(mode = "solidity")]
impl<SDK: SharedAPI> RouterAPI for ROUTER<SDK> {

    // ERC-20 with Fluent SDK example:
    // https://github.com/fluentlabs-xyz/fluentbase/blob/devel/examples/erc20/lib.rs

    #[function_id("rustString()")]
    fn rustString(&self) -> String {
        let string_test = "Hello".to_string();
        return string_test;
    }

    #[function_id("rustUint256()")]
    fn rustUint256(&self) -> U256 {
        let uint256_test = U256::from(10);
        return uint256_test;
    }

    #[function_id("rustInt256()")]
    fn rustInt256(&self) -> I256 {
        // Declare Signed variables in alloy.rs:
        // https://docs.rs/alloy-primitives/latest/alloy_primitives/struct.Signed.html#method.from_dec_str
        let int256_test = I256::unchecked_from(-10);
        return int256_test;
    }

    #[function_id("rustAddress()")]
    fn rustAddress(&self) -> Address {
        let address_test: Address = address!("d8da6bf26964af9d7eed9e03e53415d37aa96045"); // vitalik.eth 0xd8da6bf26964af9d7eed9e03e53415d37aa96045
        return address_test;
    }
    
    #[function_id("rustBytes()")]
    fn rustBytes(&self) -> Bytes {
        let bytes_test = Bytes::from("FLUENT");
        return bytes_test;
    }

    #[function_id("rustBytes32()")]
    fn rustBytes32(&self) -> B256 {
        let bytes256_test = b256!("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        return bytes256_test;
    }

    #[function_id("rustBool()")]
    fn rustBool(&self) -> bool {
        let bool_test = true;
        return bool_test;
    }

}

impl<SDK: SharedAPI> ROUTER<SDK> {
    fn deploy(&self) {
        // any custom deployment logic here
    }
}

basic_entrypoint!(ROUTER);
EOL

# 1.3 Optional Example Rust Cargo.toml file with Fluentbase SDK
rm Cargo.toml

cat <<'EOL' > Cargo.toml
[package]
edition = "2021"
name = "types_test"
version = "0.1.0"

[dependencies]
alloy-sol-types = {version = "0.7.4", default-features = false}
fluentbase-sdk = {git = "https://github.com/fluentlabs-xyz/fluentbase", default-features = false}

[lib]
crate-type = ["cdylib", "staticlib"] #For accessing the C lib
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
EOL

# 1.4 Build the Wasm Project
gblend build rust -r

# 2.1 Solidity Contract with Interface
mkdir contracts

cat <<'EOL' > contracts/FluentSdkRustTypesTest.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IFluentRust {
    // Make sure type interfaces are defined here or else there will be a compiler error.
    function rustString() external view returns (string memory);
    function rustUint256() external view returns (uint256);    
    function rustInt256() external view returns (int256);
    function rustAddress() external view returns (address);
    function rustBytes() external view returns (bytes memory);
    function rustBytes32() external view returns (bytes32);
    function rustBool() external view returns (bool);
}

contract FluentSdkRustTypesTest {
    
    IFluentRust public fluentRust;

    constructor(address FluentRustAddress) {
        fluentRust = IFluentRust(FluentRustAddress);
    }

    function getRustString() external view returns (string memory) {
        string memory rustString = fluentRust.rustString();
        return string(abi.encodePacked(rustString, " World"));
    }

    function getRustUint256() external view returns (uint256) {
        uint256 rustUint256 = fluentRust.rustUint256();
        return rustUint256;
    }

    function getRustInt256() external view returns (int256) {
        int256 rustInt256 = fluentRust.rustInt256();
        return rustInt256;
    }

    function getRustAddress() external view returns (address) {
        address rustAddress = fluentRust.rustAddress();
        return rustAddress;
    }

    function getRustBytes() external view returns (bytes memory) {
        bytes memory rustBytes = fluentRust.rustBytes();
        return rustBytes;
    }

    function getRustBytes32() external view returns (bytes32) {
        bytes32 rustBytes32 = fluentRust.rustBytes32();
        return rustBytes32;
    }

    function getRustBool() external view returns (bool) {
        bool rustBool = fluentRust.rustBool();
        return rustBool;
    }

}
EOL

# Create Environment Variables
echo "Create .env file..."

read -p "Enter your EVM wallet private key (without 0x): " PRIVATE_KEY
cat <<EOF > .env
PRIVATE_KEY=$PRIVATE_KEY
EOF

# 3.1 Deploy the Rust Contract with gblend
gblend deploy \
--private-key $PRIVATE_KEY \
--dev lib.wasm \
--gas-limit 3000000











