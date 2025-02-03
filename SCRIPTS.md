# Scripts

RPC URL:
https://mainnet.evm.nodes.onflow.org/
https://testnet.evm.nodes.onflow.org/

Verifier URL
https://evm.flowscan.io/api/
https://evm-testnet.flowscan.io/api/

## Deploy.s.sol

### Deploy the Protocol

forge script script/Deploy.s.sol:DeployScript --rpc-url <rpc-url> -vvvv --slow --legacy --broadcast

### Call Deposit.deposit()

forge script script/DepositDeposit.s.sol:DepositDepositScript --rpc-url <rpc-url> -vvvv --slow --legacy --broadcast

### Start AtmAuction

forge script script/AuctionStartAuction.s.sol:AuctionStartAuctionScript --rpc-url <rpc-url> -vvvv --slow --legacy --broadcast

### Propose AtmAuction.startAuction()

forge script script/GovernorProposeAtmAuction.s.sol:GovernorProposeAtmAuctionScript --rpc-url <rpc-url> -vvvv --slow --legacy --broadcast

### Cast Vote

forge script script/GovernorCastVote.s.sol:GovernorCastVoteScript --rpc-url <rpc-url> -vvvv --slow --legacy --broadcast

### Delegate FlowStrategy

forge script script/FlowStrategyDelegate.s.sol:FlowStrategyDelegateScript --rpc-url <rpc-url> -vvvv --slow --legacy --broadcast

### Fill AtmAuction

forge script script/AtmAuctionFill.s.sol:AtmAuctionFillScript --rpc-url <rpc-url> -vvvv --slow --legacy --broadcast 

### Execute AtmAuction.startAuction()

forge script script/GovernorExecute.s.sol:GovernorExecuteScript --rpc-url <rpc-url> -vvvv --slow --legacy --broadcast
