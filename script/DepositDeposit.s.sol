pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";  
import {Script} from "forge-std/Script.sol";
import {AtmAuction} from "../src/AtmAuction.sol";
import {BondAuction} from "../src/BondAuction.sol";
import {FlowStrategy} from "../src/FlowStrategy.sol";
import {FlowStrategyGovernor} from "../src/FlowStrategyGovernor.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {Deposit} from "../src/Deposit.sol";
contract DepositDepositScript is Script {

  struct DeployedConfig {
    address AtmAuction;
    address BondAuction;
    address Deposit;
    uint256 DepositCap;
    uint256 DepositConversionPremium;
    uint256 DepositConversionRate;
    address FlowStrategy;
    address FlowStrategyGovernor;
    address lst;
    uint256 proposalThreshold;
    uint256 quorumPercentage;
    uint256 startBlock;
    address usdc;
    uint256 votingDelay;
    uint256 votingPeriod;
  }

  function _printDeployedConfig(DeployedConfig memory config) internal pure {
    console2.log("AtmAuction: ", config.AtmAuction);
    console2.log("BondAuction: ", config.BondAuction);
    console2.log("Deposit: ", config.Deposit);
    console2.log("DepositCap: ", config.DepositCap);
    console2.log("DepositConversionPremium: ", config.DepositConversionPremium);
    console2.log("DepositConversionRate: ", config.DepositConversionRate);
    console2.log("FlowStrategy: ", config.FlowStrategy);
    console2.log("FlowStrategyGovernor: ", config.FlowStrategyGovernor);
    console2.log("lst: ", config.lst);
  }

  function _parseDeployedConfig(string memory network) internal returns (DeployedConfig memory) {
    string memory path = string.concat(vm.projectRoot(), "/", network, ".deployments.json");
    string memory json = vm.readFile(path);
    bytes memory data = vm.parseJson(json);
    DeployedConfig memory config = abi.decode(data, (DeployedConfig));
    _printDeployedConfig(config);
    return config;
  }

  function run() public { 
    string memory environment = "testnet"; // testnet or mainnet
    DeployedConfig memory config = _parseDeployedConfig(environment);

    uint256 amount = 1000 ether;

    Deposit deposit = Deposit(payable(config.Deposit));
    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address executor = vm.addr(privateKey);
    console2.log("Executor:         ", executor);
    console2.log("Executor balance: ", executor.balance);
    console2.log("DepositCap:       ", deposit.getDepositCap() / 1e18);

    vm.startBroadcast(privateKey);

    uint256 minted = deposit.deposit{value: amount}();
    
    vm.stopBroadcast();

    console2.log("Shares: ", minted / 1e18);
  }
}