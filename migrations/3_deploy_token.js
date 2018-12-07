var AFANCoin = artifacts.require("AFANCoin.sol");

module.exports = function(deployer) {
    const env = process.env.NODE_ENV ? process.env.NODE_ENV : 'develop';
    if(env === 'develop'){
        deployer.deploy(AFANCoin, 100000);
    }
};
