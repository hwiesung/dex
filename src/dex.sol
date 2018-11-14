pragma solidity ^0.4.23;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


interface Token {
    /// @return total amount of tokens
    function totalSupply()  external;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) external returns (uint256);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external;

}



contract EtherDex  {
    using SafeMath for uint256;

    address public admin; //the admin address
    address public feeAccount; //the account that will receive fees
    uint public feeMake; //percentage times (1 ether)
    uint public feeTake; //percentage times (1 ether)
    uint public feeRebate; //percentage times (1 ether)

    mapping (bytes32 => bool) public asks;

    event Ask(bytes32 hash, address tokenGive, uint amountGive, uint price, uint expire, uint nonce, address seller);
    event Sold(bytes32 hash, address tokenGive, uint amountGive, uint price, address seller, address buyer);
    event Cancel(bytes32 hash, address tokenGive, uint amountGive, uint price, address seller, address buyer);

    event Deposit(address token, address user, uint amount);
    event Withdraw(address token, address user, uint amount);

    constructor(address admin_) public {
        admin = admin_;
        feeAccount = address(0);
        feeMake = 0;
        feeTake = 0;
        feeRebate = 0;
    }

    function () payable external {

    }

    function changeAdmin(address admin_) public{
        assert(msg.sender == admin);
        admin = admin_;
    }

    function changeFeeAccount(address feeAccount_) public{
        assert (msg.sender == admin);
        feeAccount = feeAccount_;
    }

    function changeFeeMake(uint feeMake_) public{
        assert (msg.sender == admin) ;
        assert (feeMake_ <= feeMake) ;
        feeMake = feeMake_;
    }

    function changeFeeTake(uint feeTake_) public {
        assert (msg.sender == admin);
        assert (feeTake_ <= feeTake && feeTake_ >= feeRebate);
        feeTake = feeTake_;
    }

    function changeFeeRebate(uint feeRebate_) public{
        assert (msg.sender == admin);
        assert (feeRebate_ >= feeRebate && feeRebate_ <= feeTake);
        feeRebate = feeRebate_;
    }

    function depositToken(address user, address token, uint256 amount) private returns(bool){
        require (token!=address(0));
        require (Token(token).transferFrom(user, this, amount) );

        emit Deposit(token, user, amount);

        return true;
    }

    function withdrawToken(address user, address token, uint256 amount) private returns(bool){
        require (token!=address(0x0));
        require (Token(token).transfer(user, amount));

        emit Withdraw(token, user, amount);
        return true;
    }

    function askToken(address token, uint amount, uint price, uint expire, uint nonce) external {
        bytes32 hash = sha256(abi.encodePacked(this, token, amount, price, expire, nonce));
        uint256 total = price.mul( amount ).div(1 ether);
        require( total >= (0.05 ether) && total < (10 ether) );
        require(depositToken(msg.sender, token, amount));

        asks[hash] = true;

        emit Ask(hash, token, amount, price, expire, nonce, msg.sender);
    }

    function buy(bytes32 targetHash, address targetToken, uint targetAmount, uint targetPrice, uint targetExpire,  uint targetNone, address seller) payable external {
        bytes32 hash = sha256(abi.encodePacked(this, targetToken, targetAmount, targetPrice, targetExpire, targetNone));
        uint256 total = targetPrice.mul( targetAmount ).div(1 ether);
        require( asks[hash] && targetHash == hash && block.number <= targetExpire );
        require( total == msg.value );
        require( seller.call.value(msg.value)() );
        require( withdrawToken(msg.sender, targetToken, targetAmount) );

        asks[hash] = false;

        bytes32 soldHash = sha256(abi.encodePacked(hash, msg.sender));

        emit Sold(soldHash, targetToken, targetAmount, targetPrice, seller, msg.sender);

    }

    function cancelOrder(bytes32 targetHash, address targetToken, uint targetAmount, uint targetPrice, uint targetExpire,  uint targetNone) external {
        emit Cancel(soldHash, targetToken, targetAmount, targetPrice, seller, msg.sender);
    }


}
