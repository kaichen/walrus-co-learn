/*
/// Module: whitefaucet
module whitefaucet::whitefaucet;
*/

module whitefaucet::faucet {
    use sui::{
        coin::{Self, Coin},
        balance::{Self, Balance},
    };
    use sui::dynamic_field as df;
    use std::type_name::{Self, TypeName};
    use whitefaucet::nft::{Member,BlackList,check_if_valid_member,add_points};

    const ETYPE_NOT_FOUND: u64 = 0;
    const EINVALID_MEMBER: u64 = 1;

    const PERCENTAGE_PER_CLAIM: u64 = 1;
    
    public struct FaucetTreasury has key, store {
        id: UID,
    }

    
    fun init(ctx: &mut TxContext) {
        let treasury = FaucetTreasury {
            id: object::new(ctx),
        };
        transfer::share_object(treasury);
    }

    
    public fun deposit_to_treasury<T: key + store>(
        member: &mut Member,
        treasury: &mut FaucetTreasury,
        coin: Coin<T>,
    ) {
        let coin_balance = coin::into_balance(coin);
        let type_name = type_name::get<T>();
        
        if (df::exists_(&treasury.id, type_name)) {
            let balance = df::borrow_mut<TypeName, Balance<T>>(&mut treasury.id, type_name);
            balance::join(balance, coin_balance);
        } else {
            df::add(&mut treasury.id, type_name, coin_balance);
        };
        add_points(member);
    }

    
    public fun withdraw_from_treasury<T: key + store>(
        member: &Member,
        treasury: &mut FaucetTreasury,
        blackList: &BlackList,
        ctx: &mut TxContext
    ): Coin<T> {
        assert!(check_if_valid_member(member,blackList), EINVALID_MEMBER);
        let type_name = type_name::get<T>();
        assert!(df::exists_(&treasury.id, type_name), ETYPE_NOT_FOUND);
        
        let balance = df::borrow_mut<TypeName, Balance<T>>(&mut treasury.id, type_name);
        let amount = balance::value(balance) * PERCENTAGE_PER_CLAIM / 100;
        let withdrawn_balance = balance::split(balance, amount);
        coin::from_balance(withdrawn_balance, ctx)
    }


    // ==== Getter ====

    
    public fun balance<T: key + store>(treasury: &FaucetTreasury): u64 {
        let type_name = type_name::get<T>();
        if (df::exists_(&treasury.id, type_name)) {
            let balance = df::borrow<TypeName, Balance<T>>(&treasury.id, type_name);
            balance::value(balance)
        } else {
            0
        }
    }

    
    public fun contains<T: key + store>(treasury: &FaucetTreasury): bool {
        df::exists_(&treasury.id, type_name::get<T>())
    }
}