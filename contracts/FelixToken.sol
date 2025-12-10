// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FelixToken is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    string private _name;

    string private _symbol;

    uint256 public nextTokenId;

    constructor() {
    }

    function initialize(
    ) public initializer {
        // 2. 初始化ERC721（传入具体的名称和符号，避免空值）
        __ERC721_init("FelixNFT", "FELIX"); // 例如传入 "FelixToken"、"FELIX"
        // 3. 初始化所有权管理（OwnableUpgradeable）
        __Ownable_init(msg.sender); // 自动将所有者设为初始化函数的调用者
        // 4. 最后初始化UUPS升级模式
        __UUPSUpgradeable_init();
    }

    //mint nft
    function mint(uint256 tokenId) public onlyOwner returns (bool) {
        require(tokenId >= nextTokenId);
        //不能mint重复的tokenId，这里设定tokenId只能递增
        nextTokenId = nextTokenId + 1;
        _mint(msg.sender, tokenId);
        return true;
    }

    // 转移token
    function transferFrom(
        uint256 tokenId,
        address from,
        address to
    ) public onlyOwner {
        super.transferFrom(from, to, tokenId);
    }

    // ======== UUPS升级必需函数（控制升级权限）=======
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {
        // 仅所有者可触发升级，无额外逻辑需留空（确保函数体存在即可）
    }
}
