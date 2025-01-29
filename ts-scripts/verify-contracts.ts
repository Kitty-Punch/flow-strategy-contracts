import { exec } from 'child_process';
import { promises as fs } from 'node:fs';

const THREE_SECONDS = 3000;

// packages/contracts/out/Untitled.sol/Untitled.json
// eslint-disable-next-line @typescript-eslint/no-explicit-any

const getCompilerVersion = async(contractName: string):Promise<string> => {
  const data = await fs.readFile(`./out/${contractName}.sol/${contractName}.json`)
  const abi = JSON.parse(data);
  return abi.metadata.compiler.version
}

const getContractAddresses = async () => {
  const data = await fs.readFile('./out/deployed.json')
  const addresses = JSON.parse(data);
  console.log(addresses);

  const keys = Object.keys(addresses)
  await keys.map(async (key:string) => {
    await verifyContractWithTimeout(key, addresses[key]);
  })
}

const getContractAddressesMap = async () => {
  const data = await fs.readFile('./out/deployed.json')
  return JSON.parse(data);
}

const verifyContractWithTimeout = (contractName:string, address:string) => {
  setTimeout( async() => {
    await verifyContract(contractName, address);
  }, THREE_SECONDS);
};

const getConfig = async () => {
  const data = await fs.readFile('./out/deployed.config.json')
  return JSON.parse(data);
}

getContractAddresses()

const verifyContract = async(
  contractName: string,
  address: string
) => {
  console.log(`Verifying ${contractName} at ${address}`);
  const config = await getConfig();

  const addressesMap = await getContractAddressesMap();
  const compilerVersion = await getCompilerVersion(contractName)
  let command = `forge verify-contract ${address} ${contractName} --compiler-version ${compilerVersion} --watch --verifier etherscan`;

  if (contractName === 'AtmAuction') {
    command += ` --constructor-args $(cast abi-encode "constructor(address,address,address)" ${addressesMap.EthStrategy} ${addressesMap.EthStrategyGovernor} ${config.lst} )`;
  }

  if (contractName === 'BondAuction') {
    command += ` --constructor-args $(cast abi-encode "constructor(address,address,address)" ${addressesMap.EthStrategy} ${addressesMap.EthStrategyGovernor} ${config.usdc} )`;
  }

  if (contractName === 'EthStrategy') {
    command += ` --constructor-args $(cast abi-encode "constructor(address)" ${config.ethStrategyInitialOwner} )`;
  }

  if (contractName === 'EthStrategyGovernor') {
    command += ` --constructor-args $(cast abi-encode "constructor(address,uint256,uint256,uint256,uint256)" ${addressesMap.EthStrategy} ${config.quorumPercentage} ${config.votingDelay} ${config.votingPeriod} ${config.proposalThreshold} )`;
  }

  exec(command, (err, stdout) => {
    if (err) {
      console.error(err);
    }
    console.log(stdout);
  });
}