import React, { useState } from 'react';
import { ethers } from 'ethers';
import Web3Modal from 'web3modal';

export default function PokerEvaluator() {
    const [hand1Hole, setHand1Hole] = useState(['', '']);
    const [hand2Hole, setHand2Hole] = useState(['', '']);
    const [communityCards, setCommunityCards] = useState(['', '', '', '', '']);
    const [result, setResult] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [evaluatorContract, setEvaluatorContract] = useState(null);
    const [testContract, setTestContract] = useState(null);
    const [account, setAccount] = useState('');

    const suits = ['♣', '♦', '♥', '♠'];
    const ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];

    const EVALUATOR_ADDRESS = "0xfAfe09304611E7bbA73951937954A065D45b98f8"; 
    const TEST_ADDRESS = "0xb20BdbfdC49148b8cC2aF494C15E043452b163a9";

    const EVALUATOR_ABI = [
        {
            "inputs": [
                {
                    "components": [
                        {
                            "internalType": "uint32",
                            "name": "value",
                            "type": "uint32"
                        },
                        {
                            "internalType": "uint8",
                            "name": "category",
                            "type": "uint8"
                        },
                        {
                            "internalType": "uint32",
                            "name": "tiebreaker",
                            "type": "uint32"
                        },
                        {
                            "internalType": "uint32",
                            "name": "kickers",
                            "type": "uint32"
                        }
                    ],
                    "internalType": "struct TexasHoldemEvaluator.HandRank",
                    "name": "hand1",
                    "type": "tuple"
                },
                {
                    "components": [
                        {
                            "internalType": "uint32",
                            "name": "value",
                            "type": "uint32"
                        },
                        {
                            "internalType": "uint8",
                            "name": "category",
                            "type": "uint8"
                        },
                        {
                            "internalType": "uint32",
                            "name": "tiebreaker",
                            "type": "uint32"
                        },
                        {
                            "internalType": "uint32",
                            "name": "kickers",
                            "type": "uint32"
                        }
                    ],
                    "internalType": "struct TexasHoldemEvaluator.HandRank",
                    "name": "hand2",
                    "type": "tuple"
                }
            ],
            "name": "compareHands",
            "outputs": [
                {
                    "internalType": "int8",
                    "name": "",
                    "type": "int8"
                }
            ],
            "stateMutability": "pure",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint8[2]",
                    "name": "holeCards",
                    "type": "uint8[2]"
                },
                {
                    "internalType": "uint8[5]",
                    "name": "communityCards",
                    "type": "uint8[5]"
                }
            ],
            "name": "evaluateHoldemHand",
            "outputs": [
                {
                    "components": [
                        {
                            "internalType": "uint32",
                            "name": "value",
                            "type": "uint32"
                        },
                        {
                            "internalType": "uint8",
                            "name": "category",
                            "type": "uint8"
                        },
                        {
                            "internalType": "uint32",
                            "name": "tiebreaker",
                            "type": "uint32"
                        },
                        {
                            "internalType": "uint32",
                            "name": "kickers",
                            "type": "uint32"
                        }
                    ],
                    "internalType": "struct TexasHoldemEvaluator.HandRank",
                    "name": "",
                    "type": "tuple"
                }
            ],
            "stateMutability": "pure",
            "type": "function"
        }
    ];
    const TEST_ABI = [
        {
            "inputs": [
                {
                    "internalType": "uint8[2]",
                    "name": "hand1HoleCards",
                    "type": "uint8[2]"
                },
                {
                    "internalType": "uint8[5]",
                    "name": "hand1CommunityCards",
                    "type": "uint8[5]"
                },
                {
                    "internalType": "uint8[2]",
                    "name": "hand2HoleCards",
                    "type": "uint8[2]"
                },
                {
                    "internalType": "uint8[5]",
                    "name": "hand2CommunityCards",
                    "type": "uint8[5]"
                }
            ],
            "name": "compareHands",
            "outputs": [
                {
                    "internalType": "int8",
                    "name": "",
                    "type": "int8"
                }
            ],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [],
            "stateMutability": "nonpayable",
            "type": "constructor"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": false,
                    "internalType": "string",
                    "name": "testName",
                    "type": "string"
                },
                {
                    "indexed": false,
                    "internalType": "uint32",
                    "name": "value",
                    "type": "uint32"
                },
                {
                    "indexed": false,
                    "internalType": "uint8",
                    "name": "category",
                    "type": "uint8"
                },
                {
                    "indexed": false,
                    "internalType": "uint32",
                    "name": "tiebreaker",
                    "type": "uint32"
                },
                {
                    "indexed": false,
                    "internalType": "uint32",
                    "name": "kickers",
                    "type": "uint32"
                }
            ],
            "name": "HandRank",
            "type": "event"
        },
        {
            "inputs": [],
            "name": "runAllTests",
            "outputs": [
                {
                    "internalType": "bool",
                    "name": "",
                    "type": "bool"
                }
            ],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "testFourOfAKind",
            "outputs": [
                {
                    "internalType": "bool",
                    "name": "",
                    "type": "bool"
                }
            ],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "anonymous": false,
            "inputs": [
                {
                    "indexed": false,
                    "internalType": "string",
                    "name": "testName",
                    "type": "string"
                },
                {
                    "indexed": false,
                    "internalType": "bool",
                    "name": "passed",
                    "type": "bool"
                },
                {
                    "indexed": false,
                    "internalType": "string",
                    "name": "message",
                    "type": "string"
                }
            ],
            "name": "TestResult",
            "type": "event"
        },
        {
            "inputs": [],
            "name": "testRoyalFlush",
            "outputs": [
                {
                    "internalType": "bool",
                    "name": "",
                    "type": "bool"
                }
            ],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint8[2]",
                    "name": "holeCards",
                    "type": "uint8[2]"
                },
                {
                    "internalType": "uint8[5]",
                    "name": "communityCards",
                    "type": "uint8[5]"
                }
            ],
            "name": "testSpecificHand",
            "outputs": [
                {
                    "components": [
                        {
                            "internalType": "uint32",
                            "name": "value",
                            "type": "uint32"
                        },
                        {
                            "internalType": "uint8",
                            "name": "category",
                            "type": "uint8"
                        },
                        {
                            "internalType": "uint32",
                            "name": "tiebreaker",
                            "type": "uint32"
                        },
                        {
                            "internalType": "uint32",
                            "name": "kickers",
                            "type": "uint32"
                        }
                    ],
                    "internalType": "struct TexasHoldemEvaluator.HandRank",
                    "name": "",
                    "type": "tuple"
                }
            ],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "testStraightFlush",
            "outputs": [
                {
                    "internalType": "bool",
                    "name": "",
                    "type": "bool"
                }
            ],
            "stateMutability": "nonpayable",
            "type": "function"
        }
    ];

    const web3Modal = new Web3Modal({
        network: "goerli",
        cacheProvider: true,
        providerOptions: {}
    });

    function cardToNumber(cardString) {
        if (!cardString) return null;
        
        const rank = cardString.slice(0, -1);
        const suit = cardString.slice(-1);
        
        const rankIndex = ranks.indexOf(rank);
        const suitIndex = suits.indexOf(suit);
        
        console.log(`Converting card: ${cardString}`);
        console.log(`Rank: ${rank} (index: ${rankIndex})`);
        console.log(`Suit: ${suit} (index: ${suitIndex})`);
        
        if (rankIndex === -1 || suitIndex === -1) {
            console.error(`Invalid card: ${cardString}`);
            return null;
        }
        
        const cardNumber = suitIndex * 13 + rankIndex;
        console.log(`Final card number: ${cardNumber}`);
        
        return cardNumber;
    }

    async function connectWallet() {
        try {
            setLoading(true);
            setError('');

            const instance = await web3Modal.connect();
            const provider = new ethers.providers.Web3Provider(instance);
            const signer = provider.getSigner();
            const address = await signer.getAddress();

            const evaluator = new ethers.Contract(
                EVALUATOR_ADDRESS,
                EVALUATOR_ABI,
                signer
            );

            const test = new ethers.Contract(
                TEST_ADDRESS,
                TEST_ABI,
                signer
            );

            setEvaluatorContract(evaluator);
            setTestContract(test);
            setAccount(address);

            instance.on("accountsChanged", (accounts) => {
                setAccount(accounts[0]);
            });

            setLoading(false);
        } catch (error) {
            console.error("Connection error:", error);
            setError(error.message);
            setLoading(false);
        }
    }

    async function evaluateHands() {
        if (!testContract) {
            setError('Please connect wallet first');
            return;
        }
    
        try {
            setLoading(true);
            setError('');
            setResult('');
    
            const hand1Numbers = hand1Hole.map(cardToNumber);
            const hand2Numbers = hand2Hole.map(cardToNumber);
            const communityNumbers = communityCards.map(cardToNumber);
    
            if (hand1Numbers.includes(null) || hand2Numbers.includes(null) || 
                communityNumbers.includes(null)) {
                throw new Error('Please select all cards first');
            }
    
            console.log('Sending transaction with:', {
                hand1Numbers,
                communityNumbers,
                hand2Numbers
            });
    
            const tx = await testContract.compareHands(
                hand1Numbers,
                communityNumbers,
                hand2Numbers,
                communityNumbers
            );
    
            setResult('Transaction submitted - waiting for confirmation...');
    
            const receipt = await tx.wait();
            console.log('Transaction receipt:', receipt);
    
            const result = await testContract.callStatic.compareHands(
                hand1Numbers,
                communityNumbers,
                hand2Numbers,
                communityNumbers
            );
    
            let resultText;
            if (result === 1) {
                resultText = "Hand 1 wins!";
            } else if (result === -1) {
                resultText = "Hand 2 wins!";
            } else {
                resultText = "It's a tie!";
            }
    
            setResult(resultText);
        } catch (error) {
            console.error("Error evaluating hands:", error);
            setError(error.message);
        } finally {
            setLoading(false);
        }
    }

    function CardSelector({ value, onChange, usedCards }) {
        console.log('Current value:', value);
        console.log('Used cards:', usedCards);
    
        return (
            <select 
                value={value} 
                onChange={(e) => {
                    console.log('Selected value:', e.target.value); 
                    onChange(e.target.value);
                }}
                style={{
                    width: '60px',
                    height: '40px',
                    margin: '5px',
                    fontSize: '16px',
                    textAlign: 'center',
                    backgroundColor: value ? '#e8f5e9' : 'white' 
                }}
            >
                <option value="">?</option>
                {suits.map(suit => 
                    ranks.map(rank => {
                        const card = rank + suit;
                        const isUsed = usedCards.includes(card) && card !== value; 
                        if (!isUsed) {
                            return (
                                <option 
                                    key={card} 
                                    value={card}
                                    style={{
                                        color: (suit === '♥' || suit === '♦') ? 'red' : 'black'
                                    }}
                                >
                                    {card}
                                </option>
                            );
                        }
                        return null;
                    })
                )}
            </select>
        );
    }

    const usedCards = [...hand1Hole, ...hand2Hole, ...communityCards].filter(Boolean);

    const containerStyle = {
        maxWidth: '800px',
        margin: '20px auto',
        padding: '20px',
        fontFamily: 'Arial, sans-serif'
    };

    const headerStyle = {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '20px'
    };

    const buttonStyle = {
        padding: '10px 20px',
        fontSize: '16px',
        cursor: 'pointer',
        backgroundColor: '#4CAF50',
        color: 'white',
        border: 'none',
        borderRadius: '4px',
        opacity: loading ? 0.7 : 1
    };

    return (
        <div style={containerStyle}>
            <div style={headerStyle}>
                <h1>Texas Hold'em Hand Evaluator</h1>
                <button 
                    onClick={connectWallet}
                    disabled={loading}
                    style={buttonStyle}
                >
                    {account ? 
                        `Connected: ${account.slice(0,6)}...${account.slice(-4)}` : 
                        'Connect Wallet'
                    }
                </button>
            </div>

            <div style={{ marginBottom: '20px' }}>
                <h3>Community Cards (Shared)</h3>
                <div>
                {communityCards.map((card, i) => (
                    <CardSelector
                        key={i}
                        value={communityCards[i]}
                        onChange={(newCard) => {
                            const newCards = [...communityCards];
                            newCards[i] = newCard;
                            console.log('Updating communityCards:', newCards);
                            setCommunityCards(newCards);
                        }}
                        usedCards={usedCards}
                    />
                ))}
                </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '20px' }}>
                <div>
                    <h3>Player 1 Hole Cards</h3>
                    {hand1Hole.map((card, i) => (
                        <CardSelector
                            key={i}
                            value={hand1Hole[i]}
                            onChange={(newCard) => {
                                const newHand = [...hand1Hole];
                                newHand[i] = newCard;
                                console.log('Updating hand1Hole:', newHand);
                                setHand1Hole(newHand);
                            }}
                            usedCards={usedCards}
                        />
                    ))}
                </div>

                <div>
                    <h3>Player 2 Hole Cards</h3>
                    {hand2Hole.map((card, i) => (
                    <CardSelector
                        key={i}
                        value={hand2Hole[i]}
                        onChange={(newCard) => {
                            const newHand = [...hand2Hole];
                            newHand[i] = newCard;
                            console.log('Updating hand2Hole:', newHand); 
                            setHand2Hole(newHand);
                        }}
                        usedCards={usedCards}
                    />
                ))}
                </div>
            </div>

            <button 
                onClick={evaluateHands}
                disabled={loading || !testContract}
                style={{
                    ...buttonStyle,
                    opacity: (!testContract || loading) ? 0.5 : 1
                }}
            >
                {loading ? 'Evaluating...' : 'Compare Hands'}
            </button>

            {error && (
                <div style={{ 
                    marginTop: '20px', 
                    padding: '10px', 
                    backgroundColor: '#ffebee',
                    color: '#c62828',
                    borderRadius: '4px'
                }}>
                    {error}
                </div>
            )}

            {result && !error && (
                <div style={{ 
                    marginTop: '20px', 
                    padding: '10px', 
                    backgroundColor: '#e8f5e9',
                    color: '#2e7d32',
                    borderRadius: '4px'
                }}>
                    {result}
                </div>
            )}
        </div>
    );
}