**Gm, Godot game developer!**

This repository is a Demo Package of the Solana Godot SDK, which we are working on together with Virus-Axel.
The main repository, containing libs and backend code can be found here: https://github.com/Virus-Axel/godot-solana-sdk 

It is open source, so everyone can help out as we progress.

Test out the latest demo version in your browser: https://zenrepublic.github.io/GodotSolanaSDKDemos/ <br><br>
Read the documentation: https://zenwiki.gitbook.io/solana-godot-sdk-docs/

**Current features:**
- RPC API support, so you can fetch information on accounts, like their SOL balances and much more
- System Program, allowing you to do transactions of SOL to another address
- Token Program, allowing you to mint new SPL tokens and send them to other addresses
- NFT fetching and parsing images/metadata. (GIFs supported soon, we almost have that working)
- Dynamically Loading 3D NFTs as GLBs
- Wallet adapter. Currently supporting Phantom, Solflare and Backpack. Ultimate coming soon
- Candymachine v3 minting (pNFTs and Candy guard groups supported)
- Custom Anchor smart contract support + IDL converter to GDScript

**HOW TO START?** <br><br>
**Step 1.** Download the latest version of Solana SDK addon and import it it to your project. If you already have addons folder, then only import "SolanaSDK" folder into it <br><br>
**Step 2.** Inside Godot engine, go to **Project -> Project Settings -> Plugins** and enable "SolanaSDK" plugin. It should add the autoload scenes, enabling easy access to **SolanaService** class <br><br>
**Step 3.** Find "SolanaService.tscn" in **SolanaSDK -> Autoloads** and open it. This scene has all the settings you can adjust, like setting custom RPC links and your test wallet.
To make the SDK work inside editor, you will need to make sure that in **SolanaService -> WalletService** you have checked "Use Generated". This will generate a new wallet for you to test the game with.
Optionally, you can use your own keypair by creating a .txt with your wallet's private key in it anywhere in your computer and link the path in the "custom pk path" variable.<br><br>
**Step 4.** Inside **SolanaSDK -> Demos** there is "LoginScene.tscn". Launch it and check different demos we have prepared for you to learn the most crucial features the SDK provides <br><br>

Godot 4.1+ needed to run the project. Windows, Mac and Linux supported.

If you are interested in using Solana Godot SDK for your game and you need some help, drop by to our Discord server: https://discord.gg/CBydsCq4mE

