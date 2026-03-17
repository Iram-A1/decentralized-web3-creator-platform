// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/token/ERC721/extensions/ERC721URIStorage.sol?raw=true";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/access/AccessControl.sol?raw=true";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/utils/Pausable.sol?raw=true";

contract ContentNFT is ERC721URIStorage, AccessControl, Pausable {
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 private _tokenIdCounter;

    struct Content {
        address creator;
        string title;
    }

    mapping(uint256 => Content) public contentData;

    event ContentMinted(uint256 indexed tokenId, address indexed creator, string title);
    event ContentBurned(uint256 indexed tokenId, address indexed creator);

    constructor() ERC721("ContentNFT", "CNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MODERATOR_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function mintContent(string memory title, string memory tokenURI) external whenNotPaused returns (uint256) {
        require(bytes(title).length > 0, "Title cannot be empty");
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        contentData[tokenId] = Content(msg.sender, title);
        emit ContentMinted(tokenId, msg.sender, title);
        return tokenId;
    }

    function burnContent(uint256 tokenId) external onlyRole(MODERATOR_ROLE) {
        address creator = contentData[tokenId].creator;
        delete contentData[tokenId];
        _burn(tokenId);
        emit ContentBurned(tokenId, creator);
    }

    function pause() external onlyRole(PAUSER_ROLE) { _pause(); }
    function unpause() external onlyRole(PAUSER_ROLE) { _unpause(); }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
