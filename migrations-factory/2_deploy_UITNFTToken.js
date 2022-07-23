/** @format */

const UITNFTToken = artifacts.require("UITNFTToken");
const fs = require("fs");
const path = require("path");
const configFile = "../config/config.json";
const config = require(configFile);

module.exports = async (deployer, network, accounts) => {
	console.log();
	console.log("Deploying UITNFTToken ...");
	await deployer.deploy(UITNFTToken);
	const UITNFTTokenInstance = await UITNFTToken.deployed();

	config.UIT_NFT_TOKEN_ADDRESS = UITNFTTokenInstance.address;
	fs.writeFileSync(path.join(__dirname, configFile), JSON.stringify(config, null, 2));

	await UITNFTToken.deployed().then(async instance => {
		const accounts = await web3.eth.getAccounts();
		await instance.initialize("UIT NFT Token", "UITNFTToken", "This is URI", {from: accounts[0]});
		console.log("Initialize for UIT NFT Token successfully");
	});
};
