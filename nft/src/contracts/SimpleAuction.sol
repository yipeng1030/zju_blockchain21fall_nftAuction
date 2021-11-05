pragma solidity 0.8.9;

contract SimpleAuction {
    address payable[100] public beneficiary;
    address payable public wallet;
    uint[100] public auctionEnd;
    uint public nowTime = block.timestamp;
    uint public numofNft = 0;
    address payable[10] public nowNftHistoryHolder;
    
    function showHistory(uint id) public{
          nowNftHistoryHolder = allNft[id].historyHolder;
    }
    
    
    constructor(address payable _wallet) public{
        wallet = _wallet;
    }
    
    enum State{ holded,auctioning,auctioned }
    struct Nft{
        uint id;
        string data;
        address payable nowHolder;
        State nowState;
        uint numofHolder;
        address payable[10] historyHolder;
    }
    
    
    mapping (uint => Nft) public allNft;
    mapping (uint => Nft) public autioningNft;
    mapping (uint => Nft) public nowNft;
    mapping (address => uint) public balances;

    function mint(string memory _data) payable
    public{
        address payable [10] memory addr1 ;
        addr1[0] = payable(msg.sender);
        Nft memory nft = Nft(
            numofNft,
            _data,
            addr1[0],
            State.holded,
            1,
            addr1
        );
        allNft[numofNft++] = nft;
        wallet.transfer(msg.value);//the cost to mint a nft
        balances[msg.sender]++;
    }
    
    
    uint public numofSelfHold = 0;
    function showTokens() public{
        numofSelfHold = 0;
        for(uint i = 0; i < numofNft; i++)
        {
            if (allNft[i].nowHolder == payable(msg.sender))
            {
                nowNft[numofSelfHold++] = allNft[i];
            }
        }
    }
    
    
    
    address[100] public highestBidder;
    uint[100] public highestBid;

    mapping(address => uint)[100] pendingReturns;
    uint numofpendingReturns;
    

    bool[100] public ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(uint nftid,address winner, uint amount);


    function auctionBegin (
        uint auctionNumber,
        uint _biddingTime 
        ) public{
        require(allNft[auctionNumber].nowHolder == msg.sender);
        
        allNft[auctionNumber].nowState = State.auctioning;
        beneficiary[auctionNumber] = payable(msg.sender);
        auctionEnd[auctionNumber] = block.timestamp + _biddingTime;
        ended[auctionNumber] = false;
    }

    
    function showAuctions() public{
        for(uint i = 0; i < numofNft; i++)
        {
            if (allNft[i].nowState == State.auctioning)
            {
                autioningNft[allNft[i].id] = allNft[i];
            }
        }
    }
    
    function getTime() public{
        nowTime = block.timestamp;
    }


    function bid(uint bidnumber) public payable {

        showAuctions();
        //numofpendingReturns = 
        
        // 如果拍卖已结束，撤销函数的调用。
        require(
            block.timestamp <= auctionEnd[bidnumber],
            "Auction already ended."
        );
        // 如果出价不够高，返还你的钱
        require(
            msg.value > highestBid[bidnumber],
            "There already is a higher bid."
        );

        if (highestBid[bidnumber] != 0) {

            pendingReturns[bidnumber][highestBidder[bidnumber]] += highestBid[bidnumber];
        }
        highestBidder[bidnumber] = msg.sender;
        highestBid[bidnumber] = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// 取回出价（当该出价已被超越）
    function withdraw(uint _numofpendingReturns) public returns (bool) {
        numofpendingReturns = _numofpendingReturns;
        uint amount = pendingReturns[numofpendingReturns][msg.sender];
        if (amount > 0) {

            pendingReturns[numofpendingReturns][msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                pendingReturns[numofpendingReturns][msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /// 结束拍卖，
    function auctionEndding(uint _auctionTokenid) public {
        uint auctionTokenid = _auctionTokenid;
        require(block.timestamp >= auctionEnd[auctionTokenid], "Auction not yet ended.");
        require(!ended[auctionTokenid], "auctionEnd has already been called.");
        ended[auctionTokenid] = true;
        if (payable(highestBidder[auctionTokenid]) == address(0))
        {
            allNft[auctionTokenid].nowState = State.holded;
        }
        else
        {
        allNft[auctionTokenid].nowState = State.holded;
        allNft[auctionTokenid].nowHolder = payable(highestBidder[auctionTokenid]);
        allNft[auctionTokenid].historyHolder[allNft[auctionTokenid].numofHolder++] = payable(highestBidder[auctionTokenid]);
        emit AuctionEnded(auctionTokenid,highestBidder[auctionTokenid], highestBid[auctionTokenid]);
        beneficiary[auctionTokenid].transfer(highestBid[auctionTokenid]);
        }
        
    }
}
