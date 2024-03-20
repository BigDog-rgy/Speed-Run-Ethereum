// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping (address => uint256) public balances;

  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;

  bool public openForWithdraw = false;
  bool public fundsSent = false;

  event Stake(address indexed staker, uint256 amount);

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier notCompleted() {
    require(!fundsSent, "Operation not allowed. Funds have been escrowed, this contract is completed.");
    _;
  }

  function stake() public payable notCompleted {
    require(msg.value > 0, "Cannot send 0 ETH");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  function execute() public notCompleted {
    // check current time is past deadline
    require(block.timestamp > deadline, "Deadline has not passed yet.");

    if(address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
      fundsSent = true;
    } else {
      openForWithdraw = true;
    }
  }

  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  function withdraw() public notCompleted {
    require(openForWithdraw, "Withdrawal is not open.");
    uint256 stakedAmount = balances[msg.sender];
    require(stakedAmount > 0, "You have no balance to withdraw>");

    // Reset the staker's balance before transfer to prevent re-entrancy attacks
    balances[msg.sender] = 0;
    (bool sent, ) = msg.sender.call{value: stakedAmount}("");
    require(sent, "Failed to send Ether.");
  }

  receive() external payable {
    stake();
  }
}
