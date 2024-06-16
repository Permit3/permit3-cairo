#[starknet::contract]
mod Permit3 {
    use starknet::{ContractAddress, get_caller_address, get_contract_address, get_block_timestamp};
    use openzeppelin::{
        access::ownable::OwnableComponent, upgrades::upgradeable::UpgradeableComponent
    };
    use permit3::components::interface::{permit3::IPermit3, versionable::IVersionable};

    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl InternalOwnableImpl = OwnableComponent::InternalImpl<ContractState>;
    impl InternalUpgradeableImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        /// 
        rights_map: LegacyMap<(ContractAddress, ContractAddress, ContractAddress, felt252), bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl Versionable of IVersionable<ContractState> {
        fn version(self: @ContractState) -> felt252 {
            '0.0.1'
        }
    }

    #[abi(embed_v0)]
    impl Permit3 of IPermit3<ContractState> {
        fn permit(
            ref self: ContractState,
            operator: ContractAddress,
            contract: ContractAddress,
            rights: felt252,
            revoke: bool,
        ) {
            self.rights_map.write((get_caller_address(), operator, contract, rights), revoke);
        }

        fn permit_all(ref self: ContractState, operator: ContractAddress, revoke: bool) {
            self
                .rights_map
                .write(
                    (
                        get_caller_address(),
                        operator,
                        self.get_permit_all_contracts_constant(),
                        self.get_permit_all_rights_in_contract_constant()
                    ),
                    revoke
                );
        }

        fn permit_all_rights_in_contract(
            ref self: ContractState,
            operator: ContractAddress,
            contract: ContractAddress,
            revoke: bool,
        ) {
            self
                .rights_map
                .write(
                    (
                        get_caller_address(),
                        operator,
                        contract,
                        self.get_permit_all_rights_in_contract_constant()
                    ),
                    revoke
                );
        }

        fn get_permit_all_contracts_constant(self: @ContractState) -> ContractAddress {
            get_contract_address()
        }

        fn get_permit_all_rights_in_contract_constant(self: @ContractState) -> felt252 {
            0 - 1 // This returns the max value of felt252 since it wraps around
        }

        fn get_permit_status_for_contract(
            self: @ContractState,
            from: ContractAddress,
            operator: ContractAddress,
            contract: ContractAddress,
            rights: felt252,
        ) -> bool {
            self.rights_map.read((from, operator, contract, rights))
        }

        fn get_permit_all_status(
            self: @ContractState, from: ContractAddress, operator: ContractAddress
        ) -> bool {
            self
                .rights_map
                .read(
                    (
                        from,
                        operator,
                        self.get_permit_all_contracts_constant(),
                        self.get_permit_all_rights_in_contract_constant()
                    )
                )
        }
    }
}
