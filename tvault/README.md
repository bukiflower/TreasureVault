# TreasureVault ⚓

A pirate-themed smart contract for the Stacks blockchain that lets you bury digital treasure and discover it later with time-based rewards and legendary bonuses.

## 🏴‍☠️ Overview

TreasureVault allows pirates (users) to lock away their STX tokens for specified periods, earning bonuses based on treasure rarity, burial time, and mystical properties. Think of it as a gamified time-locked savings mechanism with pirate flair!

## ⭐ Features

- **Treasure Burial**: Lock STX tokens for 1+ months with custom treasure names and clues
- **Legendary Treasures**: Special treasure types with multiplier bonuses:
  - Golden Doubloons: +10% bonus
  - Kraken's Pearl: +25% bonus  
  - Dragon's Hoard: +50% bonus
  - Atlantis Coins: +100% bonus
- **Time Bonuses**: Extra 5% reward for treasures buried longer than 5 months
- **Cursed Treasures**: Opt for cursed treasures with 10% penalty for thematic gameplay
- **Treasure Maps**: Add custom clues when burying treasure
- **Emergency Recovery**: Abandon chests early with 20% penalty

## 🎮 How It Works

### Bury Treasure
```clarity
(bury-treasure 
  "Dragon's Hoard"     ;; treasure-name
  u1000000             ;; 1 STX (in microSTX)
  u3                   ;; 3 months until discovery
  "X marks the spot"   ;; treasure map clue
  false                ;; not cursed
)
```

### Dig Up Treasure
```clarity
(dig-up-treasure chest-id)
```

### Check Treasure Status
```clarity
(peek-at-chest chest-id)
```

## 💰 Treasure Calculation

Final treasure value depends on:
- **Base Amount**: Original STX deposited
- **Legendary Multiplier**: 110%-200% for special treasure names
- **Time Bonus**: +5% if buried >5 months (~21,600 blocks)
- **Curse Penalty**: -10% if marked as cursed

**Formula**: `(base × legendary × time × curse) / 10000`

## 🚀 Getting Started

### Prerequisites
- Stacks wallet with STX tokens
- Minimum 0.5 STX to bury treasure

### Deployment
Deploy the contract to Stacks blockchain and start burying treasure!

### Example Usage
1. Choose your treasure name (legendary names get bonuses!)
2. Decide burial duration (longer = potential time bonus)
3. Add a treasure map clue for fun
4. Bury your treasure and wait for discovery time
5. Dig up your treasure with accumulated bonuses

## 🗺️ Contract Functions

### Public Functions
- `bury-treasure` - Lock STX tokens as buried treasure
- `dig-up-treasure` - Claim treasure after discovery time
- `abandon-treasure-chest` - Emergency recovery with penalty

### Read-Only Functions  
- `peek-at-chest` - Check treasure status and projected value
- `get-chest-details` - Get raw treasure chest data
- `get-pirate-chest-count` - Number of chests per pirate
- `is-legendary-treasure` - Check if treasure name is legendary
- `get-legendary-multiplier` - Get bonus multiplier for treasure

## ⚠️ Important Notes

- **Minimum Deposit**: 0.5 STX required to bury treasure
- **Time Lock**: Treasure cannot be retrieved before discovery block
- **Abandonment Penalty**: 20% fee for early withdrawal
- **Unique IDs**: Each chest gets a unique ID based on pirate address

## 🎯 Error Codes

- `300`: Not the original pirate (unauthorized access)
- `301`: Treasure still buried (discovery time not reached)
- `302`: Empty treasure chest (chest not found)
- `303`: Invalid burial time (must be >0 months)
- `304`: Chest not found
- `305`: Insufficient treasure (below 0.5 STX minimum)

## 🏆 Legendary Treasures

Want maximum rewards? Use these legendary treasure names:
- **Atlantis Coins** - 2x multiplier (100% bonus)
- **Dragon's Hoard** - 1.5x multiplier (50% bonus)  
- **Kraken's Pearl** - 1.25x multiplier (25% bonus)
- **Golden Doubloons** - 1.1x multiplier (10% bonus)
