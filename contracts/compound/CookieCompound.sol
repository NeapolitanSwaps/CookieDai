pragma solidity ^0.5.2;

import "./Helpers.sol";

contract CookieCompound is Helpers {

    event LogMint(address erc20, address cErc20, uint tokenAmt, address owner);
    event LogRedeem(address erc20, address cErc20, uint tokenAmt, address owner);
    event LogBorrow(address erc20, address cErc20, uint tokenAmt, address owner);
    event LogRepay(address erc20, address cErc20, uint tokenAmt, address owner);

/**
     * @dev Deposit ETH/ERC20 and mint Compound Tokens
     */
    function mintCToken(address erc20, address cErc20, uint tokenAmt) external payable {
        enterMarket(cErc20);
        if (erc20 == getAddressETH()) {
            CETHInterface cToken = CETHInterface(cErc20);
            cToken.mint.value(msg.value)();
        } else {
            ERC20Interface token = ERC20Interface(erc20);
            uint toDeposit = token.balanceOf(msg.sender);
            if (toDeposit > tokenAmt) {
                toDeposit = tokenAmt;
            }
            token.transferFrom(msg.sender, address(this), toDeposit);
            CERC20Interface cToken = CERC20Interface(cErc20);
            setApproval(erc20, toDeposit, cErc20);
            assert(cToken.mint(toDeposit) == 0);
        }
        emit LogMint(
            erc20,
            cErc20,
            tokenAmt,
            msg.sender
        );
    }

    /**
     * @dev Redeem ETH/ERC20 and burn Compound Tokens
     * @param cTokenAmt Amount of CToken To burn
     */
    function redeemCToken(address erc20, address cErc20, uint cTokenAmt) external {
        CTokenInterface cToken = CTokenInterface(cErc20);
        uint toBurn = cToken.balanceOf(address(this));
        if (toBurn > cTokenAmt) {
            toBurn = cTokenAmt;
        }
        setApproval(cErc20, toBurn, cErc20);
        require(cToken.redeem(toBurn) == 0, "something went wrong");
        transferToken(erc20);
        uint tokenReturned = wmul(toBurn, cToken.exchangeRateCurrent());
        emit LogRedeem(
            erc20,
            cErc20,
            tokenReturned,
            address(this)
        );
    }

    /**
     * @dev Redeem ETH/ERC20 and mint Compound Tokens
     * @param tokenAmt Amount of token To Redeem
     */
    function redeemUnderlying(address erc20, address cErc20, uint tokenAmt) external {
        CTokenInterface cToken = CTokenInterface(cErc20);
        setApproval(cErc20, 10**50, cErc20);
        uint toBurn = cToken.balanceOf(address(this));
        uint tokenToReturn = wmul(toBurn, cToken.exchangeRateCurrent());
        if (tokenToReturn > tokenAmt) {
            tokenToReturn = tokenAmt;
        }
        require(cToken.redeemUnderlying(tokenToReturn) == 0, "something went wrong");
        transferToken(erc20);
        emit LogRedeem(
            erc20,
            cErc20,
            tokenToReturn,
            address(this)
        );
    }

    /**
     * @dev borrow ETH/ERC20
     */
    function borrow(address erc20, address cErc20, uint tokenAmt) external {
        enterMarket(cErc20);
        require(CTokenInterface(cErc20).borrow(tokenAmt) == 0, "got collateral?");
        transferToken(erc20);
        emit LogBorrow(
            erc20,
            cErc20,
            tokenAmt,
            address(this)
        );
    }

    /**
     * @dev Pay Debt ETH/ERC20
     */
    function repayToken(address erc20, address cErc20, uint tokenAmt) external payable {
        if (erc20 == getAddressETH()) {
            CETHInterface cToken = CETHInterface(cErc20);
            uint toRepay = msg.value;
            uint borrows = cToken.borrowBalanceCurrent(address(this));
            if (toRepay > borrows) {
                toRepay = borrows;
                msg.sender.transfer(msg.value - toRepay);
            }
            cToken.repayBorrow.value(toRepay)();
            emit LogRepay(
                erc20,
                cErc20,
                toRepay,
                address(this)
            );
        } else {
            CERC20Interface cToken = CERC20Interface(cErc20);
            ERC20Interface token = ERC20Interface(erc20);
            uint toRepay = token.balanceOf(msg.sender);
            uint borrows = cToken.borrowBalanceCurrent(address(this));
            if (toRepay > tokenAmt) {
                toRepay = tokenAmt;
            }
            if (toRepay > borrows) {
                toRepay = borrows;
            }
            setApproval(erc20, toRepay, cErc20);
            token.transferFrom(msg.sender, address(this), toRepay);
            require(cToken.repayBorrow(toRepay) == 0, "transfer approved?");
            emit LogRepay(
                erc20,
                cErc20,
                toRepay,
                address(this)
            );
        }
    }

    /**
     * @dev Pay Debt for someone else
     */
    function repaytokenBehalf(
        address borrower,
        address erc20,
        address cErc20,
        uint tokenAmt
    ) external payable
    {
        if (erc20 == getAddressETH()) {
            CETHInterface cToken = CETHInterface(cErc20);
            uint toRepay = msg.value;
            uint borrows = cToken.borrowBalanceCurrent(address(this));
            if (toRepay > borrows) {
                toRepay = borrows;
                msg.sender.transfer(msg.value - toRepay);
            }
            cToken.repayBorrowBehalf.value(toRepay)(borrower);
            emit LogRepay(
                erc20,
                cErc20,
                toRepay,
                address(this)
            );
        } else {
            CERC20Interface cToken = CERC20Interface(cErc20);
            ERC20Interface token = ERC20Interface(erc20);
            uint toRepay = token.balanceOf(msg.sender);
            uint borrows = cToken.borrowBalanceCurrent(address(this));
            if (toRepay > tokenAmt) {
                toRepay = tokenAmt;
            }
            if (toRepay > borrows) {
                toRepay = borrows;
            }
            setApproval(erc20, toRepay, cErc20);
            token.transferFrom(msg.sender, address(this), toRepay);
            require(cToken.repayBorrowBehalf(borrower, tokenAmt) == 0, "transfer approved?");
            emit LogRepay(
                erc20,
                cErc20,
                toRepay,
                address(this)
            );
        }
    }

}