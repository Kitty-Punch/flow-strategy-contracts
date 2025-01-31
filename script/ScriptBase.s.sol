pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";

abstract contract ScriptBase is Script {
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
        address operator;
    }

    struct DeployConfig {
        uint256 depositCap;
        uint256 depositConversionPremium;
        uint256 depositConversionRate;
        address lst;
        address usdc;
        bool whiteListEnabled;
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

    function _parseDeployedConfig(string memory network) internal view returns (DeployedConfig memory) {
        string memory path = string.concat(vm.projectRoot(), "/", network, ".deployments.json");
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);
        DeployedConfig memory config = abi.decode(data, (DeployedConfig));
        _printDeployedConfig(config);
        return config;
    }

    function _decodeDeployConfig(string memory environment) internal view returns (DeployConfig memory) {
        string memory path = string.concat(vm.projectRoot(), "/", environment, ".deploy.config.json");
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);
        DeployConfig memory config = abi.decode(data, (DeployConfig));
        return config;
    }

    function _writeDeploymentsJson(string memory environment, string memory output) internal {
        string memory deploymentsPath = string.concat("./", environment, ".deployments.json");
        vm.writeJson(output, deploymentsPath);
    }
}
