// contracts/ProtocolInterface.sol
pragma solidity ^0.8.0;

interface ProtocolInterface {
    function deposit(address token, uint256 amount) external returns (bool);
    function withdraw(uint256 amount) external returns (bool);
    function calculateYield() external view returns (uint256);
}
