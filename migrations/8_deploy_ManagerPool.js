/** @format */

const ManagerPool = artifacts.require("ManagerPool");
const RewardDistributor = artifacts.require("RewardDistributor");

const fs = require("fs");
const path = require("path");
const configFile = "../config/config.json";
const config = require(configFile);

module.exports = async (deployer, network, accounts) => {
	console.log();
	console.log("Deploying ManagerPool ...");
	await deployer.deploy(ManagerPool, config.FACTORY_ADDRESS, config.ACCESS_CONTROLL_ADDRESS, config.REWARD_DISTRIBUTOR_ADDRESS);
	const ManagerPoolInstance = await ManagerPool.deployed();

	config.MANAGER_POOL_ADDRESS = ManagerPoolInstance.address;
	fs.writeFileSync(path.join(__dirname, configFile), JSON.stringify(config, null, 2));

	await RewardDistributor.deployed().then(async instance => {
		meta = instance;
		const accounts = await web3.eth.getAccounts();
		await meta.managerPool().then(async result => {
			console.log(result);
			if (result == config.POOL_ADDRESS) {
			} else {
				await meta.setManagerPoolPermission(config.MANAGER_POOL_ADDRESS, {from: accounts[0]});
				console.log("Set setManagerPoolPermission for RewardDistributor successful!");
			}
		});
	});
};
