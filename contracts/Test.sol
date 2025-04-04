// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./PokerHandEvaluator.sol";

contract PokerHandEvaluatorTest is TexasHoldemEvaluator {
    function testRoyalFlush() public view returns (bool, string memory) {
        // Royal Flush in Spades + two irrelevant cards
        uint8[2] memory holeCards = [51, 50];     // AS, KS
        uint8[5] memory communityCards = [49, 48, 47, 0, 1];  // QS, JS, TS, 2H, 3H
        
        (uint16 handRank, uint8 handType) = evaluateHoldemHand(holeCards, communityCards);
        
        bool success = (handType == 10);  // Should be Royal Flush
        string memory message = success ? "Passed: Royal Flush correctly identified" : "Failed: Royal Flush not identified";
        
        return (success, message);
    }

    function testStraightFlush() public view returns (bool, string memory) {
        // 9-5 Straight Flush in Hearts + two irrelevant cards
        uint8[2] memory holeCards = [7, 6];     // 9H, 8H
        uint8[5] memory communityCards = [5, 4, 3, 50, 51];  // 7H, 6H, 5H, KS, AS
        
        (uint16 handRank, uint8 handType) = evaluateHoldemHand(holeCards, communityCards);
        
        bool success = (handType == 9);  // Should be Straight Flush
        string memory message = success ? "Passed: Straight Flush correctly identified" : "Failed: Straight Flush not identified";
        
        return (success, message);
    }

    function testFourOfAKind() public view returns (bool, string memory) {
        // Four Aces + King kicker
        uint8[2] memory holeCards = [0, 13];     // AH, AD
        uint8[5] memory communityCards = [26, 39, 50, 1, 2];  // AC, AS, KS, 3H, 4H
        
        (uint16 handRank, uint8 handType) = evaluateHoldemHand(holeCards, communityCards);
        
        bool success = (handType == 8);  // Should be Four of a Kind
        string memory message = success ? "Passed: Four of a Kind correctly identified" : "Failed: Four of a Kind not identified";
        
        return (success, message);
    }

    function testFullHouse() public view returns (bool, string memory) {
        // Aces full of Kings
        uint8[2] memory holeCards = [0, 13];     // AH, AD
        uint8[5] memory communityCards = [26, 50, 37, 1, 2];  // AC, KS, KD, 3H, 4H
        
        (uint16 handRank, uint8 handType) = evaluateHoldemHand(holeCards, communityCards);
        
        bool success = (handType == 7);  // Should be Full House
        string memory message = success ? "Passed: Full House correctly identified" : "Failed: Full House not identified";
        
        return (success, message);
    }

    function testFlush() public view returns (bool, string memory) {
        // Ace-high flush in Hearts
        uint8[2] memory holeCards = [0, 11];     // AH, KH
        uint8[5] memory communityCards = [7, 5, 3, 26, 39];  // 9H, 7H, 5H, AC, AS
        
        (uint16 handRank, uint8 handType) = evaluateHoldemHand(holeCards, communityCards);
        
        bool success = (handType == 6);  // Should be Flush
        string memory message = success ? "Passed: Flush correctly identified" : "Failed: Flush not identified";
        
        return (success, message);
    }

function testStraight() public view returns (bool, string memory) {
    // A-K-Q-J-T straight using correct bit patterns
    uint8[2] memory holeCards = [12, 11];         // AH, KH
    uint8[5] memory communityCards = [10, 9, 8, 1, 2];  // QH, JH, TH, 3H, 4H
    
    (uint16 handRank, uint8 handType) = evaluateHoldemHand(holeCards, communityCards);
    bool success = (handType == 5);
    string memory message = success ? "Passed: Straight correctly identified" : "Failed: Straight not identified";
    
    return (success, message);
}

function debugRankBits() public view returns (uint16) {
    uint8[2] memory holeCards = [12, 11];
    uint8[5] memory communityCards = [10, 9, 8, 1, 2];
    
    uint16 rankBits = 0;
    for (uint8 i = 0; i < 2; i++) {
        uint8 card = DECK[holeCards[i]];
        uint8 rank = card & 0x0F;
        rankBits |= (uint16(1) << rank);
    }
    for (uint8 i = 0; i < 5; i++) {
        uint8 card = DECK[communityCards[i]];
        uint8 rank = card & 0x0F;
        rankBits |= (uint16(1) << rank);
    }
    return rankBits;
}

    function testHandComparison() public view returns (bool, string memory) {
        // Player 1: Royal Flush
        uint8[2] memory holeCards1 = [51, 50];   // AS, KS
        
        // Player 2: Four Aces
        uint8[2] memory holeCards2 = [0, 13];    // AH, AD
        
        // Community cards with Queen, Jack, Ten of Spades
        uint8[5] memory communityCards = [49, 48, 47, 1, 2];  // QS, JS, TS, 3H, 4H
        
        uint8 winner = compareHoldemHands(holeCards1, holeCards2, communityCards);
        
        bool success = (winner == 1);  // Player 1 should win
        string memory message = success ? "Passed: Royal Flush beats Four of a Kind" : "Failed: Hand comparison error";
        
        return (success, message);
    }

    function runBasicTests() public view returns (bool allPassed, string[] memory results) {
        string[] memory results = new string[](4);
        bool allPassed = true;
        
        (bool test1, string memory result1) = testRoyalFlush();
        results[0] = result1;
        allPassed = allPassed && test1;
        
        (bool test2, string memory result2) = testStraightFlush();
        results[1] = result2;
        allPassed = allPassed && test2;
        
        (bool test3, string memory result3) = testFourOfAKind();
        results[2] = result3;
        allPassed = allPassed && test3;
        
        (bool test4, string memory result4) = testFullHouse();
        results[3] = result4;
        allPassed = allPassed && test4;
        
        return (allPassed, results);
    }

        function runAdvancedTests() public view returns (bool allPassed, string[] memory results) {
        string[] memory results = new string[](3);
        bool allPassed = true;
        
        (bool test5, string memory result5) = testFlush();
        results[0] = result5;
        allPassed = allPassed && test5;
        
        (bool test6, string memory result6) = testStraight();
        results[1] = result6;
        allPassed = allPassed && test6;
        
        (bool test7, string memory result7) = testHandComparison();
        results[2] = result7;
        allPassed = allPassed && test7;
        
        return (allPassed, results);
    }

    function runAllTests() public view returns (bool) {
        (bool basicTestsPassed,) = runBasicTests();
        (bool advancedTestsPassed,) = runAdvancedTests();
        
        return basicTestsPassed && advancedTestsPassed;
    }

    function testSpecificHands(
        uint8[2] memory holeCards1,
        uint8[2] memory holeCards2,
        uint8[5] memory communityCards
    ) public view returns (
        uint8 winner,
        uint8 hand1Type,
        uint8 hand2Type
    ) {
        (uint16 rank1, uint8 type1) = evaluateHoldemHand(holeCards1, communityCards);
        (uint16 rank2, uint8 type2) = evaluateHoldemHand(holeCards2, communityCards);
        
        winner = rank1 < rank2 ? 1 : rank2 < rank1 ? 2 : 0;
        return (winner, type1, type2);
    }
}