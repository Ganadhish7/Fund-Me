// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// import {AggregatorV3Interface} from  "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {PriceConverter} from "./PriceConverter.sol";

contract FundMe {

    using PriceConverter for uint256;

    uint256 public minimumUSD = 5e18;  // or 5 * 1e18

    address[] public funders;

    mapping(address funder => uint256 amountFunded) public addressToAmountFunded;


    address public owner;
    constructor(){
        owner = msg.sender;
    }

    function fund() public payable {
       
        require(msg.value.getConversionRate() >= minimumUSD, "Didn't send enough ETH");
    
        funders.push(msg.sender);

        // mapping 
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner{
    
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        //reset the array 
        funders = new address[](0);

        //withdraw the funds
        payable(msg.sender).transfer(address(this).balance);
        // transfer automatically reverts if the transaction fails

        // send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, )= payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call failed");
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not owner");
        _; 
     }

    // receive()
    receive() external payable {
        fund();
    }

    // fallback
    fallback() external payable {
        fund();
    }
}
