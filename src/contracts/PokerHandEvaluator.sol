// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract TexasHoldemEvaluator {
   uint8[52] public DECK;
   uint16[7462] public RANKS;
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
       0x100F  // 5-4-3-2-A
   ];

   uint16[13] public PRIMES = [
       2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41
   ];

   constructor() {
       for (uint8 i = 0; i < 52; i++) {
           uint8 rank = i % 13;
           uint8 suit = i / 13;
           DECK[i] = (suit << 4) | rank;
       }
       initializeRanks();
   }

   function initializeRanks() private {
       for (uint16 i = 0; i < 10; i++) {
           RANKS[i] = i + 1;
       }
       
       uint16 rank = 10;
       
       for (uint16 i = 0; i < 156; i++) {
           RANKS[rank] = i + 11;
           rank++;
       }
       
       for (uint16 i = 0; i < 156; i++) {
           RANKS[rank] = i + 167;
           rank++;
       }
       
       for (uint16 i = 0; i < 1277; i++) {
           RANKS[rank] = i + 323;
           rank++;
       }
       
       for (uint16 i = 0; i < 10; i++) {
           RANKS[rank] = i + 1600;
           rank++;
       }
       
       for (uint16 i = 0; i < 858; i++) {
           RANKS[rank] = i + 1610;
           rank++;
       }
       
       for (uint16 i = 0; i < 858; i++) {
           RANKS[rank] = i + 2468;
           rank++;
       }
       
       for (uint16 i = 0; i < 2860; i++) {
           RANKS[rank] = i + 3326;
           rank++;
       }
       
       for (uint16 i = 0; i < 1277; i++) {
           RANKS[rank] = i + 6186;
           rank++;
       }
   }

   function evaluateHoldemHand(
       uint8[2] memory holeCards,
       uint8[5] memory communityCards
   ) public view returns (
       uint16 handRank,
       uint8 handType
   ) {
       require(holeCards[0] < 52 && holeCards[1] < 52, "Invalid hole cards");
       require(holeCards[0] != holeCards[1], "Duplicate hole cards");

       for(uint8 i = 0; i < 5; i++) {
           require(communityCards[i] < 52, "Invalid community card");
           require(communityCards[i] != holeCards[0] && communityCards[i] != holeCards[1], 
               "Community card matches hole card");
           
           for(uint8 j = i + 1; j < 5; j++) {
               require(communityCards[i] != communityCards[j], "Duplicate community cards");
           }
       }

       uint8[7] memory allCards;
       allCards[0] = holeCards[0];
       allCards[1] = holeCards[1];
       for(uint8 i = 0; i < 5; i++) {
           allCards[i + 2] = communityCards[i];
       }

       return evaluateBestHand(allCards);
   }

   function evaluateBestHand(uint8[7] memory cards) private view 
       returns (uint16 handRank, uint8 handType) {
       uint16 rankBits = 0;
       uint8[4] memory suitCounts;
       uint8 maxSuitCount = 0;
       uint8 maxSuit = 0;
       uint32 rankProduct = 1;

       for (uint8 i = 0; i < 7; i++) {
           uint8 card = DECK[cards[i]];
           uint8 rank = card & 0x0F;
           uint8 suit = (card >> 4) & 0x03;
           
           rankBits |= (uint16(1) << rank);
           rankProduct *= PRIMES[rank];
           
           suitCounts[suit]++;
           if (suitCounts[suit] > maxSuitCount) {
               maxSuitCount = suitCounts[suit];
               maxSuit = suit;
           }
       }

       if (maxSuitCount >= 5) {
           uint16 flushBits = 0;
           for (uint8 i = 0; i < 7; i++) {
               uint8 card = DECK[cards[i]];
               if (((card >> 4) & 0x03) == maxSuit) {
                   flushBits |= (uint16(1) << (card & 0x0F));
               }
           }

           for (uint8 i = 0; i < 10; i++) {
               if ((flushBits & STRAIGHTS[i]) == STRAIGHTS[i]) {
                   return (i + 1, i == 0 ? 10 : 9);
               }
           }

           return (323 + findFlushRank(flushBits), 6);
       }

       for (uint8 i = 0; i < 10; i++) {
           if ((rankBits & STRAIGHTS[i]) == STRAIGHTS[i]) {
               return (1600 + i, 5);
           }
       }

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

       if (maxCount == 4) {
           return (11 + findFourOfAKindRank(rankCounts, rankProduct), 8);
       }
       if (maxCount == 3 && pairs >= 2) {
           return (167 + findFullHouseRank(rankCounts, rankProduct), 7);
       }
       if (maxCount == 3) {
           return (1610 + findThreeOfAKindRank(rankCounts, rankProduct), 4);
       }
       if (pairs >= 2) {
           return (2468 + findTwoPairRank(rankCounts, rankProduct), 3);
       }
       if (pairs == 1) {
           return (3326 + findOnePairRank(rankCounts, rankProduct), 2);
       }
       
       return (6186 + findHighCardRank(rankBits), 1);
   }

   function findFlushRank(uint16 bits) private pure returns (uint16) {
       uint16 rank = 0;
       uint16 temp = bits;
       while (temp != 0) {
           rank = (rank << 1) | (temp & 1);
           temp >>= 1;
       }
       return rank;
   }

   function findFourOfAKindRank(uint8[13] memory counts, uint32 product) private pure returns (uint16) {
       uint16 rank = 0;
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

   function findFullHouseRank(uint8[13] memory counts, uint32 product) private pure returns (uint16) {
       uint8 threeOfAKind = 0;
       uint8 pair = 0;
       
       for (int8 i = 12; i >= 0; i--) {
           if (counts[uint8(i)] == 3) {
               threeOfAKind = uint8(i);
               break;
           }
       }
       
       for (int8 i = 12; i >= 0; i--) {
           if (counts[uint8(i)] >= 2 && uint8(i) != threeOfAKind) {
               pair = uint8(i);
               break;
           }
       }
       
       return threeOfAKind * 13 + pair;
   }

   function findThreeOfAKindRank(uint8[13] memory counts, uint32 product) private pure returns (uint16) {
       uint16 rank = 0;
       uint8 kickers = 0;
       uint8 threeOfAKind = 0;
       
       for (uint8 i = 0; i < 13; i++) {
           if (counts[i] == 3) {
               threeOfAKind = i;
           }
       }
       
       rank = threeOfAKind * 66;
       
       for (int8 i = 12; i >= 0; i--) {
           if (counts[uint8(i)] == 1) {
               rank += kickers * uint8(i);
               kickers++;
               if (kickers == 2) break;
           }
       }
       
       return rank;
   }

   function findTwoPairRank(uint8[13] memory counts, uint32 product) private pure returns (uint16) {
       uint8[2] memory pairs;
       uint8 pairCount = 0;
       uint8 kicker = 0;
       
       for (int8 i = 12; i >= 0; i--) {
           if (counts[uint8(i)] == 2) {
               pairs[pairCount] = uint8(i);
               pairCount++;
               if (pairCount == 2) break;
           }
       }
       
       for (int8 i = 12; i >= 0; i--) {
           if (counts[uint8(i)] == 1) {
               kicker = uint8(i);
               break;
           }
       }
       
       return (pairs[0] * 13 + pairs[1]) * 13 + kicker;
   }

   function findOnePairRank(uint8[13] memory counts, uint32 product) private pure returns (uint16) {
       uint16 rank = 0;
       uint8 kickers = 0;
       uint8 pair = 0;
       
       for (uint8 i = 0; i < 13; i++) {
           if (counts[i] == 2) {
               pair = i;
               break;
           }
       }
       
       rank = pair * 220;
       
       for (int8 i = 12; i >= 0; i--) {
           if (counts[uint8(i)] == 1) {
               rank += kickers * uint8(i);
               kickers++;
               if (kickers == 3) break;
           }
       }
       
       return rank;
   }

   function findHighCardRank(uint16 rankBits) private pure returns (uint16) {
       uint16 rank = 0;
       uint8 count = 0;
       
       for (int8 i = 12; i >= 0; i--) {
           if ((rankBits & (uint16(1) << uint8(i))) != 0) {
               rank = rank * 13 + uint8(i);
               count++;
               if (count == 5) break;
           }
       }
       
       return rank;
   }

   function compareHoldemHands(
       uint8[2] memory holeCards1,
       uint8[2] memory holeCards2,
       uint8[5] memory communityCards
   ) public view returns (uint8) {
       (uint16 rank1, ) = evaluateHoldemHand(holeCards1, communityCards);
       (uint16 rank2, ) = evaluateHoldemHand(holeCards2, communityCards);

       return rank1 < rank2 ? 1 : rank2 < rank1 ? 2 : 0;
   }
}