use starknet::{ContractAddress};

#[starknet::interface]
pub trait IPermit3<TContractState> {
    fn permit(
        ref self: TContractState,
        operator: ContractAddress,
        contract: ContractAddress,
        rights: felt252,
        number_of_permits: u64,
    );

    fn permit_all(ref self: TContractState, operator: ContractAddress, number_of_permits: u64,);

    fn permit_all_rights_in_contract(
        ref self: TContractState,
        operator: ContractAddress,
        contract: ContractAddress,
        number_of_permits: u64,
    );

    fn consume_permit_as_operator(
        ref self: TContractState, from: ContractAddress, contract: ContractAddress, rights: felt252
    ) -> u64;

    fn consume_permit_as_contract(
        ref self: TContractState, from: ContractAddress, operator: ContractAddress, rights: felt252
    ) -> u64;

    fn get_permit_all_contracts_constant(self: @TContractState) -> ContractAddress;

    fn get_permit_all_rights_in_contract_constant(self: @TContractState) -> felt252;

    fn get_unlimited_number_of_permits_constant(self: @TContractState) -> u64;

    fn get_permit_status_for_contract(
        self: @TContractState,
        from: ContractAddress,
        operator: ContractAddress,
        contract: ContractAddress,
        rights: felt252,
    ) -> u64;

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
