var TokenMarket = artifacts.require("TokenMarket.sol");
var AFANCoin = artifacts.require("AFANCoin.sol");

const Web3 = require("web3");
const web3 = new Web3(new Web3.providers.HttpProvider('HTTP://127.0.0.1:7545'));

contract('TokenMarket', function(accounts) {

    before(async function(){
        this.env = process.env.NODE_ENV ? process.env.NODE_ENV: 'develop';
        this.market = await TokenMarket.deployed();
        if(this.env == 'develop'){
            this.token = await AFANCoin.deployed();
            await this.token.transfer(accounts[3], web3.utils.toWei('30000', 'ether'), {from: accounts[0]});
            let balance = await this.token.balanceOf(accounts[3]);
            console.log('token balance:'+balance);
        }


    });

    it("admin change", async function() {
        await this.market.changeAdmin(accounts[1], {from: accounts[0]});
        let admin = await this.market.admin.call();
        console.log('admin:'+admin);
        return assert.equal(admin, accounts[1], "changeAdmin() failed");
    });

    it("feeAccount change", async function() {
        await this.market.changeFeeAccount(accounts[2], {from: accounts[1]});
        let feeAccount = await this.market.feeAccount.call();
        console.log('feeAccount:'+feeAccount);
        return assert.equal(feeAccount, accounts[2], "changeFeeAccount() failed");
    });

    it("tokenAdmin change", async function() {
        console.log(this.token.address);
        await this.market.changeTokenAdmin(this.token.address, accounts[3], {from: accounts[1]});
        let tokenAdmin = await this.market.tokenAdmin(this.token.address);
        console.log('tokenAdmin:'+tokenAdmin);
        return assert.equal(tokenAdmin, accounts[3], "changeTokenAdmin() failed");

    });

    it("tokenPrice change", async function() {
        let target = web3.utils.toWei('0.002', 'ether');
        await this.market.changeTokenPrice(this.token.address, target, {from: accounts[3]});
        let result = await this.market.price(this.token.address);
        console.log('token price:'+result.toNumber());
        return assert.equal(result.toNumber(), target, "changeTokenPrice() failed");
    });

    it("deposit Token", async function() {
        let target = web3.utils.toWei('5000', 'ether');
        await this.token.approve(this.token.address, target, {from:accounts[3]});
        let allow = await this.token.allowance(accounts[3], this.token.address );

        console.log('allowed:'+allow.toNumber());


        await this.market.depositTokenByAdmin(this.token.address, target, {from:accounts[3]});

        let result = await this.market.depositedToken(this.token.address);

        console.log('deposited Token:'+result.toNumber());

        return assert.equal(result.toNumber(), target, "depositTokenByAdmin() failed");
    });

    it("deposit Ether", async function() {
        let target = web3.utils.toWei('5', 'ether');

        await this.market.depositEtherByAdmin(this.token.address, {from:accounts[3], value:target});

        let result = await this.market.depositedEther(this.token.address);

        console.log('deposited Ether:'+result.toNumber());

        return assert.equal(result.toNumber(), target, "depositEtherByAdmin() failed");
    });

    it("exchange to Token", async function() {
        let price = await this.market.price(this.token.address);
        let amount = web3.utils.toWei('50', 'ether');
        let total = price * 50;

        let beforeTokenBalance = await this.market.depositedToken(this.token.address);
        console.log('token price:'+price.toNumber()+' total:'+total);

        console.log('beforeTokenBalance:'+beforeTokenBalance);
        await this.market.exchangeToToken(this.token.address, amount, {from:accounts[4], value:total});


        let afterTokenBalance = await this.market.depositedToken(this.token.address);
        console.log('afterTokenBalance:'+afterTokenBalance);

        let expectTokenBalance = parseFloat(beforeTokenBalance) - parseFloat(amount);
        console.log('expectToken:'+expectTokenBalance);


        let balanceToken = await this.token.balanceOf(accounts[4]);
        console.log(accounts[4]+' has '+balanceToken.toNumber());



        return assert.equal(expectTokenBalance , (parseFloat(afterTokenBalance)), "unmatched balance failed");
    });


});
