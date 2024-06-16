use starknet::{ContractAddress};

#[starknet::interface]
pub trait IPermit3<TContractState> {
    fn permit(
        ref self: TContractState,
        operator: ContractAddress,
        contract: ContractAddress,
        rights: felt252,
        revoke: bool,
    );

    fn permit_all(ref self: TContractState, operator: ContractAddress, revoke: bool,);

    fn permit_all_rights_in_contract(
        ref self: TContractState,
        operator: ContractAddress,
        contract: ContractAddress,
        revoke: bool,
    );

    fn get_permit_all_contracts_constant(self: @TContractState) -> ContractAddress;

    fn get_permit_all_rights_in_contract_constant(self: @TContractState) -> felt252;

    fn get_permit_status_for_contract(
        self: @TContractState,
        from: ContractAddress,
        operator: ContractAddress,
        contract: ContractAddress,
        rights: felt252,
    ) -> bool;

    fn get_permit_all_status(
        self: @TContractState, from: ContractAddress, operator: ContractAddress
    ) -> bool;
}
