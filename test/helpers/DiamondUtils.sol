// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

abstract contract DiamondUtils is Test {
    function generateSelectors(
        string memory _facetName
    ) internal returns (bytes4[] memory selectors) {
        //get string of contract methods
        string[] memory cmd = new string[](4);
        cmd[0] = "forge";
        cmd[1] = "inspect";
        cmd[2] = _facetName;
        cmd[3] = "methods";
        bytes memory res = vm.ffi(cmd);
        string memory st = string(res);

        // Count the number of selectors by counting colons
        uint256 selectorCount = 0;
        bytes memory stBytes = bytes(st);
        for (uint256 i = 0; i < stBytes.length; i++) {
            if (stBytes[i] == ":") {
                selectorCount++;
            }
        }

        selectors = new bytes4[](selectorCount);
        uint256 currentIndex = 0;

        // Parse the string to extract function signatures
        bytes memory stBytes2 = bytes(st);
        uint256 start = 0;
        uint256 end = 0;
        bool inQuotes = false;

        for (uint256 i = 0; i < stBytes2.length; i++) {
            if (stBytes2[i] == '"') {
                inQuotes = !inQuotes;
                if (!inQuotes) {
                    end = i;
                    if (start > 0) {
                        string memory method = substring(st, start + 1, end);
                        if (bytes(method).length > 0) {
                            selectors[currentIndex++] = bytes4(keccak256(bytes(method)));
                        }
                    }
                } else {
                    start = i;
                }
            }
        }

        return selectors;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}
