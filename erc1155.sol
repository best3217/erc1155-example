pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract erc1155example is ERC1155, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    uint256 initialAmount = 10**17;
    uint256 maxSupply = 10;

    string public constant name = "erc1155example";
    string public constant symbol = "example";
    uint256 public endTime = 1669845600; // 2022-12-01
    mapping(uint256 => uint256) public totalSupply;
    mapping(address => mapping(uint256 => uint256)) public supplyByUser;
    mapping (uint256 => string) private _tokenURIs;
    string public prefixURI = "https://[redacted].com/";
    address[] public wallets = [0xc6f7c07419a4652703374608C653CA97502719bD, 0x0883d96A992EEE7c29FB26703F86f8F5D476C626];
    uint256[] public walletPercents = [90, 10];

    constructor()
        ERC1155("")
    {}

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return string(
            abi.encodePacked(
            prefixURI,
            Strings.toString(_tokenId),
            ".json"
           )
        );
    }

    function setPrefixURI(string memory newUri) public {
        prefixURI = newUri;
    }

    function mint(uint256 token_id, uint256 supply) public payable {
        require(block.timestamp < endTime, "time is expired");
        uint256 supplies = totalSupply[token_id];

        require(supply <= 10, "you can mint max 10 supplies once");
        require(supplyByUser[msg.sender][token_id] < maxSupply, "You have already minted this token");
        require(supplies < 2000, "can't mint this token anymore");
        uint256 amount = 10000000000;
        if(((supplies+supply) % 100) < 10 && supplies > 90 ) {
            amount = getPriceBySupplies(supplies)*(supply-(supplies+supply) % 100) + getPriceBySupplies(supplies+supply)*((supplies+supply) % 100);
        }else {
            amount = getPriceBySupplies(supplies) * supply;
        }

        console.log(amount);

        require(msg.value == amount, "influence amount");
        _mint(msg.sender, token_id, supply, "");
        totalSupply[token_id] += supply;
        supplyByUser[msg.sender][token_id] += supply;

        divisionOfBenifit(msg.value);
    }

    function batchMint(uint256[] memory _ids, uint256[] memory quantities) public payable {
        uint256 totalAmount;
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 supply = quantities[i];

            uint256 supplies = totalSupply[_id];
            require(supply <= 10, "you can mint max 10 supplies once");
            require(supplyByUser[msg.sender][_id] < maxSupply, "You have already minted this token");
            require(supplies < 2000, "can't mint this token anymore");

            uint256 amount;
            if(((supplies+supply) % 100) < 10 && supplies > 90) {
                amount = getPriceBySupplies(supplies)*(supply-(supplies+supply) % 100) + getPriceBySupplies(supplies+supply)*((supplies+supply) % 100);
            }else {
                amount = getPriceBySupplies(supplies) * supply;
            }

            totalAmount += amount;
        }

        console.log(totalAmount);
        require(msg.value == totalAmount, "influence amount");
        _mintBatch(msg.sender, _ids, quantities, "");

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 supply = quantities[i];
            totalSupply[_id] += supply;
            supplyByUser[msg.sender][_id] += supply;
        }

        divisionOfBenifit(msg.value);
    }

    function divisionOfBenifit(uint256 amount) private {
        for(uint i = 0; i < wallets.length; i++) {
            (bool sent,) = wallets[i].call{value: amount * walletPercents[i]/100}("");
            console.log(sent);
        }
    }

    function setDivision(address[] memory newWallets, uint256[] memory newPercets) public onlyOwner {
        require(newWallets.length == newPercets.length, "addresses length and percents length should be same");
        wallets = newWallets;
        walletPercents = newPercets;
    }

    function getInitialAmount() public view returns(uint256) {
        return initialAmount;
    }

    function getPriceBySupplies(uint256 supplies) internal view returns(uint256) {
        return initialAmount + (supplies / 100)*(initialAmount/10);
    }

    function setEndTime(uint256 newTime) public onlyOwner {
        endTime = newTime;
    }

    function getTokenPrice(uint256 token_id) public view returns(uint256) {
        uint256 supplies = totalSupply[token_id];
        return getPriceBySupplies(supplies);
    }
}