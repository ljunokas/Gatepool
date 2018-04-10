pragma solidity ^0.4.0;
contract TokenInterface {
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
}

contract GatepoolContract {
    address owner;
    address contractAddress = this;
    
    // token contract address
    address tokenAddress;
    // ICO address where ehters must be transfered
    address icoAddress;
    
    // contract balance
    uint value;
    uint constant hardCap = 10 ether;
    uint constant hardCapTotalTokenSupply = 1000;
    uint constant ratio = hardCapTotalTokenSupply/hardCap;
    uint constant houseEtherFeePercent = 10;
    uint constant houseTokenFeePercent = 10;
    
    
    bool releaseTokens = false;
    bool releaseEther = false;
    
    // token contract instance
    TokenInterface private _instance;
    
    mapping (address => bool) userAddr;
    
    struct Investor {
        uint maxValue;
        uint invested;
        bool claimed;
    }

    Investor myInvestor;
    
    mapping (address => Investor) _investors;

    function GatepoolContract() public {
        //creator is the owner
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
     modifier individualCap() {
        require(_investors[msg.sender].maxValue <= _investors[msg.sender].invested + msg.value);
        _;
    }
    
    modifier onlyWhitelisted() {
        require(userAddr[msg.sender]);
        _;
    }
    
    modifier hardCapMod() {
        require(msg.value + value <= hardCap);
        _;
    }
    
    // only owner of contract can whitelist the address
    function whitelistAddress (address user, uint maxVal) public onlyOwner {
        userAddr[user] = true;
        _investors[user].maxValue = maxVal;
        _investors[user].invested = 0;
        _investors[user].claimed = false;
    }
    
    // owner should set token contract instance when available
    function setContractInstance(address _address) public onlyOwner {
        tokenAddress = _address;
        _instance = TokenInterface(address(_address));
    }
    
    function setIcoAddress(address _address) public onlyOwner {
        icoAddress = _address;
    }
    
    // owner makes the transfer to ico address
    function sendEtherToIco () public onlyOwner returns (bool) {
        icoAddress.transfer(value);
        return true;
    }
    
    function claimTokens () public onlyWhitelisted returns (bool){
        require(!_investors[msg.sender].claimed);
        uint tokensToBeClaimed =  _investors[msg.sender].invested * ratio;
        _instance.approve(msg.sender, tokensToBeClaimed);
        if(_instance.transferFrom(contractAddress, msg.sender, tokensToBeClaimed)){
             _investors[msg.sender].claimed = true;
              return true;
        } else {
            _investors[msg.sender].claimed = false;
             return false;
        }
       
    }
    
    function initiateReleaseEther() public onlyOwner {
        releaseEther = true;
    }
    
    function withdrawEther() public onlyWhitelisted returns (bool) {
        require(releaseEther);
        require(userAddr[msg.sender]);
        require(_investors[msg.sender].invested > 0);
        
        msg.sender.transfer(_investors[msg.sender].invested);
        _investors[msg.sender].invested = 0;
        
        return true;
    }
    
    function () payable public hardCapMod onlyWhitelisted individualCap {
        value += msg.value;
        _investors[msg.sender].invested += msg.value;
    }
    
    
    
    function contractBalance () public returns (uint) {
        return contractAddress.balance;
    }
    
}


