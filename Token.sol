pragma solidity ^0.4.18;


contract Token {

	/// total amount of tokens
	uint public totalSupply;

    // state variables
    mapping (address => uint) balances;

    mapping (address => mapping (address => uint)) allowance;


    // functions
	/// @param _owner The address from which the balance will be retrieved
	/// @return The balance
    function balanceOf(address _owner) public constant returns (uint) {
        return balances[_owner];
    }
	
	// Transfer the balance from owner's account to another account
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);

        uint previousBalances = balances[_from] + balances[_to];
        balances[_from] -= _value;
        balances[_to] += _value;

        Transfer(_from, _to, _value);
        assert(balances[_from] + balances[_to] == previousBalances);
    }
	
	
	// Transfer the balance from owner's account to another account
    function transfer(address _to, uint _value) public {
        _transfer(msg.sender, _to, _value);
    }

	// Send `tokens` amount of tokens from address `from` to address `to`
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
	/// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
	/// @param _value The amount of token to be transferred
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
	
	// Allow `spender` to withdraw from your account, multiple times, up to the `tokens` amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowanceOf(address _owner, address _spender) public constant returns (uint remaining) {
        return allowance[_owner][_spender];
    }


    // events
    event Transfer(address indexed _from, address indexed _to, uint _value);

    event Approval(address indexed _owner, address indexed _spender, uint _value);

}