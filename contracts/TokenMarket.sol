pragma solidity ^0.4.23;


import "./utils/SafeMath.sol";
import "./tokens/ERC20.sol";

contract TokenMarket  {
    using SafeMath for uint256;

    address public admin;
    address public feeAccount;
    uint256 public makerFee; //for seller
    uint256 public takerFee; //for buyer

    mapping (address => address) public tokenAdmin;

    mapping (address => uint) public incomes;
    
    constructor(address _feeAccount) public {
        admin = msg.sender;
        feeAccount = _feeAccount;
        makerFee = 0;   // 1 means 0.001% fee
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

    function changeTokenAdmin(address _admin) public{
        require(msg.sender == admin && _admin != admin);
        admin = _admin;
    }


    function changeMakerFee(uint256 _makerFee) public{
        require (msg.sender == admin) ;
        require (_makerFee != makerFee) ;
        makerFee = _makerFee;
    }

    function changeTakerFee(uint256 _takerFee) public{
        require (msg.sender == admin) ;
        require (_takerFee != takerFee) ;
        takerFee = _takerFee;
    }

    function withdrawFee(uint256 amount) public returns(bool){
        require (msg.sender == admin) ;
        require ( feeAccount != address(0) ) ;
        return feeAccount.call.value(amount)();
    }

    function withdrawTokenFee(address token, uint256 amount) public returns(bool){
        require (msg.sender == admin) ;
        require ( feeAccount != address(0) ) ;
        return withdrawToken(feeAccount, token, amount);
    }

    function calFee(uint256 amount, uint256 fee) private pure returns(uint256){
        return amount.mul(fee).div(100000);
    }

    function withdrawToken(address user, address token, uint256 amount) private returns(bool){
        require (token!=address(0x0));
        require (ERC20(token).transfer(user, amount));

        return true;
    }

    function depositToken(address user, address token, uint256 amount) private returns(bool){
        require (token!=address(0));
        require (Token(token).transferFrom(user, this, amount) );

        return true;
    }


}
