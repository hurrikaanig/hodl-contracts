// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFHodl.sol";
import "./FHodl.sol";

contract VestingForcedHodl is Ownable{
    
    uint256 limitForUnstake = 60;
    uint256 public totalStakedTokens;
    uint256 TotalToCollect = 1000 ether;

    mapping(address => uint256) public stakers;
    mapping(address => uint256) public lastStakeTimestamp;

    IFHodl public token;

    constructor(IFHodl _token) {
        token = _token;
    }

    //
    // Vesting
    //

    function vest(uint256 _amount) public {
        token.transferFrom(msg.sender, address(this), _amount);
        stakers[msg.sender] += _amount;
        lastStakeTimestamp[msg.sender] = block.timestamp;
        totalStakedTokens += _amount;
    }

    function unvest() public {
        require(stakers[msg.sender] > 0, "no balance to unvest");
        //add unstake penalty
        uint256 timeStaked = block.timestamp - lastStakeTimestamp[msg.sender];
        uint256 amountToCollect = 0;
        for (; timeStaked >= limitForUnstake; timeStaked -= limitForUnstake) {
            amountToCollect += 1;
        }
        uint256 percentage_of_tokens = stakers[msg.sender] * 10000 / totalStakedTokens * TotalToCollect;
        token.mint(amountToCollect * percentage_of_tokens / 10000, msg.sender);
        token.transferFrom(address(this), msg.sender, stakers[msg.sender]);
        totalStakedTokens -= stakers[msg.sender];
        stakers[msg.sender] = 0;
        lastStakeTimestamp[msg.sender] = 0;
    }

    function collectRewards() public {
        require(block.timestamp - lastStakeTimestamp[msg.sender] >= limitForUnstake);
        uint256 timeStaked = block.timestamp - lastStakeTimestamp[msg.sender];
        uint256 amountToCollect = 0;
        for (; timeStaked >= limitForUnstake; timeStaked -= limitForUnstake) {
            amountToCollect += 1;
        }
        uint256 percentage_of_tokens = stakers[msg.sender] * 10000 / totalStakedTokens * TotalToCollect;
        token.mint(amountToCollect * percentage_of_tokens / 10000, msg.sender);
        lastStakeTimestamp[msg.sender] = block.timestamp;

    }

    function setStakers(address staker, uint256 amount) internal {
        stakers[staker] = amount;
    }

}