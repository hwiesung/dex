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
    mapping (address => mapping (address => uint)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)
    mapping (address => mapping (bytes32 => uint)) public orders; //mapping of user accounts to mapping of order hashes to booleans (true = submitted by user, equivalent to offchain signature)
    mapping (address => mapping (bytes32 => uint)) public orderFills; //mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled)
    mapping (address => mapping (bytes32 => uint)) public orderPrices;

    event SellOrder(bytes32 hash, address tokenGive, uint amountGive, uint price, uint expire, uint nonce, address user);
    event Order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user);
    event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);

    constructor(address admin_, address feeAccount_, uint feeMake_, uint feeTake_, uint feeRebate_) public {
        admin = admin_;
        feeAccount = feeAccount_;
        feeMake = feeMake_;
        feeTake = feeTake_;
        feeRebate = feeRebate_;
    }

    function () payable external {
        tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add( msg.value);
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
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

    function deposit()  payable external {
        tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add( msg.value);
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }

    function withdraw(uint256 amount) public {
        require (tokens[address(0)][msg.sender] >= amount);
        tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].sub(amount);
        require (msg.sender.call.value(amount)());
        emit Withdraw(address(0), msg.sender, amount, tokens[address(0)][msg.sender]);
    }

    function depositToken(address token, uint256 amount) public{
        require (token!=address(0));
        require (Token(token).approve(this, amount) );
        require (Token(token).transferFrom(msg.sender, this, amount) );
        tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function withdrawToken(address token, uint256 amount) public{
        require (token!=address(0x0));
        require (tokens[token][msg.sender] >= amount);
        tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
        require (Token(token).transfer(msg.sender, amount));
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function balanceOf(address token, address user) public view returns (uint256) {
        return tokens[token][user];
    }

    function sellOrder(address tokenGive, uint amountGive, uint price, uint expire, uint nonce) public {
        bytes32 hash = sha256(abi.encodePacked(this, tokenGive, amountGive, price, expire, nonce));
        orders[msg.sender][hash] = amountGive;
        orderPrices[msg.sender][hash] = price;
        emit SellOrder(hash, tokenGive, amountGive, price, expire, nonce, msg.sender);
    }


    function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) public {
        //amount is in amountGet terms
        bytes32 hash = sha256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
        assert ((
            (orders[user][hash]>0 && ecrecover(keccak256( abi.encodePacked("\x19Ethereum Signed Message:\n32", hash) ),v,r,s) == user) ||
            block.number > expires ||
            orderFills[user][hash].add(amount) > amountGet
            ));
        tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
        orderFills[user][hash] = orderFills[user][hash].add(amount);
        emit Trade(tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, msg.sender);
    }

    function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {
        uint feeMakeXfer = amount.mul(feeMake) / (1 ether);
        uint feeTakeXfer = amount.mul( feeTake) / (1 ether);
        uint feeRebateXfer = 0;

        tokens[tokenGet][msg.sender] = tokens[tokenGet][msg.sender].sub( amount.add(feeTakeXfer));
        tokens[tokenGet][user] = tokens[tokenGet][user].add( amount.add(feeRebateXfer).sub( feeMakeXfer));
        tokens[tokenGet][feeAccount] = tokens[tokenGet][feeAccount].add(feeMakeXfer.add(feeTakeXfer).sub(feeRebateXfer));
        tokens[tokenGive][user] = tokens[tokenGive][user].sub(amountGive.mul( amount) / amountGet);
        tokens[tokenGive][msg.sender] = tokens[tokenGive][msg.sender].add( amountGive.mul( amount) / amountGet);
    }

    function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) public constant returns(bool) {
        if (!(
        tokens[tokenGet][sender] >= amount &&
        availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount
        )) return false;
        return true;
    }

    function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) internal constant returns(uint) {
        bytes32 hash = sha256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
        if (!(
        ( ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == user) &&
        block.number <= expires
        )) return 0;
        uint available1 = amountGet.sub( orderFills[user][hash]);
        uint available2 = amountGet.mul(tokens[tokenGive][user]) / amountGive;
        if (available1<available2) return available1;
        return available2;
    }

    function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user) public constant returns(uint) {
        bytes32 hash = sha256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
        return orderFills[user][hash];
    }

    function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 hash = sha256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
        assert ((orders[msg.sender][hash] > 0 && ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) != msg.sender));
        orderFills[msg.sender][hash] = amountGet;
        emit Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
    }
}
