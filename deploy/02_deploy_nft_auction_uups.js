const { upgrades, ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { save } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log("部署用户地址", deployer);
  const Action = await ethers.getContractFactory("Auction02");
  //通过代理合约部署
  const auctionProxy = await upgrades.deployProxy(Action, [], {
    initializer: "initialize",
  });
  //等待合约部署完毕
  await auctionProxy.waitForDeployment();
  //代理合约地址
  const proxyAddress = await auctionProxy.getAddress();
  //实现合约地址
  const implAddress = await upgrades.erc1067.getImplementationAddress(
    proxyAddress
  );
  //合约信息存储文件
  const storePath = path.resolve(__dirname, "./.cache/proxyAuction.json");
  //将逻辑合约、代理合约 保存到指定地址上去
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
    abi: Action.interface.format("json"),
    address: proxyAddress,
    args: [],
    log: true,
  });
};

module.exports.tags = ["deployAuction02"];
