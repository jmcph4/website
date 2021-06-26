---
date: 2021-06-26 18:00:00
title: "Viewing EVM Bytecode Unix Style"
layout: post
started: 2020-06-25 11:18:00
tags: [unix, ethereum, tooling, evm, bytecode, smart contracts]
---

Often in blockchain development (specifically smart contract work, in this case), tooling tends to converge on easy-to-use web-based interfaces. This makes a lot of sense and the current offerings are certainly vast and effective. However, if you're reading this, you likely already prefer a clean and minimalist interface for *all* of your computing -- not just development work.

Additionally, viewing the bytecode of a deployed contract is an absolutely *critical* task when it comes to interacting with the Ethereum blockchain (and any other SC-capable blockchain for that matter). It's how developers can debug, verify, and learn about either their own protocols or other ones. It's how security researchers can inspect, audit, and exploit protocols. It's how users (admittedly, particularly technical ones) can perform their own due diligence on protocols. Across the board, it's an innately vital activity.

So, wouldn't it be nice if this was easy to do all from the comfort of your own shell? There are certainly multiple ways to achieve this, and today I'll be showing you two. I particularly like the first as I hacked it together in probably 30 seconds, but the second is less commands.

# Method 1: No Smart Contract Development Tools #

Firstly, we're going to need to make sure we have our software installed:

```
$ sudo apt-get install curl jq
$ pip3 install pyevmasm 
```

`curl(1)` is pretty obvious due to its ubiquity. [`jq(1)`](https://stedolan.github.io/jq/) is like `sed(1)` but for JSON -- it allows us to manipulate JSON data in an ergonomic and minimalistic way.

Now we're ready to go! Conceptually, how this is going to work is:

 1. Call the `eth_getCode` RPC on a (synced) Eth1 node
 2. Grab the JSON response
 3. Extract the `result` field from this JSON object
 4. Pipe it into `evmasm`
 5. Dump the disassembly to the shell!

Here's what it looks like:

```
$ curl -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_getCode","params": ["[ADDRESS]", "latest"],"id":1}' [ENDPOINT] 2> /dev/null | jq -r ".result" | evmasm -d 
```

Where,

 - `ADDRESS` is the Ethereum address of the smart contract in question
 - `ENDPOINT` is the HTTP address of the Ethereum node we'll be using

For an actual, working example:

```sh
$ curl -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_getCode","params": ["0xE95782d36be250139027908c86648b01118eB407", "latest"],"id":1}' https://kovan.infura.io/v3/946670af70a14439978fce09a4f8e8e9 | jq -r ".result" | evmasm -d
00000000: PUSH20 0xe95782d36be250139027908c86648b01118eb407
00000015: ADDRESS
00000016: EQ
00000017: PUSH1 0x80
00000019: PUSH1 0x40
0000001b: MSTORE
0000001c: PUSH1 0x0
0000001e: DUP1
0000001f: REVERT
00000020: INVALID
00000021: LOG2
00000022: PUSH5 0x6970667358
00000028: INVALID
00000029: SLT
0000002a: SHA3
0000002b: INVALID
0000002c: PUSH10 0x7773d4bdfecf23ca8adc
00000037: PUSH17 0x88470d453cee95f328a24d6a5bc0d9532a
00000049: GAS
0000004a: INVALID
0000004b: PUSH5 0x736f6c6343
00000051: STOP
00000052: ADDMOD
00000053: STOP
00000054: STOP
00000055: CALLER
```

Voilà!

# Method 2: Dapp Tools #

This method leverages the mighty [dapp.tools](https://dapp.tools) to grab our code for us. Let's grab our prerequisites.

```
$ sudo apt-get install curl
$ curl -L https://nixos.org/nix/install | sh
$ curl https://dapp.tools/install | sh
$ pip3 install pyevmasm 
```

While I don't enjoy `curl`ing arbitrary remote code and piping it straight into a shell, these are the official recommendations for *both* pieces of software. As always, do your own research!

The strategy here is:

 1. Use `seth` to handle our RPC interaction (this still necessitates a synced Eth1 node, of course)
 2. Pipe the retrieved bytecode into `evmasm`

I told you it was less steps!

```
$ ETH_RPC_URL=[ENDPOINT] seth code [ADDRESS] | evmasm -d
```

Once again, a concrete example:

```
$ ETH_RPC_URL=https://kovan.infura.io/v3/946670af70a14439978fce09a4f8e8e9 seth code 0xE95782d36be250139027908c86648b01118eB407 | evmasm -d
00000000: PUSH20 0xe95782d36be250139027908c86648b01118eb407
00000015: ADDRESS
00000016: EQ
00000017: PUSH1 0x80
00000019: PUSH1 0x40
0000001b: MSTORE
0000001c: PUSH1 0x0
0000001e: DUP1
0000001f: REVERT
00000020: INVALID
00000021: LOG2
00000022: PUSH5 0x6970667358
00000028: INVALID
00000029: SLT
0000002a: SHA3
0000002b: INVALID
0000002c: PUSH10 0x7773d4bdfecf23ca8adc
00000037: PUSH17 0x88470d453cee95f328a24d6a5bc0d9532a
00000049: GAS
0000004a: INVALID
0000004b: PUSH5 0x736f6c6343
00000051: STOP
00000052: ADDMOD
00000053: STOP
00000054: STOP
00000055: CALLER
```

