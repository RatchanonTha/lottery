// SPDX-License-Identifier: GPL-3.0
import "./CommitReveal.sol";
pragma solidity >=0.8.2 <0.9.0;

contract lottery is CommitReveal{
    address owner;
    uint public stage;
    uint numParticipants;
    uint pot;
    mapping (address => uint) public choice;
    uint[] allChoice;
    uint CurrentIndex = 0;
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
        choice[msg.sender] = CurrentIndex++;
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
            stage = 3;
            timeStart = 0;
            require(stage == 2, "Stage 3 now");
        }
    }




}