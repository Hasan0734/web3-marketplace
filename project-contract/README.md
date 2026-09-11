# Web3 Freelance Marketplace (ProjectContract)

An industry-standard, secure, and gas-optimized decentralized freelance marketplace built with **Solidity** and the **Hardhat** development framework. This platform allows clients to post projects with locked budgets, enables freelancers to place specific bids, manages active deliverables, and secures the payout distribution using architectural security patterns and **OpenZeppelin's ReentrancyGuard**.

## 🚀 Key Features & Business Logic
- **Escrow-Based Project Creation:** Clients lock the project budget in Escrow (`msg.value`) upon creation to ensure absolute trust for freelancers.
- **Dynamic Bidding System:** Implements a multi-dimensional nested tracking system allowing multiple freelancers to bid amounts less than or equal to the maximum allocated budget.
- **Automated Client Refund:** If a freelancer bids less than the maximum budget (e.g., Budget: 50, Bid: 40), the smart contract automatically calculates and returns the surplus (10) back to the client immediately upon payment release.
- **State History Tracking:** Provides comprehensive indexing and history tracking arrays for both clients and freelancers, allowing frontends to query work histories instantly without heavy blockchain logs loop.

---

## 🛡️ Security Architecture & Audit-Ready Measures

### 1. Reentrancy Protection (OpenZeppelin)
To fully block malicious contract callbacks from draining the escrow balance during token distribution, the contract integrates **OpenZeppelin's `ReentrancyGuard`**. The `releasePayment` function explicitly implements the `nonReentrant` modifier, making recursive loop attacks programmatically impossible.

### 2. Checks-Effects-Interactions Pattern
The contract strictly enforces the CEI pattern during sensitive state transformations. For instance, in `releasePayment`, the state variable status change (`project.currentStatus = Status.Completed;`) is explicitly executed **before** triggering any low-level external `.call{value: ...}("")` actions.

### 3. Strict State Validation Modifiers
Custom input validation modifiers like `checkProjectExist` wrap around active functions (`submitBid`, `assignFreelancer`, `submitWork`, `releasePayment`) to safely prevent uninitialized data corruption and empty memory address interactions.

---

## 📂 Folder Structure

```text
web3-marketplace/
├── contracts/
│   └── ProjectContract.sol       # Core Smart Contract Logic
├── test/
│   └── ProjectContract.test.js   # Automated Hardhat Unit Tests
├── scripts/
│   └── deploy.js                 # Network Deployment Script
├── hardhat.config.js             # Hardhat Setup Configuration File
└── README.md                     # Project Documentation
```

---

## 🛠️ Tech Stack & Dependencies
- **Language:** Solidity v0.8.13+
- **Framework:** Hardhat
- **Library:** `@openzeppelin/contracts` (ReentrancyGuard)

---

## 💻 Local Installation & Usage Guide

### Prerequisites
Ensure you have **Node.js (v16.x or higher)** and **npm** installed on your local machine.

### 1. Clone & Install Dependencies
Clone the repository and install the standard dependencies, including OpenZeppelin contracts:
```bash
git clone <your-repository-url>
cd web3-marketplace
npm install
npm install @openzeppelin/contracts
```

### 2. Compile the Smart Contracts
Compile the contracts using the Hardhat compiler to ensure there are no syntax or type errors:
```bash
npx hardhat compile
```

### 3. Run Automated Test Cases
Run the local JavaScript/TypeScript unit tests to verify the core requirements, modifier checks, and edge cases:
```bash
npx hardhat test
```

### 4. Code Coverage & Gas Reporting (Optional)
To review code execution coverage and check gas usage optimization metrics per function call:
```bash
npx hardhat test --gas-report
```

---

## 📝 Smart Contract Architecture Breakdown

### State Structures & Enums
- **`Status`**: Tracks project lifecycle phases: `Pending`, `Active`, `Completed`, `Cancelled`.
- **`Project` Struct**: Bundles comprehensive meta-data containing `projectId`, `title`, `description`, escrow `budget`, timestamped `deadline`, explicit addresses for the `owner` and `freelancer`, `currentStatus`, and a boolean tracking `isWorkSubmited`.

### Optimized Data Mappings
- `mapping(uint => Project) public projects;` -> Primary data store mapping unique internal IDs to projects.
- `mapping(address => mapping(uint256 => uint256)) public freelancerBids;` -> High-efficiency nested mapping designed to map `freelancer address => project ID => bid amount`.

---

## 📄 License
This project is licensed under the **MIT License**.
