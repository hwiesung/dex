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



contract TokenMarket  {
    using SafeMath for uint256;

    address public admin;
    address public feeAccount;
    uint public makerFee; //for seller
    uint public takerFee; //for buyer

    mapping (bytes32 => bool) public asks;

    event Ask(bytes32 hash, address token, uint amount, uint price, uint total, uint expire, uint nonce, address indexed seller);
    event Sold(bytes32 hash, address token, uint amount, uint price, address indexed seller, address indexed buyer);
    event Cancel(bytes32 hash, address token, uint amount, uint price, address indexed seller);


    constructor() public {
        admin = msg.sender;
        feeAccount = msg.sender;
        makerFee = 0;
        takerFee = 0;
    }

    function () payable external {

    }

    function changeAdmin(address _admin) public{
        require(msg.sender == admin && _admin != admin);
        admin = _admin;
    }

    function changeFeeAccount(address _feeAccount) public{
        require(msg.sender == admin && _feeAccount != feeAccount);
        feeAccount = _feeAccount;
    }


    function changeMakerFee(uint _makerFee) public{
        require (msg.sender == admin) ;
        require (_makerFee != makerFee) ;
        makerFee = _makerFee;
    }

    function changeTakerFee(uint _takerFee) public{
        require (msg.sender == admin) ;
        require (_takerFee != takerFee) ;
        takerFee = _takerFee;
    }

    function depositToken(address user, address token, uint256 amount) private returns(bool){
        require (token!=address(0));
        require (Token(token).transferFrom(user, this, amount) );

        return true;
    }

    function withdrawToken(address user, address token, uint256 amount) private returns(bool){
        require (token!=address(0x0));
        require (Token(token).transfer(user, amount));

        return true;
    }

    function askToken(address token, uint amount, uint price, uint expire, uint nonce) external {
        bytes32 hash = sha256(abi.encodePacked(this, token, amount, price, expire, nonce, msg.sender));
        uint256 total = price.mul( amount ).div(1 ether);
        require( !asks[hash] );
        require( total >= (0.05 ether) && total < (10 ether) );
        require(depositToken(msg.sender, token, amount));

        asks[hash] = true;

        emit Ask(hash, token, amount, price, total, expire, nonce, msg.sender);
    }

    function buy(bytes32 targetHash, address targetToken, uint targetAmount, uint targetPrice, uint targetTotal, uint targetExpire,  uint targetNonce, address seller) payable external {
        bytes32 hash = sha256(abi.encodePacked(this, targetToken, targetAmount, targetPrice, targetExpire, targetNonce, seller));
        require( asks[hash] && targetHash == hash && block.number <= targetExpire );
        require( targetTotal == msg.value );
        require( seller.call.value(msg.value)() );
        require( withdrawToken(msg.sender, targetToken, targetAmount) );

        asks[hash] = false;

        bytes32 soldHash = sha256(abi.encodePacked(hash, msg.sender));

        emit Sold(soldHash, targetToken, targetAmount, targetPrice, seller, msg.sender);

    }

    function cancelOrder(bytes32 targetHash, address targetToken, uint targetAmount, uint targetPrice, uint targetExpire, uint targetNonce) external {
        bytes32 hash = sha256(abi.encodePacked(this, targetToken, targetAmount, targetPrice, targetExpire, targetNonce, msg.sender));
        require( asks[hash] && targetHash == hash );
        require( withdrawToken(msg.sender, targetToken, targetAmount) );

        asks[hash] = false;

        emit Cancel(hash, targetToken, targetAmount, targetPrice, msg.sender);
    }

}
