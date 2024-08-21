// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

// import {LinkToken} from "../test/mocks/LinkToken.sol";
import {Script, console2} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import { LinkToken } from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;

    address public FOUNDRY_DEFAULT_SENDER =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__InvalidChainId();
     struct NetworkConfig {
        uint256 subscriptionId;
        bytes32 gasLane;
        uint256 automationUpdateInterval;
        uint256 raffleEntranceFee;
        uint32 callbackGasLimit;
        address vrfCoordinatorV2_5;
        address link;
        address account;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        // networkConfigs[ETH_MAINNET_CHAIN_ID] = getMainnetEthConfig();
        // Note: We skip doing the local config
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinatorV2_5 != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaEthConfig()
        public
        pure
        returns (NetworkConfig memory sepoliaNetworkConfig)
    {
        sepoliaNetworkConfig = NetworkConfig({
            subscriptionId: 106539989387452818213374511335114411410082422318584178264203768254420886629048, // If left as 0, our scripts will create one!
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            automationUpdateInterval: 30, // 30 seconds
            raffleEntranceFee: 0.01 ether,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0xC83BF0315121E03544Fc71589EfA2BAc1334A6d1
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
    if (localNetworkConfig.vrfCoordinatorV2_5 != address(0)) {
        console2.log("Local config already set, returning existing config.");
        return localNetworkConfig;
    }
    // deploy mocks
    vm.startBroadcast();
    VRFCoordinatorV2_5Mock vrfCoordinatorMock = 
        new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, 
        MOCK_WEI_PER_UINT_LINK); 
        LinkToken linkToken = new LinkToken();

    vm.stopBroadcast();

    localNetworkConfig = NetworkConfig({
        subscriptionId: 0, // If left as 0, our scripts will create one!
        gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
        automationUpdateInterval: 30, // 30 seconds
        raffleEntranceFee: 0.01 ether,
        callbackGasLimit: 500000, // 500,000 gas
        vrfCoordinatorV2_5: address(vrfCoordinatorMock),
        link: address(linkToken),
        account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
    });

    console2.log("Local config created:");
    console2.log("vrfCoordinatorV2_5:", address(vrfCoordinatorMock));

    return localNetworkConfig;
}

}
