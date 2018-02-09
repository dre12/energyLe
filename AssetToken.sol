pragma solidity ^0.4.18;


contract AssetToken {

    // struct type
    struct AssetObject {
    address owner;
    uint value;
    string name;
    string infolink;
    }

    // state variables
    string public name = "EnergyAssetToken";

    string public symbol = "AssetToken";

    uint public decimals = 18;

    uint public numObject = 0;

    address public creator = 0x0;

    mapping (uint => AssetObject) assetObjects;

    mapping (address => mapping (uint => address)) allowance;

    // functions
    function AssetToken() public {
        creator = msg.sender;
    }

    function register(address _owner, uint _value, string _name, string _infolink) public onlyCreator returns (uint registerID) {
        registerID = numObject++;
        assetObjects[registerID] = AssetObject(_owner, _value, _name, _infolink);
        Registration(_owner, _value, _name, _infolink, registerID);
    }

    function _transferOwnership(uint _objectID, address _from, address _to) internal {
        require(_to != 0x0);
        require(assetObjects[_objectID].owner == _from);
        assetObjects[_objectID].owner = _to;
        TransferOwnership(_objectID, _from, _to);
    }

    function transferOwnership(address _to, uint _objectID) public {
        _transferOwnership(_objectID, msg.sender, _to);
    }

    function transferOwnershipFrom(address _from, address _to, uint _objectID) public returns (bool success) {
        require(allowance[_from][_objectID] == msg.sender);
        require(assetObjects[_objectID].owner == _from);
        _transferOwnership(_objectID, _from, _to);
        return true;
    }

    function approve(address _newOwner, uint _objectID) public returns (bool success) {
        require(assetObjects[_objectID].owner == msg.sender);
        require(_newOwner != 0x0);
        allowance[msg.sender][_objectID] = _newOwner;
        Approval(msg.sender, _newOwner, _objectID);
        return true;
    }

    function allowanceOf(address _owner, uint _objectID) public constant returns (address) {
        return allowance[_owner][_objectID];
    }

    function verify(uint _objectID, address _owner) public constant returns (bool) {
        return assetObjects[_objectID].owner == _owner;
    }

    function getObjectOwner(uint _id) public constant returns (address owner) {
        owner = assetObjects[_id].owner;
    }

    function getObjectValue(uint _id) public constant returns (uint value) {
        value = assetObjects[_id].value;
    }

    function getObjectName(uint _id) public constant returns (string _name) {
        _name = assetObjects[_id].name;
    }

    function getObjectInfolink(uint _id) public constant returns (string infolink) {
        infolink = assetObjects[_id].infolink;
    }

    // modifiers
    modifier onlyCreator(){
        require(msg.sender == creator);
        _;
    }

    // events
    event Registration(address indexed _owner, uint _value, string _name, string _infolink, uint _index);

    event TransferOwnership(uint _id, address indexed _from, address indexed _to);

    event Approval(address indexed _owner, address indexed _newOwner, uint _objectID);

}