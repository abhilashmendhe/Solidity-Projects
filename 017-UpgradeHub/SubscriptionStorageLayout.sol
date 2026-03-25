// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

/*
    Build an upgradeable subscription manager for a SaaS-like dApp. The proxy contract stores user subscription 
    info (like plans, renewals, and expiry dates), while the logic for managing subscriptions—adding plans, upgrading users, 
    pausing accounts—lives in an external logic contract. When it's time to add new features or fix bugs, you simply 
    deploy a new logic contract and point the proxy to it using `delegatecall`, without migrating any data. This simulates how 
    real-world apps push updates without asking users to reinstall. You'll learn how to architect upgrade-safe contracts using the 
    proxy pattern and `delegatecall`, separating storage from logic for long-term maintainability.

        -------------------------------------------------

    When we say **upgradeable contracts**, we’re talking about separating **storage** from **logic**.

    The idea is:
    - You deploy one contract that stores the **data** — we’ll call it the **proxy**.
    - You deploy another contract that holds the **logic** — this is the actual code.
    - The proxy uses `delegatecall` to execute logic from the external contract — but on **its own storage**.

    So if you ever need to change behavior, you don’t touch the proxy — you just point it to a new logic contract. All the data stays safe.
*/

contract SubscriptionStorageLayout {


}