var TokenMarket = artifacts.require("TokenMarket.sol");
var AFANCoin = artifacts.require("AFANCoin.sol");

contract('TokenMarket', function(accounts) {

    before(async function(){
        this.env = process.env.NODE_ENV ? process.env.NODE_ENV: 'develop';
        if(this.env == 'develop'){
            this.token = await AFANCoin.deployed();
        }

    });

    it("admin change", function() {
        return TokenMarket.deployed().then(function(instance) {
            contractInstance = instance;
            return contractInstance.changeAdmin(accounts[1], {from: accounts[0]});
        }).then(function() {
            return contractInstance.admin.call();
        }).then(function(admin) {
            console.log('admin:'+admin);
            assert.equal(admin, accounts[1], "changeAdmin() failed");
        });
    });

    it("feeAccount change", function() {
        return TokenMarket.deployed().then(function(instance) {
            contractInstance = instance;
            return contractInstance.changeFeeAccount(accounts[2], {from: accounts[1]});
        }).then(function() {
            return contractInstance.feeAccount.call();
        }).then(function(feeAccount) {
            console.log('feeAccount:'+feeAccount);
            assert.equal(feeAccount, accounts[2], "changeFeeAccount() failed");
        });
    });

    it("tokenAdmin change", function() {
        console.log(this.token.address);
        return TokenMarket.deployed().then((instance)=> {
            contractInstance = instance;
            return contractInstance.changeTokenAdmin(this.token.address, accounts[3], {from: accounts[1]});
        }).then(()=> {
            return contractInstance.tokenAdmin(this.token.address);
        }).then((tokenAdmin)=> {
            console.log('tokenAdmin:'+tokenAdmin);
            assert.equal(tokenAdmin, accounts[3], "changeTokenAdmin() failed");
        });
    });


});
