const { upgrades, ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { save } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log("部署用户地址:", deployer);
  const Auction = await ethers.getContractFactory("Auction");
  //通过代理合约部署
  const ntfAuctionProxy = await upgrades.deployProxy(Auction, [], {
    initializer: "initialize",
  });
  //等待合约部署完毕
  await ntfAuctionProxy.waitForDeployment();
  const proxyAddress = await ntfAuctionProxy.getAddress();
  const implAddress = await upgrades.erc1967.getImplementationAddress(
    proxyAddress
  );
  console.log("代理合约地址:", proxyAddress);
  console.log("实现合约地址:", implAddress);

  const storePath = path.resolve(__dirname, "./.cache/proxyNftAuction.json");
  // console.log("当前路径:",__dirname)
  // console.log("存储路径:",storePath)

  fs.writeFileSync(
    storePath,
    JSON.stringify({
      proxyAddress,
      implAddress,
      implAddress: await upgrades.erc1967.getImplementationAddress(
        proxyAddress
      ),
    })
  );

  await save("AuctionProxy", {
    abi: Auction.interface.format("json"),
    address: proxyAddress,
    args: [],
    log: true,
  });
};

module.exports.tags = ["deployAuction"];
