# DAO

An on-chain governance system with timelock-controlled execution, built with [Foundry](https://book.getfoundry.sh/) and [OpenZeppelin](https://www.openzeppelin.com/contracts).

This project implements a complete DAO governance lifecycle: token holders propose changes, vote on them, and — once a proposal passes — execution is delayed through a timelock before it takes effect. The timelock acts as a safety buffer, giving the community time to react before any approved change goes live.

## Governance Flow

A proposal moves through four sequential stages. Each stage depends on the one before it, so the order is enforced by the system rather than by convention:

1. **Propose** — A token holder submits a proposal describing the target contract, the function to call, and its arguments. The proposal enters a `Pending` state.
2. **Vote** — After a short delay the proposal becomes `Active`. Token holders cast votes weighted by their voting power. If the proposal meets quorum and passes, it becomes `Succeeded`.
3. **Queue** — A passed proposal is queued into the timelock, which starts a mandatory delay before the proposal can run.
4. **Execute** — Once the timelock delay has elapsed, the proposal is executed and the target contract is updated. Attempting to execute before the delay expires reverts.

## Contracts

| Contract | Description |
| --- | --- |
| `MyGovernor` | The core governance contract. Handles proposing, voting, queuing, and executing. Integrates the timelock and the voting token. |
| `GovToken` | An ERC20 voting token (`ERC20Votes`). Voting power is derived from token balances, with checkpointing for snapshot-based voting. |
| `TimeLock` | An `OpenZeppelin TimelockController` that enforces a mandatory delay between a proposal passing and its execution. |
| `Box` | A simple target contract owned by the timelock. It can only be modified through the full governance process — used to demonstrate that the DAO controls it. |

## Tech Stack

- **Solidity** — smart contract language
- **Foundry** — development, testing, and deployment framework
- **OpenZeppelin Contracts** — `Governor`, `GovernorTimelockControl`, `ERC20Votes`, `TimelockController`

## Getting Started

### Prerequisites

You need [Foundry](https://book.getfoundry.sh/getting-started/installation) installed:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Installation

Clone the repository and install dependencies:

```bash
git clone https://github.com/<your-username>/dao.git
cd dao
forge install
```

### Build

```bash
forge build
```

### Test

```bash
forge test
```

For more detailed output, run with increased verbosity:

```bash
forge test -vvv
```

## Project Structure

```
dao/
├── src/
│   ├── MyGovernor.sol     # Core governance contract
│   ├── GovToken.sol       # ERC20 voting token
│   ├── TimeLock.sol       # Timelock controller
│   └── Box.sol            # Governed target contract
├── test/
│   └── MyGovernorTest.sol # Governance lifecycle tests
├── script/                # Deployment scripts
└── foundry.toml           # Foundry configuration
```

## What the Tests Cover

The test suite verifies both sides of the governance flow:

- **Timelock enforcement** — executing a queued proposal *before* the timelock delay has passed reverts, proving the safety buffer works.
- **Full lifecycle** — a proposal that is proposed, voted through, queued, and executed *after* the delay successfully updates the governed contract.

## License

This project is licensed under the MIT License.
