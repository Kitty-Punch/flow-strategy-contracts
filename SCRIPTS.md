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
