pragma solidity ^0.4.23;


import "./utils/SafeMath.sol";



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
    uint256 public fee;

    mapping (address => address) public tokenAdmin;

    mapping (address => uint256) public depositedToken;
    mapping (address => uint256) public depositedEther;

    mapping (address => uint256) public price;

    mapping (address => uint256) public income;

    event TokenPrice(address indexed token, uint256 price);
    event WithdrawEther(address indexed token, address user, uint256 amount, uint256 value, uint256 fee);
    event WithdrawToken(address indexed token, address user, uint256 amount, uint256 value, uint256 fee);
    event DepositToken(address indexed token, uint256 amount);

    constructor() public {
        admin = msg.sender;
        feeAccount = address(0);
        fee = 0;   // 1 means 0.001% fee
    }

    function () payable external {

    }

    function changeAdmin(address _admin) public{
        require(msg.sender == admin && _admin != address(0) && _admin != admin);
        admin = _admin;
    }

    function changeFeeAccount(address _feeAccount) public{
        require(msg.sender == admin && _feeAccount != address(0) && _feeAccount != feeAccount);
        feeAccount = _feeAccount;
    }

    function changeTokenAdmin(address _token, address _admin) public{
        require(msg.sender == admin && _token != address(0) && _admin != address(0) && _admin != tokenAdmin[_token]);
        tokenAdmin[_token] = _admin;
    }

    function changeFee(uint256 _fee) public{
        require (msg.sender == admin) ;
        require (_fee != fee) ;
        fee = _fee;
    }

    function changeTokenPrice(address _token, uint256 _price) public{
        require (msg.sender == tokenAdmin[_token]) ;
        require (_price != 0 && _token != address(0) ) ;
        price[_token] = _price;

        emit TokenPrice(_token, _price);
    }

    function withdrawFee(uint256 _amount) public returns(bool){
        require (msg.sender == admin) ;
        require ( feeAccount != address(0) ) ;
        require ( _amount > 0);
        return feeAccount.call.value(_amount)();
    }

    function withdrawTokenFee(address _token, uint256 _amount) public returns(bool){
        require (msg.sender == admin) ;
        require ( feeAccount != address(0) ) ;
        require ( _amount > 0);
        return withdrawToken(feeAccount, _token, _amount);
    }

    function calcFee(uint256 _amount, uint256 _fee) private pure returns(uint256){
        return _amount.mul(_fee).div(100000);
    }

    function withdrawToken(address _user, address _token, uint256 _amount) private returns(bool){
        require (_token!=address(0x0));
        require (Token(_token).transfer(_user, _amount));

        return true;
    }

    function depositToken(address _user, address _token, uint256 _amount) private returns(bool){
        require (_token!=address(0));
        require (Token(_token).transferFrom(_user, address(this), _amount) );

        return true;
    }

    function depositTokenByAdmin(address _token, uint256 _amount) external {
        require( msg.sender == tokenAdmin[_token] );
        require( depositToken(msg.sender, _token, _amount) );

        depositedToken[_token] = depositedToken[_token].add(_amount);

        emit DepositToken(_token, _amount);
    }

    function depositEtherByAdmin(address _token) payable external {
        require( msg.sender == tokenAdmin[_token] ) ;

        depositedEther[_token] = depositedEther[_token].add(msg.value);
    }


    function exchangeToEther(address _token, uint256 _amount) external {
        require(_token!=address(0x0));
        require(price[_token] > 0);

        uint256 total = _amount.mul(price[_token]).div(1 ether);

        require( address(this).balance >= total && depositedEther[_token] >= total);
        uint256 charge = 0;
        if(fee != 0 ){
            charge = calcFee(total, fee);
            total = total.sub(charge);
        }

        require(depositToken(msg.sender, _token, _amount));
        require(msg.sender.call.value(total)());

        emit WithdrawEther(_token, msg.sender, _amount, total, charge);
    }

    function exchangeToToken(address _token, uint256 _amount) payable external {
        require(_token!=address(0x0));
        require(price[_token] > 0);
        require( depositedToken[_token] >= _amount );
        uint256 total = _amount.mul(price[_token]).div(1 ether);
        require( total == msg.value );
        uint256 charge = 0;
        uint gotToken = _amount;

        if(fee != 0 ){
            charge = calcFee(_amount, fee);
            gotToken = _amount.sub(charge);
        }

        require(withdrawToken(msg.sender, _token, gotToken));

        depositedToken[_token] = depositedToken[_token].sub(_amount);
        depositedEther[_token] = depositedEther[_token].add(total);

        if(charge > 0 ){
            income[_token] = income[_token].add(charge);
        }


        emit WithdrawToken(_token, msg.sender, gotToken, total, charge);
    }


}
