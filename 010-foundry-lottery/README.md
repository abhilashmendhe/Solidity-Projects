# Random raffle contracts
## What are we doing?

1. Users can enter by paying for a ticket
    1. All the ticket fees goes to the winner after the lottery has be drawn.
2. After X period of time, our contract will automatically draw a winner
    1. This will be done programatically
    2. Using Chainlink VRF & Chainlink Automation
        1. Chainlink VRF -> Randomness
        2. Chainlink Automation -> Time based triggers

## Tests! 

1. Write deploy scripts
2. Write tests
    1. Local chain
    2. Forked testnet
    3. Forked mainnet