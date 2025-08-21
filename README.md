# 🎁 Tokenized Gift Card System

A Clarity smart contract that enables businesses to issue redeemable gift cards as blockchain tokens with expiration logic.

## 🚀 Features

- 🏪 **Business Registration**: Companies can register to issue gift cards
- 💳 **Gift Card Issuance**: Create tokenized gift cards with custom amounts and expiry dates
- 🔄 **Redemption System**: Recipients can redeem cards partially or fully before expiration
- ⏰ **Expiration Logic**: Automatic expiry based on block height
- 📊 **Business Analytics**: Track total cards issued and business status
- 🔧 **Management Tools**: Extend expiry dates and toggle business status

## 📋 Contract Functions

### Business Operations
- `register-business` - Register as a gift card issuing business
- `deactivate-business` / `reactivate-business` - Toggle business status
- `get-business-stats` - View business metrics

### Gift Card Operations
- `issue-gift-card` - Create new gift card tokens
- `redeem-gift-card` - Redeem tokens for value
- `extend-card-expiry` - Extend expiration date (business only)
- `get-card-details` - View complete card information

### Token Operations (SIP-010)
- `transfer` - Transfer tokens between users
- `get-balance` - Check token balance
- `get-total-supply` - View total tokens in circulation

## 🛠 Usage Examples

### Register a Business
```clarity
(contract-call? .tokenized-gift-card-system register-business "Coffee Shop")
```

### Issue a Gift Card
```clarity
;; Issue 100 token gift card to recipient, expires in 52560 blocks (~1 year)
(contract-call? .tokenized-gift-card-system issue-gift-card 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u100 u52560)
```

### Redeem Gift Card
```clarity
;; Redeem 50 tokens from card ID 1
(contract-call? .tokenized-gift-card-system redeem-gift-card u1 u50)
```

### Check Card Status
```clarity
(contract-call? .tokenized-gift-card-system get-card-details u1)
```

## 🏗 Deployment

1. Clone this repository
2. Install Clarinet: `npm install -g @hirosystems/clarinet`
3. Deploy to testnet: `clarinet deploy --testnet`
4. Deploy to mainnet: `clarinet deploy --mainnet`

## 📖 Contract Architecture

- **SIP-010 Compliant**: Implements standard token interface
- **Expiration Logic**: Uses block height for time-based expiry
- **Multi-Business Support**: Multiple businesses can issue cards
- **Partial Redemption**: Cards can be redeemed in portions
- **Transfer Support**: Tokens can be transferred between users

## 🔒 Security Features

- Business registration required for card issuance
- Only card recipients can redeem their cards
- Only issuing business can extend expiry dates
- Automatic expiration prevents indefinite token circulation

## 📈 Token Economics

- **Total Supply**: Dynamic based on issued cards
- **Decimals**: 0 (whole tokens only)
- **Burning**: Tokens are burned when redeemed
- **Minting**: Only businesses can mint through card issuance
