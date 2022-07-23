/** @format */

const Factory = artifacts.require("FactoryProxy");
const MissionFactory = artifacts.require("MissionContract");
const ScholarshipFactory = artifacts.require("ScholarshipContract");
const SubjectFactory = artifacts.require("SubjectContract");
const TuitionFactory = artifacts.require("TuitionContract");

const fs = require("fs");
const path = require("path");
const configFile = "../config/config.json";
const config = require(configFile);

module.exports = async (deployer, network, accounts) => {
	console.log();
	console.log("Deploying MissionFactory ...");
	await deployer.deploy(MissionFactory, "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000");
	const MissionFactoryInstance = await MissionFactory.deployed();

	console.log();
	console.log("Deploying ScholarshipFactory ...");
	await deployer.deploy(ScholarshipFactory, "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000");
	const ScholarshipFactoryInstance = await ScholarshipFactory.deployed();

	console.log();
	console.log("Deploying SubjectFactory ...");
	await deployer.deploy(SubjectFactory, "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000");
	const SubjectFactoryInstance = await SubjectFactory.deployed();

	console.log();
	console.log("Deploying TuitionFactory ...");
	await deployer.deploy(TuitionFactory, "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000");
	const TuitionFactoryInstance = await TuitionFactory.deployed();

	console.log();
	console.log("Deploying Factory ...");
	await deployer.deploy(
		Factory,
		MissionFactoryInstance.address,
		SubjectFactoryInstance.address,
		ScholarshipFactoryInstance.address,
		TuitionFactoryInstance.address,
	);
	const FactoryInstance = await Factory.deployed();

	config.FACTORY_ADDRESS = FactoryInstance.address;
	fs.writeFileSync(path.join(__dirname, configFile), JSON.stringify(config, null, 2));
};
