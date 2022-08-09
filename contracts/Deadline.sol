pragma solidity ^0.8.0;

// SPDX-License-Identifier:MIT

//calculate deadline of stake
interface IDeadline {
    function timestamp() external view returns (uint256);

    function luckTime(address sender, uint128 position)
        external
        view
        returns (uint128);
}

contract Deadline {
    enum staking {
        None,
        for1month,
        for3months,
        for6months,
        for12months
    }
    staking choice;
    mapping(address => mapping(uint128 => uint128)) public luckTime;
    mapping(address => uint64) public positions;

    modifier isExist(uint128 position) {
        require(
            luckTime[msg.sender][position] != 0 &&
                position <= positions[msg.sender],
            "this position dose not exist!"
        );
        _;
    }
    modifier isDone(uint128 position) {
        require(
            luckTime[msg.sender][position] < block.timestamp,
            "this stake position dose not end yet!!!"
        );
        _;
    }
    modifier checkChoice(uint128 _choice) {
        require(_choice > 0 && _choice <= 4, "wrong Choise!!!");
        _;
    }

    function stakeFor(uint8 _choice, address sender)
        internal
        checkChoice(_choice)
        returns (uint256)
    {
        choice = staking(_choice);
        uint128 position = positions[sender];
        uint128 stakeEndTime;
        if (choice == staking(1)) {
            stakeEndTime = luckTime[sender][position] = uint128(
                block.timestamp + 30 days //1 month lock
            );
        } else if (choice == staking(2)) {
            stakeEndTime = luckTime[sender][position] = uint128(
                block.timestamp + 90 days //3 month lock
            );
        } else if (choice == staking(3)) {
            stakeEndTime = luckTime[sender][position] = uint128(
                block.timestamp + 182 days + 12 hours // half year lock
            );
        } else if (choice == staking(4)) {
            stakeEndTime = luckTime[sender][position] = uint128(
                block.timestamp + 365 days //1 year lock
            );
        }
        positions[sender]++;
        return stakeEndTime;
    }

    function timestamp() external view returns (uint256) {
        return block.timestamp;
    }
}
