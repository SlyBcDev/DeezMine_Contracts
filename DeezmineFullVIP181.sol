pragma solidity ^0.5.0;

import "./Counters.sol";
import "./SafeMath.sol";

contract DeezMine {
    
    using SafeMath for uint;
    
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
        // Mapping from owner to list of owned token IDs
    mapping(address => string[]) private _ownedTokens;
        // Mapping from token ID to index of the owner tokens list
    mapping(string => uint256) private _ownedTokensIndex;
        // Mapping from token id to position in the allTokens array
    mapping(string => uint256) private _allTokensIndex;
    
        /**
     * @dev Constructor function
     */
    constructor () public {
        _name = "DeezMine";
        _symbol = "DZM";
        _isAdmin[msg.sender]=true;
        _isCertifier[msg.sender]=true;
        _canTransferTokenFromContract[msg.sender]=true;
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
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (string memory) {
        require(index < balanceOf(owner), "VIP181Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
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
        require(getApproved(tokenId)==msg.sender, "VIP181: transfer caller is not approved");

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
        
        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
        
        

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    
     /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, string memory tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }
    
       /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, string memory tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            string memory lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }
    
        /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(string memory tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
    
    
        /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, string memory tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();
        
        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);

        emit Transfer(address(0), to, tokenId);
    }
    
    //-------------------------------------------------------------------------//
    //----------------------Contract DeezMine----------------------------------//
    //-------------------------------------------------------------------------//
    
        
//Variable
  struct instrumentInfo {
      string brand;
      string model;
      string instrumentType;
      uint birthDateOfInstrument;
      string serialNumber;
   }

  mapping (string => instrumentInfo) public instrument;
  mapping (string => bool) public isStolenOrLost;
  
  mapping (string => string[]) public pictures;
  mapping (string => uint) public numberOfPictures;
    
  mapping (string => string[]) public storieOfInstrument;
  mapping (string => uint) public numberOfStories;
  
  mapping (address => bool) public _isAdmin;
  mapping (address => bool) public _isCertifier;


  event newInstrument(string _tokenId, string _brand, string _serialNumber, address indexed _certifier); 
  event newOwner(string indexed _tokenId, uint date, address _newOwnerAddress);
  event hasBeenStolenOrLost(string indexed _tokenId, uint date, string _message);
  event hasBeenRecover(string indexed _tokenId, uint date, string _message);
  event warningAlarm(string indexed _tokenId, uint date, string _location);
  event historyEvent(string indexed _tokenId,uint _date, string _details);

    // Modifier
 
    modifier isOwner(string memory _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
    }
    
    modifier isAdmin(address _admin){
        require(_isAdmin[_admin]==true);
        _;
    }
    
    modifier isCertifier(address _certifier){
        require(_isCertifier[_certifier]==true);
        _;
    }
    
     modifier isAuthorizedToTransferFromContract(address _asker){
        require(_canTransferTokenFromContract[_asker]==true);
        _;
    }

    
    //-------------------------------------------------------------------------//
    //----------------------Fonction d'administration--------------------------//
    //-------------------------------------------------------------------------//
    
    function addAdmin(address _newAdmin) public isAdmin(msg.sender) {
        _isAdmin[_newAdmin]=true;
    }
    
    function addCertifier(address _newCertifier) public isAdmin(msg.sender){
        _isCertifier[_newCertifier]=true;
    }
    
    function addUserCanTransferTokenFromContract(address _newCanTransferTokenFromContract) public isAdmin(msg.sender) {
        _canTransferTokenFromContract[_newCanTransferTokenFromContract]=true;
    }
    
    function deleteAdmin(address _oldAdmin) public isAdmin(msg.sender) isAdmin(_oldAdmin){
        require(_oldAdmin != msg.sender);
        _isAdmin[_oldAdmin]=false;
    }
    
    function deleteCertifier(address _oldCertifier) public isAdmin(msg.sender) isCertifier(_oldCertifier){
        _isCertifier[_oldCertifier]=false;
    }
    
     function deleteUserCanTransferTokenFromContract(address _oldCanTransferTokenFromContract) public isAdmin(msg.sender){
        _canTransferTokenFromContract[_oldCanTransferTokenFromContract]=false;
    }
    
    //-------------------------------------------------------------------------//
    //--------------Enregistrement et transfer de l'instrument-----------------//
    //-------------------------------------------------------------------------//

  function checkInBrandNewInstrument(
    string memory _brand,
    string memory _model,
    string memory _instrumentType,
    string memory _serialNumber,
    string memory _picture1,
    string memory _picture2,
    string memory _picture3,
    string memory _tokenId
    ) public isCertifier(msg.sender){
       
        _mint(address(this), _tokenId);
        
        instrument[_tokenId].brand = _brand;
        instrument[_tokenId].model = _model;
        instrument[_tokenId].instrumentType = _instrumentType;
        instrument[_tokenId].birthDateOfInstrument = now;
        instrument[_tokenId].serialNumber = _serialNumber;
        numberOfPictures[_tokenId] = 3;
        pictures[_tokenId].push(_picture1);
        pictures[_tokenId].push(_picture2);
        pictures[_tokenId].push(_picture3);

        emit newInstrument(_tokenId,_brand,_serialNumber,msg.sender);

    }
    
  function checkInNotNewInstrument(
    string memory _brand,
    string memory _model,
    string memory _instrumentType,
    string memory _serialNumber,
    string memory _picture,
    string memory _tokenId,
    uint _estimateDate
    ) public isCertifier(msg.sender){
 
        _mint(address(this), _tokenId);
        
        instrument[_tokenId].brand = _brand;
        instrument[_tokenId].model = _model;
        instrument[_tokenId].instrumentType = _instrumentType;
        instrument[_tokenId].birthDateOfInstrument = _estimateDate;
        instrument[_tokenId].serialNumber = _serialNumber;
        numberOfPictures[_tokenId] = 1;
        pictures[_tokenId].push(_picture);

        //return _newItemId;
        emit newInstrument(_tokenId,_brand,_serialNumber,msg.sender);
    }
    
     function takeOwnership( string memory _tokenId, address _futurOwner) public isAuthorizedToTransferFromContract(msg.sender) {
        _transferFrom(address(this),_futurOwner,_tokenId);
        string memory _story = string(abi.encodePacked("This instrument have a new owner address : ", _addressToString(_futurOwner)));
        createStory(_tokenId,_story);
        emit newOwner(_tokenId, now, _futurOwner);
        
    }
    

    
    
    //-------------------------------------------------------------------------//
    //---------------------Déclaration de vol ou de perte----------------------//
    //-------------------------------------------------------------------------//
    
    // Un owner peut déclarer son intrument volé ou perdu. 
    function declareStolenOrLost( string memory _tokenId, string memory _message) public isOwner(_tokenId){
        isStolenOrLost[_tokenId] = true;
        string memory concatNowDetails = string(abi.encodePacked(_uint2str(now), "=>", _message));
        storieOfInstrument[_tokenId].push(concatNowDetails);
        numberOfStories[_tokenId] = numberOfStories[_tokenId].add(1);
        emit hasBeenStolenOrLost(_tokenId,now,_message);
    }
    
    // Le owner est le seul à pouvoir pretendre avoir retrouvé son instrument. 
    function declareRecover( string memory _tokenId, string memory _message) public isOwner(_tokenId){
        isStolenOrLost[_tokenId] = false;
        string memory concatNowDetails = string(abi.encodePacked(_uint2str(now), "=>", _message));
        storieOfInstrument[_tokenId].push(concatNowDetails);
        numberOfStories[_tokenId] = numberOfStories[_tokenId].add(1);
        emit hasBeenRecover(_tokenId, now, _message);
    }
    
        
    //-------------------------------------------------------------------------//
    //------------------------------Utilitaires--------------------------------//
    //-------------------------------------------------------------------------//
    

    // fonction permettant de transformer uint en string
    function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
    // fonction permettant de transformer une adresse en string
      function _addressToString(address _addr) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(51);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
    
        
    //-------------------------------------------------------------------------//
    //----------------------Historique de l'instrument-------------------------//
    //-------------------------------------------------------------------------//


    function createStory ( string memory _tokenId, string memory _details) public isCertifier(msg.sender){

        string memory concatNowDetails = string(abi.encodePacked(_uint2str(now), "=>", _details));
        storieOfInstrument[_tokenId].push(concatNowDetails);
        numberOfStories[_tokenId] = numberOfStories[_tokenId].add(1);
        emit historyEvent(_tokenId,now,_details);
    }
    
}
