var TokenMarket = artifacts.require("TokenMarket");

contract('TokenMarket', function(accounts) {

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
