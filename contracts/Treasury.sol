// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProtocolInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Treasury is Ownable {
    mapping(address => uint256) public balances;
    mapping(address => ProtocolInterface) public protocols;
    mapping(address => uint256) public distributionRatios;
    address[] private protocolAddresses;
    IUniswapV2Router02 public uniswapRouter;

    event Deposit(address indexed token, uint256 amount);
    event Withdraw(address indexed protocol, uint256 amount);
    event FundDistributed(address indexed protocol, uint256 amount);
    event ProtocolRegistered(address indexed protocol);

    constructor(address _uniswapRouter) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    function deposit(address token, uint256 amount) public {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        balances[token] += amount;
        emit Deposit(token, amount);
    }

    function registerProtocol(address protocol, ProtocolInterface protocolInterface) public onlyOwner {
        protocols[protocol] = protocolInterface;
        protocolAddresses.push(protocol);
        emit ProtocolRegistered(protocol);
    }

    function setDistributionRatio(address protocol, uint256 ratio) public onlyOwner {
        distributionRatios[protocol] = ratio;
    }

    function distribute(address token) public onlyOwner {
        uint256 totalAmount = balances[token];
        require(totalAmount > 0, "Insufficient balance");

        for (uint i = 0; i < protocolAddresses.length; i++) {
            ProtocolInterface protocol = protocols[protocolAddresses[i]];
            uint256 amount = totalAmount * distributionRatios[protocolAddresses[i]] / 100;
            require(IERC20(token).approve(protocolAddresses[i], amount), "Approval failed");
            protocol.deposit(token, amount);
            balances[token] -= amount;
            emit FundDistributed(protocolAddresses[i], amount);
        }
    }

    function withdraw(address protocol, uint256 amount) public onlyOwner {
        ProtocolInterface protocolContract = protocols[protocol];
        protocolContract.withdraw(amount);
        balances[protocol] += amount;
        emit Withdraw(protocol, amount);
    }

    function calculateYield() public view returns (uint256) {
        uint256 totalYield = 0;
        uint256 totalAmount = 0;
        for (uint i = 0; i < protocolAddresses.length; i++) {
            ProtocolInterface protocol = protocols[protocolAddresses[i]];
            uint256 yield = protocol.calculateYield(); // This should return the APY as a fixed-point number
            uint256 amount = balances[protocolAddresses[i]];
            totalYield += yield * amount;
            totalAmount += amount;
        }
        return totalAmount > 0 ? totalYield / totalAmount : 0; // Calculate the weighted average yield
    }


    function getProtocolAddresses() public view returns (address[] memory) {
        return protocolAddresses;
    }

    function swapTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external onlyOwner {
        IERC20(tokenIn).approve(address(uniswapRouter), amountIn);
        uniswapRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }
}
