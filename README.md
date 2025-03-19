# Guide to Build a Blended App on Fluent Devnet
<img src="https://images.mirror-media.xyz/publication-images/_89lCC1I0m5JlMwv14wo3.png?height=360&width=720" width="700"/>
## Start...

- Faucet [Here](https://faucet.dev.gblend.xyz/)

- Explorer [Here](https://blockscout.dev.gblend.xyz/)

- Open [Github Codespace](https://github.com/codespaces)

- Paste the below command to Build a Blended App

## Automatic Setup
### 1. Clone the repository
```bash
git clone https://github.com/ToanBm/fluent-devnet-build-app.git && cd fluent-devnet-build-app
```
### 2. Run the setup script
```bash
chmod +x app.sh && ./app.sh
```


### Ps: Choose "Creat a TypeScrip Project" and enter 3 times.
![Picture](https://github.com/ToanBm/fluent-devnet-build-app/blob/main/hardhat.jpg)
## ---------------------------------Done!-----------------------------------------------
## Manual Setup
## Step 1: System Updates and Installation of Required Tools
### Update System Packages
```bash
sudo apt update
```
```bash
sudo apt upgrade -y
```
```bash
sudo apt install build-essential -y
```
# Node.js and npm Installation
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```
# pnpm Installation
```bash
npm install -g pnpm
```
### Rust and Cargo Installation
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
```bash
source $HOME/.cargo/env
```
```bash
rustup install nightly
rustup override set nightly
rustc --version
```
```bash
rustup target add wasm32-unknown-unknown
```
## Step 2: Initialize Rust Project

### Set Up Rust Project
```bash
cargo new --lib greeting
cd greeting
```
### Configure Rust Project
```bash
rm Cargo.toml && nano Cargo.toml
```
Edit file `Cargo.toml` as in the code below. 
(Ctrl + X, Y and Enter will do to save)
```bash
[package]
edition = "2021"
name = "greeting"
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
```

### Write Rust Smart Contract

```bash
rm src/lib.rs && nano src/lib.rs
```
Edit file `lib.rs` as in the code below. 
(Ctrl + X, Y and Enter will do to save)

```bash
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
```

### Create a Makefile

```bash
nano Makefile
```
Edit file `Makefile` as in the code below. 
(Ctrl + X, Y and Enter will do to save)

```bash
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
```

### Build Wasm Project
```bash
make
```
## Step 3: Initialize Solidity Project

### Create Project Directory
```bash
cd ../
mkdir typescript-wasm-project && cd typescript-wasm-project
mkdir greeting && cd greeting
mkdir bin && cd ../../
```
```bash
cp /workspaces/codespaces-blank/greeting/target/wasm32-unknown-unknown/release/greeting.wasm /workspaces/codespaces-blank/typescript-wasm-project/greeting/bin/
```
```bash
cd typescript-wasm-project
```
```bash
npm init -y
```
### Install Dependencies
```bash
npm install --save-dev typescript ts-node hardhat hardhat-deploy ethers dotenv @nomicfoundation/hardhat-toolbox @typechain/ethers-v6 @typechain/hardhat @types/node
pnpm add ethers@^5.7.2 @nomiclabs/hardhat-ethers@2.0.6
pnpm install
npx hardhat
```
After `npx hardhat` command, it will ask us for some information, enter it as in the image below

![hardhat2](https://github.com/kocality/fluent-devnet/assets/69348404/ba8d407c-6d61-4fac-b628-f170ba13e2cd)

## Configure TypeScript and Hardhat

### Update Hardhat Configuration

```bash
rm hardhat.config.ts && nano hardhat.config.ts
```
Edit file `hardhat.config.ts` as in the code below. 
(Ctrl + X, Y and Enter will do to save)

```bash
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
      {
        version: "0.8.27", // Added compatibility for 0.8.27
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
```

### Update Package

```bash
rm package.json && nano package.json
```
Edit file `hardhat.config.ts` as in the code below. 
(Ctrl + X, Y and Enter will do to save)

```bash
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
```

### Set Up Environment Variables
Here we will enter the private key. I used my Metamask wallet. Get ETH from [Fluent Devnet Faucet](https://faucet.dev.thefluent.xyz/) to the wallet will use.

Enter your private key where it says `your-private-key-here`.

```bash
nano .env
```

```bash
DEPLOYER_PRIVATE_KEY=your-private-key-here
```

![private](https://github.com/kocality/fluent-devnet/assets/69348404/767b2ce6-caf0-4885-8f28-77f2a50d6af0)


## Write Solidity Contracts
### Define the Interface
```bash
nano contracts/IFluentGreeting.sol
```
Edit file `IFluentGreeting.sol` as in the code below. 
(Ctrl + X, Y and Enter will do to save)

```bash
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFluentGreeting {
    function greeting() external view returns (string memory);
}
```

### Implement Greeting Contract
```bash
nano contracts/GreetingWithWorld.sol
```
Edit file `GreetingWithWorld.sol` as in the code below. 
(Ctrl + X, Y and Enter will do to save)

```bash
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
```

## Step 4: Deploy Both Contracts Using Hardhat
### Create the Deployment Script
This deployment script is responsible for deploying both the Rust smart contract (compiled to Wasm) and the Solidity smart contract.

```bash
mkdir deploy && nano deploy/01_deploy_contracts.ts
```
Edit file `01_deploy_contracts.ts` as in the code below. 
(Ctrl + X, Y and Enter will do to save)

```bash
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
```

### Create Hardhat Task
```bash
mkdir tasks && nano tasks/get-greeting.ts
```
Edit file `get-greeting.ts` as in the code below. 
(Ctrl + X, Y and Enter will do to save)

```bash
import { task } from "hardhat/config";
import { ethers } from "hardhat";

task("get-greeting", "Fetches the greeting from the deployed GreetingWithWorld contract")
  .addParam("contract", "The address of the deployed GreetingWithWorld contract")
  .setAction(async ({ contract }, hre) => {
    const GreetingWithWorld = await hre.ethers.getContractAt("GreetingWithWorld", contract);
    const greeting = await GreetingWithWorld.getGreeting();
    console.log("Greeting:", greeting);
  });
```

## Step 5: Compile and Deploy the Contracts
```bash
pnpm hardhat compile
```
```bash
pnpm hardhat deploy
``` 
If successful, you will see the result: GreetingWithWorld contract deployed at: 0x.....
Use the value 0x... for the command below.
![deploy](https://github.com/kocality/fluent-devnet/assets/69348404/65c39233-29cf-4110-afa1-13c1edbca9e7)

```bash
pnpm hardhat get-greeting --contract 0x.....
```

If you get the output you see below, it means it is done. You can search for tx through Explorer.

![son](https://github.com/kocality/fluent-devnet/assets/69348404/a83133f6-3ef3-44a8-8a88-d49beef76f1f)

 ## Thank you! 
 ### This article references Kocality's instructions.


