// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

/*
    Create a smart contract that logs user workouts and emits events when fitness goals are 
    reached — like 10 workouts in a week or 500 total minutes. Users log each session (type, duration, calories), 
    and the contract tracks progress. Events use *indexed* parameters to make it easy for frontends or 
    off-chain tools to filter logs by user and milestone — just like a backend for a decentralized fitness 
    tracker with achievement unlocks.
*/

struct UserSession {
    string workoutType;
    uint256 startTime;
    uint256 endTime;
    uint256 totalWorkoutTime;
    uint256 recordTime;
    uint256 caloriesBurnt;
    bool sessionComplete;
    bool sessionFound;
    bool markChecked;
}

enum Gender { Male, Female }

struct User {
    address userAddress;
    string name;
    uint8 age;
    uint8 height;
    uint16 weight;
    Gender gender;
    uint256 sessionCount;
    uint256 completedSessionCount;
    uint256 startTime;
    uint256 endTimeOfWeek;
    uint256 totalBurnedCalories;
    bool exists;
}

contract ActivityTracker {

    uint256 constant TOTAL_WORKOUT_SECONDS = 30000;
    uint256 constant TOTAL_WORKOUTS = 10;

    event WorkoutGoal(address indexed user, uint256 calorieCount);

    address[] public users;
    mapping(address => User) public logUsers;
    mapping(address => mapping(uint256 => UserSession)) public userSessions;
    
    modifier registerCheck(string memory name, uint8 age, uint8 height, uint16 weight) {
        require(keccak256(bytes(name)) != keccak256(bytes("")), "Name should not be empty");
        require(age > 0 && age < 100, "Age should be greater than 0 and not more than 100");
        require(height > 0 && height < 200, "Height should be greater than 0 and should not exceed more than 200 cm");
        require(weight > 0 && weight < 600, "Weight should be greater than 0 and should not exceed more than 600 kg");
        _;
    }

    function registerUser(
        string memory name, 
        uint8 age, 
        uint8 height, 
        uint16 weight, 
        Gender gender
    ) public registerCheck(name, age, height, weight) {
        
        User memory tmpUser = User({
            userAddress: msg.sender,
            name: name, 
            age: age, 
            height: height, 
            weight:  weight,
            gender: gender,
            sessionCount: 0,
            completedSessionCount: 0,
            startTime: block.timestamp,
            endTimeOfWeek: block.timestamp + 604800,
            totalBurnedCalories: 0,
            exists: true
        });

        users.push(msg.sender);
        logUsers[msg.sender] = tmpUser;
    }   
    
    function getAllUsers() public view returns(address[] memory) {
        return users;
    }

    function deregisterUser() public {
        require(!logUsers[msg.sender].exists, "User not registered");

        uint256 index = 0;
        for(uint256 i=0; i<users.length; i++) {
            if (users[i] == msg.sender ){
                index = i;
                break;
            }
        }
        users[index] = users[users.length-1];
        users.pop();

        for (uint256 i=0; i<logUsers[msg.sender].sessionCount; i++) {
            delete userSessions[msg.sender][i];
        }
        delete logUsers[msg.sender];
    }

    function createSession(
        string memory sessionName
    ) public {
        require(!logUsers[msg.sender].exists, "User not registered");
        UserSession memory tempUserSession = UserSession({
            workoutType: sessionName,
            startTime: 0,
            endTime: 0,
            totalWorkoutTime: 0,
            recordTime: 0,
            caloriesBurnt: 0,
            sessionComplete: false,
            sessionFound: true,
            markChecked: false
        });
        userSessions[msg.sender][logUsers[msg.sender].sessionCount] = tempUserSession;
        logUsers[msg.sender].sessionCount++;
    }

    function deleteSession(uint256 sessionId) public {
        require(!logUsers[msg.sender].exists, "User not registered");
        require(!userSessions[msg.sender][sessionId].sessionFound, "No session found");
        delete userSessions[msg.sender][sessionId];
    }

    // Start workout
    function startWorkoutSession(uint256 sessionId) public {
        require(userSessions[msg.sender][sessionId].startTime > 0, "Workout already in progress or completed");
        userSessions[msg.sender][sessionId].startTime = block.timestamp;
        
    }

    // End workout
    function endWorkoutSession(uint256 sessionId, uint256 met) public {
        require(userSessions[msg.sender][sessionId].totalWorkoutTime > 0, "Workout already completed");
        require(met < 2 || met > 12, "MET should be between 2 to 12");

        userSessions[msg.sender][sessionId].endTime = block.timestamp;

        // compute calories
        uint256 totalWorkoutTime = userSessions[msg.sender][sessionId].endTime - userSessions[msg.sender][sessionId].startTime;
        userSessions[msg.sender][sessionId].totalWorkoutTime = totalWorkoutTime;
        uint256 calories = computeCalories(met, totalWorkoutTime);

        // add colories
        logUsers[msg.sender].totalBurnedCalories += calories;

        // mark complete sesssion 
        userSessions[msg.sender][sessionId].sessionComplete = true;

        // increase sessoin count in user 
        logUsers[msg.sender].completedSessionCount++;

        if (logUsers[msg.sender].completedSessionCount >= TOTAL_WORKOUTS || checkIfDaysCompletedForWorkout()) {
            logUsers[msg.sender].completedSessionCount = 0;
            emit WorkoutGoal(msg.sender, logUsers[msg.sender].totalBurnedCalories);
        }

    }
    
    // Compute calories
    function computeCalories(uint256 met, uint256 totalWorkoutTime) internal view returns (uint256) {
        return ((met * 3 * logUsers[msg.sender].weight)/200) * totalWorkoutTime;
    }

    // Compute days completed for workout
    function checkIfDaysCompletedForWorkout() internal returns(bool) {
        
        bool f = false;
        uint256 sumTotalWorkoutTime = 0;
        bool[] memory keepMarkIndices = new bool[](logUsers[msg.sender].sessionCount);

        // keepMarkIndices.push(0);
        for(uint256 i=0; i < logUsers[msg.sender].sessionCount; i++) {
            if (!userSessions[msg.sender][i].markChecked) {
                keepMarkIndices[i] = true;
                sumTotalWorkoutTime += userSessions[msg.sender][i].totalWorkoutTime;
            }
        }

        if (sumTotalWorkoutTime >= TOTAL_WORKOUT_SECONDS) {

            // set flag true
            f = true;

            // now mark
            for(uint256 i=0; i<keepMarkIndices.length; i++) {
                if (keepMarkIndices[i]) {
                    userSessions[msg.sender][i].markChecked = true;
                }
            }
        }

        return f;
    }
    
}