require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
/** @type import('hardhat/config').HardhatUserConfig */

// 1. 添加自定义 "accounts" 任务（核心）
task(
  "accounts",
  "Prints the list of accounts for the specified network"
).setAction(async (taskArgs, hre) => {
  // 2. 连接到指定网络（这里是 sepolia），获取账号列表
  const accounts = await hre.ethers.getSigners();

  // 3. 打印账号地址和对应名称（匹配 namedAccounts）
  console.log("📡 Connected to Sepolia network - Accounts:");
  accounts.forEach((account, index) => {
    let accountName = "Unknown";
    if (index === 0) accountName = "deployer";
    if (index === 1) accountName = "signerAccount";
    if (index === 2) accountName = "buyerAccount";
    console.log(`[${index}] ${accountName}: ${account.address}`);
  });
});

module.exports = {
  solidity: "0.8.28",
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_URL,
      chainId: 11155111,
      accounts: [
        process.env.PRIVATE_KEY1,
        process.env.PRIVATE_KEY2,
        process.env.PRIVATE_KEY3,
      ],
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    signerAccount: {
      default: 1,
    },
    buyerAccount: {
      default: 2,
    },
  },
};
