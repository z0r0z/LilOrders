# LilOrders
[Git Source](https://github.com/z0r0z/LilOrders/blob/41fa9757e463fb7c5ba94db950e3edb437ca4715/src/LilOrders.sol)

**Author:**
z0r0z.eth

*Lil-est order protocol for ETH/ERC20/ERC721.*


## State Variables
### orders

```solidity
mapping(bytes32 orderHash => Order) orders;
```


## Functions
### make


```solidity
function make(Order calldata order) public payable;
```

### cancel


```solidity
function cancel(bytes32 order) public;
```

### execute


```solidity
function execute(bytes32 order) public payable;
```

## Events
### Made

```solidity
event Made(bytes32 indexed orderHash);
```

## Errors
### Cancelled

```solidity
error Cancelled();
```

### OutOfTime

```solidity
error OutOfTime();
```

### Unauthorized

```solidity
error Unauthorized();
```

### AlreadyExecuted

```solidity
error AlreadyExecuted();
```

### InsufficientETH

```solidity
error InsufficientETH();
```

## Structs
### Order

```solidity
struct Order {
    uint80 nonce;
    Standard tokenInStd;
    Standard tokenOutStd;
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    uint256 amountOut;
    address maker;
    uint40 validAfter;
    uint40 validUntil;
    bool executed;
    bool cancelled;
}
```

## Enums
### Standard

```solidity
enum Standard {
    NATIVE,
    TOKEN
}
```

