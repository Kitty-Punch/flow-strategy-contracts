pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";  
import {Script} from "forge-std/Script.sol";
import {AtmAuction} from "../src/AtmAuction.sol";
import {BondAuction} from "../src/BondAuction.sol";
import {FlowStrategy} from "../src/FlowStrategy.sol";
import {FlowStrategyGovernor} from "../src/FlowStrategyGovernor.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {Deposit} from "../src/Deposit.sol";
contract DeployScript is Script {

  struct Config {
    uint256 depositCap;
    uint256 depositConversionPremium;
    uint256 depositConversionRate;
    address lst;
    uint256 proposalThreshold;
    uint256 quorumPercentage;
    address usdc;
    uint256 votingDelay;
    uint256 votingPeriod;
    bool whiteListEnabled;
  }

  function _getWhitelist() internal returns (address[] memory) {
    address[] memory whitelist = new address[](3);
    whitelist[0] = address(0xcd05082a302b70c96fc83B95775a1CA753d9A789);
    whitelist[1] = address(0x14f2BeD0663D6cCC2E9AD070eC0b7F91fC07dEFB);
    whitelist[2] = address(0x30e19Cdc9008754AdDe6e874d4F5AAA94EBf934e);

    for (uint256 i = 0; i < whitelist.length; i++) {
      console2.log("whitelist[%d]: ", i, whitelist[i]);
    }
    return whitelist;
  }

  function _decodeConfig(string memory environment) internal returns (Config memory) {
    string memory path = string.concat(vm.projectRoot(), "/", environment, ".deploy.config.json");
    string memory json = vm.readFile(path);
    bytes memory data = vm.parseJson(json);
    Config memory config = abi.decode(data, (Config));
    return config;
  }

  function run() public { 
    string memory environment = "testnet"; // testnet or mainnet
    Config memory config = _decodeConfig(environment);
    address operator = address(0xcd05082a302b70c96fc83B95775a1CA753d9A789);
    address[] memory whitelist = _getWhitelist();

    console2.log("votingDelay: ", config.votingDelay);
    console2.log("votingPeriod: ", config.votingPeriod);
    console2.log("proposalThreshold: ", config.proposalThreshold);
    console2.log("quorumPercentage: ", config.quorumPercentage);
    console2.log("lst: ", config.lst);
    console2.log("usdc: ", config.usdc);
    console2.log("depositCap: ", config.depositCap);
    console2.log("depositConversionRate: ", config.depositConversionRate);
    console2.log("depositConversionPremium: ", config.depositConversionPremium);
    console2.log("operator: ", operator);
    // console2.log("whitelist: ", whitelist.length);
    
    address publicKey = vm.addr(vm.envUint("PRIVATE_KEY"));
    console2.log("publicKey: ", publicKey);
    // console2.log("balance: ", publicKey.balance);

    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

    FlowStrategy flowStrategy = new FlowStrategy(publicKey);
    FlowStrategyGovernor flowStrategyGovernor = new FlowStrategyGovernor(IVotes(address(flowStrategy)), config.quorumPercentage, config.votingDelay, config.votingPeriod, config.proposalThreshold);
    AtmAuction atmAuction = new AtmAuction(address(flowStrategy), address(flowStrategyGovernor), config.usdc);

    BondAuction bondAuction = new BondAuction(address(flowStrategy), address(flowStrategyGovernor), config.usdc);
    
    Deposit deposit = new Deposit(address(flowStrategyGovernor), address(flowStrategy), operator, config.depositConversionRate, config.depositConversionPremium, config.depositCap, config.whiteListEnabled);

    deposit.addWhitelist(whitelist);


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
    // vm.serializeAddress(deployments, "DepositOperator", config.operator);
    vm.serializeUint(deployments, "startBlock", block.number);
    vm.serializeAddress(deployments, "lst", config.lst);
    vm.serializeUint(deployments, "proposalThreshold", config.proposalThreshold);
    vm.serializeUint(deployments, "quorumPercentage", config.quorumPercentage);
    vm.serializeAddress(deployments, "usdc", config.usdc);
    vm.serializeUint(deployments, "votingDelay", config.votingDelay);
    string memory output = vm.serializeUint(deployments, "votingPeriod", config.votingPeriod);

    _writeJson(environment, output);
  }

  function _writeJson(string memory environment, string memory output) internal {
    string memory deploymentsPath = string.concat("./", environment, ".deployments.json");
    vm.writeJson(output, deploymentsPath);
  }
}
