const { ethers, deployments } = require("hardhat");
const { expect } = require("chai");
const hre = require("hardhat");

describe("test erc721", async function () {
  it("Should be ok", async function () {
    await main();
  });
});

async function main() {
  await deployments.fixture(["deployAuction"]);
  const AuctionProxy = await deployments.get("AuctionProxy");

  const [signer, buyer] = await ethers.getSigners();

  //1.部署ERC721 合约 start
  const FelixToken = await ethers.getContractFactory("FelixToken");
  const felixToken = await FelixToken.deploy();
  await felixToken.waitForDeployment();
  //###########合约部署结束###############

  const felixTokenAddress = await felixToken.getAddress();
  console.log("##########################################");
  console.log("felixTokenAddress:", felixTokenAddress);
  console.log("signer 地址:", signer.address); // 必须有效
  console.log("buyer 地址:", buyer.address); // 必须有效

  //mint 10个NFT
  for (let i = 0; i < 10; i++) {
    await felixToken.mint(signer.address, i + 1);
  }

  const tokenId = 1;
  //2. 调用 createAuction 方法创建拍卖
  const nftAuction = await ethers.getContractAt(
    "Auction",
    AuctionProxy.address
  );
  //给代理合约授权
  await felixToken
    .connect(signer)
    .setApprovalForAll(AuctionProxy.address, true);

  console.log("NFT 合约地址:", felixTokenAddress);
  console.log("拍卖代理合约地址:", AuctionProxy.address);
  console.log("要授权的地址（拍卖合约）:", AuctionProxy.address);

  await nftAuction.createAuction(
    10,
    ethers.parseEther("0.01"),
    felixTokenAddress,
    tokenId
  );

  const auction = await nftAuction.auctions(tokenId);

  console.log("创建拍卖成功::", auction);

  //3. 购买者参与拍卖
  await nftAuction
    .connect(buyer)
    .placeBid(tokenId, { value: ethers.parseEther("0.02") });

  //4.结束拍卖
  //等待10秒
  await new Promise((resolve) => setTimeout(resolve, 12 * 1000));
  await nftAuction.connect(signer).endAuction(tokenId);

  //验证结果
  const auctionResult = await nftAuction.auctions(tokenId);
  console.log("结束拍卖后读取拍卖结果::", auctionResult);
  expect(auctionResult.highestBidder).to.equal(buyer.address);
  expect(auctionResult.highestBid).to.equal(ethers.parseEther("0.02"));

  const owner = await felixToken.ownerOf(tokenId);
  console.log("owner::", owner);
  expect(owner).to.equal(buyer.address);
}
