pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";  
import {Script} from "forge-std/Script.sol";
import {AtmAuction} from "../src/AtmAuction.sol";
import {BondAuction} from "../src/BondAuction.sol";
import {FlowStrategy} from "../src/FlowStrategy.sol";
import {FlowStrategyGovernor} from "../src/FlowStrategyGovernor.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {Deposit} from "../src/Deposit.sol";
contract Deploy is Script {

  struct Config {
    uint256 depositCap;
    uint256 depositConversionPremium;
    uint256 depositConversionRate;
    address depositSigner;
    address lst;
    uint256 proposalThreshold;
    uint256 quorumPercentage;
    address usdc;
    uint256 votingDelay;
    uint256 votingPeriod;
    bool whiteListEnabled;
  }

  function run() public { 

    string memory root = vm.projectRoot();
    string memory path = string.concat(root, "/testnet.deploy.config.json");
    string memory json = vm.readFile(path);
    bytes memory data = vm.parseJson(json);
    Config memory config = abi.decode(data, (Config));

    console2.log("votingDelay: ", config.votingDelay);
    console2.log("votingPeriod: ", config.votingPeriod);
    console2.log("proposalThreshold: ", config.proposalThreshold);
    console2.log("quorumPercentage: ", config.quorumPercentage);
    console2.log("lst: ", config.lst);
    console2.log("usdc: ", config.usdc);
    console2.log("depositCap: ", config.depositCap);
    console2.log("depositConversionRate: ", config.depositConversionRate);
    console2.log("depositConversionPremium: ", config.depositConversionPremium);
    console2.log("depositSigner: ", config.depositSigner);

    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
    address publicKey = vm.addr(vm.envUint("PRIVATE_KEY"));
    console2.log("publicKey: ", publicKey);

    FlowStrategy flowStrategy = new FlowStrategy(publicKey);
    FlowStrategyGovernor flowStrategyGovernor = new FlowStrategyGovernor(IVotes(address(flowStrategy)), config.quorumPercentage, config.votingDelay, config.votingPeriod, config.proposalThreshold);
    AtmAuction atmAuction = new AtmAuction(address(flowStrategy), address(flowStrategyGovernor), config.lst);
    BondAuction bondAuction = new BondAuction(address(flowStrategy), address(flowStrategyGovernor), config.usdc);
    Deposit deposit = new Deposit(address(flowStrategyGovernor), address(flowStrategy), config.depositSigner, config.depositConversionRate, config.depositConversionPremium, config.depositCap, config.whiteListEnabled);

    flowStrategy.grantRoles(address(atmAuction), flowStrategy.MINTER_ROLE());
    flowStrategy.grantRoles(address(bondAuction), flowStrategy.MINTER_ROLE());
    flowStrategy.grantRoles(address(deposit), flowStrategy.MINTER_ROLE());
    flowStrategy.mint(publicKey, 1);
    
    flowStrategy.transferOwnership(address(flowStrategyGovernor));

    vm.stopBroadcast();

    string memory deployments = "deployments";

    vm.serializeAddress(deployments, "FlowStrategy", address(flowStrategy));
    vm.serializeAddress(deployments, "FlowStrategyGovernor", address(flowStrategyGovernor));
    vm.serializeAddress(deployments, "AtmAuction", address(atmAuction));
    vm.serializeAddress(deployments, "BondAuction", address(bondAuction));
    vm.serializeAddress(deployments, "Deposit", address(deposit));
    vm.serializeUint(deployments, "DepositCap", config.depositCap);
    vm.serializeUint(deployments, "DepositConversionRate", config.depositConversionRate);
    vm.serializeUint(deployments, "DepositConversionPremium", config.depositConversionPremium);
    vm.serializeAddress(deployments, "DepositSigner", config.depositSigner);
    vm.serializeUint(deployments, "startBlock", block.number);
    vm.serializeAddress(deployments, "lst", config.lst);
    vm.serializeUint(deployments, "proposalThreshold", config.proposalThreshold);
    vm.serializeUint(deployments, "quorumPercentage", config.quorumPercentage);
    vm.serializeAddress(deployments, "usdc", config.usdc);
    vm.serializeUint(deployments, "votingDelay", config.votingDelay);
    string memory output = vm.serializeUint(deployments, "votingPeriod", config.votingPeriod);

    vm.writeJson(output, "./out/deployments.json");
  }
}