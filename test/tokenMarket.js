var TokenMarket = artifacts.require("TokenMarket.sol");
var AFANCoin = artifacts.require("AFANCoin.sol");

contract('TokenMarket', function(accounts) {

    before(async function(){
        let token = await AFANCoin.deployed();
        console.log(token);
    });

    it("admin change", function() {
        return TokenMarket.deployed().then(function(instance) {
            contractInstance = instance;
            return contractInstance.changeAdmin(accounts[1], {from: accounts[0]});
        }).then(function() {
            return contractInstance.admin.call();
        }).then(function(admin) {
            console.log(admin);
            assert.equal(admin, accounts[1], "changeAdmin() failed");
        });
    });

});
