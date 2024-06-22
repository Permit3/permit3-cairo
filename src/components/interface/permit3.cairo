//! SPDX-License-Identifier: Apache 2.0
//!
//! Permit3 Interface
//!
//! Permit3 empowers any smart contract to implement arbitrary access control rules.

use starknet::{ContractAddress};

#[starknet::interface]
pub trait IPermit3<TContractState> {
    /// Creates a permit.
    ///
    /// # Arguments
    /// * `operator`: The address permitted to make a contract call on the caller's behalf.
    /// * `contract`: The contract that the operator is permitted to call on the caller's behalf.
    /// * `rights`: Defines what specifically (e.g. function, parameters, etc.) the operator is permitted to call on the caller's behalf.
    /// * `number_of_permits`: The number of times the operator is permitted to make contract calls on the caller's behalf. This may be consumed per permitted call.
    ///
    /// # Events
    /// * `DidSetPermit`
    fn permit(
        ref self: TContractState,
        operator: ContractAddress,
        contract: ContractAddress,
        rights: felt252,
        number_of_permits: u64,
    );

    /// Permits an operator to perform all actions on behalf of the caller.
    /// Internally calls `permit(...)`.
    fn permit_all(ref self: TContractState, operator: ContractAddress, number_of_permits: u64,);

    /// Permits an operator to perform all actions within the specified contract on behalf of the caller.
    /// Internally calls `permit(...)`.
    fn permit_all_rights_in_contract(
        ref self: TContractState,
        operator: ContractAddress,
        contract: ContractAddress,
        number_of_permits: u64,
    );

    /// As an operator, consume 1 permit allocated to you by the `from` address.
    /// 
    /// # Returns
    /// `u64`: The remaining number of permits left for this specific right.
    fn consume_permit_as_operator(
        ref self: TContractState, from: ContractAddress, contract: ContractAddress, rights: felt252
    ) -> u64;

    /// As a contract, consume 1 permit allocated to you by the `from` address.
    /// 
    /// # Returns
    /// `u64`: The remaining number of permits left for this specific right.
    fn consume_permit_as_contract(
        ref self: TContractState, from: ContractAddress, operator: ContractAddress, rights: felt252
    ) -> u64;

    /// Returns a constant used when permitting an operator to call all contracts on the caller's behalf.
    fn get_permit_all_contracts_constant(self: @TContractState) -> ContractAddress;

    /// Returns a constant used when permitting an operator to call all functions within a contract on the caller's behalf.
    fn get_permit_all_rights_in_contract_constant(self: @TContractState) -> felt252;

    /// Returns a constant used to grant an operator an unlimited number of permits for some rights in a contract.
    fn get_unlimited_number_of_permits_constant(self: @TContractState) -> u64;

    /// Returns the remaining number of permits for a specific right.
    fn get_permit_status_for_contract(
        self: @TContractState,
        from: ContractAddress,
        operator: ContractAddress,
        contract: ContractAddress,
        rights: felt252,
    ) -> u64;

    /// Returns the remaining number of times an operator is permitted to perform any action.
    fn get_permit_all_status(
        self: @TContractState, from: ContractAddress, operator: ContractAddress
    ) -> u64;
}

pub mod Permit3Event {
    #[derive(Drop, starknet::Event)]
    pub struct DidSetPermit {
        pub from: super::ContractAddress,
        pub operator: super::ContractAddress,
        pub contract: super::ContractAddress,
        pub rights: felt252,
        pub number_of_permits: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct DidConsumePermit {
        pub from: super::ContractAddress,
        pub operator: super::ContractAddress,
        pub contract: super::ContractAddress,
        pub rights: felt252,
    }
}
