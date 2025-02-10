### **FlowStrategy ($FLOWSTR)**

#### **What is it?**

FlowStrategy (\$FLOWSTR) is a tokenized vehicle for FLOW accumulation, giving \$FLOWSTR holders a claim on a growing pool of FLOW managed through fully transparent, onchain strategies.

Think of FlowStrategy as **MicroStrategy, but entirely onchain and transparent**. If you’re familiar with how MicroStrategy operates, you already get the gist.

**Note:** To maximize efficiency and capture staking yield, FlowStrategy will likely hold **ankrFLOW** xinstead of plain FLOW.

---

### **TL;DR**

1. **Seed Pool:**  
   * The protocol starts with an initial FLOW pool funded by early depositors.  
   * Early backers receive $FLOWSTR tokens, aligning their incentives with the protocol’s growth.  
2. **Growth Mechanisms:**  
   * **Convertible Bonds:** Users buy bonds with USDF. Proceeds are used to buy FLOW, growing the pool and increasing $FLOWSTR’s value.  
   * **ATM Offerings:** If $FLOWSTR trades at a premium to NAV, new tokens are sold at the market price. Proceeds are used to acquire more FLOW.  
   * **Redemptions:** If $FLOWSTR trades at a discount to NAV, holders can vote to redeem FLOW.

   ---

### **How It Works**

#### **1\. Convertible Bonds (USDF for FLOW Acquisition):**

FlowStrategy raises funds by issuing **onchain convertible bonds**, which are structured as follows:

* **Initial Offering:**  
  * Bonds are sold at a fixed price in USDF with a maturity date and a strike price in $FLOWSTR.  
* **Conversion Option:**  
  * At maturity, bondholders can convert bonds into $FLOWSTR tokens if the token’s market price exceeds the strike price.  
  * Conversion is performed onchain, allowing bondholders to capture appreciation in $FLOWSTR’s value.  
* **Redemption Option:**  
  * If $FLOWSTR’s market price does not exceed the strike price, bondholders can redeem the bonds for their principal in USDF, potentially with a fixed yield.  
* **Protocol Benefits:**  
  * USDF raised is immediately used to buy FLOW, growing the pool and boosting $FLOWSTR’s NAV.  
  * Conversion aligns bondholder incentives with the protocol’s long-term success.

  ---

#### **2\. At-The-Money (ATM) Offerings:**

If $FLOWSTR trades at a **premium to NAV**, FlowStrategy issues new tokens to capture demand and grow the FLOW pool.

* **Mechanism:**  
  * New $FLOWSTR tokens are sold at the market price, capped at a percentage per week to maintain upside for existing holders.  
  * Proceeds are used to buy FLOW and add it to the pool.  
* **Benefits:**  
  * Prevents runaway premiums by issuing tokens only when $FLOWSTR is overvalued.  
  * Scales the FLOW pool efficiently, increasing NAV for all holders.

  

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
