// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Auction is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    //记录每个token对应的token信息
    mapping(uint256 => AuctionInfo) private tokenMap;

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
        address _seller;
        //出价最高的地址
        address _highestBuyer;
        //NFT合约地址
        address _contractAddress;
        //拍卖是否结束
        bool _ended;
    }

    constructor() {}

    function initialize() public initializer {
        // 1. 初始化父类（顺序：先初始化基础类，再初始化业务类）
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init(); // 初始化 UUPSUpgradeable
    }

    // ======== UUPS升级必需函数（控制升级权限）=======
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {
        // 仅所有者可触发升级，无额外逻辑需留空（确保函数体存在即可）
    }

    function createAuction(
        uint tokenId,
        uint256 startTime,
        uint256 duration,
        uint256 startPrice,
        address nftContractAddress,
        address seller
    ) public onlyOwner {
        AuctionInfo memory info = AuctionInfo({
            _startPrice: startPrice,
            _tokenId: tokenId,
            _startTime: startTime,
            _duration: duration,
            _seller: seller,
            _contractAddress: nftContractAddress,
            _ended: false,
            _highestBuyer: address(0),
            _highestPrice: 0
        });
        tokenMap[tokenId] = info;
    }

    //出价
    function bid(uint256 tokenId) external payable {
        AuctionInfo memory token = tokenMap[tokenId];
        require(
            token._highestPrice < msg.value,
            "the price must greate than last price"
        );
        require(
            !token._ended &&
                (block.timestamp < (token._startTime + token._duration)),
            "the auction has finished"
        );
        if (token._highestBuyer != address(0)) {
            //有更高的出价，则将上一个最高价的金额退回给买家
            payable(token._highestBuyer).transfer(token._highestPrice);
        }
        token._highestPrice = msg.value;
        token._highestBuyer = msg.sender;
        //写回状态变量
        tokenMap[tokenId] = token;
    }

    function endAuction(uint256 tokenId) external onlyOwner {
        AuctionInfo memory token = tokenMap[tokenId];
        require(!token._ended, "the auction has been ended");
        token._ended = true;
        IERC721(address(this)).safeTransferFrom(
            token._seller,
            token._highestBuyer,
            token._tokenId
        );
        if (token._highestBuyer != address(0)) {
            //出售成功，将竞拍的ETH转给卖家
            payable(token._seller).transfer(token._highestPrice);
        }
    }
}
