const RPT = artifacts.require("ERC20")
const Treasury = artifacts.require("Treasury")
const PaymentGateWay = artifacts.require("PaymentGateway")

module.exports = async function(deployer, network, accounts) {
   await deployer.deploy(RPT)
   let RPTInstance = await RPT.deployed()

   await deployer.deploy(Treasury, RPTInstance.address)
   let treasuryInstance = await Treasury.deployed()

   await deployer.deploy(PaymentGateWay, treasuryInstance.address, accounts[0], {from: accounts[1]})
}

