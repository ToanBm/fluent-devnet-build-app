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
# Step 1: System Updates and Installation of Required Tools
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

# Step 2: Initialize Rust Project
print_command "Installing Rust Project..."
cargo new --lib greeting
cd greeting

print_command "Configure Rust Project..."
cat <<'EOL' > Cargo.toml
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
EOL

print_command "Writing Rust Smart Contract..."
cat <<'EOL' > src/lib.rs
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
EOL

print_command "Creating a Makefile..."
cat <<'EOL' > Makefile
.DEFAULT_GOAL := all

# Compilation flags
RUSTFLAGS := '-C link-arg=-zstack-size=131072 -C target-feature=+bulk-memory -C opt-level=z -C strip=symbols'

# Paths to the target WASM file and output directory
WASM_TARGET := ./target/wasm32-unknown-unknown/release/greeting.wasm
WASM_OUTPUT_DIR := bin
WASM_OUTPUT_FILE := $(WASM_OUTPUT_DIR)/greeting.wasm

# Commands
CARGO_BUILD := cargo build --release --target=wasm32-unknown-unknown --no-default-features
RM := rm -rf
MKDIR := mkdir -p
CP := cp

# Targets
all: build

build: prepare_output_dir
	@echo "Building the project..."
	RUSTFLAGS=$(RUSTFLAGS) $(CARGO_BUILD)

	@echo "Copying the wasm file to the output directory..."
	$(CP) $(WASM_TARGET) $(WASM_OUTPUT_FILE)

prepare_output_dir:
	@echo "Preparing the output directory..."
	$(RM) $(WASM_OUTPUT_DIR)
	$(MKDIR) $(WASM_OUTPUT_DIR)

.PHONY: all build prepare_output_dir
EOL

print_command "Building Wasm Project..."
make

# Step 3: Initialize Solidity Project
print_command "Creating Project Directory..."
cd ../
mkdir typescript-wasm-project && cd typescript-wasm-project
mkdir greeting && cd greeting
mkdir bin && cd ../../

cp /workspaces/codespaces-blank/greeting/target/wasm32-unknown-unknown/release/greeting.wasm /workspaces/codespaces-blank/typescript-wasm-project/greeting/bin/
npm init -y

print_command "Installing Dependencies..."
npm install --save-dev typescript ts-node hardhat hardhat-deploy ethers dotenv @nomicfoundation/hardhat-toolbox @typechain/ethers-v6 @typechain/hardhat @types/node
pnpm add ethers@^5.7.2 @nomiclabs/hardhat-ethers@2.0.6
pnpm install
npx hardhat

print_command "Updating Hardhat Configuration..."
cat <<'EOL' > hardhat.config.ts
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import * as dotenv from "dotenv";
import "./tasks/get-greeting"; 
import "@nomiclabs/hardhat-ethers"; 

dotenv.config();

const config: HardhatUserConfig = {
  defaultNetwork: "dev",
  networks: {
    dev: {
      url: process.env.RPC_URL || "https://rpc.dev.thefluent.xyz/",
      accounts: [process.env.DEPLOYER_PRIVATE_KEY || "your-private-key"],
      chainId: 20993,
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.24",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
};

export default config;
EOL

print_command "Updating Package..."
rm package.json

cat <<'EOL' > package.json
{
  "name": "blendedapp",
  "version": "1.0.0",
  "description": "Blended Hello, World",
  "main": "index.js",
  "scripts": {
    "compile": "npx hardhat compile",
    "deploy": "npx hardhat deploy"
  },
  "devDependencies": {
    "@nomicfoundation/hardhat-ethers": "^3.0.0",
    "@nomicfoundation/hardhat-toolbox": "^5.0.0",
    "@nomicfoundation/hardhat-verify": "^2.0.0",
    "@openzeppelin/contracts": "^5.0.2",
    "@typechain/ethers-v6": "^0.5.0",
    "@typechain/hardhat": "^9.0.0",
    "@types/node": "^20.12.12",
    "dotenv": "^16.4.5",
    "hardhat": "^2.22.4",
    "hardhat-deploy": "^0.12.4",
    "ts-node": "^10.9.2",
    "typescript": "^5.4.5"
  },
  "dependencies": {
    "ethers": "^6.12.2",
    "fs": "^0.0.1-security"
  }
}
EOL

# Create Environment Variables
echo "Create .env file..."

read -p "Enter your EVM wallet private key (without 0x): " DEPLOYER_PRIVATE_KEY
cat <<EOF > .env
DEPLOYER_PRIVATE_KEY=$DEPLOYER_PRIVATE_KEY
EOF

# Write Solidity Contracts


cat <<'EOL' > contracts/GreetingWithWorld.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IFluentGreeting.sol";

contract GreetingWithWorld {
    IFluentGreeting public fluentGreetingContract;

    constructor(address _fluentGreetingContractAddress) {
        fluentGreetingContract = IFluentGreeting(_fluentGreetingContractAddress);
    }

    function getGreeting() external view returns (string memory) {
        string memory greeting = fluentGreetingContract.greeting();
        return string(abi.encodePacked(greeting, ", World"));
    }
}
EOL

# Step 4: Deploy Both Contracts Using Hardhat
# Create the Deployment Script

mkdir deploy
cat <<'EOL' > deploy/01_deploy_contracts.ts
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import fs from "fs";
import crypto from "crypto";
import path from "path";
require("dotenv").config();

const DEPLOYER_PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY || "your-private-key";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, network } = hre;
  const { deploy, save, getOrNull } = deployments;
  const { deployer: deployerAddress } = await getNamedAccounts();

  console.log("deployerAddress", deployerAddress);

  // Deploying WASM Contract
  console.log("Deploying WASM contract...");
  const wasmBinaryPath = "./greeting/bin/greeting.wasm";
  const provider = new ethers.providers.JsonRpcProvider(network.config.url);
  const deployer = new ethers.Wallet(DEPLOYER_PRIVATE_KEY, provider);

  const fluentGreetingContractAddress = await deployWasmContract(wasmBinaryPath, deployer, provider, getOrNull, save);

  // Deploying Solidity Contract
  console.log("Deploying GreetingWithWorld contract...");
  const greetingWithWorld = await deploy("GreetingWithWorld", {
    from: deployerAddress,
    args: [fluentGreetingContractAddress],
    log: true,
  });

  console.log(`GreetingWithWorld contract deployed at: ${greetingWithWorld.address}`);
};

async function deployWasmContract(
  wasmBinaryPath: string,
  deployer: ethers.Wallet,
  provider: ethers.providers.JsonRpcProvider,
  getOrNull: any,
  save: any
) {
  const wasmBinary = fs.readFileSync(wasmBinaryPath);
  const wasmBinaryHash = crypto.createHash("sha256").update(wasmBinary).digest("hex");
  const artifactName = path.basename(wasmBinaryPath, ".wasm");
  const existingDeployment = await getOrNull(artifactName);

  if (existingDeployment && existingDeployment.metadata === wasmBinaryHash) {
    console.log("WASM contract bytecode has not changed. Skipping deployment.");
    console.log(`Existing contract address: ${existingDeployment.address}`);
    return existingDeployment.address;
  }

  const gasPrice = (await provider.getFeeData()).gasPrice;

  const transaction = {
    data: "0x" + wasmBinary.toString("hex"),
    gasLimit: 3000000,
    gasPrice: gasPrice,
  };

  const tx = await deployer.sendTransaction(transaction);
  const receipt = await tx.wait();

  if (receipt && receipt.contractAddress) {
    console.log(`WASM contract deployed at: ${receipt.contractAddress}`);

    const artifact = {
      abi: [],
      bytecode: "0x" + wasmBinary.toString("hex"),
      deployedBytecode: "0x" + wasmBinary.toString("hex"),
      metadata: wasmBinaryHash,
    };

    const deploymentData = {
      address: receipt.contractAddress,
      ...artifact,
    };

    await save(artifactName, deploymentData);
  } else {
    throw new Error("Failed to deploy WASM contract");
  }

  return receipt.contractAddress;
}

export default func;
func.tags = ["all"];
EOL

# Create Hardhat Task
mkdir tasks
cat <<'EOL' > tasks/get-greeting.ts
import { task } from "hardhat/config";
import { ethers } from "hardhat";

task("get-greeting", "Fetches the greeting from the deployed GreetingWithWorld contract")
  .addParam("contract", "The address of the deployed GreetingWithWorld contract")
  .setAction(async ({ contract }, hre) => {
    const GreetingWithWorld = await hre.ethers.getContractAt("GreetingWithWorld", contract);
    const greeting = await GreetingWithWorld.getGreeting();
    console.log("Greeting:", greeting);
  });
  EOL

  # Step 5: Compile and Deploy the Contracts
  pnpm hardhat compile
  
  pnpm hardhat deploy





















