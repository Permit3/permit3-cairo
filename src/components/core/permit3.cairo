#[starknet::contract]
mod Permit3 {
    use starknet::{
        ContractAddress, event::EventEmitter, get_caller_address, get_contract_address,
        get_block_timestamp
    };
    use openzeppelin::{
        access::ownable::OwnableComponent, upgrades::upgradeable::UpgradeableComponent
    };
    use permit3::components::{
        interface::{permit3::{IPermit3, Permit3Event}, versionable::IVersionable},
        util::storefelt252array::StoreFelt252Array
    };

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
        /// LegacyMap<(from, operator, contract, rights), number_of_permits>
        rights_map: LegacyMap<(ContractAddress, ContractAddress, ContractAddress, felt252), u64>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        ///
        DidSetPermit: Permit3Event::DidSetPermit,
        DidConsumePermit: Permit3Event::DidConsumePermit,
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
            '0.1.0'
        }
    }

    #[abi(embed_v0)]
    impl Permit3 of IPermit3<ContractState> {
        fn permit(
            ref self: ContractState,
            operator: ContractAddress,
            contract: ContractAddress,
            rights: felt252,
            number_of_permits: u64,
        ) {
            self
                .rights_map
                .write((get_caller_address(), operator, contract, rights), number_of_permits);
            self
                .emit(
                    Event::DidSetPermit(
                        Permit3Event::DidSetPermit {
                            from: get_caller_address(),
                            operator,
                            contract,
                            rights,
                            number_of_permits
                        }
                    )
                );
        }

        fn permit_all(ref self: ContractState, operator: ContractAddress, number_of_permits: u64,) {
            self
                .permit(
                    operator,
                    self.get_permit_all_contracts_constant(),
                    self.get_permit_all_rights_in_contract_constant(),
                    number_of_permits
                );
        }

        fn permit_all_rights_in_contract(
            ref self: ContractState,
            operator: ContractAddress,
            contract: ContractAddress,
            number_of_permits: u64,
        ) {
            self
                .permit(
                    operator,
                    contract,
                    self.get_permit_all_rights_in_contract_constant(),
                    number_of_permits
                );
        }

        fn consume_permit_as_operator(
            ref self: ContractState,
            from: ContractAddress,
            contract: ContractAddress,
            rights: felt252
        ) -> u64 {
            self._consume_permit(from, get_caller_address(), contract, rights)
        }

        fn consume_permit_as_contract(
            ref self: ContractState,
            from: ContractAddress,
            operator: ContractAddress,
            rights: felt252
        ) -> u64 {
            self._consume_permit(from, operator, get_caller_address(), rights)
        }

        fn get_permit_all_contracts_constant(self: @ContractState) -> ContractAddress {
            get_contract_address() // Using this contract address so it doesn't conflict with any other address
        // This contract does not support permits, so we can do this safely
        }

        fn get_permit_all_rights_in_contract_constant(self: @ContractState) -> felt252 {
            0 - 1 // This returns the max value of felt252 since it wraps around
        }

        fn get_unlimited_number_of_permits_constant(self: @ContractState) -> u64 {
            18446744073709551615 // Max value for u64
        }

        fn get_permit_status_for_contract(
            self: @ContractState,
            from: ContractAddress,
            operator: ContractAddress,
            contract: ContractAddress,
            rights: felt252,
        ) -> u64 {
            /// Skipping check for operator-level permit all since there is a dedicated getter for it
            /// First check for contract-level permit all
            let mut number_of_permits: u64 = self
                .rights_map
                .read(
                    (from, operator, contract, self.get_permit_all_rights_in_contract_constant())
                );
            /// Then check for a specific permit
            if number_of_permits == 0 {
                number_of_permits = self.rights_map.read((from, operator, contract, rights));
            }
            number_of_permits
        }

        fn get_permit_all_status(
            self: @ContractState, from: ContractAddress, operator: ContractAddress
        ) -> u64 {
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

    #[generate_trait]
    impl Permit3InternalImpl of Permit3InternalTrait {
        fn _consume_permit(
            ref self: ContractState,
            from: ContractAddress,
            operator: ContractAddress,
            contract: ContractAddress,
            rights: felt252
        ) -> u64 {
            let mut number_of_permits = self.rights_map.read((from, operator, contract, rights));
            if number_of_permits != self.get_unlimited_number_of_permits_constant() {
                number_of_permits -= 1;
                self.rights_map.write((from, operator, contract, rights), number_of_permits);
            }
            self
                .emit(
                    Event::DidConsumePermit(
                        Permit3Event::DidConsumePermit { from, operator, contract, rights }
                    )
                );
            number_of_permits
        }
    }
}
