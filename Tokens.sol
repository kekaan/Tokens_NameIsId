pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

contract Tokens {

    struct CarToken {
        string name;
        string brand;
        uint enginePower;
        uint topSpeed;
    }

    CarToken[] public tokensArr;
    mapping (uint=>uint) public tokenIdToOwner;
    mapping (string=>uint) nameToTokenId;
    mapping (uint=>uint) sellingTokenIdToPrice;

    constructor() public {
        require(tvm.pubkey() != 0, 101);
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();
    }

    modifier checkOwnerAndAccept {
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();
        _;
    }

    function createToken(
        string name, 
        string brand, 
        uint enginePower, 
        uint topSpeed
    )
        public 
    {
        require(!nameToTokenId.exists(name), 103, "Token with this name already exists.");
        tvm.accept();
        tokensArr.push(CarToken(name, brand, enginePower, topSpeed));
        uint id = tokensArr.length - 1;
        tokenIdToOwner[id] = msg.pubkey();
        nameToTokenId[name] = id;
    }

    function getSellingList() 
        public 
        view 
        checkOwnerAndAccept 
        returns(string[])
    {
        string[] list;
        optional(uint, uint) currentOpt = sellingTokenIdToPrice.min();
        while (currentOpt.hasValue()){
            (uint tokenId, uint price) = currentOpt.get();
            list.push(format("Token name: {}. Price: {}", tokensArr[tokenId].name, price));
            currentOpt = sellingTokenIdToPrice.next(tokenId);
        }
        return list;
    }

    function getTokenIdByName(string tokenName) internal view returns(uint){
        return nameToTokenId[tokenName];
    }

    function offerForSale(string tokenName, uint price) public {
        require(nameToTokenId.exists(tokenName), 106, "This token doesn't exist");
        require(msg.pubkey() == tokenIdToOwner[getTokenIdByName(tokenName)], 104, "You are not the owner of the token.");
        require(!sellingTokenIdToPrice.exists(getTokenIdByName(tokenName)), 105, "Token is already up for sale.");
        tvm.accept();
        sellingTokenIdToPrice[getTokenIdByName(tokenName)] = price;
    }
}