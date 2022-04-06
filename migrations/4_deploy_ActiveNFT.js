/** @format */

const ActiveNFT = artifacts.require("ActiveNFT");
const fs = require("fs");
const path = require("path");
const configFile = "../config/config.json";
const config = require(configFile);

module.exports = async (deployer, network, accounts) => {
	console.log();
	console.log("Deploying ActiveNFT ...");
	await deployer.deploy(ActiveNFT, config.ACCESS_CONTROLL_ADDRESS, config.UIT_NFT_TOKEN_ADDRESS);
	const ActiveNFTInstance = await ActiveNFT.deployed();

	config.ACTIVE_NFT_ADDRESS = ActiveNFTInstance.address;
	fs.writeFileSync(path.join(__dirname, configFile), JSON.stringify(config, null, 2));
};
