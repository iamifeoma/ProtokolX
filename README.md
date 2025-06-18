# Clarity Fungible Token (ERC-20 Equivalent)

A secure and feature-rich fungible token smart contract implementation in Clarity for the Stacks blockchain. This contract provides all standard ERC-20 functionality with additional security enhancements and utility functions.

## Features

### Core Token Functionality
- ✅ **Standard Transfers** - Send tokens between addresses
- ✅ **Allowance System** - Delegate spending permissions
- ✅ **Transfer From** - Execute transfers on behalf of others
- ✅ **Token Metadata** - Name, symbol, decimals, total supply

### Advanced Features
- 🔒 **Overflow Protection** - Prevents arithmetic overflow attacks
- 🔥 **Mint & Burn** - Owner can mint new tokens, users can burn their own
- 📦 **Batch Transfers** - Send to multiple recipients in one transaction
- ⚡ **Safe Allowance Management** - Increase/decrease allowances safely
- 👤 **Ownership Management** - Transferable contract ownership

### Security Features
- 🛡️ **Input Validation** - Comprehensive parameter checking
- 🚫 **Self-Transfer Prevention** - Blocks invalid operations
- 💯 **Static Analysis Clean** - Passes Clarity analyzer without warnings
- 🔐 **Access Controls** - Proper authorization for privileged functions

## Contract Constants

```clarity
TOKEN_NAME: "MyToken"
TOKEN_SYMBOL: "MTK"
DECIMALS: 6
TOTAL_SUPPLY: 1,000,000 tokens (with decimals)
```

## Core Functions

### Read-Only Functions

#### `get-name()`
Returns the token name.

#### `get-symbol()`
Returns the token symbol.

#### `get-decimals()`
Returns the number of decimal places.

#### `get-total-supply()`
Returns the total token supply.

#### `balance-of(account: principal)`
Returns the token balance of the specified account.

#### `allowance(owner: principal, spender: principal)`
Returns the amount that spender is allowed to spend on behalf of owner.

### Public Functions

#### `transfer(recipient: principal, amount: uint)`
Transfer tokens from sender to recipient.
- Validates amount > 0
- Checks sufficient balance
- Prevents overflow
- Blocks self-transfers

#### `transfer-from(sender: principal, recipient: principal, amount: uint)`
Transfer tokens from sender to recipient using allowance.
- Requires sufficient allowance
- Updates allowance after transfer
- Same validations as `transfer`

#### `approve(spender: principal, amount: uint)`
Set allowance for spender to spend on behalf of caller.
- Prevents self-approval
- Allows setting allowance to 0

#### `increase-allowance(spender: principal, amount: uint)`
Safely increase allowance by specified amount.
- Prevents overflow
- More secure than direct `approve`

#### `decrease-allowance(spender: principal, amount: uint)`
Safely decrease allowance by specified amount.
- Prevents underflow
- Validates sufficient current allowance

#### `mint(recipient: principal, amount: uint)` (Owner Only)
Mint new tokens to recipient address.
- Only callable by contract owner
- Prevents overflow
- Cannot mint to owner address

#### `burn(amount: uint)`
Burn tokens from caller's balance.
- Reduces total circulating supply
- Irreversible operation

#### `batch-transfer(recipients: list)`
Transfer tokens to multiple recipients in one transaction.
- Supports up to 50 recipients
- Validates total amount against balance
- Atomic operation (all or nothing)

#### `transfer-ownership(new-owner: principal)` (Owner Only)
Transfer contract ownership to new address.
- Only callable by current owner
- Cannot transfer to current owner

## Usage Examples

### Basic Operations

```clarity
;; Transfer 1000 tokens to another address
(contract-call? .my-token transfer 'SP1234...ABCD u1000000)

;; Check balance
(contract-call? .my-token balance-of 'SP1234...ABCD)

;; Approve spending
(contract-call? .my-token approve 'SP5678...EFGH u500000)
```

### Advanced Operations

```clarity
;; Safely increase allowance
(contract-call? .my-token increase-allowance 'SP5678...EFGH u100000)

;; Batch transfer to multiple addresses
(contract-call? .my-token batch-transfer 
  (list 
    {recipient: 'SP1111...AAAA, amount: u100000}
    {recipient: 'SP2222...BBBB, amount: u200000}
    {recipient: 'SP3333...CCCC, amount: u150000}))

;; Burn tokens (reduce supply)
(contract-call? .my-token burn u50000)
```

### Owner Operations

```clarity
;; Mint new tokens (owner only)
(contract-call? .my-token mint 'SP1234...ABCD u1000000)

;; Transfer ownership (owner only)
(contract-call? .my-token transfer-ownership 'SP9999...ZZZZ)
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 401 | `ERR_UNAUTHORIZED` | Caller lacks required permissions |
| 402 | `ERR_INSUFFICIENT_BALANCE` | Insufficient token balance |
| 403 | `ERR_INSUFFICIENT_ALLOWANCE` | Insufficient spending allowance |
| 404 | `ERR_INVALID_AMOUNT` | Invalid amount (zero or negative) |
| 405 | `ERR_INVALID_RECIPIENT` | Invalid recipient address |
| 406 | `ERR_OVERFLOW` | Arithmetic overflow detected |

## Deployment

1. **Customize Constants**: Update token name, symbol, decimals, and total supply in the contract
2. **Deploy Contract**: Deploy to Stacks blockchain using Clarinet or Stacks CLI
3. **Verify Deployment**: Check that initial supply is allocated to deployer address
4. **Test Functions**: Verify all functions work as expected

## Testing

Run the contract through Clarity's static analyzer:
```bash
clarity-cli check contracts/token.clar
```

Expected output: ✅ No warnings or errors

## Security Considerations

- **Overflow Protection**: All arithmetic operations are overflow-safe
- **Input Validation**: All user inputs are thoroughly validated
- **Access Control**: Owner-only functions properly restricted
- **Reentrancy Safe**: No external calls that could cause reentrancy
- **Static Analysis**: Passes all Clarity static analysis checks


## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## Support

For questions or issues:
- Open an issue on GitHub
- Check the Clarity documentation
- Join the Stacks community Discord