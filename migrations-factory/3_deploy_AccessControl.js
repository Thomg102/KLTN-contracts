/** @format */

const AccessControl = artifacts.require("AccessControl");
const fs = require("fs");
const path = require("path");
const configFile = "../config/config.json";
const config = require(configFile);

module.exports = async (deployer, network, accounts) => {
	console.log();
	console.log("Deploying AccessControl ...");
	await deployer.deploy(AccessControl);
	const AccessControlInstance = await AccessControl.deployed();

	config.ACCESS_CONTROLL_ADDRESS = AccessControlInstance.address;
	fs.writeFileSync(path.join(__dirname, configFile), JSON.stringify(config, null, 2));
};
