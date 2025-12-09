// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
contract Auction is Initializable,UUPSUpgradeable,Ownable {
    
    //记录每个token对应的token信息
    mapping (uint256 => AuctionInfo) tokenMap;

    struct AuctionInfo {
        //tokenID
        uint256 _tokenId;
        //起拍价
        uint256 _startPrice;
        //当前最高价
        uint256 _highestPrice;
        //拍卖开始时间(秒)
        uint256 _startTime;
        //拍卖持续时间(秒)
        uint256 _duration;

        //出售者
        address _seller,
        //出价最高的地址
        address _highestBuyer;
        //NFT合约地址
        address _contractAddress;

        //拍卖是否结束
        bool _ended;
    }

    constructor() {}

    function initialize() public initializer {
        _owner = msg.sender;
         // 1. 初始化父类（顺序：先初始化基础类，再初始化业务类）
        __Initializable_init(); // 初始化 Initializable
        __UUPSUpgradeable_init(); // 初始化 UUPSUpgradeable
    }

    function  _authorizeUpgrade(address newImplementation) internal override onlyOwner{
        //UUPS升级的核心函数
    }

    function createAuction(uint memory tokenId,uint256 memory startTime,uint256 memory duration,uint256 startPrice,address nftContractAddress) public onlyOwner{
       AuctionInfo memory info=(AuctionInfo{
           _startPrice:startPrice,
           _tokenId:tokenId,
           _startTime:startTime,
           _duration:duration

       })
    }

   //出价
   function bid(uint256 calldata tokenId,uint256 calldata price) external payable {
      MyToken storage token =tokenMap[tokenId];
    require(token._highestPrice<price,"the price must grate than last price");
    token._highestPrice=price;
    token._highestBuyer=msg.sender;
    tokenMap[tokenId]=token;
   }
   

   function endAuction(uint256 calldata tokenId) external onlyOwner{
      MyToken token=tokenMap[tokenId];
      
   }
}
