#!/bin/bash

# Step 1: Install Hardhat and resolve dependency issues
echo "Installing Hardhat and resolving dependency conflicts..."
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers --legacy-peer-deps

# Step 2: Create a new Hardhat project with default settings
echo "Creating a new Hardhat project..."
npx hardhat init --javascript --yes

echo "Hardhat project setup complete!"

