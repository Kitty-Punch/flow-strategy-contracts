pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";
import {AtmAuction} from "../src/AtmAuction.sol";
import {BondAuction} from "../src/BondAuction.sol";
import {FlowStrategy} from "../src/FlowStrategy.sol";
import {FlowStrategyGovernor} from "../src/FlowStrategyGovernor.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {Deposit} from "../src/Deposit.sol";
import {ScriptBase} from "./ScriptBase.s.sol";

contract DeployScript is ScriptBase {
    struct GovernanceConfig {
        uint256 proposalThreshold;
        uint256 quorumPercentage;
        uint256 votingDelay;
        uint256 votingPeriod;
        address[] whitelist;
    }

    function _getWhitelist() internal pure returns (address[] memory) {
        address[] memory whitelist = new address[](3);
        whitelist[0] = address(0xcd05082a302b70c96fc83B95775a1CA753d9A789);
        whitelist[1] = address(0x14f2BeD0663D6cCC2E9AD070eC0b7F91fC07dEFB);
        whitelist[2] = address(0x30e19Cdc9008754AdDe6e874d4F5AAA94EBf934e);

        for (uint256 i = 0; i < whitelist.length; i++) {
            console2.log("whitelist[%d]: ", i, whitelist[i]);
        }
        return whitelist;
    }

    function _getGovernanceConfig() internal pure returns (GovernanceConfig memory) {
        GovernanceConfig memory governanceConfig;
        // The number of votes required in order for a voter to become a proposer.
        governanceConfig.proposalThreshold = 0;
        // The minimum number of cast voted required for a proposal to have a quorum.
        governanceConfig.quorumPercentage = 4;
        // Delay, between the proposal is created and the vote starts. The unit this duration is expressed in depends
        // on the clock (see ERC-6372) this contract uses.
        governanceConfig.votingDelay = 10 seconds;
        // Delay between the vote start and vote end. The unit this duration is expressed in depends on the clock (see ERC-6372) this contract uses.
        // NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
        // duration compared to the voting delay.
        governanceConfig.votingPeriod = 1 hours;
        governanceConfig.whitelist = _getWhitelist();
        return governanceConfig;
    }

    function run() public {
        uint256 privateKeyUint = vm.envUint("PRIVATE_KEY");
        address publicKey = vm.addr(privateKeyUint);
        string memory environment = "testnet"; // testnet or mainnet
        DeployConfig memory config = _decodeDeployConfig(environment);
        address operator = address(0xcd05082a302b70c96fc83B95775a1CA753d9A789);

        GovernanceConfig memory governanceConfig = _getGovernanceConfig();

        console2.log("Voting Delay:..................", governanceConfig.votingDelay);
        console2.log("Voting Period:.................", governanceConfig.votingPeriod);
        console2.log("Proposal Threshold:............", governanceConfig.proposalThreshold);
        console2.log("Quorum Percentage:.............", governanceConfig.quorumPercentage);
        console2.log("LST:...........................", config.lst);
        console2.log("USDC:..........................", config.usdc);
        console2.log("Deposit Cap:...................", config.depositCap);
        console2.log("Deposit Conversion Rate:.......", config.depositConversionRate);
        console2.log("Deposit Conversion Premium:....", config.depositConversionPremium);
        console2.log("Operator:......................", operator);
        console2.log("Executor:......................", publicKey);

        vm.startBroadcast(privateKeyUint);

        DeployedConfig memory deployedConfig = _deployContracts(config, governanceConfig, publicKey, operator);

        vm.stopBroadcast();

        _serializeDeployments(environment, deployedConfig);
    }

    function _deployContracts(
        DeployConfig memory config,
        GovernanceConfig memory governanceConfig,
        address deployer,
        address operator
    ) internal returns (DeployedConfig memory deployedConfig) {
        FlowStrategy flowStrategy = new FlowStrategy(deployer);
        FlowStrategyGovernor flowStrategyGovernor = new FlowStrategyGovernor(
            IVotes(address(flowStrategy)),
            governanceConfig.quorumPercentage,
            governanceConfig.votingDelay,
            governanceConfig.votingPeriod,
            governanceConfig.proposalThreshold
        );
        AtmAuction atmAuction = new AtmAuction(address(flowStrategy), address(flowStrategyGovernor), config.usdc);

        BondAuction bondAuction = new BondAuction(address(flowStrategy), address(flowStrategyGovernor), config.usdc);

        Deposit deposit = new Deposit(
            address(flowStrategyGovernor),
            address(flowStrategy),
            operator,
            config.depositConversionRate,
            config.depositConversionPremium,
            config.depositCap,
            config.whiteListEnabled
        );

        deposit.addWhitelist(governanceConfig.whitelist);

        flowStrategy.grantRoles(address(atmAuction), flowStrategy.MINTER_ROLE());
        flowStrategy.grantRoles(address(bondAuction), flowStrategy.MINTER_ROLE());
        flowStrategy.grantRoles(address(deposit), flowStrategy.MINTER_ROLE());
        flowStrategy.mint(deployer, 1);

        flowStrategy.transferOwnership(address(flowStrategyGovernor));

        deployedConfig.AtmAuction = address(atmAuction);
        deployedConfig.BondAuction = address(bondAuction);
        deployedConfig.Deposit = address(deposit);
        deployedConfig.DepositCap = config.depositCap;
        deployedConfig.DepositConversionPremium = config.depositConversionPremium;
        deployedConfig.DepositConversionRate = config.depositConversionRate;
        deployedConfig.FlowStrategy = address(flowStrategy);
        deployedConfig.FlowStrategyGovernor = address(flowStrategyGovernor);
        deployedConfig.lst = address(config.lst);
        deployedConfig.proposalThreshold = governanceConfig.proposalThreshold;
        deployedConfig.quorumPercentage = governanceConfig.quorumPercentage;
        deployedConfig.startBlock = block.number;
        deployedConfig.usdc = address(config.usdc);
        deployedConfig.votingDelay = governanceConfig.votingDelay;
        deployedConfig.votingPeriod = governanceConfig.votingPeriod;
        deployedConfig.operator = operator;
    }

    function _serializeDeployments(string memory environment, DeployedConfig memory deployedConfig)
        internal
        returns (string memory)
    {
        string memory deployments = "deployments";
        vm.serializeAddress(deployments, "FlowStrategy", deployedConfig.FlowStrategy);
        vm.serializeAddress(deployments, "FlowStrategyGovernor", deployedConfig.FlowStrategyGovernor);
        vm.serializeAddress(deployments, "AtmAuction", deployedConfig.AtmAuction);
        vm.serializeAddress(deployments, "BondAuction", deployedConfig.BondAuction);
        vm.serializeAddress(deployments, "Deposit", deployedConfig.Deposit);
        vm.serializeUint(deployments, "DepositCap", deployedConfig.DepositCap);
        vm.serializeUint(deployments, "DepositConversionRate", deployedConfig.DepositConversionRate);
        vm.serializeUint(deployments, "DepositConversionPremium", deployedConfig.DepositConversionPremium);
        vm.serializeUint(deployments, "startBlock", deployedConfig.startBlock);
        vm.serializeAddress(deployments, "lst", deployedConfig.lst);
        vm.serializeUint(deployments, "proposalThreshold", deployedConfig.proposalThreshold);
        vm.serializeUint(deployments, "quorumPercentage", deployedConfig.quorumPercentage);
        vm.serializeAddress(deployments, "usdc", deployedConfig.usdc);
        vm.serializeUint(deployments, "votingDelay", deployedConfig.votingDelay);
        vm.serializeAddress(deployments, "operator", deployedConfig.operator);
        string memory output = vm.serializeUint(deployments, "votingPeriod", deployedConfig.votingPeriod);
        _writeDeploymentsJson(environment, output);
        return output;
    }
}
