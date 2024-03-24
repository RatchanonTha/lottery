// SPDX-License-Identifier: GPL-3.0
import "./CommitReveal.sol";
pragma solidity >=0.8.2 <0.9.0;

contract lottery is CommitReveal{
    address owner;
    uint public stage;
    uint numParticipants;
    uint pot;
    mapping (uint => address) public UserAddr;
    uint[] allChoice;
    mapping (uint => uint) public candidate; //new index is what old index
    mapping (address => bool) public commitments;
    uint[3] time;
    uint numCommit = 0;
    uint numReveal = 0;
    uint timeStart = 0;

    constructor(uint T1,uint T2,uint T3, uint N) {
        owner = msg.sender;
        numParticipants = N;
        stage = 1;
        time[0] = T1;
        time[1] = T2;
        time[2] = T3;
    }

    function UserCommit(uint _value, uint salt) public payable {
        require(stage == 1, "Not state 1 now");
        require(numCommit < numParticipants, "No room for you");
        require(msg.value == 0.001 ether);
        if(timeStart != 0 && block.timestamp - timeStart > time[0]) {
            stage = 2;
            timeStart = 0;
            require(stage == 1, "Stage 2 now");
        }

        pot += msg.value;
        commit(getSaltedHash(bytes32(_value),bytes32(salt)));
        commitments[msg.sender] = true;
        numCommit++;
        if (numCommit == 1) {
            timeStart = block.timestamp;
        } 
        else if (numCommit == numParticipants) {
            stage = 2;
            timeStart = 0;
        }
         
    }

    function UserReveal(uint answer,uint salt) public {
        require(stage == 2, "Not state 2 now");
        if(timeStart != 0 && block.timestamp - timeStart > time[1]) {
            stage = 3;
            timeStart = block.timestamp;
            require(stage == 2, "Stage 3 now");
        }

        revealAnswer(bytes32(answer),bytes32(salt));
        UserAddr[numReveal++] = msg.sender;
        allChoice.push(answer);
        numReveal++;
        if (numReveal == 1) {
            timeStart = block.timestamp;
        }
        else if (numReveal == numParticipants) {
            stage = 3;
            timeStart = block.timestamp;
        }
    }

    function findWinner() public payable{
        require(msg.sender == owner, "Only contract owner can call this function");
        require(stage == 3, "Not state 3 now");
        if(block.timestamp - timeStart > time[2]) {
            stage = 4;
            timeStart = 0;
            require(stage == 2, "Stage 3 now");
        }
        uint FinalValue;
        uint answer;
        uint CurrentIndex = 0;
        bool legit = false;

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
        answer = uint(getHash(bytes32(FinalValue))) % CurrentIndex;
        if(legit) {
            address payable winner = payable(UserAddr[candidate[answer]]);
            uint amount = 1 ether * numCommit * 98 / 100000;
            winner.transfer(amount);
            amount = 1 ether * numCommit * 2 / 100000;
            OwnerAcc.transfer(amount);
        } else {
            OwnerAcc.transfer(pot);
        }
    }

    function UserWithdraw() public payable {
        if(block.timestamp - timeStart > time[2] && stage == 3) {
            stage = 4;
        }
        require(stage == 4, "Not state 3 now");
        require(commitments[msg.sender], "Already withdraw or Didn't commit");

        address payable user = payable(msg.sender);
        user.transfer(0.001 ether);
        commitments[msg.sender] = false;
    }


}