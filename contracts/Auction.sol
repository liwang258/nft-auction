// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Auction is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    //记录每个token对应的token信息
    mapping(uint256 => AuctionInfo) private tokenMap;
    //预言机eth转usd的喂价数据
    AggregatorV3Interface internal eth2usdDataFeed;
    //USDC 小数位数（通常是 6 位）
    uint8 public constant USDC_DECIMALS = 6;

    // Chainlink 价格喂价小数位数（ETH/USD 是 8 位，需根据实际喂价调整）
    uint8 public constant ORACLE_DECIMALS = 8;

    address private usdcContract;

    enum CurrencyType {
        USDC,
        ETH
    }

    struct AuctionInfo {
        //tokenID
        uint256 _tokenId;
        //起拍价(W)
        uint256 _startPrice;
        //当前最高价(W)
        uint256 _highestPrice;
        //拍卖开始时间(秒)
        uint256 _startTime;
        //拍卖持续时间(秒)
        uint256 _duration;
        //货币种类 1:ETH 2:USDC
        CurrencyType _currencyType;
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

    function initialize(
        address _eth2usdDataFeed,
        address _usdcAddress
    ) public initializer {
        // 1. 初始化父类（顺序：先初始化基础类，再初始化业务类）
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init(); // 初始化 UUPSUpgradeable
        eth2usdDataFeed = AggregatorV3Interface(_eth2usdDataFeed); //初始化eth转USD的喂价合约地址
        usdcContract = _usdcAddress; //USDC合约地址
    }

    // ======== UUPS升级必需函数（控制升级权限）=======
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {
        // 仅所有者可触发升级，无额外逻辑需留空（确保函数体存在即可）
    }

    function createAuction(
        uint256 tokenId,
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
            _currencyType: CurrencyType.ETH,
            _ended: false,
            _highestBuyer: address(0),
            _highestPrice: 0
        });
        tokenMap[tokenId] = info;
    }

    //出价
    function bid(uint256 tokenId, uint256 price) external payable {
        AuctionInfo storage token = tokenMap[tokenId];
        require(
            !token._ended &&
                (block.timestamp < (token._startTime + token._duration)),
            "the auction has finished"
        );

        int256 exchangeRateRaw = getChainlinkDataFeedLatestAnswer();
        require(exchangeRateRaw > 0, "the exchage rate must be great then 0");
        uint256 exchangeRate = uint256(exchangeRateRaw); // 确认喂价为正后，转为无符号

        //当前最高价：统一转换成ETH来计算
        uint256 lastPriceInEth;
        if (token._currencyType == CurrencyType.USDC) {
            lastPriceInEth =
                (token._highestPrice * 1e18) /
                ((10 ** USDC_DECIMALS * exchangeRate) /
                    (10 ** (18 - ORACLE_DECIMALS)));
        } else {
            lastPriceInEth = token._highestPrice;
        }
        //当前最高价：统一转换成ETH来计算
        uint256 requestPrice;
        if (msg.value == 0) {
            requestPrice =
                (price * 1e18) /
                ((10 ** USDC_DECIMALS * exchangeRate) /
                    (10 ** (18 - ORACLE_DECIMALS)));
        }

        require(
            requestPrice > token._startPrice,
            "the price must greate than start price"
        );

        require(
            requestPrice > lastPriceInEth,
            "the price must greate than last price"
        );
        //如果用户传递的是USDC，则需要先接受用户的USDC
        if (msg.value == 0) {
            token._currencyType = CurrencyType.USDC;
            IERC20 erc20 = IERC20(usdcContract);
            bool received = erc20.transferFrom(
                msg.sender,
                address(this),
                price
            );
            require(received, "Failed to receive USDC");
        }
        //退还上一个最高出价的款项
        refund(tokenId);
        token._highestBuyer = msg.sender;
        //将当前竞价设置为最高出价
        if (msg.value > 0) {
            token._highestPrice = msg.value;
            token._currencyType = CurrencyType.ETH;
        } else {
            token._highestPrice = price;
            token._currencyType = CurrencyType.USDC;
        }
    }

    //将已经出价的退款给竞拍者
    function refund(uint256 tokenId) private {
        AuctionInfo storage token = tokenMap[tokenId];
        //退回上一个最高出价,只有上一次出价>0且是非0地址 才执行退款逻辑
        if (token._highestBuyer != address(0) && token._highestPrice > 0) {
            if (token._currencyType == CurrencyType.ETH) {
                // 上一轮是 ETH 出价，用 call 退款（避免 2300 gas 限制）
                (bool success, ) = payable(token._highestBuyer).call{
                    value: token._highestPrice
                }("");
                require(success, "ETH refund failed");
            } else {
                IERC20 erc20 = IERC20(usdcContract);
                // 上一轮是 USDC 出价，需通过 USDC 合约转账退款（假设已导入 IERC20）
                erc20.transfer(token._highestBuyer, token._highestPrice);
            }
        }
    }

    function endAuction(uint256 tokenId) external onlyOwner {
        AuctionInfo memory token = tokenMap[tokenId];
        require(!token._ended, "the auction has been ended");
        token._ended = true;
        //只有有人竞价，且出价价格>0才会执行转账动作
        if (token._highestBuyer != address(0) && token._highestPrice > 0) {
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

    //获取最新的喂价数据
    function getChainlinkDataFeedLatestAnswer() public view returns (int256) {
        (
            ,
            /* uint80 roundId */
            int256 answer /*uint256 startedAt*/ /*uint256 updatedAt*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = eth2usdDataFeed.latestRoundData();
        return answer;
    }
}
