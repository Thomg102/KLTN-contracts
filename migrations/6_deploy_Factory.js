/** @format */

const Factory = artifacts.require("Factory");
const MissionFactory = artifacts.require("MissionFactory");
const ScholarshipFactory = artifacts.require("ScholarshipFactory");
const SubjectFactory = artifacts.require("SubjectFactory");
const TuitionFactory = artifacts.require("TuitionFactory");

const fs = require("fs");
const path = require("path");
const configFile = "../config/config.json";
const config = require(configFile);

module.exports = async (deployer, network, accounts) => {
	console.log();
	console.log("Deploying MissionFactory ...");
	await deployer.deploy(MissionFactory);
	const MissionFactoryInstance = await MissionFactory.deployed();

	console.log();
	console.log("Deploying ScholarshipFactory ...");
	await deployer.deploy(ScholarshipFactory);
	const ScholarshipFactoryInstance = await ScholarshipFactory.deployed();

	console.log();
	console.log("Deploying SubjectFactory ...");
	await deployer.deploy(SubjectFactory);
	const SubjectFactoryInstance = await SubjectFactory.deployed();

	console.log();
	console.log("Deploying TuitionFactory ...");
	await deployer.deploy(TuitionFactory);
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
