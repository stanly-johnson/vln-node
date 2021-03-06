#!/bin/bash
# Spinup a local env with relaychains and parachains for testing.
# This script expects compiled polkadot, acala and vln binaries under /polkadot, /Acala and /vln-node
# directories. Run this script only after initial setup as per https://github.com/paritytech/cumulus/blob/master/README.md
# Ref : https://wiki.acala.network/build/development-guide/composable-chains/open-hrmp-channel

set -e
# turn a string into a flag
function flagify() {
  printf -- '--%s' "$(tr '[:upper:]' '[:lower:]' <<< "$1")"
}

# start relaychains in seperate screens for debugging
function startrelaychain() {
 screen_name="$1"
 auth="$2"
 port="$3"
 wsport="$4"
 rpcport="$5"

 screen -dmS "$screen_name" \
 ../polkadot/target/release/polkadot --chain "../polkadot/rococo-local-cfde.json" \
 --tmp --rpc-external --ws-external --rpc-cors all --discover-local -lruntime=trace \
  --ws-port "$wsport" --port "$port" --rpc-port "$rpcport" \
  "$(flagify "$auth")"
}

function startvlnparachain() {
 screen_name="$1"
 chain="$2"
 port="$3"
 wsport="$4"
 rpcport="$5"

 # create outputs for chainid
 ./target/release/vln_parachain export-genesis-state --parachain-id "$chain" > genesis-state-"$chain"

 ./target/release/vln_parachain export-genesis-wasm > genesis-wasm-"$chain"

 screen -dmS "$screen_name" \
 ./target/release/vln_parachain --collator --tmp \
 --parachain-id "$chain" -lruntime=trace \
 --alice --force-authoring \
 --rpc-external --ws-external --rpc-cors all \
 --port "$port" --ws-port "$wsport" -- --execution wasm \
 --chain "../polkadot/rococo-local-cfde.json" \
 --port "$rpcport"
}

function startacalaparachain() {
 # create outputs for chainid
 ../Acala/target/release/acala export-genesis-state --chain dev --parachain-id 666 > genesis-state-666

 ../Acala/target/release/acala export-genesis-wasm --chain dev > genesis-wasm-666

 screen -dmS acala \
 ../Acala/target/release/acala --chain dev --collator --tmp \
 --parachain-id 666 -lruntime=trace \
 --rpc-external --ws-external --rpc-cors all \
 --port 40338 --ws-port 9979 -- --execution wasm \
 --chain "../polkadot/rococo-local-cfde-real-overseer.json" \
 --port 30339
}

# Start relaychain
startrelaychain relay1 alice 30333 9944 9933
startrelaychain relay2 bob 30334 9945 9934
startrelaychain relay3 charlie 30335 9946 9935

# start acala parachain
#startacalaparachain

# start vln parachain
startvlnparachain vln 2000 40335 9947 30336
#startvlnparachain vln2 400 40336 9948 30337