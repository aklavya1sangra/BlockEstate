// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract LandRegistry {

    address public admin;

    constructor() {
        admin = msg.sender;
    }

    enum LandType { Private, Public, StateAuthority, StateLand }
    enum VerificationStatus { Pending, Verified, UnderDispute }

    struct Land {
        uint landId;
        string location;
        uint area;
        address owner;
        LandType landType;
        VerificationStatus status;  // This was missing in your ABI!
    }

    mapping(uint => Land) public lands;
    
    // Events
    event LandRegistered(uint indexed landId, address indexed owner, uint timestamp);
    event LandVerified(uint indexed landId, address indexed verifiedBy, uint timestamp);
    event LandDisputed(uint indexed landId, address indexed disputedBy, uint timestamp);
    event LandStatusChanged(uint indexed landId, VerificationStatus status, uint timestamp);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin allowed");
        _;
    }
    
    modifier landExists(uint _id) {
        require(lands[_id].landId == _id, "Land does not exist");
        _;
    }

    // Register land - only admin
    function registerLand(
        uint _id,
        string memory _location,
        uint _area,
        address _owner,
        LandType _landType
    ) public onlyAdmin {
        // FIXED: Check if land exists properly
        require(lands[_id].landId == 0, "Land ID already exists");
        require(_area > 0, "Area must be greater than 0");
        require(bytes(_location).length > 0, "Location cannot be empty");
        require(_owner != address(0), "Invalid owner address");
        
        lands[_id] = Land(
            _id,
            _location,
            _area,
            _owner,
            _landType,
            VerificationStatus.Pending
        );
        
        emit LandRegistered(_id, _owner, block.timestamp);
        emit LandStatusChanged(_id, VerificationStatus.Pending, block.timestamp);
    }

    // Verify land - only admin
    function verifyLand(uint _id) public onlyAdmin landExists(_id) {
        Land storage land = lands[_id];
        require(land.status != VerificationStatus.Verified, "Land already verified");
        
        land.status = VerificationStatus.Verified;
        
        emit LandVerified(_id, msg.sender, block.timestamp);
        emit LandStatusChanged(_id, VerificationStatus.Verified, block.timestamp);
    }

    // Mark dispute - only admin
    function markDispute(uint _id) public onlyAdmin landExists(_id) {
        Land storage land = lands[_id];
        require(land.status != VerificationStatus.UnderDispute, "Land already under dispute");
        
        land.status = VerificationStatus.UnderDispute;
        
        emit LandDisputed(_id, msg.sender, block.timestamp);
        emit LandStatusChanged(_id, VerificationStatus.UnderDispute, block.timestamp);
    }

    // Transfer ownership
    function transferOwnership(uint _id, address _newOwner) public landExists(_id) {
        Land storage land = lands[_id];
        
        require(msg.sender == land.owner || msg.sender == admin, "Not owner or admin");
        require(_newOwner != address(0), "Invalid new owner address");
        
        land.owner = _newOwner;
        
        // Reset status on transfer
        if (land.status != VerificationStatus.Pending) {
            land.status = VerificationStatus.Pending;
            emit LandStatusChanged(_id, VerificationStatus.Pending, block.timestamp);
        }
        
        emit OwnershipTransferred(_id, msg.sender, _newOwner, block.timestamp);
    }

    // FIXED: Get land details - NOW RETURNS 6 VALUES including status
    function getLand(uint _id) public view returns (
        uint landId,
        string memory location,
        uint area,
        address owner,
        LandType landType,
        VerificationStatus status
    ) {
        Land memory land = lands[_id];
        require(land.landId == _id, "Land does not exist");
        
        return (
            land.landId,
            land.location,
            land.area,
            land.owner,
            land.landType,
            land.status
        );
    }

    // Helper function to check if land exists
    function landExists_(uint _id) public view returns (bool) {
        return lands[_id].landId == _id;
    }

    // Add missing event
    event OwnershipTransferred(uint indexed landId, address indexed oldOwner, address indexed newOwner, uint timestamp);
}