// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage} from "../libraries/AppStorage.sol";

contract ERC20Facet {
    AppStorage internal s;
    
    function initialize(string memory _name, string memory _symbol, uint8 _decimals) external {
        s.name = _name;
        s.symbol = _symbol;
        s.decimals = _decimals;
    }
    
    function name() external view returns (string memory) {
        return s.name;
    }
    
    function symbol() external view returns (string memory) {
        return s.symbol;
    }
    
    function decimals() external view returns (uint8) {
        return s.decimals;
    }
    
    function totalSupply() external view returns (uint256) {
        return s.totalSupply;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return s.balances[account];
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }
    
    function allowance(address owner, address spender) external view returns (uint256) {
        return s.allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        
        uint256 fromBalance = s.balances[from];
        require(fromBalance >= amount, "Insufficient balance");
        
        s.balances[from] = fromBalance - amount;
        s.balances[to] += amount;
        
        emit Transfer(from, to, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");
        
        s.allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = s.allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Insufficient allowance");
            s.allowances[owner][spender] = currentAllowance - amount;
        }
    }
} 