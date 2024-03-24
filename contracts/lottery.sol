// SPDX-License-Identifier: GPL-3.0
import "./CommitReveal.sol";
pragma solidity >=0.8.2 <0.9.0;

contract lottery is CommitReveal{
    address public owner;
    uint public stage;
    uint public numParticipants;
    uint public pot;
    mapping (uint => address) public UserAddr; //store user that reveal
    address[] public CommitAddr; //store user that commit
    uint[] public allChoice;
    mapping (uint => uint) public candidate; //new index is what old index
    mapping (address => bool) public commitments;
    uint[3] public time;
    uint public numCommit = 0;
    uint public numReveal = 0;
    uint public timeStart = 0;
    bool public GaveReward = false;
    uint public CurrentIndex = 0;
    bool legit = false;

    constructor(uint T1,uint T2,uint T3, uint N) {
        owner = msg.sender;
        numParticipants = N;
        stage = 1;
        time[0] = T1;
        time[1] = T2;
        time[2] = T3;
    }

    function resetValue() public {
        for(uint i=0; i < numReveal; i++) {
            UserAddr[i] = address(0);
            allChoice[i] = 0;
        }
        for(uint j=0; j < CurrentIndex; j++) {
            candidate[j] = 0;
        }
        for(uint k=0; k < numCommit; k++) {
            commitments[CommitAddr[k]] = false;
            CommitAddr[k] = address(0);
        }
        CurrentIndex = 0;
        numCommit = 0;
        numReveal = 0;
        timeStart = 0;
        GaveReward = false;
        pot = 0;
        stage = 1;
        legit = false;
    }

    function UserCommit(uint _value, uint salt) public payable {
        require(stage == 1, "Not state 1 now");
        require(numCommit < numParticipants, "No room for you");
        require(msg.value == 0.001 ether);
        if(timeStart != 0) { // if not the first commit and time's out
            require(block.timestamp - timeStart < time[0], "Time's up for commiting");
        }

        pot += msg.value;
        commit(getSaltedHash(bytes32(_value),bytes32(salt)));
        commitments[msg.sender] = true;
        CommitAddr.push(msg.sender);
        numCommit++;
        if (numCommit == 1) {
            timeStart = block.timestamp;
        } 
        else if (numCommit == numParticipants) {
            stage = 2;
            timeStart = block.timestamp;
        }
         
    }

    function UserReveal(uint answer,uint salt) public {
        if(block.timestamp - timeStart > time[0] && stage == 1) {
            require(block.timestamp - timeStart < time[0]+time[1], "Time's up for revealing"); //if already passed stage 1,is it still in state2?
            stage = 2;
            timeStart = block.timestamp;
        }
        require(stage == 2, "Not state 2 now");
        require(block.timestamp - timeStart < time[1], "Time's up for revealing");

        revealAnswer(bytes32(answer),bytes32(salt));
        UserAddr[numReveal] = msg.sender;
        allChoice.push(answer);
        numReveal++;
        if (numReveal == numCommit) {
            stage = 3;
            timeStart = block.timestamp;
        }
    }

    function findWinner() public payable{
        if(((numCommit != 0 && block.timestamp - timeStart > time[0] + time[1]) && stage == 1) || ((numCommit != 0 && block.timestamp - timeStart > time[1]) && stage == 2)) {
            require(block.timestamp - timeStart < time[0]+time[1]+time[2], "Time's up for finding winner"); //if already passed stage 1 and stage2,is it still in state3?
            stage = 3;
            timeStart = block.timestamp;
        } 

        require(msg.sender == owner, "Only contract owner can call this function");
        require(stage == 3, "Not state 3 now");
        require(block.timestamp - timeStart < time[2], "Time's up for finding winner");
        uint FinalValue;
        uint answer;
        uint amount;

        for(uint i=0; i < numReveal; i++) {
            if(allChoice[i] >= 0 && allChoice[i] <= 999) {
                legit = true;
                if(FinalValue == 0) {
                    FinalValue = allChoice[i];
                    continue;
                }
                FinalValue = FinalValue ^ allChoice[i];
                candidate[CurrentIndex++] = i;
            }
        }

        address payable OwnerAcc = payable(owner);
        if(legit) {
            answer = uint(getHash(bytes32(FinalValue))) % CurrentIndex;
            address payable winner = payable(UserAddr[candidate[answer]]);
            amount = 1 ether * numCommit * 98 / 100000;
            winner.transfer(amount);
            amount = 1 ether * numCommit * 2 / 100000;
            OwnerAcc.transfer(amount);
        } else {
            OwnerAcc.transfer(pot);
        }
        GaveReward = true;
        resetValue();
    }

    function UserWithdraw() public payable {
        if((((numCommit != 0 && block.timestamp - timeStart > time[0] + time[1] + time[2]) && stage == 1) || ((numCommit != 0 && block.timestamp - timeStart > time[1] + time[2]) && stage == 2)) || ((numCommit != 0 && block.timestamp - timeStart > time[2]) && stage == 3)) {
            stage = 4;
        }
        require(stage == 4, "Not state 4 now");
        require(commitments[msg.sender], "Already withdraw or Didn't commit");

        address payable user = payable(msg.sender);
        user.transfer(0.001 ether);
        commitments[msg.sender] = false;
        numCommit = numCommit - 1;
        if(numCommit == 0) {
            resetValue();
        }
    }


}