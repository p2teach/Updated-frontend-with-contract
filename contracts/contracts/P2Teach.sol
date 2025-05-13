// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract P2Teach {
    struct User {
        string name;
        string email;
        bool isRegistered;
        uint256 joinDate;
        address walletAddress;
        address[] linkedWallets;
    }

    mapping(address => User) public users;
 
    address[] public userAddresses;
    mapping(address => address) public walletToPrimaryAccount;

    struct Booking {
        uint256 id;
        string location;
        uint256 date;
        string time;
        uint256 tutorId;
        uint256 studentId;
        address tutorWalletAddress;
        address studentWalletAddress;
        uint256 createdAt;
    }

    struct Session {
        uint256 id;
        uint256 user_id;
        string coursetitle;
        string subjectitle;
        uint256 price;
        address walletaddress;
        uint256 duration;
        uint256 created_at;
        uint256 updated_at;
    }

    Session[] public sessions;
    Booking[] public bookings;
    mapping(uint256 => uint256) public bookingIdToIndex;

    event BookingCreated(
        uint256 indexed id,
        address indexed tutorWallet,
        address indexed studentWallet,
        uint256 date
    );

    event UserUpdated(address indexed userAddress, string name, string email);

    modifier userHasAccount() {
        require(users[msg.sender].isRegistered, "User not registered!");
        _;
    }

    event UserRegistered(address indexed userAddress, string name, string email);
    event WalletLinked(address indexed primaryAddress, address indexed linkedWallet);

    modifier onlyUnregistered() {
        require(!users[msg.sender].isRegistered, "User already registered");
        _;
    }


    

    function registerUser(string memory _name, string memory _email) public onlyUnregistered {
        users[msg.sender] = User({
            name: _name,
            email: _email,
            isRegistered: true,
            joinDate: block.timestamp,
            walletAddress: msg.sender,
            linkedWallets: new address[](0)
        });
        
        userAddresses.push(msg.sender);
        walletToPrimaryAccount[msg.sender] = msg.sender;
        emit UserRegistered(msg.sender, _name, _email);
    }

    function registerWithExternalWallet(
        string memory _name, 
        string memory _email, 
        address _externalWallet
    ) public onlyUnregistered {
        require(_externalWallet != address(0), "Invalid wallet address");
        require(!users[_externalWallet].isRegistered, "External wallet already registered");
        
        // Register the msg.sender as primary account
        users[msg.sender] = User({
            name: _name,
            email: _email,
            isRegistered: true,
            joinDate: block.timestamp,
            walletAddress: _externalWallet, // Store the external wallet as primary
            linkedWallets: new address[](0)
        });
        
        // Link the external wallet to this account
        walletToPrimaryAccount[_externalWallet] = msg.sender;
        users[msg.sender].linkedWallets.push(_externalWallet);
        
        userAddresses.push(msg.sender);
        emit UserRegistered(msg.sender, _name, _email);
        emit WalletLinked(msg.sender, _externalWallet);
    }

    function linkAdditionalWallet(address _newWallet) public userHasAccount {
        require(_newWallet != address(0), "Invalid wallet address");
        require(!users[_newWallet].isRegistered, "Wallet already registered");
        require(walletToPrimaryAccount[_newWallet] == address(0), "Wallet already linked");
        
        walletToPrimaryAccount[_newWallet] = msg.sender;
        users[msg.sender].linkedWallets.push(_newWallet);
        emit WalletLinked(msg.sender, _newWallet);
    }

    function updateUser(string memory _name, string memory _email) userHasAccount public {
        users[msg.sender].name = _name;
        users[msg.sender].email = _email;
        emit UserUpdated(msg.sender, _name, _email);
    }

    function createSession(
        uint256 _user_id,
        string memory _coursetitle,
        string memory _subjectitle,
        uint256 _price,
        uint256 _duration,
        address _walletaddress
    ) public userHasAccount {
        sessions.push(Session({
            id: sessions.length,
            user_id: _user_id,
            coursetitle: _coursetitle,
            subjectitle: _subjectitle,
            price: _price,
            walletaddress: _walletaddress,
            duration: _duration,
            created_at: block.timestamp,
            updated_at: block.timestamp
        }));
    }
    
    function getSession(uint256 _id) public view userHasAccount returns (Session memory) {
        return sessions[_id];
    }

    function createBooking(
        string memory _location,
        uint256 _date,
        string memory _time,
        uint256 _tutorId,
        uint256 _studentId,
        address _tutorWalletAddress,
        address _studentWalletAddress
    ) external userHasAccount returns (uint256) {
        require(users[_tutorWalletAddress].isRegistered, "Tutor not registered");
        require(users[_studentWalletAddress].isRegistered, "Student not registered");
        
        uint256 newBookingId = bookings.length + 1;
        
        Booking memory newBooking = Booking({
            id: newBookingId,
            location: _location,
            date: _date,
            time: _time,
            tutorId: _tutorId,
            studentId: _studentId,
            tutorWalletAddress: _tutorWalletAddress,
            studentWalletAddress: _studentWalletAddress,
            createdAt: block.timestamp
        });
        
        bookings.push(newBooking);
        bookingIdToIndex[newBookingId] = bookings.length - 1;
        
        emit BookingCreated(newBookingId, _tutorWalletAddress, _studentWalletAddress, _date);
        
        return newBookingId;
    }

    function getBooking(uint256 _bookingId) external userHasAccount view returns (Booking memory) {
        require(_bookingId > 0 && _bookingId <= bookings.length, "Booking does not exist");
        uint256 index = bookingIdToIndex[_bookingId];
        return bookings[index];
    }

    function getUser(address _userAddress) public view returns (
        string memory name,
        string memory email,
        bool isRegistered,
        uint256 joinDate,
        address walletAddress
    ) {
        User memory user = users[_userAddress];
        return (user.name, user.email, user.isRegistered, user.joinDate, user.walletAddress);
    }

    function getTotalUsers() public view returns (uint256) {
        return userAddresses.length;
    }

    function getUserByWallet(address _wallet) public view returns (
        string memory name,
        string memory email,
        bool isRegistered,
        uint256 joinDate,
        address primaryWallet,
        address[] memory linkedWallets
    ) {
        address primary = walletToPrimaryAccount[_wallet];
        require(primary != address(0) || users[_wallet].isRegistered, "User not found");
        
        if (primary == address(0)) {
            // This is a primary wallet
            primary = _wallet;
        }
        
        User memory user = users[primary];
        return (
            user.name,
            user.email,
            user.isRegistered,
            user.joinDate,
            primary,
            user.linkedWallets
        );
    }

    function getUserByIndex(uint256 index) public view returns (
        string memory name,
        string memory email,
        bool isRegistered,
        uint256 joinDate,
        address walletAddress
    ) {
        require(index < userAddresses.length, "Index out of bounds");
        address userAddress = userAddresses[index];
        User memory user = users[userAddress];
        return (user.name, user.email, user.isRegistered, user.joinDate, user.walletAddress);
    }
}