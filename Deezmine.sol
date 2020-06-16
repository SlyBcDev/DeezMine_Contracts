pragma solidity ^0.5.0;

import "./VIP181.sol";
import "./SafeMath.sol";

contract DeezMine is VIP181 {
    
    using SafeMath for uint;
    
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


  event newInstrument(string indexed _id, string _brand, string _serialNumber, address indexed _certifier); 
  event newOwner(string indexed _id, uint date, address _newOwnerAddress);
  event hasBeenStolenOrLost(string indexed _id, uint date, string _message);
  event hasBeenRecover(string indexed _id, uint date, string _message);
  event warningAlarm(string indexed _id, uint date, string _location);
  event historyEvent(string indexed _id,uint _date, string _details);

    // Modifier
 
    modifier isOwner(string memory _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
    }
    
    modifier canTransferTokenFromContract(address _asker){
        require(_canTransferTokenFromContract[_asker]==true);
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

    constructor() VIP181("DeezMine", "DZM") public{
    _isAdmin[msg.sender]=true;
    _isCertifier[msg.sender]=true;
    _canTransferTokenFromContract[msg.sender]=true;
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
    
     function deleteUserCanTransferTokenFromContract(address _oldCanTransferTokenFromContract) public isAdmin(msg.sender) canTransferTokenFromContract(_oldCanTransferTokenFromContract){
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
    string memory _hashUidNfcTag
    ) public isCertifier(msg.sender){
       
        _mint(address(this), _hashUidNfcTag);
        
        instrument[_hashUidNfcTag].brand = _brand;
        instrument[_hashUidNfcTag].model = _model;
        instrument[_hashUidNfcTag].instrumentType = _instrumentType;
        instrument[_hashUidNfcTag].birthDateOfInstrument = now;
        instrument[_hashUidNfcTag].serialNumber = _serialNumber;
        numberOfPictures[_hashUidNfcTag] = 3;
        pictures[_hashUidNfcTag].push(_picture1);
        pictures[_hashUidNfcTag].push(_picture2);
        pictures[_hashUidNfcTag].push(_picture3);

        emit newInstrument(_hashUidNfcTag,_brand,_serialNumber,msg.sender);

    }
    
  function checkInNotNewInstrument(
    string memory _brand,
    string memory _model,
    string memory _instrumentType,
    string memory _serialNumber,
    string memory _picture,
    string memory _hashUidNfcTag,
    uint _estimateDate
    ) public isCertifier(msg.sender){
 
        _mint(address(this), _hashUidNfcTag);
        
        instrument[_hashUidNfcTag].brand = _brand;
        instrument[_hashUidNfcTag].model = _model;
        instrument[_hashUidNfcTag].instrumentType = _instrumentType;
        instrument[_hashUidNfcTag].birthDateOfInstrument = _estimateDate;
        instrument[_hashUidNfcTag].serialNumber = _serialNumber;
        numberOfPictures[_hashUidNfcTag] = 1;
        pictures[_hashUidNfcTag].push(_picture);

        //return _newItemId;
        emit newInstrument(_hashUidNfcTag,_brand,_serialNumber,msg.sender);

    }
    
     function takeOwnership( string memory _hashUidNfcTag, address _futurOwner) public canTransferTokenFromContract(msg.sender) {
        transferFrom(address(this),_futurOwner,_hashUidNfcTag);
        string memory _story = string(abi.encodePacked("This instrument have a new owner address : ", _addressToString(_futurOwner)));
        createStory(_hashUidNfcTag,_story);
        emit newOwner(_hashUidNfcTag, now, _futurOwner);
        
    }
    

    
    
    //-------------------------------------------------------------------------//
    //---------------------Déclaration de vol ou de perte----------------------//
    //-------------------------------------------------------------------------//
    
    // Un owner peut déclarer son intrument volé ou perdu. 
    function declareStolenOrLost( string memory _hashUidNfcTag, string memory _message) public isOwner(_hashUidNfcTag){
        isStolenOrLost[_hashUidNfcTag] = true;
        string memory concatNowDetails = string(abi.encodePacked(_uint2str(now), "=>", _message));
        storieOfInstrument[_hashUidNfcTag].push(concatNowDetails);
        numberOfStories[_hashUidNfcTag] = numberOfStories[_hashUidNfcTag].add(1);
        emit hasBeenStolenOrLost(_hashUidNfcTag,now,_message);
    }
    
    // Le owner est le seul à pouvoir pretendre avoir retrouvé son instrument. 
    function declareRecover( string memory _hashUidNfcTag, string memory _message) public isOwner(_hashUidNfcTag){
        isStolenOrLost[_hashUidNfcTag] = false;
        string memory concatNowDetails = string(abi.encodePacked(_uint2str(now), "=>", _message));
        storieOfInstrument[_hashUidNfcTag].push(concatNowDetails);
        numberOfStories[_hashUidNfcTag] = numberOfStories[_hashUidNfcTag].add(1);
        emit hasBeenRecover(_hashUidNfcTag, now, _message);
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


    function createStory ( string memory _hashUidNfcTag , string memory _details) public isCertifier(msg.sender){

        string memory concatNowDetails = string(abi.encodePacked(_uint2str(now), "=>", _details));
        storieOfInstrument[_hashUidNfcTag].push(concatNowDetails);
        numberOfStories[_hashUidNfcTag] = numberOfStories[_hashUidNfcTag].add(1);
        emit historyEvent(_hashUidNfcTag,now,_details);
    }
    


}



 
