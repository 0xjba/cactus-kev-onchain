// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title HandEvaluator
 * @dev This contract evaluates Texas Hold'em hands by determining the best 5-card
 * combination from a player's 2 hole cards and 5 community cards.
 */
contract HandEvaluator {
    // Constants for card ranks
    uint8 public constant RANK_2 = 0;
    uint8 public constant RANK_3 = 1;
    uint8 public constant RANK_4 = 2;
    uint8 public constant RANK_5 = 3;
    uint8 public constant RANK_6 = 4;
    uint8 public constant RANK_7 = 5;
    uint8 public constant RANK_8 = 6;
    uint8 public constant RANK_9 = 7;
    uint8 public constant RANK_T = 8;
    uint8 public constant RANK_J = 9;
    uint8 public constant RANK_Q = 10;
    uint8 public constant RANK_K = 11;
    uint8 public constant RANK_A = 12;
    
    // Constants for card suits
    uint8 public constant SUIT_CLUBS = 0;
    uint8 public constant SUIT_DIAMONDS = 1;
    uint8 public constant SUIT_HEARTS = 2;
    uint8 public constant SUIT_SPADES = 3;
    
    /// @dev Represents the 52-card deck.
    uint8[52] public DECK;

    /**
     * @dev STRAIGHTS holds bitmasks representing each possible straight rank pattern.
     * Each value is a 16-bit integer where consecutive bits set to 1 represent a run of 5 ranks.
     */
    uint16[10] public STRAIGHTS = [
        0x1F00, // A-K-Q-J-T
        0x0F80, // K-Q-J-T-9
        0x07C0, // Q-J-T-9-8
        0x03E0, // J-T-9-8-7
        0x01F0, // T-9-8-7-6
        0x00F8, // 9-8-7-6-5
        0x007C, // 8-7-6-5-4
        0x003E, // 7-6-5-4-3
        0x001F, // 6-5-4-3-2
        0x100F  // 5-4-3-2-A (special case where Ace is low)
    ];

    /// @dev PRIMES is a list of prime numbers for each rank (2..A).
    uint16[13] public PRIMES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41];

    /**
     * @dev Constructor that initializes the DECK array.
     * Each card in DECK is stored as a byte: the lower nibble is the rank, the upper nibble is the suit.
     */
    constructor() {
        for (uint8 i = 0; i < 52; i++) {
            uint8 rank = i % 13;
            uint8 suit = i / 13;
            DECK[i] = (suit << 4) | rank;
        }
    }

    /**
     * @dev Gets the rank of a card (0-12, representing 2-A)
     * @param card The card value
     * @return The rank value (0-12)
     */
    function getRank(uint8 card) public pure returns (uint8) {
        return card & 0x0F;
    }

    /**
     * @dev Gets the suit of a card (0-3, representing clubs, diamonds, hearts, spades)
     * @param card The card value
     * @return The suit value (0-3)
     */
    function getSuit(uint8 card) public pure returns (uint8) {
        return (card >> 4) & 0x03;
    }

    /**
     * @dev evaluateHoldemHand takes two hole cards and five community cards, validates them,
     * then evaluates the best 5-card hand out of those 7 cards.
     * @param holeCards A two-element array containing the player's hole cards (0-51).
     * @param communityCards A five-element array containing the community cards (0-51).
     * @return handRank A numeric rank indicating the hand's strength within its category.
     * @return handType A numeric category (1=Royal Flush, 2=Straight Flush, ..., 10=High Card).
     */
    function evaluateHoldemHand(
        uint8[2] memory holeCards,
        uint8[5] memory communityCards
    ) public view returns (uint32 handRank, uint8 handType) {
        require(holeCards[0] < 52 && holeCards[1] < 52, 'Invalid hole cards');
        require(holeCards[0] != holeCards[1], 'Duplicate hole cards');

        for (uint8 i = 0; i < 5; i++) {
            require(communityCards[i] < 52, 'Invalid community card');
            require(
                communityCards[i] != holeCards[0] &&
                communityCards[i] != holeCards[1],
                'Community card matches hole card'
            );

            for (uint8 j = i + 1; j < 5; j++) {
                require(
                    communityCards[i] != communityCards[j],
                    'Duplicate community cards'
                );
            }
        }

        // Combine hole cards and community cards into a 7-card array
        uint8[7] memory allCards;
        allCards[0] = holeCards[0];
        allCards[1] = holeCards[1];
        for (uint8 i = 0; i < 5; i++) {
            allCards[i + 2] = communityCards[i];
        }

        // Evaluate the best 5-card hand out of the 7 cards
        return evaluateBestHand(allCards);
    }

    /**
     * @dev evaluateBestHand calculates the best hand type and rank from 7 cards.
     * @param cards A seven-element array of card indices (0-51).
     * @return handRank Numeric rank indicating the exact ordering of the hand within its category.
     * @return handType A value representing the type (1=Royal Flush, 2=Straight Flush, ..., 10=High Card).
     */
    function evaluateBestHand(
        uint8[7] memory cards
    ) private view returns (uint32 handRank, uint8 handType) {
        uint16 rankBits = 0;
        uint8[4] memory suitCounts;
        uint8 maxSuitCount = 0;
        uint8 maxSuit = 0;

        for (uint8 i = 0; i < 7; i++) {
            uint8 card = DECK[cards[i]];
            uint8 rank = card & 0x0F;          // Extract rank (lower 4 bits)
            uint8 suit = (card >> 4) & 0x03;   // Extract suit (next 2 bits)

            rankBits |= (uint16(1) << rank);

            suitCounts[suit]++;
            if (suitCounts[suit] > maxSuitCount) {
                maxSuitCount = suitCounts[suit];
                maxSuit = suit;
            }
        }

        // Check for flush
        if (maxSuitCount >= 5) {
            uint16 flushBits = 0;
            for (uint8 i = 0; i < 7; i++) {
                uint8 card = DECK[cards[i]];
                if (((card >> 4) & 0x03) == maxSuit) {
                    flushBits |= (uint16(1) << (card & 0x0F));
                }
            }

            // Check for straight flush
            for (uint8 i = 0; i < 10; i++) {
                if ((flushBits & STRAIGHTS[i]) == STRAIGHTS[i]) {
                    // i == 0 means it's an A-K-Q-J-T straight (aka Royal Flush).
                    return (uint32(i + 1), i == 0 ? 1 : 2); // 1=Royal Flush, 2=Straight Flush
                }
            }

            return (uint32(323 + findFlushRank(flushBits)), 5); // 5=Flush
        }

        // Check for straight
        for (uint8 i = 0; i < 10; i++) {
            if ((rankBits & STRAIGHTS[i]) == STRAIGHTS[i]) {
                return (uint32(1600 + i), 6); // 6=Straight
            }
        }

        // Count ranks for other combinations
        uint8[13] memory rankCounts;
        uint8 maxCount = 0;
        uint8 pairs = 0;

        for (uint8 i = 0; i < 7; i++) {
            uint8 rank = DECK[cards[i]] & 0x0F;
            rankCounts[rank]++;
            if (rankCounts[rank] > maxCount) {
                maxCount = rankCounts[rank];
            }
            if (rankCounts[rank] == 2) {
                pairs++;
            }
        }

        // Check for Four of a Kind
        if (maxCount == 4) {
            return (uint32(11 + findFourOfAKindRank(rankCounts)), 3); // 3=Four of a Kind
        }

        // Check for Full House
        if (maxCount == 3 && pairs >= 2) {
            return (uint32(167 + findFullHouseRank(rankCounts)), 4); // 4=Full House
        }

        // Check for Three of a Kind
        if (maxCount == 3) {
            return (uint32(1610 + findThreeOfAKindRank(rankCounts)), 7); // 7=Three of a Kind
        }

        // Check for Two Pair
        if (pairs >= 2) {
            return (uint32(2468 + findTwoPairRank(rankCounts)), 8); // 8=Two Pair
        }

        // Check for One Pair
        if (pairs == 1) {
            return (uint32(3326 + findOnePairRank(rankCounts)), 9); // 9=One Pair
        }

        // Otherwise, it's a High Card
        return (uint32(6186 + findHighCardRank(rankBits)), 10); // 10=High Card
    }

    /**
     * @dev findFlushRank calculates a numeric representation of the flush cards.
     * @param bits Bitmask representing which ranks are present in the flush suit.
     * @return A numeric value encoding the flush ranks, used for tie-breaking.
     */
    function findFlushRank(uint16 bits) private pure returns (uint32) {
        uint32 rank = 0;
        uint16 temp = bits;
        while (temp != 0) {
            rank = (rank << 1) | (temp & 1);
            temp >>= 1;
        }
        return rank;
    }

    /**
     * @dev findFourOfAKindRank locates which rank is four-of-a-kind and which is the kicker.
     * @param counts Array of counts for each rank (0..12).
     * @return The rank used in tie-breaking: (4-card rank * 13) + kicker rank.
     */
    function findFourOfAKindRank(
        uint8[13] memory counts
    ) private pure returns (uint32) {
        uint32 rank = 0;
        for (uint8 i = 0; i < 13; i++) {
            if (counts[i] == 4) {
                rank = i * 13;
                for (uint8 j = 0; j < 13; j++) {
                    if (counts[j] == 1) {
                        return rank + j;
                    }
                }
            }
        }
        return rank;
    }

    /**
     * @dev findFullHouseRank locates the triplet rank and the pair rank for a full house.
     * @param counts Array of counts for each rank (0..12).
     * @return The numeric rank = (threeOfAKindRank * 13 + pairRank).
     */
    function findFullHouseRank(
        uint8[13] memory counts
    ) private pure returns (uint32) {
        uint8 threeOfAKind = 0;
        uint8 pair = 0;

        // Find the highest 3-of-a-kind
        for (int8 i = 12; i >= 0; i--) {
            if (counts[uint8(i)] == 3) {
                threeOfAKind = uint8(i);
                break;
            }
        }

        // Find the highest pair (can be 2 or 3 if leftover)
        for (int8 i = 12; i >= 0; i--) {
            if (counts[uint8(i)] >= 2 && uint8(i) != threeOfAKind) {
                pair = uint8(i);
                break;
            }
        }

        return uint32(threeOfAKind) * 13 + pair;
    }

    /**
     * @dev findThreeOfAKindRank locates the triple rank and calculates kickers.
     * @param counts Array of counts for each rank (0..12).
     * @return Numeric rank for tie-breaking among three-of-a-kind hands.
     */
    function findThreeOfAKindRank(
        uint8[13] memory counts
    ) private pure returns (uint32) {
        uint32 rank = 0;
        uint8 kickers = 0;
        uint8 threeOfAKind = 0;

        // Identify the three-of-a-kind rank
        for (uint8 i = 0; i < 13; i++) {
            if (counts[i] == 3) {
                threeOfAKind = i;
            }
        }

        unchecked {
            // Multiply the triple rank by 66 to create a base offset
            rank = uint32(threeOfAKind) * 66;

            // Identify the highest two kickers
            for (int8 i = 12; i >= 0; i--) {
                if (counts[uint8(i)] == 1) {
                    rank += uint32(kickers) * uint32(uint8(i));
                    kickers++;
                    if (kickers == 2) break;
                }
            }
        }

        return rank;
    }

    /**
     * @dev findTwoPairRank locates the top two pairs and then picks the kicker.
     * @param counts Array of counts for each rank (0..12).
     * @return A numeric value combining the pair ranks and the kicker for tie-breaks.
     */
    function findTwoPairRank(
        uint8[13] memory counts
    ) private pure returns (uint32) {
        uint8[2] memory pairs;
        uint8 pairCount = 0;
        uint8 kicker = 0;

        // Gather the highest 2 pairs
        for (int8 i = 12; i >= 0; i--) {
            if (counts[uint8(i)] == 2) {
                pairs[pairCount] = uint8(i);
                pairCount++;
                if (pairCount == 2) break;
            }
        }

        // Find the highest kicker
        for (int8 i = 12; i >= 0; i--) {
            if (counts[uint8(i)] == 1) {
                kicker = uint8(i);
                break;
            }
        }

        unchecked {
            // Combine pairs and kicker into a single numeric
            return (uint32(pairs[0]) * 13 + pairs[1]) * 13 + kicker;
        }
    }

    /**
     * @dev findOnePairRank locates the pair rank and identifies the top three kickers.
     * @param counts Array of counts for each rank (0..12).
     * @return A numeric value for tie-breaking: (pair rank * 220) + sum of three kickers.
     */
    function findOnePairRank(
        uint8[13] memory counts
    ) private pure returns (uint32) {
        uint32 rank = 0;
        uint8 kickers = 0;
        uint8 pair = 0;

        // Identify the pair rank
        for (uint8 i = 0; i < 13; i++) {
            if (counts[i] == 2) {
                pair = i;
                break;
            }
        }

        unchecked {
            // Multiply pair rank by 220 for base offset
            rank = uint32(pair) * 220;

            // Identify three kickers
            for (int8 i = 12; i >= 0; i--) {
                if (counts[uint8(i)] == 1) {
                    rank += uint32(kickers) * uint32(uint8(i));
                    kickers++;
                    if (kickers == 3) break;
                }
            }
        }

        return rank;
    }

    /**
     * @dev findHighCardRank calculates the top 5 cards in descending order and encodes them.
     * @param rankBits A 16-bit mask indicating which ranks are present.
     * @return Numeric rank used for tie-breaking among high-card hands.
     */
    function findHighCardRank(uint16 rankBits) private pure returns (uint32) {
        uint32 rank = 0;
        uint8 count = 0;

        unchecked {
            for (int8 i = 12; i >= 0; i--) {
                if ((rankBits & (uint16(1) << uint8(i))) != 0) {
                    rank = rank * 13 + uint32(uint8(i));
                    count++;
                    if (count == 5) break;
                }
            }
        }

        return rank;
    }

    /**
     * @dev compareHoldemHands compares two players' hands given the same community cards.
     * Returns 1 if player 1's hand is stronger, 2 if player 2's hand is stronger, or 0 if tied.
     * @param holeCards1 Player 1's hole cards.
     * @param holeCards2 Player 2's hole cards.
     * @param communityCards The same community cards for both players.
     * @return 1 if Player 1 wins, 2 if Player 2 wins, 0 if tie.
     */
    function compareHoldemHands(
        uint8[2] memory holeCards1,
        uint8[2] memory holeCards2,
        uint8[5] memory communityCards
    ) public view returns (uint8) {
        (uint32 rank1, uint8 type1) = evaluateHoldemHand(holeCards1, communityCards);
        (uint32 rank2, uint8 type2) = evaluateHoldemHand(holeCards2, communityCards);

        // Compare hand types first (lower type is better, 1=Royal Flush is best)
        if (type1 < type2) {
            return 1; // Player 1 wins
        } else if (type2 < type1) {
            return 2; // Player 2 wins
        } 

        // If hand types are the same, compare hand ranks
        // For One Pair (type 9), the rank value encoding is:
        // (pair_rank * 220) + kicker_adjustments
        // So a higher rank indicates better cards (A > K > Q)
        if (rank1 > rank2) {
            return 1; // Player 1 wins
        } else if (rank2 > rank1) {
            return 2; // Player 2 wins
        }

        // If both hand type and rank are the same, it's a tie
        return 0;
    }
}