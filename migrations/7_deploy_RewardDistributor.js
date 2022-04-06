n/** @format */

const RewardDistributor = artifacts.require("RewardDistributor");

const fs = require("fs");
const path = require("path");
const configFile = "../config/config.json";
const config = require(configFile);

module.exports = async (deployer, network, accounts) => {
	console.log();
	console.log("Deploying RewardDistributor ...");
	await deployer.deploy(RewardDistributor, config.UIT_TOKEN_ADDRESS, "0x0000000000000000000000000000000000000000");
	const RewardDistributorInstance = await RewardDistributor.deployed();

	config.REWARD_DISTRIBUTOR_ADDRESS = RewardDistributorInstance.address;
	fs.writeFileSync(path.join(__dirname, configFile), JSON.stringify(config, null, 2));
};
