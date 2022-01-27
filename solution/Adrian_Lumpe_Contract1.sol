
pragma solidity ^0.5.0;
import "../contracts/Store.sol";

contract TheStore is HTLStore {
    struct Lock {
        address benefactor;
        uint amount;
        uint32 timeout;
        bool exists;
        bool blocked;
    }

    mapping(bytes32 => Lock) private locks;


    modifier onlyBenefactor(bytes32 lock) { // Modifier
        require(
            msg.sender == locks[lock].benefactor,
            "Only benefactor can call this."
        );
        _;
    }

    modifier validLock(bytes32 lock) { // Modifier
        require(
            !locks[lock].blocked,
            "The lock has been blocked."
        );
        _;
    }

    // A Deposited event should be emitted after ether has been successfully
    // deposited to the store.
    event Deposited(address benefactor, bytes32 lock, uint amount, uint32 timeout);

    // A Claimed event should be emitted after deposited ether has been
    // successfully claimed from the store.
    event Claimed(address beneficiary, bytes32 lock, uint key, uint amount);

    // A Recovered event should be emitted after ether has been recovered by the
    // initial benefactor.
    event Recovered(address benefactor, bytes32 lock, uint amount);

    // deposit should add the sent ether to the amount stored for the lock. The
    // claim period timeout should be reset to now + duration.
    function deposit(bytes32 lock, uint duration) external payable validLock(lock) {
        if(locks[lock].exists) {
            require(msg.sender == locks[lock].benefactor, "Only benefactor can call this.");
            locks[lock].amount += msg.value;
            locks[lock].timeout = uint32(now + duration);
        }
        else {
            locks[lock] = Lock(msg.sender, msg.value, uint32(now + duration), true, false);
        }

        emit Deposited(locks[lock].benefactor, lock, msg.value, locks[lock].timeout);
    }

    // claim should allow a holder of the correct pre-image key to withdraw the
    // ether stored for the lock = keccak256(key) within the claim period.
    function claim(uint key) external validLock(keccak256(abi.encodePacked(key))) {
        bytes32 lock = keccak256(abi.encodePacked(key));

        require(locks[lock].amount > 0, "The lock does not contain any ETH.");
        require(now <= locks[lock].timeout, "The lock has timed out and is not claimable anymore."); // check that the claim period is not over, yet

        msg.sender.transfer(locks[lock].amount);
        locks[lock].blocked = true;

        emit Claimed(msg.sender, lock, key, locks[lock].amount);
    }

    // recover should allow the initial depositor to recover the ether stored
    // for the lock after the claim period has ended.
    function recover(bytes32 lock) external onlyBenefactor(lock) validLock(lock) {
        require(now > locks[lock].timeout, "Lock is still claimable.");

        msg.sender.transfer(locks[lock].amount);
        locks[lock].blocked = true;

        emit Recovered(locks[lock].benefactor, lock, locks[lock].amount);
    }
}