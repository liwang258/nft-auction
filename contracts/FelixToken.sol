// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract FelixToken is
    ERC721Upgradeable,
    Initializable,
    UUPSUpgradeable,
    Ownable
{
    string private _name;

    string private _symbol;

    uint256 public nextTokenId;

    constructor(){}

    function initialize() public initializer {
        _name="TOKEN_FELEX";
        _symbol="TOKEN_FELEX"
        _owner = msg.sender;
        super.ERC721(_name,_symbol);
         // 1. 初始化父类（顺序：先初始化基础类，再初始化业务类）
        __Initializable_init(); // 初始化 Initializable
        __ERC721_init(name, symbol); // 初始化 ERC721 的 name 和 symbol（核心！）
        __UUPSUpgradeable_init(); // 初始化 UUPSUpgradeable
    }

      //mint nft
    function mint(uint256 tokenId) public Ownable bool{
        require(tokenId>=nextTokenId);
        //不能mint重复的tokenId，这里设定tokenId只能递增
        nextTokenId=nextTokenId+1;
        super._safeMint(_owner,tokenId);
        return true; 
    }
    // 转移token
    function transferFrom(uint256 tokenId,address from,address to) public onlyOwner{
        super._safeTransfer(from,to,tokenId);
    }

     function  _authorizeUpgrade(address newImplementation) internal override onlyOwner{
        //UUPS升级的核心函数
    }
}
