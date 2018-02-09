pragma solidity ^0.4.18;


import './RepToken.sol';
import './LendOffer.sol';


interface EnergyCoinInterfaceInterface {
    function balanceOf(address) public constant returns (uint);

    function transferFrom(address, address, uint) public returns (bool);

    function transfer(address, uint) public;
}


interface AssetTokenInterface {
    function transferOwnershipFrom(address, address, uint) public returns (bool);

    function transferOwnership(address, uint) public;

    function getObjectOwner(uint) public constant returns (address);
}


contract EnergyLendOffer {

    // state variables
    EnergyCoinInterface energybank;

    RepToken energycredit;

    AssetTokenInterface energycollateral;

    address public owner;

    uint public waitingForBorrowerNum;

    uint public waitingForPaybackNum;

    uint public closedNum;

    uint public totalAccountNum;

    mapping (uint => address) allAccountList;

    mapping (address => address[]) historyPerAccount;

    uint RepTokenRate = 1000;

    // functions
    function EnergyLendOffer() public {
        energycredit = new RepToken();
        owner = msg.sender;
    }

    function setUpEnergyCoin(address energyCoinAddress) public onlyByOwner {
        energybank = EnergyCoinInterface(energyCoinAddress);
    }

    function setUpAssetToken(address AssetTokenAddress) public onlyByOwner {
        energycollateral = AssetTokenInterface(AssetTokenAddress);
    }

    function postLendOffer(uint _lend_energycoin,
    uint _payback_energycoin, uint _expired_time, string _requirement) public setUpReady returns (bool success) {
        address lender = msg.sender;
        energybank.transferFrom(lender, this, _lend_energycoin);

        LendOffer offer = new LendOffer();
        offer.setData(lender, _lend_energycoin, _payback_energycoin, _expired_time, _requirement);

        if (historyPerAccount[lender].length == 0) {
            allAccountList[totalAccountNum] = lender;
            totalAccountNum ++;
        }
        historyPerAccount[lender].push(offer);
        waitingForBorrowerNum++;
        success = true;
    }

    function cancelLendOffer(address _offer) public setUpReady returns (bool success) {
        LendOffer offer = LendOffer(_offer);
        address lender = offer.lender();
        require(lender == msg.sender);

        offer.cancelOffer();
        energybank.transfer(lender, offer.lend_energycoin());
        success = true;
    }


    function applyForLoan(address _offer, uint _asset_token) public setUpReady returns (bool success) {
        LendOffer offer = LendOffer(_offer);
        address borrower = msg.sender;
        address lender = offer.lender();
        require(lender != borrower);
        require(borrower == energycollateral.getObjectOwner(_asset_token));

        offer.apply(borrower, _asset_token);
        success = true;
    }


    function acceptBorrower(address _offer, address _borrower) public setUpReady returns (bool success) {
        LendOffer offer = LendOffer(_offer);
        address lender = offer.lender();
        uint amount = offer.lend_energycoin();
        uint asset_token = offer.borrowerAssetToken(_borrower);
        require(lender == msg.sender);
        require(lender != _borrower);
        energycollateral.transferOwnershipFrom(_borrower, this, asset_token);

        offer.accept(_borrower);
        energybank.transfer(_borrower, amount);

        historyPerAccount[_borrower].push(offer);
        waitingForBorrowerNum --;
        waitingForPaybackNum ++;
        success = true;
    }

    function paybackLoan(address _offer) public setUpReady returns (bool success){
        LendOffer offer = LendOffer(_offer);
        address borrower = offer.borrower();
        address lender = offer.lender();
        uint amount = offer.payback_energycoin();
        require(borrower == msg.sender);
        require(energybank.balanceOf(borrower) >= amount);

        offer.payBack();
        energybank.transferFrom(borrower, lender, amount);
        energycollateral.transferOwnership(borrower, offer.asset_token());
        waitingForPaybackNum --;
        closedNum ++;
        energycredit.issueTokens(borrower, amount / RepTokenRate);
        success = true;
    }

    function defaultLoan(address _offer) public setUpReady returns (bool success) {
        LendOffer offer = LendOffer(_offer);
        address borrower = offer.borrower();
        address lender = offer.lender();

        offer.timeOut();
        energycollateral.transferOwnership(lender, offer.asset_token());
        waitingForPaybackNum --;
        closedNum ++;
        energycredit.burnTokens(borrower);
        success = true;
    }

    function getUserOffer(address account, string state) public constant setUpReady returns (address[]){
        LendOffer curOffer;
        uint arraySize = getArraySize(state);
        address[] memory offerList = new address[](arraySize);
        address[] memory offerForUser = historyPerAccount[account];
        uint allIndex = 0;
        uint ansIndex = 0;
        while (allIndex < offerForUser.length && ansIndex < arraySize) {
            address offerId = offerForUser[allIndex];
            curOffer = LendOffer(offerId);
            if (_onlyInOfferState(curOffer, state)) {
                offerList[ansIndex] = offerId;
                ansIndex ++;
            }
            allIndex ++;
        }
        return offerList;
    }

    function _onlyInOfferState(LendOffer _offer, string _state) internal constant returns (bool){
        if (keccak256(_state) == keccak256('waitingForBorrower')) {
            return _offer.isWaitingForBorrower();
        }
        else if (keccak256(_state) == keccak256('waitingForPayback')) {
            return _offer.isWaitingForPayback();
        }
        else if (keccak256(_state) == keccak256('closed')) {
            return _offer.isClosed();
        }
    }

    function getOfferDetails(address offerId) public constant returns (
    address borrower,
    uint lend_energycoin,
    uint payback_energycoin,
    uint expired_period,
    uint asset_token,
    uint start,
    address lender){
        LendOffer offer = LendOffer(offerId);
        return offer.getDetails();
    }

    function getArraySize(string _state) internal constant returns (uint){
        if (keccak256(_state) == keccak256('waitingForBorrower')) {
            return waitingForBorrowerNum;
        }
        else if (keccak256(_state) == keccak256('waitingForPayback')) {
            return waitingForPaybackNum;
        }
        else if (keccak256(_state) == keccak256('closed')) {
            return closedNum;
        }
    }

    function getEnergyCoinAddr() public constant returns (address) {
        return energybank;
    }

    function getEnergyCollateralAddr() public constant returns (address) {
        return energycollateral;
    }

    function getCredit(address _user) public constant returns (uint) {
        return energycredit.balanceOf(_user);
    }

    // modifers

    modifier onlyByOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier setUpReady(){
        require(address(energybank) != 0x0);
        require(address(energycollateral) != 0x0);
        require(address(energycredit) != 0x0);
        _;
    }

}