// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

import "./ERC721A.sol";
import "./IERC721A.sol";
import "./Base64.sol";
import "./Ownable.sol";
import "./AnonymiceLibrary.sol";
import "./Utility.sol";

contract CitizensOfOverworld is ERC721A, Ownable {
    /*

    *******************************************************************************************************************
    *                                                                                                                 *
    *   ______   __    __      __                                                           ______                    *
    *  /      \ |  \  |  \    |  \                                                         /      \                   *
    * |  000000\ \00 _| 00_    \00 ________   ______   _______    _______         ______  |  000000\                  *
    * | 00   \00|  \|   00 \  |  \|        \ /      \ |       \  /       \       /      \ | 00_  \00                  *
    * | 00      | 00 \000000  | 00 \00000000|  000000\| 0000000\|  0000000      |  000000\| 00 \                      *
    * | 00   __ | 00  | 00 __ | 00  /    00 | 00    00| 00  | 00 \00    \       | 00  | 00| 0000                      *
    * | 00__/  \| 00  | 00|  \| 00 /  0000_ | 00000000| 00  | 00 _\000000\      | 00__/ 00| 00                        *
    *  \00    00| 00   \00  00| 00|  00    \ \00     \| 00  | 00|       00       \00    00| 00                        *
    *   \000000  \00    \0000  \00 \00000000  \0000000 \00   \00 \0000000         \000000  \00                        *
    *                                                                                                                 *
    *   ______                                                                    __        __         0000000000     *
    *  /      \                                                                  |  \      |  \      00000000000000   *
    * |  000000\ __     __   ______    ______   __   __   __   ______    ______  | 00  ____| 00      00000000000000   *
    * | 00  | 00|  \   /  \ /      \  /      \ |  \ |  \ |  \ /      \  /      \ | 00 /      00      00000000000000   *   
    * | 00  | 00 \00\ /  00|  000000\|  000000\| 00 | 00 | 00|  000000\|  000000\| 00|  0000000        0000000000     *
    * | 00  | 00  \00\  00 | 00    00| 00   \00| 00 | 00 | 00| 00  | 00| 00   \00| 00| 00  | 00       000000000000    *
    * | 00__/ 00   \00 00  | 00000000| 00      | 00_/ 00_/ 00| 00__/ 00| 00      | 00| 00__| 00      01000000000010   *
    *  \00    00    \000    \00     \| 00       \00   00   00 \00    00| 00      | 00 \00    00      01000000000010   *  
    *   \000000      \0      \0000000 \00        \00000\0000   \000000  \00       \00  \0000000        0000  0000     *   
    *                                                                                                                 *
    *                                                                                                                 *
    *  on-chain, animated digital collectibles                                                                        *
    *                                                                                                                 *
    *                                                                                                                 *
    *   created by @0xMongoon ( ＾◡＾)っ ♡                                                                             *                                               
    *                                                                                                                 *
    *   with inspiration from all the devs & collections living on-chain                                              *
    *******************************************************************************************************************
                                                                                            



     __     __                     __            __        __                     
    |  \   |  \                   |  \          |  \      |  \                    
    | 00   | 00 ______    ______   \00  ______  | 00____  | 00  ______    _______ 
    | 00   | 00|      \  /      \ |  \ |      \ | 00    \ | 00 /      \  /       \
     \00\ /  00 \000000\|  000000\| 00  \000000\| 0000000\| 00|  000000\|  0000000
      \00\  00 /      00| 00   \00| 00 /      00| 00  | 00| 00| 00    00 \00    \ 
       \00 00 |  0000000| 00      | 00|  0000000| 00__/ 00| 00| 00000000 _\000000\
        \000   \00    00| 00      | 00 \00    00| 00    00| 00 \00     \|       00
         \0     \0000000 \00       \00  \0000000 \0000000  \00  \0000000 \0000000 
    */

    //  **********  //
    //  * ERC721 *  //
    //  **********  //

    // ERC721A values.
    uint256 public constant MAX_SUPPLY = 11111;
    uint256 public constant MAX_PER_TXN = 4;
    uint256 public constant PRICE_AFTER_FIRST_MINT = 0.005 ether;

    //  ******************************  //
    //  * Mint Tracking & Regulation *  //
    //  ******************************  //

    // used to start/pause mint
    bool public mintLive = false;

    // tracks if an address has already minted a Citizen or not
    mapping(address => bool) public hasMinted;

    // tracks how many Citizens the owner has minted
    uint256 public tokensMintedByOwner = 0;

    // used to prevent flashbots from reverting their mint after seeing traits they got (courtesy Circolors)
    mapping(address => uint256) private lastWrite;

    // hashing stuff
    uint256 private seed_nonce;

    //  ***********  //
    //  * Utility *  //
    //  ***********  //    

    // Used for converting small uints to strings with low gas
    string[33] private lookup;

    //  ************************************  //
    //  * STORAGE OF COMPRESSED IMAGE DATA *  //
    //  ************************************  //

    // Used to store the compressed trait images as bytes.
    bytes[][] private compressedTraitImages;

    // Used to store the compressed trait metadata as bytes32.
    bytes32[][] private compressedTraitMetadata;

    string[] private backgrounds;

    // Used to store the animation and gradient data for each legendary trait as a string.
    string[] private legendaryAnimations;

    // Used to store the pixels for each legendary trait as a string.
    string private legendaryPixels;

    // Used to store all possible colors as a single bytes object.
    bytes private hexColorPalette;

    // Once the owner loads the data, this is set to true, and the data is locked.
    bool public compressedDataLoaded;

    //  **************************************  //
    //  * STORAGE OF DECOMPRESSED IMAGE DATA *  //
    //  **************************************  //

    // Used to store the bounds within the SVG coordinate system for each trait.
    struct Bounds {
        uint8 minX;
        uint8 maxX;
        uint8 minY;
        uint8 maxY;
    }

    // Used to store the color and length of each pixel of a trait.
    struct Pixel {
        uint8 length;
        uint8 colorIndex;
    }

    // Used to store the decompressed trait image.
    struct DecompressedTraitImage {
        Bounds bounds;
        Pixel[] draws;
    }

    //  ***************************  //
    //  * RENDERING OF IMAGE DATA *  //
    //  ***************************  //

    // Constant values that will be used to build the SVG.
    // Some are only used if the Citizen has a 'rainbow' trait or is legendary.
    string private constant _SVG_PRE_STYLE_ATTRIBUTE =
        '<svg xmlns="http://www.w3.org/2000/svg" id="citizen" viewBox="-4.5 -5 42 42" width="640" height="640" style="';
    string private constant _SVG_DEF_TAGS =
        ' shape-rendering: crispedges; image-rendering: -moz-crisp-edges; background-repeat: no-repeat;"><defs><radialGradient id="i"><stop offset="0%" style="stop-color:#000000;stop-opacity:.9"/><stop offset="100%" style="stop-opacity:0"/></radialGradient>';
    string private constant _SVG_RAINBOW_ANIMATION_DEF_IF_RAINBOW =
        '<animate xmlns="http://www.w3.org/2000/svg" href="#r" attributeName="fill" values="red;orange;yellow;green;blue;violet;red;" dur="1s" repeatCount="indefinite"/>';
    string private constant _SVG_CLIP_DEF_IF_LEGENDARY =
        '<clipPath id="c"><rect x="11" y="13" width="11" height="16"/><rect x="10" y="15" width="1" height="14"/><rect x="22" y="15" width="1" height="14"/><rect x="12" y="29" width="4" height="4"/><rect x="17" y="29" width="4" height="4"/><rect x="16" y="29" width="1" height="1"/></clipPath>';
    string private constant _SVG_TAG_PRE_ANIMATION_ID_REF =
        '</defs><ellipse cx="16.5" cy="33" rx="6" ry="2" fill="url(#i)"><animate attributeType="XML" attributeName="rx" dur="1.3s" values="9;7;9" repeatCount="indefinite" calcMode="spline" keyTimes="0; 0.5; 1" keySplines="0.5 0 0.5 1; 0.5 0 0.5 1"/></ellipse><g fill="url(#';
    string private constant _SVG_FINAL_START_TAG =
        ')" clip-path="url(#c)" id="r"><animateTransform attributeType="XML" attributeName="transform" type="translate" values="0,.5;0,-.5;0,.5" repeatCount="indefinite" dur="1.3s" calcMode="spline" keyTimes="0; 0.5; 1" keySplines="0.5 0 0.5 1; 0.5 0 0.5 1"/>';
    string private constant _SVG_END_TAG = "</g></svg>";

    // Used to store the DNA for each Citizen. This DNA is used to determine the traits of each Citizen upon rendering via tokenURI().
    struct DNA {
        uint256 Legendary;
        uint256 Body;
        uint256 Pants;
        uint256 Shirt;
        uint256 Eyes;
        uint256 Hat;
        uint256 Accessory;
        uint256 Mouth;
        uint256 Background;
    }

    // Contains the DNA for every Citizen, keyed by tokenId.
    mapping(uint256 => uint256) public tokenIdToSeed;    

    /*
     ________                                 __      __                               
    |        \                               |  \    |  \                              
    | 00000000__    __  _______    _______  _| 00_    \00  ______   _______    _______ 
    | 00__   |  \  |  \|       \  /       \|   00 \  |  \ /      \ |       \  /       \
    | 00  \  | 00  | 00| 0000000\|  0000000 \000000  | 00|  000000\| 0000000\|  0000000
    | 00000  | 00  | 00| 00  | 00| 00        | 00 __ | 00| 00  | 00| 00  | 00 \00    \ 
    | 00     | 00__/ 00| 00  | 00| 00_____   | 00|  \| 00| 00__/ 00| 00  | 00 _\000000\
    | 00      \00    00| 00  | 00 \00     \   \00  00| 00 \00    00| 00  | 00|       00
     \00       \000000  \00   \00  \0000000    \0000  \00  \000000  \00   \00 \0000000 
    
    */

    constructor() ERC721A("Citizens of Overworld Redux", "OVRWRLD") {}

    //  ***********************************  //
    //  * FLASHBOT MINT REVERT PREVENTION *  //
    //  ***********************************  //

    // Prevents someone calling read functions the same block they mint (courtesy of Circolors)
    modifier disallowIfStateIsChanging() {
        require(
            owner() == msg.sender || lastWrite[msg.sender] < block.number,
            "pwnd"
        );
        _;
    }

    //  *****************  //
    //  * CUSTOM ERRORS *  //
    //  ********/********  //

    error MaxPerTxn();
    error SoldOut();

    /*

    __       __  __             __     
   |  \     /  \|  \           |  \                             _   _
   | 00\   /  00 \00 _______  _| 00_                           ((\o/))
   | 000\ /  000|  \|       \|   00 \                     .-----//^\\-----.
   | 0000\  0000| 00| 0000000\\000000                     |    /`| |`\    |
   | 00\00 00 00| 00| 00  | 00 | 00 __                    |      | |      |
   | 00 \000| 00| 00| 00  | 00 | 00|  \                   |      | |      |
   | 00  \0 | 00| 00| 00  | 00  \00  00                   |      | |      |
    \00      \00 \00 \00   \00   \0000       ༼ つ ◕_◕ ༽つ  '------===------'

    */

    function mint(uint256 quantity) external payable {
        require(mintLive, "!MintLive");
        uint256 totalminted = _totalMinted();
        uint256 newSupply = totalminted + quantity;
        require(balanceOf(msg.sender) + quantity < 5, "MaxPerWallet");
        if (newSupply + (30-tokensMintedByOwner) > MAX_SUPPLY) revert SoldOut();
        if (quantity > MAX_PER_TXN) revert MaxPerTxn();
        uint256 totalFee;
        totalFee = (quantity - (hasMinted[msg.sender]?0:1)) * PRICE_AFTER_FIRST_MINT;
        require(msg.value == totalFee, "BadPrice");
        hasMinted[msg.sender] = true;
        lastWrite[msg.sender] = block.number;
        _safeMint(msg.sender, quantity);
        for (; totalminted < newSupply; ++totalminted) {
            uint256 seed = generateSeed(totalminted);
            tokenIdToSeed[totalminted] = seed;
            unchecked {
              seed_nonce += seed;
            }
        }
    }

    /*
       ______   __    __      __                                            
      /      \ |  \  |  \    |  \                                                                       (=(   )=)
     |  000000\ \00 _| 00_    \00 ________   ______   _______                                            `.\ /,'
     | 00   \00|  \|   00 \  |  \|        \ /      \ |       \                                             `\.
     | 00      | 00 \000000  | 00 \00000000|  000000\| 0000000\                                          ,'/ \`.
     | 00   __ | 00  | 00 __ | 00  /    00 | 00    00| 00  | 00                                         (=(   )=)
     | 00__/  \| 00  | 00|  \| 00 /  0000_ | 00000000| 00  | 00                                          `.\ /,'
      \00    00| 00   \00  00| 00|  00    \ \00     \| 00  | 00                                            ,/'
       \000000  \00    \0000  \00 \00000000  \0000000 \00   \00                                          ,'/ \`.
       ______                                                     __      __                            (=(   )=)
      /      \                                                   |  \    |  \                            `.\ /,'
     |  000000\  ______   _______    ______    ______   ______  _| 00_    \00  ______   _______            `\.
     | 00 __\00 /      \ |       \  /      \  /      \ |      \|   00 \  |  \ /      \ |       \         ,'/ \`.
     | 00|    \|  000000\| 0000000\|  000000\|  000000\ \000000\\000000  | 00|  000000\| 0000000\       (=(   )=)
     | 00 \0000| 00    00| 00  | 00| 00    00| 00   \00/      00 | 00 __ | 00| 00  | 00| 00  | 00        `.\ /,'
     | 00__| 00| 00000000| 00  | 00| 00000000| 00     |  0000000 | 00|  \| 00| 00__/ 00| 00  | 00          ,/'
      \00    00 \00     \| 00  | 00 \00     \| 00      \00    00  \00  00| 00 \00    00| 00  | 00        ,'/ \`.
       \000000   \0000000 \00   \00  \0000000 \00       \0000000   \0000  \00  \000000  \00   \00       (=(   )=)
    */

    /**
     * Creates DNA object for Overworld's newest Citizen via pseudorandom trait generation.
     */
    function generateSeed(uint256 tokenId) private view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    tokenId,
                    msg.sender,
                    block.timestamp,
                    block.difficulty,
                    seed_nonce
                )
            )
        );
    }

    /*
                                                                                                                              ▒▒
                                                                                                                            ▒▒░░▒▒
     ______   __    __      __                                                                                            ▒▒░░░░░░▒▒ 
    /      \ |  \  |  \    |  \                                                                                         ▒▒░░░░░░░░░░▒▒
   |  000000\ \00 _| 00_    \00 ________   ______   _______                                                           ▒▒░░░░░░░░░░░░░░▒▒
   | 00   \00|  \|   00 \  |  \|        \ /      \ |       \                                                        ▒▒░░▒▒░░░░░░░░░░░░░░▒▒ 
   | 00      | 00 \000000  | 00 \00000000|  000000\| 0000000\                                                     ░░  ▒▒░░▒▒░░░░░░░░░░░░░░▒▒
   | 00   __ | 00  | 00 __ | 00  /    00 | 00    00| 00  | 00                                                   ░░  ██  ▒▒░░▒▒░░░░░░░░░░▒▒  
   | 00__/  \| 00  | 00|  \| 00 /  0000_ | 00000000| 00  | 00                                                 ░░  ██      ▒▒░░▒▒░░░░░░▒▒    
    \00    00| 00   \00  00| 00|  00    \ \00     \| 00  | 00                                               ░░  ██      ██  ▒▒░░▒▒░░▒▒  
     \000000  \00    \0000  \00 \00000000  \0000000 \00   \00                                             ░░  ██      ██      ▒▒░░▒▒   
                                                                                                        ░░  ██      ██      ██  ▒▒    
    _______                             __                      __                                    ░░  ██      ██      ██  ░░        
   |       \                           |  \                    |  \                                 ░░  ██      ██      ██  ░░    
   | 0000000\  ______   _______    ____| 00  ______    ______   \00 _______    ______               ▒▒██      ██      ██  ░░  
   | 00__| 00 /      \ |       \  /      00 /      \  /      \ |  \|       \  /      \            ▒▒░░▒▒    ██      ██  ░░ 
   | 00    00|  000000\| 0000000\|  0000000|  000000\|  000000\| 00| 0000000\|  000000\           ▒▒░░░░▒▒██      ██  ░░    
   | 0000000\| 00    00| 00  | 00| 00  | 00| 00    00| 00   \00| 00| 00  | 00| 00  | 00         ▒▒░░░░░░░░▒▒    ██  ░░    
   | 00  | 00| 00000000| 00  | 00| 00__| 00| 00000000| 00      | 00| 00  | 00| 00__| 00         ▒▒░░░░░░░░░░▒▒██  ░░    
   | 00  | 00 \00     \| 00  | 00 \00    00 \00     \| 00      | 00| 00  | 00 \00    00       ▒▒░░░░░░░░░░░░░░▒▒░░        
    \00   \00  \0000000 \00   \00  \0000000  \0000000 \00       \00 \00   \00 _\0000000       ▒▒░░░░░░░░░░▒▒▒▒          
                                                                             |  \__| 00       ████░░░░▒▒▒▒              
                                                                              \00    00     ██████▒▒▒▒     
                                                                              \000000       ████                                  
    */

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        disallowIfStateIsChanging
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name": "Citizen ',
                            _toString(tokenId),
                            '", "image": "data:image/svg+xml;base64,',
                            Base64.encode(bytes(tokenIdToSVG(tokenId))),
                            '","attributes":',
                            tokenIdToMetadata(tokenId),
                            "}"
                        )
                    )
                )
            );
    }

    function getDNA(uint256 seed) public view disallowIfStateIsChanging returns (DNA memory) {
        uint256 extractedRandomNum;
        int256 rand;
        uint256 mask = 0xFFFF;

        uint256 traitLegendary;
        uint256 traitBody;
        uint256 traitPants;
        uint256 traitShirt;
        uint256 traitEyes;
        uint256 traitHat;
        uint256 traitAccessory;
        uint256 traitMouth;
        uint256 traitBackground;

        // Calculate Legendary trait based on seed
        uint256[9] memory legendaryRarity = [
            uint256(9944),
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7
        ];

        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 10000);
        for (uint256 i; i < 9; ++i) {
            if (rand - int256(legendaryRarity[i]) < 0) {
                traitLegendary = i;
                break;
            }
            rand -= int256(legendaryRarity[i]);
        }

        // Calculate Body trait based on seed
        uint256[9] memory bodyRarity = [
            uint256(25),
            25,
            25,
            25,
            25,
            25,
            24,
            24,
            1
        ];

        seed >>= 4;
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 200);
        for (uint256 i; i < 9; ++i) {
            if (rand - int256(bodyRarity[i]) < 0) {
                traitBody = i;
                break;
            }
            rand -= int256(bodyRarity[i]);
        }

        // Calculate Pants trait based on seed
        uint256[16] memory pantsRarity = [
            uint256(18),
            16,
            4,
            16,
            16,
            17,
            15,
            10,
            14,
            4,
            14,
            14,
            15,
            16,
            8,
            2
        ];

        seed >>= 1;
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 200);
        for (uint256 i; i < 16; ++i) {
            if (rand - int256(pantsRarity[i]) < 0) {
                traitPants = i;
                break;
            }
            rand -= int256(pantsRarity[i]);
        }

        // Calculate Shirt trait based on seed
        uint256[21] memory shirtRarity = [
            uint256(19),
            19,
            19,
            19,
            19,
            19,
            17,
            15,
            6,
            6,
            6,
            6,
            6,
            6,
            6,
            2,
            2,
            2,
            2,
            6,
            2
        ];

        seed >>= 1;
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 200);
        for (uint256 i; i < 21; ++i) {
            if (rand - int256(shirtRarity[i]) < 0) {
                traitShirt = i;
                break;
            }
            rand -= int256(shirtRarity[i]);
        }

        // Calculate Eyes trait based on seed
        uint256[24] memory eyesRarity = [
            uint256(10),
            5,
            10,
            10,
            10,
            5,
            1,
            4,
            25,
            1,
            25,
            4,
            4,
            2,
            2,
            2,
            2,
            22,
            10,
            10,
            16,
            3,
            15,
            2
        ];

        seed >>= 4;
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 200);
        for (uint256 i; i < 24; ++i) {
            if (rand - int256(eyesRarity[i]) < 0) {
                traitEyes = i;
                break;
            }
            rand -= int256(eyesRarity[i]);
        }

        // Calculate Hat trait based on seed
        uint256[33] memory hatRarity = [
            uint256(2),
            12,
            12,
            12,
            4,
            5,
            4,
            12,
            12,
            12,
            4,
            12,
            1,
            4,
            5,
            2,
            2,
            13,
            5,
            2,
            2,
            2,
            5,
            13,
            13,
            4,
            3,
            3,
            3,
            3,
            3,
            8,
            1
        ];

        seed >>= 4;
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 200);
        for (uint256 i; i < 33; ++i) {
            if (rand - int256(hatRarity[i]) < 0) {
                traitHat = i;
                break;
            }
            rand -= int256(hatRarity[i]);
        }

        // Calculate Accessory trait based on seed
        uint256[7] memory accessoryRarity = [uint256(10), 4, 20, 3, 12, 150, 1];

        seed >>= 4;
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 200);
        for (uint256 i; i < 7; ++i) {
            if (rand - int256(accessoryRarity[i]) < 0) {
                traitAccessory = i;
                break;
            }
            rand -= int256(accessoryRarity[i]);
        }

        // Calculate Mouth trait based on seed
        uint256[31] memory mouthRarity = [
            uint256(2),
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            4,
            3,
            4,
            15,
            24,
            4,
            4,
            4,
            3,
            24,
            3,
            4,
            11,
            9,
            3,
            4,
            11,
            11,
            11,
            10,
            10,
            4,
            4
        ];

        seed >>= 4;
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 200);
        for (uint256 i; i < 31; ++i) {
            if (rand - int256(mouthRarity[i]) < 0) {
                traitMouth = i;
                break;
            }
            rand -= int256(mouthRarity[i]);
        }

        // Calculate Background trait based on seed
        uint256[12] memory backgroundRarity = [
            uint256(30),
            30,
            30,
            30,
            30,
            30,
            3,
            3,
            3,
            3,
            4,
            4
        ];

        seed >>= 4;
        extractedRandomNum = seed & mask;
        rand = int256(extractedRandomNum % 200);
        for (uint256 i; i < 12; ++i) {
            if (rand - int256(backgroundRarity[i]) < 0) {
                traitBackground = i;
                break;
            }
            rand -= int256(backgroundRarity[i]);
        }

        return
            DNA({
                Legendary: traitLegendary,
                Body: traitBody,
                Pants: traitPants,
                Shirt: traitShirt,
                Eyes: traitEyes,
                Hat: traitHat,
                Accessory: traitAccessory,
                Mouth: traitMouth,
                Background: traitBackground
            });
    }
    

    /**
     * Given a tokenId, returns its SVG.
     */
    function tokenIdToSVG(uint256 tokenId) public view disallowIfStateIsChanging returns (string memory) {
        // Get the DNA derived from the tokenId's seed
        DNA memory dna = getDNA(tokenIdToSeed[tokenId]);

        // This will hold the SVG pixels (represented as SVG <rect> elements
        string memory svgRectTags;

        if (dna.Legendary == 0) {
            svgRectTags = string(
                abi.encodePacked(
                    svgRectTags,
                    getRectTagsFromCompressedImageData(
                        compressedTraitImages[4][dna.Body % 8],
                        dna.Body == 8
                    )
                )
            );

            if (dna.Pants != 14) {
                svgRectTags = string(
                    abi.encodePacked(
                        svgRectTags,
                        getRectTagsFromCompressedImageData(
                            compressedTraitImages[5][dna.Pants % 15],
                            dna.Pants == 15
                        )
                    )
                );
            }

            if (dna.Shirt != 19) {
                svgRectTags = string(
                    abi.encodePacked(
                        svgRectTags,
                        getRectTagsFromCompressedImageData(
                            compressedTraitImages[6][
                                dna.Mouth < 8
                                    ? (dna.Shirt + dna.Pants) % 8
                                    : dna.Shirt % 20
                            ], // If mouth is beard, make shirt solid color
                            dna.Shirt == 20
                        )
                    )
                );
            }

            svgRectTags = string(
                abi.encodePacked(
                    svgRectTags,
                    getRectTagsFromCompressedImageData(
                        compressedTraitImages[0][dna.Eyes == 23 ? 1 : dna.Eyes],
                        dna.Eyes == 23
                    )
                )
            );

            if (dna.Hat != 31) {
                svgRectTags = string(
                    abi.encodePacked(
                        svgRectTags,
                        getRectTagsFromCompressedImageData(
                            compressedTraitImages[1][
                                dna.Hat == 32
                                    ? (dna.Hat + dna.Shirt + dna.Pants) % 20
                                    : dna.Hat
                            ],
                            dna.Hat == 32
                        )
                    )
                );
            }

            if (dna.Accessory != 5) {
                svgRectTags = string(
                    abi.encodePacked(
                        svgRectTags,
                        getRectTagsFromCompressedImageData(
                            compressedTraitImages[2][dna.Accessory % 6],
                            dna.Accessory == 6
                        )
                    )
                );
            }

            svgRectTags = string(
                abi.encodePacked(
                    svgRectTags,
                    getRectTagsFromCompressedImageData(
                        compressedTraitImages[3][dna.Mouth],
                        false
                    )
                )
            );
        } else {
            svgRectTags = string(
                abi.encodePacked(svgRectTags, legendaryPixels)
            );
        }

        return 
            string(
                abi.encodePacked(
                    _SVG_PRE_STYLE_ATTRIBUTE,
                    getBackgroundStyleFromDnaIndex(
                        dna.Background,
                        dna.Legendary > 0
                    ),
                    _SVG_DEF_TAGS,
                    (dna.Legendary > 0)
                        ? ""
                        : _SVG_RAINBOW_ANIMATION_DEF_IF_RAINBOW,
                    (dna.Legendary > 0) ? _SVG_CLIP_DEF_IF_LEGENDARY : "",
                    (dna.Legendary > 0)
                        ? legendaryAnimations[dna.Legendary]
                        : "",
                    _SVG_TAG_PRE_ANIMATION_ID_REF,
                    AnonymiceLibrary.toString(dna.Legendary),
                    _SVG_FINAL_START_TAG,
                    svgRectTags,
                    _SVG_END_TAG
                )
            );
    }

    function tokenIdToMetadata(uint256 tokenId)
        public
        view
        disallowIfStateIsChanging
        returns (string memory)
    {
        unchecked {
            DNA memory tokenDna = getDNA(tokenIdToSeed[tokenId]);
            string memory metadataString;

            if (tokenDna.Legendary > 0) {
                metadataString = string(
                    abi.encodePacked(
                        '{"trait_type":"',
                        Utility.bytes32ToString(compressedTraitMetadata[8][0]),
                        '","value":"',
                        Utility.bytes32ToString(
                            compressedTraitMetadata[8][tokenDna.Legendary + 1]
                        ),
                        '"}'
                    )
                );
            } else {
                for (uint256 i; i < 9; ++i) {
                    uint256 traitValueIndex;

                    if (i == 0) {
                        traitValueIndex = tokenDna.Eyes;
                    } else if (i == 1) {
                        traitValueIndex = tokenDna.Hat;
                    } else if (i == 2) {
                        traitValueIndex = tokenDna.Accessory;
                    } else if (i == 3) {
                        traitValueIndex = tokenDna.Mouth;
                    } else if (i == 4) {
                        traitValueIndex = tokenDna.Body;
                    } else if (i == 5) {
                        traitValueIndex = tokenDna.Pants;
                    } else if (i == 6) {
                        traitValueIndex = tokenDna.Mouth < 8
                            ? (tokenDna.Shirt + tokenDna.Pants) % 8
                            : tokenDna.Shirt % 20;
                    } else if (i == 7) {
                        traitValueIndex = tokenDna.Background;
                    } else if (i == 8) {
                        traitValueIndex = tokenDna.Legendary;
                    } else {
                        traitValueIndex = uint256(69);
                    }

                    string memory traitName = Utility.bytes32ToString(
                        compressedTraitMetadata[i][0]
                    );
                    string memory traitValue = Utility.bytes32ToString(
                        compressedTraitMetadata[i][traitValueIndex + 1]
                    );

                    string memory startline;
                    if (i != 0) startline = ",";

                    metadataString = string(
                        abi.encodePacked(
                            metadataString,
                            startline,
                            '{"trait_type":"',
                            traitName,
                            '","value":"',
                            traitValue,
                            '"}'
                        )
                    );
                }
            }

            return string.concat("[", metadataString, "]");
        }
    }

    /**
     * Given the compressed image data for a single trait, and whether or not it is of special type,
     * return a string of rects that will be inserted into the final svg rendering.
     */
    function getRectTagsFromCompressedImageData(
        bytes memory compressedImage,
        bool isRainbow
    ) private view returns (string memory) {
        DecompressedTraitImage memory image = decompressTraitImageData(
            compressedImage
        );

        Pixel memory pixel;

        string[] memory cache = new string[](256);

        uint256 currentX = 0;
        uint256 currentY = image.bounds.minY;

        // will hold data for 4 rects
        string[16] memory buffer;

        string memory part;

        string memory rects;

        uint256 cursor;

        for (uint8 i = 0; i < image.draws.length; ++i) {
            pixel = image.draws[i];
            uint8 drawLength = pixel.length;

            uint8 length = getRectLength(currentX, drawLength, 32);

            if (pixel.colorIndex != 0) {
                buffer[cursor] = lookup[length]; // width
                buffer[cursor + 1] = lookup[currentX]; // x
                buffer[cursor + 2] = lookup[currentY]; // y
                buffer[cursor + 3] = getColorFromPalette(
                    hexColorPalette,
                    pixel.colorIndex,
                    cache
                ); // color

                cursor += 4;

                if (cursor > 15) {
                    part = string(
                        abi.encodePacked(
                            part,
                            getChunk(cursor, buffer, isRainbow)
                        )
                    );
                    cursor = 0;
                }
            }

            currentX += length;

            if (currentX > 31) {
                currentX = 0;
                ++currentY;
            }
        }

        if (cursor != 0) {
            part = string(
                abi.encodePacked(part, getChunk(cursor, buffer, isRainbow))
            );
        }

        rects = string(abi.encodePacked(rects, part));

        return rects;
    }

    /**
     * Given a Run-Length Encoded image in 'bytes', decompress it into a more workable data structure.
     */
    function decompressTraitImageData(bytes memory image)
        private
        pure
        returns (DecompressedTraitImage memory)
    {
        Bounds memory bounds = Bounds({
            minX: uint8(image[0]),
            maxX: uint8(image[1]),
            minY: uint8(image[2]),
            maxY: uint8(image[3])
        });

        uint256 pixelDataIndex;
        Pixel[] memory draws = new Pixel[]((image.length - 4) / 2);
        for (uint256 i = 4; i < image.length; i += 2) {
            draws[pixelDataIndex] = Pixel({
                length: uint8(image[i]),
                colorIndex: uint8(image[i + 1])
            });
            ++pixelDataIndex;
        }

        return DecompressedTraitImage({bounds: bounds, draws: draws});
    }

    /**
     * Given an x-coordinate, Pixel length, and right bound, return the Pixel
     * length for a single SVG rectangle.
     */
    function getRectLength(
        uint256 currentX,
        uint8 drawLength,
        uint8 maxX
    ) private pure returns (uint8) {
        uint8 remainingPixelsInLine = maxX - uint8(currentX);
        return
            drawLength <= remainingPixelsInLine
                ? drawLength
                : remainingPixelsInLine;
    }

    /**
     * Get the target hex color code from the cache. Populate the cache if
     * the color code does not yet exist.
     */
    function getColorFromPalette(
        bytes memory palette,
        uint256 index,
        string[] memory cache
    ) private pure returns (string memory) {
        if (bytes(cache[index]).length == 0) {
            uint256 i = index * 3;
            cache[index] = Utility._toHexString(
                abi.encodePacked(palette[i], palette[i + 1], palette[i + 2])
            );
        }
        return cache[index];
    }

    /**
     * Builds up to 4 rects given a buffer (array of strings, each contiguous group of 4 strings belonging to a
     * single rect.
     */
    function getChunk(
        uint256 cursor,
        string[16] memory buffer,
        bool isRainbow
    ) private pure returns (string memory) {
        string memory chunk;

        for (uint256 i = 0; i < cursor; i += 4) {
            bool isRectBlackColor = (keccak256(
                abi.encodePacked((buffer[i + 3]))
            ) == keccak256(abi.encodePacked(("000001"))));
            chunk = string(
                abi.encodePacked(
                    chunk,
                    '<rect width="',
                    buffer[i],
                    '" height="1" x="',
                    buffer[i + 1],
                    '" y="',
                    buffer[i + 2],
                    isRainbow && !isRectBlackColor ? "" : '" fill="#',
                    isRainbow && !isRectBlackColor ? "" : buffer[i + 3],
                    '"/>'
                )
            );
        }
        return chunk;
    }

    /**
     * Given an index (derived from the Citizen's "background" trait), returns the html-styled background string,
     * which will be inserted into the svg.
     */
    function getBackgroundStyleFromDnaIndex(uint256 index, bool isLegendary)
        private
        view
        returns (string memory)
    {
        if (isLegendary)
            return string.concat("background: ", backgrounds[12], ";");
        else 
            return string.concat("background: ", backgrounds[index], ";");
    }

    /*
     ______         __                __                         ██████       
    /      \       |  \              |  \                      ██      ██   
   |  000000\  ____| 00 ______ ____   \00 _______              ██      ██ 
   | 00__| 00 /      00|      \    \ |  \|       \           ██████████████ 
   | 00    00|  0000000| 000000\0000\| 00| 0000000\        ██              ██
   | 00000000| 00  | 00| 00 | 00 | 00| 00| 00  | 00        ██      ██      ██
   | 00  | 00| 00__| 00| 00 | 00 | 00| 00| 00  | 00        ██      ██      ██
   | 00  | 00 \00    00| 00 | 00 | 00| 00| 00  | 00        ██              ██  
    \00   \00  \0000000 \00  \00  \00 \00 \00   \00          ██████████████  
    
    */

    /**
     * Responsible for loading all of the data required to generate Citizens on-chain.

     * To be used by the owner of the contract upon deployment.

     * This function can only be called once to ensure immutability of the image data and your Citizen.
     */
    function loadCompressedData(
        bytes[][] calldata _inputTraits,
        bytes32[][] calldata _traitMetadata,
        string[] calldata _backgrounds,
        string[] calldata _legendaryAnimations,
        string calldata _legendaryRects,
        bytes calldata _colorHexList,
        string[33] calldata _lookup
    ) external onlyOwner {
        require(!compressedDataLoaded, "Loaded");
        compressedDataLoaded = true;
        compressedTraitImages = _inputTraits;
        compressedTraitMetadata = _traitMetadata;
        backgrounds = _backgrounds;
        legendaryAnimations = _legendaryAnimations;
        legendaryPixels = _legendaryRects;
        hexColorPalette = _colorHexList;
        lookup = _lookup;
    }

    /**
     * The owner (0xMongoon) is allowed to mint up to 30 custom Citizens.
     * These will be reserved for giveaways || community ideas || memes.
     */
    function ownerMint(uint256[] calldata customSeeds)
        external
        onlyOwner
    {
        uint256 quantity = customSeeds.length;
        uint256 totalminted = _totalMinted();
        unchecked {
            if (totalminted + quantity > MAX_SUPPLY) revert SoldOut();
            if (quantity > 30) revert MaxPerTxn();
            _safeMint(msg.sender, quantity);

            for (uint256 i; i < quantity; ++i) {
                tokenIdToSeed[totalminted + i] = customSeeds[i];
            }
            tokensMintedByOwner += quantity;
        }
    }

    function flipMintStatus() external onlyOwner {
        mintLive = !mintLive;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _share = address(this).balance;
        require(payable(address(0x52937c80c288A2f61F7Ac95210DA0bc7C688a7ee)).send(_share));
    }
}
