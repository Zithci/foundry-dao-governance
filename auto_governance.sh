#!/bin/bash

# Configuration
RPC_URL="http://127.0.0.1:8545"
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
USER_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

# Fetch Addresses
GOV_TOKEN=$(cat broadcast/DeployDAO.s.sol/31337/run-latest.json | jq -r '.transactions[] | select(.contractName == "GovToken") | .contractAddress' | head -n 1)
GOVERNOR=$(cat broadcast/DeployDAO.s.sol/31337/run-latest.json | jq -r '.transactions[] | select(.contractName == "MyGovernor") | .contractAddress' | head -n 1)
BOX=$(cat broadcast/DeployDAO.s.sol/31337/run-latest.json | jq -r '.transactions[] | select(.contractName == "Box") | .contractAddress' | head -n 1)

DESC="Hoki777"
DESC_HASH=$(cast keccak "$DESC")
CALLDATA="0x6057361d0000000000000000000000000000000000000000000000000000000000000309"

echo "--- DAO AUTOMATION (V5 - INSTANT MODE) ---"

# 1. Delegate
echo "[1/6] Delegating..."
cast send "$GOV_TOKEN" "delegate(address)" "$USER_ADDRESS" --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL" > /dev/null
cast rpc anvil_mine --rpc-url "$RPC_URL" > /dev/null

# 2. Propose
echo "[2/6] Submitting proposal..."
cast send "$GOVERNOR" "propose(address[],uint256[],bytes[],string)" "[$BOX]" "[0]" "[$CALLDATA]" "$DESC" --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL" > /dev/null

# Get ID
PROPOSAL_ID=$(cast call "$GOVERNOR" "hashProposal(address[],uint256[],bytes[],bytes32)" "[$BOX]" "[0]" "[$CALLDATA]" "$DESC_HASH" --rpc-url "$RPC_URL")
echo "Proposal ID: $PROPOSAL_ID"

# 3. Mine Delay (1 block)
cast rpc anvil_mine --rpc-url "$RPC_URL" > /dev/null

# 4. Vote
echo "[4/6] Voting FOR..."
cast send "$GOVERNOR" "castVoteWithReason(uint256,uint8,string)" "$PROPOSAL_ID" 1 "$DESC" --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL" > /dev/null

# 5. Time Travel (Now only 15 blocks!)
echo "[5/6] Passing voting period (15 blocks)..."
cast rpc anvil_mine 15 --rpc-url "$RPC_URL" > /dev/null
echo "DONE."

# 6. Queue & Execute
echo "[6/6] Finalizing..."
# Queue
cast send "$GOVERNOR" "queue(address[],uint256[],bytes[],bytes32)" "[$BOX]" "[0]" "[$CALLDATA]" "$DESC_HASH" --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL" > /dev/null

# Timelock Delay
cast rpc anvil_increaseTime 3601 --rpc-url "$RPC_URL" > /dev/null
cast rpc anvil_mine --rpc-url "$RPC_URL" > /dev/null

# Execute
cast send "$GOVERNOR" "execute(address[],uint256[],bytes[],bytes32)" "[$BOX]" "[0]" "[$CALLDATA]" "$DESC_HASH" --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL" > /dev/null

# Verify
FINAL_VAL=$(cast call "$BOX" "getNumber()" --rpc-url "$RPC_URL")
echo "-----------------------------------"
echo "VERIFICATION: Box Value is now: $FINAL_VAL"
echo "-----------------------------------"
