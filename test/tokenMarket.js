var TokenMarket = artifacts.require("TokenMarket.sol");
var AFANCoin = artifacts.require("AFANCoin.sol");
var web3 = require('web3');

contract('TokenMarket', function(accounts) {

    before(async function(){
        this.env = process.env.NODE_ENV ? process.env.NODE_ENV: 'develop';
        if(this.env == 'develop'){
            this.token = await AFANCoin.deployed();
        }

        this.market = await TokenMarket.deployed();
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
        console.log(this.token.address);

        let target = web3.utils.toWei('0.002', 'ether');
        await this.market.changeTokenPrice(this.token.address, target, {from: accounts[3]});
        let result = await this.market.price(this.token.address);
        console.log('token price:'+result.toNumber());
        return assert.equal(result.toNumber(), target, "changeTokenPrice() failed");
    });


});
