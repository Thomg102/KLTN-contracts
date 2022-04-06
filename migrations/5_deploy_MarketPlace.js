/** @format */

const Marketplace = artifacts.require("Marketplace");
const fs = require("fs");
const path = require("path");
const configFile = "../config/config.json";
const config = require(configFile);

module.exports = async (deployer, network, accounts) => {
	console.log();
	console.log("Deploying Marketplace ...");
	await deployer.deploy(Marketplace, config.ACCESS_CONTROLL_ADDRESS, config.UIT_TOKEN_ADDRESS, config.UIT_NFT_TOKEN_ADDRESS);
	const MarketplaceInstance = await Marketplace.deployed();

	config.MARKETPLACE_ADDRESS = MarketplaceInstance.address;
	fs.writeFileSync(path.join(__dirname, configFile), JSON.stringify(config, null, 2));
};
