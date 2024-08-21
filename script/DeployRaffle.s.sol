// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Script, console2 } from "forge-std/Script.sol";
import { Raffle } from "src/Raffle.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { AddConsumer, CreateSubscription, FundSubscription } from "./interaction.s.sol";

contract DeployRaffle is Script {

    function run() public {}

    function Deployraffle() public returns(Raffle, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinatorV2_5) =
                createSubscription.createSubscription(config.vrfCoordinatorV2_5, config.account);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinatorV2_5, config.subscriptionId, config.link, config.account
            );
        }

        vm.startBroadcast(config.account); // Start broadcasting the transactions
        Raffle raffle = new Raffle(
            config.subscriptionId,
            config.gasLane,
            config.automationUpdateInterval,
            config.raffleEntranceFee,
            config.callbackGasLimit,
            config.vrfCoordinatorV2_5
        );

        console2.log("Deployed Raffle contract at:", address(raffle));
        vm.stopBroadcast(); // Stop broadcasting the transactions
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoordinatorV2_5, config.subscriptionId, config.account);

        return (raffle, helperConfig);

    }

}