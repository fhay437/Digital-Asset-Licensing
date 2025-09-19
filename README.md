# Digital Asset Licensing Smart Contract

A comprehensive smart contract built on the Stacks blockchain for managing digital asset licensing, royalty payments, and compliance tracking. This contract enables creators to monetize their digital assets while maintaining control and ensuring proper compensation through automated royalty distribution.

## Features

### Core Functionality
- **Digital Asset Registration**: Securely register and tokenize digital assets with metadata
- **Automated Licensing**: Create time-bound licenses with customizable terms
- **Royalty Management**: Automatic royalty distribution with platform fee handling
- **Compliance Tracking**: Built-in compliance scoring and monitoring system
- **License Transfers**: Transfer license ownership between parties
- **License Extensions**: Extend license duration with additional payments

### Asset Types Supported
- Research Assets (`TYPE-RESEARCH`)
- Commercial Assets (`TYPE-COMMERCIAL`) 
- Educational Assets (`TYPE-EDUCATIONAL`)
- Non-Profit Assets (`TYPE-NON-PROFIT`)

### Status Management
- Active (`STATUS-ACTIVE`)
- Expired (`STATUS-EXPIRED`)
- Suspended (`STATUS-SUSPENDED`)
- Revoked (`STATUS-REVOKED`)

## Contract Overview

### Key Components

1. **Digital Assets Map**: Core asset data including owner, licensee, royalty rates, and revenue tracking
2. **Asset Metadata**: Detailed information including title, description, technical specs, and usage terms
3. **User Assets**: Index of owned and licensed assets per user
4. **Content Assets**: Mapping of content hashes to asset IDs
5. **Compliance Records**: Tracking compliance scores and manager notes

### Validation & Security

- Comprehensive input validation for all parameters
- Principal validation to prevent invalid addresses
- Duration and fee validation with configurable minimums/maximums
- Royalty rate validation (0-100% in basis points)
- String length validation for all text fields

## Installation & Deployment

### Prerequisites
- Stacks CLI installed
- Clarity development environment set up
- STX tokens for deployment and testing

### Deployment
```bash
# Deploy to local testnet
stacks deploy contracts/digital-asset-licensing.clar

# Deploy to Stacks mainnet
stacks deploy contracts/digital-asset-licensing.clar --network mainnet
```

## Usage Examples

### Creating a Digital Asset License

```clarity
(contract-call? .digital-asset-licensing create-digital-asset
  'SP1234...LICENSEE         ;; licensee principal
  "QmX1Y2Z3..."              ;; content hash (IPFS/similar)
  u2                         ;; commercial asset type
  u1000                      ;; 10% royalty rate (1000 basis points)
  u5000000                   ;; 5 STX licensing fee (5M microSTX)
  u2592000                   ;; 30 days duration (in seconds)
  "My Digital Asset"         ;; title
  "A valuable digital asset" ;; description
  "Technical specifications" ;; technical specs
  "Usage terms and conditions" ;; usage terms
)
```

### Paying Royalties

```clarity
(contract-call? .digital-asset-licensing pay-royalty
  u1                         ;; asset ID
  u10000000                  ;; 10 STX revenue amount
)
```

### Checking Asset Status

```clarity
(contract-call? .digital-asset-licensing is-asset-valid u1)
(contract-call? .digital-asset-licensing get-digital-asset u1)
(contract-call? .digital-asset-licensing calculate-asset-value u1)
```

## Administrative Functions

### Platform Fee Management
```clarity
;; Set platform fee rate (only contract owner)
(contract-call? .digital-asset-licensing set-platform-fee-rate u300) ;; 3%
```

### Compliance Management
```clarity
;; Set compliance manager
(contract-call? .digital-asset-licensing set-compliance-manager 'SP5678...MANAGER)

;; Update compliance score
(contract-call? .digital-asset-licensing update-compliance-score 
  u1 u75 "Compliance review completed")
```

### Emergency Controls
```clarity
;; Emergency asset pause (only contract owner)
(contract-call? .digital-asset-licensing emergency-pause-asset u1)
```

## Security Features

- **Access Control**: Role-based permissions for owners, compliance managers, and users
- **Input Validation**: Comprehensive validation of all inputs and parameters
- **Safe Math**: Protected arithmetic operations to prevent overflow/underflow
- **Emergency Controls**: Administrative functions for handling critical situations
- **Compliance Automation**: Automatic suspension of non-compliant assets

## Economic Model

### Fee Structure
- **Platform Fee**: Configurable percentage of royalty payments (default 2.5%)
- **Licensing Fees**: Paid upfront by licensees to asset owners
- **Extension Fees**: 50% of original licensing fee for license extensions
- **Minimum Fees**: Configurable minimums to prevent spam

### Revenue Distribution
1. Licensee pays royalties based on reported revenue
2. Platform fee deducted from royalty payment
3. Remaining amount transferred to asset owner
4. All transactions recorded for audit trail

## Read-Only Functions

- `get-digital-asset(asset-id)`: Retrieve complete asset information
- `get-asset-metadata(asset-id)`: Get asset metadata
- `get-user-assets(user)`: Get assets owned/licensed by user
- `is-asset-valid(asset-id)`: Check if asset license is active
- `calculate-asset-value(asset-id)`: Calculate asset financial metrics
- `get-platform-fee-rate()`: Get current platform fee rate

## Error Handling

The contract includes comprehensive error handling with descriptive error codes:

- `ERR-UNAUTHORIZED-ACCESS` (u100): Access denied
- `ERR-INVALID-ASSET-ID` (u101): Invalid asset ID
- `ERR-ASSET-NOT-FOUND` (u102): Asset doesn't exist
- `ERR-ASSET-EXPIRED` (u103): Asset license expired
- `ERR-INSUFFICIENT-PAYMENT` (u104): Payment too low
- And many more...

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests
4. Submit a pull request with detailed description
