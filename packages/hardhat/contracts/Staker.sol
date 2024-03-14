// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping (address => uint256) public balances;

  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 30 seconds;

  bool public openForWithdraw = false;

  event Stake(address indexed staker, uint256 amount);

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  function stake() public payable {
    require(msg.value > 0, "Cannot send 0 ETH");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  function execute() public {
    // check current time is past deadline
    require(block.timestamp > deadline, "Deadline has not passed yet.");

    if(address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
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

  function withdraw() public {
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
  

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)


  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`


  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend


  // Add the `receive()` special function that receives eth and calls stake()

}
