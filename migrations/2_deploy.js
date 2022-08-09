const Factory = artifacts.require('Factory.sol');
const SwapLibrary = artifacts.require('BullCoinLibrary.sol');
const Swap = artifacts.require('Swap.sol');
const Staking = artifacts.require('Staking.sol');

//these addresses deployed on ropsten
const testBULC="0xa45EaFE149785Acd6bD57cdF8B351d8fe6554aA8"
const testBUSD="0x7A3A2e8636C7A3492cF9f6c0F0904A38CFb4e1A9"
const testWETH="0xf0ca7A7882bb8592740eBa6accb6eD9413b582DA"



module.exports = async function (deployer, _network, addresses) {
  await deployer.deploy(Factory, addresses[0])
  const factory = await Factory.deployed()
  await factory.createPair(testBULC,testBUSD);
  const BulcBusdPair=await factory.getPair(testBULC,testBUSD)
  await deployer.deploy(SwapLibrary)
  await deployer.link(SwapLibrary, Swap);
  await deployer.deploy(Swap,factory.address,testWETH);
  await deployer.link(SwapLibrary, Staking);
  await deployer.deploy(Staking,BulcBusdPair,testBULC)
};