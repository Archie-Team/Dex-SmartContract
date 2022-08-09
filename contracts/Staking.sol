// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./libraries/BullCoinLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Deadline.sol";

contract Staking is Ownable, ReentrancyGuard, Deadline {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    IUniswapV2Pair public pair; //PAIR ADDRESS
    IERC20 public rewardToken; //REWARD TOKEN ADDRESS
    IERC20 public stakingToken; //LP TOKEN ADDRESS

    uint256 public StakedRewardFreezed = 0; //FREEZED STAKE REWARD
    uint256 public StakedReward; //FREE STAKE REWAED
    uint256 public totalValueLockLPToken; // LP TOKEN LOCKED
    uint256 public totalValueLockBUSD; //LP TOKEN LOCKED PER BUSD
    mapping(address => uint256) public AllStakedBalance; // stake = {};
    mapping(address => mapping(uint32 => uint256)) public stakedBalance; // stake = {};
    mapping(address => mapping(uint32 => uint8)) public stakedChoise; // choise = {};

    event Stake(address indexed user, uint256 amount, uint256 endTime);
    event Unstake(address indexed user, uint256 amount, uint256 reward);
    event Distribute(address indexed user, uint256 reward);

    constructor(address _stakingToken, address _rewardToken) {
        /* ======= PAIR AND LPTOKEN HAVE SAVE ADDRESSES ======= */
        pair = IUniswapV2Pair(_stakingToken); //PAIR ADDRESS
        stakingToken = IERC20(_stakingToken); //LP TOKEN ADDRESS
        rewardToken = IERC20(_rewardToken); //REWARD ADDRESS
    }

    /* ========== FUNCTIONS ========== */

    function calculateAmountBulc(uint256 _amountBusd)
        public
        view
        returns (uint256)
    {
        bool trueToken = (pair.token0() == address(rewardToken)); //CHECK WHICH TOKEN ADDRESS IS REWARD ADDRESS

        uint256 reserveBulc; //REWARD ADDRESS
        uint256 reserveBusd; //FEE TOKEN ADDRESS
        if (trueToken) {
            (reserveBulc, reserveBusd, ) = pair.getReserves(); //GET RESERVES
        } else {
            (reserveBusd, reserveBulc, ) = pair.getReserves(); //GET RESERVES
        }
        return BullCoinLibrary.quote(_amountBusd, reserveBusd, reserveBulc);
    }

    function calculateAmountBusd(uint256 _BulcAmount)
        public
        view
        returns (uint256)
    {
        bool trueToken = (pair.token0() != address(rewardToken)); //CHECK WHICH ADDRESS IS NOT REWARD ADDRESS

        uint256 reserveBulc; //REWARD TOKEN ADDRESS
        uint256 reserveBusd; //FEE TOKEN ADDRESS
        if (!trueToken) {
            (reserveBulc, reserveBusd, ) = pair.getReserves(); //GET RESERVES
        } else {
            (reserveBusd, reserveBulc, ) = pair.getReserves(); //GET RESERVES
        }
        return BullCoinLibrary.quote(_BulcAmount, reserveBulc, reserveBusd);
    }

    function calculateValue(uint256 _LpTokenAmount)
        public
        view
        returns (uint256 valueLpPerBusd)
    {
        uint256 LPBalancePair = pair.totalSupply(); //
        bool trueToken = (pair.token0() != address(rewardToken));
        uint256 BusdAmount;

        if (trueToken) {
            (BusdAmount, , ) = pair.getReserves();
        } else {
            (, BusdAmount, ) = pair.getReserves();
        }
        uint256 BusdBalancePair = BusdAmount;

        uint256 pairValue = BusdBalancePair * 2;
        uint256 LpTokenPerBusdValue = Math.ceilDiv(pairValue, LPBalancePair);
        valueLpPerBusd = _LpTokenAmount * LpTokenPerBusdValue;
    }

    function calculatePermit(uint256 amount_, uint8 choice_)
        public
        pure
        returns (uint256 exactAmount)
    {
        uint256 amount = amount_; //GAS SAVING

        if (choice_ == 1) {
            exactAmount = Math.ceilDiv((amount * 60), (12 * 100)); //60APR
        }
        if (choice_ == 2) {
            exactAmount = Math.ceilDiv((amount * 120), (4 * 100)); //120APR
        }
        if (choice_ == 3) {
            exactAmount = Math.ceilDiv((amount * 160), (2 * 100)); //160APR
        }
        if (choice_ == 4) {
            exactAmount = Math.ceilDiv((amount * 300), 100); //300APR
        }
    }

    function calculate(uint256 _LPamount, uint8 choice)
        public
        view
        returns (uint256 permitPerBulc)
    {
        uint256 BusdAmount = calculateValue(_LPamount);
        uint256 permitPerBusd = calculatePermit(BusdAmount, choice);
        permitPerBulc = calculateAmountBulc(permitPerBusd);
    }

    function stake(uint256 _amount, uint8 _Choise)
        external
        checkChoice(_Choise)
        nonReentrant
    {
        require(_amount > 0, "Cannot stake 0");
        uint256 lock = calculate(_amount, _Choise);
        require(StakedReward > lock, "owner have not enough bulc to pay!");
        IERC20 Busd;
        bool trueToken = (pair.token0() != address(rewardToken));
        if (trueToken) {
            Busd = IERC20(pair.token0());
        } else {
            Busd = IERC20(pair.token1());
        }

        uint256 fee = calculateValue(_amount) / 100;
        Busd.transferFrom(msg.sender, owner(), fee);
        StakedReward -= lock;
        StakedRewardFreezed += lock;
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        AllStakedBalance[msg.sender] += _amount; // stake[address] = amount;
        stakedBalance[msg.sender][uint32(positions[msg.sender])] = _amount; // stake[address] = amount;
        stakedChoise[msg.sender][uint32(positions[msg.sender])] = _Choise;
        totalValueLockLPToken += _amount; // T = T + amount;
        totalValueLockBUSD += calculateValue(_amount);
        uint256 endTime = stakeFor(_Choise, msg.sender);
        emit Stake(msg.sender, _amount, endTime);
    }

    function unstake(uint32 position)
        external
        isExist(position)
        isDone(position)
        nonReentrant
    {
        uint256 deposited = stakedBalance[msg.sender][position]; // deposited = stake[address];
        stakedBalance[msg.sender][position] = 0; // stake[address] = 0;

        uint8 choise = stakedChoise[msg.sender][position];
        uint256 reward = calculate(deposited, choise);

        if (reward > 0) {
            rewardToken.safeTransfer(msg.sender, reward);
        }
        stakingToken.safeTransfer(msg.sender, deposited);

        StakedRewardFreezed -= reward;
        totalValueLockLPToken -= deposited; // T = T - deposited;
        totalValueLockBUSD -= calculateValue(deposited);

        AllStakedBalance[msg.sender] -= deposited; // stake[address] - deposited ;
        update(position, msg.sender); //update positions

        emit Unstake(msg.sender, deposited, reward);
    }

    function distribute(uint256 _reward) external onlyOwner {
        require(_reward > 0, "Cannot distribute 0");

        rewardToken.safeTransferFrom(msg.sender, address(this), _reward);
        StakedReward += _reward;
        emit Distribute(msg.sender, _reward);
    }

    function witdraw(uint256 rewardTokenAmount) external onlyOwner {
        require(rewardTokenAmount == 0, "0 amount");
        require(
            rewardTokenAmount <= StakedReward,
            "you can witdraw rewardFreezd"
        );
        rewardToken.transfer(msg.sender, rewardTokenAmount);
        StakedReward -= rewardTokenAmount;
        emit Distribute(msg.sender, rewardTokenAmount);
    }

    function rewardOf(address _account, uint32 position)
        public
        view
        returns (uint256)
    {
        uint256 deposited = stakedBalance[_account][position];
        uint8 choice = stakedChoise[_account][position];
        return calculate(deposited, choice);
    }

    function update(uint32 position_, address sender) internal {
        for (uint32 i = position_; i < positions[sender]; i++) {
            stakedChoise[msg.sender][i] = stakedChoise[msg.sender][i + 1];
            stakedBalance[msg.sender][i] = stakedBalance[msg.sender][i + 1];
            luckTime[msg.sender][i] = luckTime[msg.sender][i + 1];
        }
        stakedBalance[msg.sender][uint32(positions[sender])] = 0;
        stakedChoise[msg.sender][uint32(positions[sender])] = 0;
        luckTime[msg.sender][uint32(positions[sender])] = 0;
        positions[sender] -= 1;
    }

    function getAll(address sender_, uint8 position)
        external
        view
        isExist(position)
        returns (
            uint256 deadLine,
            uint256 reward,
            uint256 choise,
            uint256 LPTokenBalnce
        )
    {
        deadLine = luckTime[sender_][position];
        reward = rewardOf(sender_, position);
        choise = stakedChoise[sender_][position];
        LPTokenBalnce = stakedBalance[sender_][position];
    }
}
