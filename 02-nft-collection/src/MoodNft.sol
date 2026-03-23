// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNft is ERC721 {
    
    error MoodNft__CanFlipMoodIfNotOwner();

    uint256 private sTokenCounter;
    string private sSadSvgImageUri;
    string private sHappySvgImageUri;

    enum Mood {
        HAPPY,
        SAD
    }

    mapping(uint256 => Mood) private sTokenIdMood;

    // constructor() ERC721("Mood NFT", "MONFT") {}
    constructor(string memory _sadSvgImageUri, string memory _happySvgImageUri) ERC721("Mood NFT", "MONFT") {
        sTokenCounter = 0;
        sSadSvgImageUri = _sadSvgImageUri;
        sHappySvgImageUri = _happySvgImageUri;
    }

    function mintNft() public {
        _safeMint(msg.sender, sTokenCounter);
        sTokenIdMood[sTokenCounter] = Mood.HAPPY;
        sTokenCounter++;
    }

    function flipMood(uint256 tokenId) public {
        if (getApproved(tokenId) != msg.sender && ownerOf(tokenId) != msg.sender)  {
            revert MoodNft__CanFlipMoodIfNotOwner();
        } 

        if (sTokenIdMood[tokenId] == Mood.HAPPY) {
            sTokenIdMood[tokenId] == Mood.SAD;
        } else {
            sTokenIdMood[tokenId] == Mood.HAPPY;
        }
    }

    function _baseURI() internal pure override returns(string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {

        string memory imageURI;
        if (sTokenIdMood[tokenId] == Mood.HAPPY) {
            imageURI = sHappySvgImageUri;
        } else {
            imageURI = sSadSvgImageUri;
        }

        return string(
            abi.encodePacked(_baseURI(),
                Base64.encode(
                    bytes(abi.encodePacked(
                        '{"name":"',
                        name(), // You can add whatever name here
                        '", "description":"An NFT that reflects the mood of the owner, 100% on Chain!", ',
                        '"attributes": [{"trait_type": "moodiness", "value": 100}], "image":"',
                        imageURI,
                        '"}'
                    ))
                )
            )
        );
    }
}