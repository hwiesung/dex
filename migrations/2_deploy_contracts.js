var TokenMarket = artifacts.require("TokenMarket.sol");

module.exports = function(deployer) {
    deployer.deploy(TokenMarket);
};
