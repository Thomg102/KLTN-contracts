/** @format */

const UITToken = artifacts.require("UITToken");
const fs = require("fs");
const path = require("path");
const configFile = "../config/config.json";
const config = require(configFile);

module.exports = async (deployer, network, accounts) => {
	console.log();
	console.log("Deploying UITToken ...");
	await deployer.deploy(UITToken);
	const UITTokenInstance = await UITToken.deployed();

	config.UIT_TOKEN_ADDRESS = UITTokenInstance.address;
	fs.writeFileSync(path.join(__dirname, configFile), JSON.stringify(config, null, 2));
};
