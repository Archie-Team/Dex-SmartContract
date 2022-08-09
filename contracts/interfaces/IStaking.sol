// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

interface IStake {
    function pair() external view returns (address);

    function timestamp() external view returns (uint256);

    function luckTime(address sender, uint128 position)
        external
        view
        returns (uint128);

    function StakedRewardFreezed() external view returns (uint256);

    function StakedReward() external view returns (uint256);

    function totalValueLuckLPToken() external view returns (uint256);

    function totalValueLuckBUSD() external view returns (uint256);

    function AllStakedBalance(address account) external view returns (uint256);

    function rewardToken() external view returns (address);

    function stakingToken() external view returns (address);

    function rewardOf(address _account, uint32 position)
        external
        view
        returns (uint256);

    function getAll(address _account, uint32 position)
        external
        view
        returns (
            uint256 remainedTime,
            uint256 reward,
            uint256 choise,
            uint256 LPTokenBalnce
        );

    function stakedBalance(address account, uint32)
        external
        view
        returns (uint256);

    function stakedChoise(address account, uint32)
        external
        view
        returns (uint256);

    function calculateAmountBulc(uint256 _amountBusd)
        external
        view
        returns (uint256);

    function calculateAmountBusd(uint256 _BulcAmount)
        external
        view
        returns (uint256);

    function calculateValue(uint256 _LpTokenAmount)
        external
        view
        returns (uint256 valueLpPerBusd);

    function calculatePermit(uint256 amount_, uint8 choice_)
        external
        pure
        returns (uint256 exactAmount);

    function calculate(uint256 _LPamount, uint8 choice)
        external
        view
        returns (uint256 permitPerBulc);

    function stake(uint256 _amount, uint8 _Choise) external;

    function unstake(uint32 position) external;

    function distribute(uint256 _reward) external;

    function witdraw(uint256 rewardTokenAmount) external;
}
