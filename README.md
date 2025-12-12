# NFT 拍卖场

这个工程主要实现对NTF的拍卖，支持用户使用USDC或者ETH进行竞价拍卖  主要有以下功能
1. 添加一个待拍卖的NFT
   1. 需要提供NFT的合约地址以及tokenId
   2. 设置NFT的起始价格(NFT(wei))
2. 用户出价（ETH或者USDC）参与拍卖
   1. 上一个最高竞拍会自动退款
3. 结束拍卖
   1. 拍卖所得将ETH或者USDC将自动转给卖家，
   2. NFT将自动转移给最高竞拍者

要运行这个工程需要按照以下步骤进行:
1. 在项目跟目录新增.env文件，并配置
```shell
  SEPOLIA_URL=sepolia URL地址
  SEPOLIA_CHAINID=11155111
  PRIVATE_KEY1=账户1的私钥
  PRIVATE_KEY2=账户2的私钥
  PRIVATE_KEY3=账户3的私钥
```
2. 执行以下命令
```shell
npx hardhat help
#执行测试脚本
npx hardhat test
REPORT_GAS=true npx hardhat test
#部署合约到指定网络上去
npx hardhat run deploy/xxx.js --network sepolia
```
