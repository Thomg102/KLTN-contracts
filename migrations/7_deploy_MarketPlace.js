/** @format */

const Marketplace = artifacts.require("Marketplace");
const UITNFTToken = artifacts.require("UITNFTToken");
const fs = require("fs");
const path = require("path");
const configFile = "../config/config.json";
const config = require(configFile);

module.exports = async (deployer, network, accounts) => {
	console.log();
	console.log("Deploying Marketplace ...");
	await deployer.deploy(
		Marketplace,
		config.ACCESS_CONTROLL_ADDRESS,
		config.UIT_TOKEN_ADDRESS,
		config.UIT_NFT_TOKEN_ADDRESS,
		config.REWARD_DISTRIBUTOR_ADDRESS,
		config.ACTIVE_NFT_ADDRESS,
	);
	const MarketplaceInstance = await Marketplace.deployed();

	await UITNFTToken.deployed().then(async (instance) => {
		const accounts = await web3.eth.getAccounts();
		try {
			await instance.addOperator(MarketplaceInstance.address, { from: accounts[0] });
			
		} catch {
			
		}
		try {
			await instance.addOperator(config.ACTIVE_NFT_ADDRESS, { from: accounts[0] });
			
		} catch {
		
	});

	config.MARKETPLACE_ADDRESS = MarketplaceInstance.address;
	fs.writeFileSync(path.join(__dirname, configFile), JSON.stringify(config, null, 2));
};
