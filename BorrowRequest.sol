pragma solidity ^0.4.18;


import './SafeMath.sol';


contract BorrowRequest {

    enum State {
    Init,
    Cancelled,
    WaitingForLender,
    WaitingForPayback,
    Expired,
    Finished
    }

    using SafeMath for uint;

    address public creator = 0x0;

    State public currentState = State.Init;

    address public borrower;

    uint public borrow_energycoin;

    uint public payback_energycoin;

    uint public expired_period;

    uint public asset_token;

    uint public start = 0;

    address public lender = 0x0;

    function BorrowRequest(address _borrower, uint _borrow_energycoin, uint _payback_energycoin,
    uint _expired_period, uint _asset_token) public {
        creator = msg.sender;
        borrower = _borrower;
        borrow_energycoin = _borrow_energycoin;
        payback_energycoin = _payback_energycoin;
        expired_period = _expired_period;
        asset_token = _asset_token;
        currentState = State.WaitingForLender;
    }

    function reachAgreement(address _lender) public onlyCreator onlyInState(State.WaitingForLender) {
        lender = _lender;
        start = now;
        currentState = State.WaitingForPayback;
    }

    function cancelRequest() public onlyCreator onlyInState(State.WaitingForLender) {
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

    function isWaitingForLender() public view returns (bool succeess){
        return currentState == State.WaitingForLender;
    }

    function isWaitingForPayback() public view returns (bool succeess){
        return currentState == State.WaitingForPayback;
    }

    function isClosed() public view returns (bool succeess){
        return currentState == State.Expired || currentState == State.Finished;
    }

    function getDetails() public view returns (address _borrower,
    uint _borrow_energycoin,
    uint _payback_energycoin,
    uint _expired_period,
    uint _asset_token,
    uint _start,
    address _lender){
        return (borrower, borrow_energycoin, payback_energycoin, expired_period, asset_token, start, lender);
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