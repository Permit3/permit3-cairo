use starknet::{ContractAddress};

#[starknet::interface]
trait IMockCounter<TContractState> {
    fn increment(ref self: TContractState, use_permit: bool, permit_from: ContractAddress);
    fn clear(ref self: TContractState, use_permit: bool, permit_from: ContractAddress);
    fn get_counter(self: @TContractState, user: ContractAddress) -> u64;
}

#[starknet::contract]
mod MockCounter {
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use permit3::components::{
        interface::permit3::{IPermit3Dispatcher, IPermit3DispatcherTrait},
        mock::mockcounter::IMockCounter
    };

    #[storage]
    struct Storage {
        permit3_instance: IPermit3Dispatcher,
        counter: LegacyMap<ContractAddress, u64>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, permit3_address: ContractAddress) {
        self.permit3_instance.write(IPermit3Dispatcher { contract_address: permit3_address });
    }

    #[abi(embed_v0)]
    impl MockCounterImpl of IMockCounter<ContractState> {
        fn increment(ref self: ContractState, use_permit: bool, permit_from: ContractAddress) {
            let mut address_to_modify = get_caller_address();
            if use_permit {
                self
                    .permit3_instance
                    .read()
                    .consume_permit_as_contract(
                        permit_from, get_caller_address(), selector!("increment")
                    );
                address_to_modify = permit_from;
            }
            self.counter.write(address_to_modify, self.counter.read(address_to_modify) + 1);
        }

        fn clear(ref self: ContractState, use_permit: bool, permit_from: ContractAddress) {
            let mut address_to_modify = get_caller_address();
            if use_permit {
                self
                    .permit3_instance
                    .read()
                    .consume_permit_as_contract(
                        permit_from, get_caller_address(), selector!("clear")
                    );
                address_to_modify = permit_from;
            }
            self.counter.write(address_to_modify, 0);
        }

        fn get_counter(self: @ContractState, user: ContractAddress) -> u64 {
            self.counter.read(user)
        }
    }
}
