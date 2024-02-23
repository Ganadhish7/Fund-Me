// SPDX-License-Identifier: MIT

// Get funds from users
// withdraw funds
// set a minimum funding value in USD 

pragma solidity ^0.8.19;

// import {AggregatorV3Interface} from  "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {PriceConverter} from "./PriceConverter.sol";

contract FundMe {

    using PriceConverter for uint256;

    uint256 public minimumUSD = 5e18;  // or 5 * 1e18

    // to keep track of the users who send us money 
    // array of funders
    address[] public funders;

    // mapping to see how much each sender has send 
    mapping(address funder => uint256 amountFunded) public addressToAmountFunded;


    address public owner;
    // The constructor is a keyword and special function in solidity 
    // this is going to be a function that is immediately called whenever the contract is deployed
    constructor(){
        owner = msg.sender;
    }

    function fund() public payable {
        // Allow users to send money
        // have a minimum dollar amout to send which may be 5$
        // 1. How do we send ETH to this contract?? 
        // msg.value.getConversionRate();
        require(msg.value.getConversionRate() >= minimumUSD, "Didn't send enough ETH");
        // second element in require is Revert 
        // what is revert?
        // undo any actions that have been done, and send the remaining gas back

        funders.push(msg.sender);

        // mapping 
        addressToAmountFunded[msg.sender] += msg.value;
    }

    // we don't want everyone to withdraw from the contract
    // only the owner can withdraw
    function withdraw() public onlyOwner{
        // require(msg.sender == owner, "Must be owner!!");
        // for loop to reset the mappings to zero or initial state
        // for(/* starting index, ending index, step amount */)
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        //reset the array 
        funders = new address[](0);

        //withdraw the funds

        // transfer
        // msg.sender is of type address // msg.sender = address
        // payable(msg.sender) is of type payable address // payable(msg.sender) = payable address
        // here (this) keyword refers to this contract as whole
        // in order to send native token like ethereum we can only work with payable address that is why wrap it in the (payable) typecaster
        payable(msg.sender).transfer(address(this).balance);
        // transfer automatically reverts if the transaction fails

        // send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");
        // send function returns boolean and reverts the transaction if we add require statement

        // call
        (bool callSuccess, )= payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call failed");
    }

    // modifier is going to allow us to create a keyword that we can put right in
    // the function declaration to add some functionality very quickly and easily
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not owner");
        _;  // this indicates to execute everything else after the function above
     }

    // what happens if someone sends this contract ETH without calling the fund function 
    // receive()
    receive() external payable {
        fund();
    }
    
    // fallback
    fallback() external payable {
        fund();
    }
}