#[starknet::interface]
pub trait IVersionable<TContractState> {
    fn version(self: @TContractState) -> felt252;
}
