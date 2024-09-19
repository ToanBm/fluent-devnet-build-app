#!/bin/bash

sudo apt-get update && sudo apt get upgrade -y
clear

echo "Installing dependencies..."
npm install --save-dev hardhat
npm install dotenv
npm install @swisstronik/utils
npm install @openzeppelin/hardhat-upgrades
npm install @openzeppelin/contracts
npm install @nomicfoundation/hardhat-toolbox
echo "Installation completed."

echo "Creating a Hardhat project..."
npx hardhat

rm -f contracts/Lock.sol
