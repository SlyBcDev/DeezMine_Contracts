pragma solidity ^0.5.0;

import "./Counters.sol";

contract VIP181 {
    
    //custom add
    mapping (address => bool) public _canTransferTokenFromContract;
    
    using Counters for Counters.Counter;
    
    //event
    event Transfer(address indexed _from, address indexed _to, string indexed _tokenId);
    event Approval(address indexed _owner, address indexed _spender, string indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;
    
    // Array with all token ids, used for enumeration
    string[] private _allTokens;
    
    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;
        // Mapping from token ID to owner
    mapping (string => address) private _tokenOwner;
        // Mapping from token ID to approved address
    mapping (string => address) private _tokenApprovals;
        // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
        /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
    }

    
    
    //Function
    
    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }
    
        /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(string memory tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "VIP181: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(string memory tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "VIP181: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, string memory tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_canTransferTokenFromContract[msg.sender]==true, "This function must be called by a special account");

        _transferFrom(from, to, tokenId);
    }
    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, string memory tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "VIP181: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "VIP181: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(string memory tokenId) public view returns (address) {
        require(_exists(tokenId), "VIP181: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "VIP181: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
        /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, string memory tokenId) internal view returns (bool) {
        require(_exists(tokenId), "VIP181: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    
        /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(string memory tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
    
       /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, string memory tokenId) private {
        require(ownerOf(tokenId) == from, "VIP181: transfer of token that is not own");
        require(to != address(0), "VIP181: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    
        /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, string memory tokenId) internal {
        require(to != address(0), "VIP181: mint to the zero address");
        require(!_exists(tokenId), "VIP181: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();
        _allTokens.push(tokenId);

        emit Transfer(address(0), to, tokenId);
    }
    
    
}
