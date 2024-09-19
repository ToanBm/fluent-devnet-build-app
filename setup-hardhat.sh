#!/bin/bash

# Step 1: Install Hardhat
echo "Installing Hardhat..."
npm install --save-dev hardhat

# Step 2: Create a new Hardhat project
echo "Creating a new Hardhat project..."
npx hardhat init --javascript --yes

# Optional: Install dependencies commonly used with Hardhat
echo "Installing common Hardhat plugins and dependencies..."
npm install --save-dev @nomiclabs/hardhat-ethers ethers @nomiclabs/hardhat-waffle @nomiclabs/hardhat-etherscan chai

echo "Hardhat project setup complete!"
