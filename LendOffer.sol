pragma solidity ^0.4.18;


import './SafeMath.sol';


contract LendOffer {

    using SafeMath for uint;

    enum State {
    Init,
    Cancelled,
    WaitingForBorrower,
    WaitingForPayback,
    Expired,
    Finished
    }

    address public creator = 0x0;

    State public currentState;

    address public borrower = 0x0;

    address public lender = 0x0;

    uint public lend_energycoin;

    uint public payback_energycoin;

    uint public expired_period;

    uint public asset_token;

    uint public start = 0;

    string public requirement;

    mapping (address => uint) public borrowerAssetToken;

    address[] candidate;

    function LendOffer() public {
        creator = msg.sender;
        currentState = State.Init;
    }

    function setData(address _lender, uint _lend_energycoin, uint _payback_energycoin, uint _expired_period, string _requirement)
    public onlyCreator onlyInState(State.Init) {
        lender = _lender;
        lend_energycoin = _lend_energycoin;
        payback_energycoin = _payback_energycoin;
        expired_period = _expired_period;
        requirement = _requirement;
        currentState = State.WaitingForBorrower;
    }

    function apply(address _borrower, uint _asset_token) public onlyCreator onlyInState(State.WaitingForBorrower) {
        candidate.push(_borrower);
        borrowerAssetToken[_borrower] = _asset_token;
    }

    function accept(address _borrower) public onlyCreator onlyInState(State.WaitingForBorrower) {
        borrower = _borrower;
        asset_token = borrowerAssetToken[_borrower];
        start = now;
        currentState = State.WaitingForPayback;
    }

    function cancelOffer() public onlyCreator onlyInState(State.WaitingForBorrower) {
        currentState = State.Cancelled;
    }

    function payBack() public onlyCreator onlyInState(State.WaitingForPayback) {
        require(start + expired_period >= now);
        currentState = State.Finished;
    }

    function timeOut() public onlyCreator onlyInState(State.WaitingForPayback) {
        require(start + expired_period < now);
        currentState = State.Expired;
    }

    function isWaitingForBorrower() public view returns (bool succeess){
        return currentState == State.WaitingForBorrower;
    }

    function isWaitingForPayback() public view returns (bool succeess){
        return currentState == State.WaitingForPayback;
    }

    function isClosed() public view returns (bool succeess){
        return currentState == State.Expired || currentState == State.Finished;
    }

    function getDetails() public view returns (address _borrower,
    uint _lend_energycoin,
    uint _payback_energycoin,
    uint _expired_period,
    uint _asset_token,
    uint _start,
    address _lender){
        return (borrower, lend_energycoin, payback_energycoin, expired_period, asset_token, start, lender);
    }

    // modifiers
    modifier onlyInState(State _state){
        require(currentState == _state);
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

}