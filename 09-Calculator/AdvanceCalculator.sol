// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

contract AdvanceCalculator {


    function pow(uint256 a, uint256 b) external  pure returns(uint256) {
        require(b >= 0, "b should be a positive integer");
        if (b==0) {
            return 1;
        }

        uint256 ans = 1;

        while (b > 0) {
            if (b & 1 == 1) {
                ans *= a;
            }
            a *= a;
            b >>= 1;
        }

        return ans;
    }

    function sqrt(uint256 a) external pure returns(uint256) {
        require(a >=0, "a should be a positive integer");
        uint256 l = 1;
        uint256 h = a;
        
        uint256 ans = 1;
        while (l < h) {
            uint256 mid = (h+l) / 2;
            if ((mid*mid) <= a ) {
                ans = mid; 
                l = mid + 1;
            } else {
                h = mid - 1;
            }
        }
        return ans;
    }

    struct Complex {
        int256 a;
        int256 b;
    }

    function addComplex(Complex calldata c1, Complex calldata c2) external pure returns (Complex memory c) {
        Complex memory newComplex = Complex(c1.a+c2.a, c1.b+c2.b);
        return newComplex;
    }

    function subComplex(Complex calldata c1, Complex calldata c2) external pure returns (Complex memory c) {
        Complex memory newComplex = Complex(c1.a-c2.a, c1.b-c2.b);
        return newComplex;
    }
}