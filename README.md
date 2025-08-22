# Hair Salon and Barbershop Services - Clarity Smart Contracts

A comprehensive blockchain-based management system for hair salons and barbershops built on the Stacks blockchain using Clarity smart contracts.

## System Overview

This system provides a complete solution for managing salon operations including:

- **Salon Management**: Register stylists, define services, and manage salon operations
- **Appointment System**: Book appointments with stylist preferences and availability tracking
- **Service History**: Track detailed service records with product usage and ratings
- **Pricing System**: Transparent, dynamic pricing with multiple calculation factors
- **Loyalty & Referrals**: Reward programs with tier-based benefits and certification tracking

## Architecture

The system consists of five interconnected Clarity contracts:

1. `salon-management.clar` - Core salon and stylist management
2. `appointment-system.clar` - Appointment booking and scheduling
3. `service-history.clar` - Service records and product tracking
4. `pricing-system.clar` - Dynamic pricing calculations
5. `loyalty-referrals.clar` - Loyalty programs and referral system

## Key Features

### Transparency
- All pricing rules are on-chain and verifiable
- Service history is immutable and transparent
- Loyalty calculations are auditable

### Flexibility
- Customizable service offerings per salon
- Dynamic pricing based on multiple factors
- Flexible appointment scheduling

### Trust
- Blockchain-verified service records
- Transparent loyalty point calculations
- Immutable certification tracking

## Getting Started

1. Install dependencies: `npm install`
2. Run tests: `npm test`
3. Deploy contracts using Clarinet

## Contract Interactions

Each contract is designed to work independently while maintaining data consistency across the system. The modular design allows for easy extension and customization.

## Testing

Comprehensive test suite with 67 test cases covering all functionality using Vitest.
