import React, { useState, useRef, useEffect } from 'react';
import { ethers } from 'ethers';
import Web3Modal from 'web3modal';
import { Wallet, ChevronDown, AlertTriangle, Github } from 'lucide-react';

function PokerEvaluator() {
    const [hand1Hole, setHand1Hole] = useState(['', '']);
    const [hand2Hole, setHand2Hole] = useState(['', '']);
    const [communityCards, setCommunityCards] = useState(['', '', '', '', '']);
    const [result, setResult] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [evaluatorContract, setEvaluatorContract] = useState(null);
    const [testContract, setTestContract] = useState(null);
    const [account, setAccount] = useState('');
    const [activeSelector, setActiveSelector] = useState(null);
    const [chainId, setChainId] = useState(null);
    const [provider, setProvider] = useState(null);

    const SEPOLIA_CHAIN_ID = 11155111;

    const suits = ['♣', '♦', '♥', '♠'];
    const ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];
    const EVALUATOR_ADDRESS = "0x5609DbC36C71267b87258B8913Bb03231BE4BBEa";
    const TEST_ADDRESS = "0x5609DbC36C71267b87258B8913Bb03231BE4BBEa";
    const EVALUATOR_ABI = [
        "function evaluateHoldemHand(uint8[2] memory holeCards, uint8[5] memory communityCards) public view returns (uint32 handRank, uint8 handType)",
        "function compareHoldemHands(uint8[2] memory holeCards1, uint8[2] memory holeCards2, uint8[5] memory communityCards) public view returns (uint8)"
    ];
    const TEST_ABI = [
        "function evaluateHoldemHand(uint8[2] memory holeCards, uint8[5] memory communityCards) public view returns (uint32 handRank, uint8 handType)",
        "function compareHoldemHands(uint8[2] memory holeCards1, uint8[2] memory holeCards2, uint8[5] memory communityCards) public view returns (uint8)"
    ];

    const web3Modal = new Web3Modal({
        network: "sepolia",
        cacheProvider: true,
        providerOptions: {}
    });

    useEffect(() => {
        if (provider) {
            const handleChainChanged = async (newChainId) => {
                const chainIdNumber = parseInt(newChainId, 16);
                setChainId(chainIdNumber);
                
                // Clear existing contracts
                setTestContract(null);
                setEvaluatorContract(null);

                if (chainIdNumber === SEPOLIA_CHAIN_ID) {
                    setError('');
                    // Reinitialize with fresh provider
                    const web3Provider = new ethers.providers.Web3Provider(provider.provider);
                    setProvider(web3Provider);
                    await initializeContracts(web3Provider);
                } else {
                    setError('Please switch to Sepolia network');
                }
            };

            provider.on("chainChanged", handleChainChanged);
            return () => {
                provider.removeListener("chainChanged", handleChainChanged);
            };
        }
    }, [provider]);

    // Check for cached provider on component mount
    useEffect(() => {
        if (web3Modal.cachedProvider) {
            connectWallet();
        }
    }, []);

    async function initializeContracts(currentProvider = provider) {
        if (!currentProvider) {
            setError('Provider not initialized');
            return;
        }

        try {
            const network = await currentProvider.getNetwork();
            if (network.chainId !== SEPOLIA_CHAIN_ID) {
                setError('Please switch to Sepolia network');
                return;
            }

            const signer = currentProvider.getSigner();
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
            setError('');
        } catch (error) {
            console.error("Failed to initialize contracts:", error);
            setError('Failed to initialize contracts');
        }
    }

    async function switchNetwork() {
        try {
            setLoading(true);
            await window.ethereum.request({
                method: 'wallet_switchEthereumChain',
                params: [{ chainId: '0xaa36a7' }], // Sepolia chainId in hex
            });
            
            // Create fresh provider instance after network switch
            const instance = await web3Modal.connect();
            const web3Provider = new ethers.providers.Web3Provider(instance);
            setProvider(web3Provider);
            
            const network = await web3Provider.getNetwork();
            setChainId(network.chainId);
            
            if (network.chainId === SEPOLIA_CHAIN_ID) {
                await initializeContracts(web3Provider);
            }
            
            setLoading(false);
        } catch (error) {
            console.error('Failed to switch network:', error);
            setError('Failed to switch network. Please try manually.');
            setLoading(false);
        }
    }

    async function connectWallet() {
        try {
            setLoading(true);
            setError('');

            const instance = await web3Modal.connect();
            const web3Provider = new ethers.providers.Web3Provider(instance);
            setProvider(web3Provider);

            const network = await web3Provider.getNetwork();
            setChainId(network.chainId);

            const signer = web3Provider.getSigner();
            const address = await signer.getAddress();
            setAccount(address);

            if (network.chainId !== SEPOLIA_CHAIN_ID) {
                setError('Please switch to Sepolia network');
                setLoading(false);
                return;
            }

            await initializeContracts(web3Provider);

            instance.on("accountsChanged", (accounts) => {
                if (accounts.length === 0) {
                    // Handle disconnection
                    setAccount('');
                    setChainId(null);
                    setProvider(null);
                    setEvaluatorContract(null);
                    setTestContract(null);
                } else {
                    setAccount(accounts[0]);
                }
            });

            setLoading(false);
        } catch (error) {
            console.error("Connection error:", error);
            setError(error.message);
            setLoading(false);
        }
    }

    function cardToNumber(cardString) {
        if (!cardString) return null;
        
        const rank = cardString.slice(0, -1);
        const suit = cardString.slice(-1);
        
        const rankIndex = ranks.indexOf(rank);
        const suitIndex = suits.indexOf(suit);
        
        if (rankIndex === -1 || suitIndex === -1) {
            console.error(`Invalid card: ${cardString}`);
            return null;
        }
        
        const cardNumber = suitIndex * 13 + rankIndex;
        return cardNumber;
    }

    async function evaluateHands() {
        if (!testContract) {
            setError('Please connect wallet first');
            return;
        }

        // Verify network and refresh provider if needed
        try {
            const network = await provider.getNetwork();
            if (network.chainId !== SEPOLIA_CHAIN_ID) {
                setError('Please switch to Sepolia network');
                return;
            }

            // Refresh the contract instance with current provider
            const signer = provider.getSigner();
            const freshContract = new ethers.Contract(
                TEST_ADDRESS,
                TEST_ABI,
                signer
            );
    
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
    
            const result = await freshContract.callStatic.compareHoldemHands(
                hand1Numbers,
                hand2Numbers,
                communityNumbers
            );
    
            let resultText;
            if (result === 1) {
                resultText = "Hand 1 wins!";
            } else if (result === 2) {
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

    function CardSelector({ value, onChange, usedCards, id }) {
        const getCardColor = (suit) => {
            return suit === '♥' || suit === '♦' ? 'text-red-500' : 'text-white';
        };

        const renderCard = (cardValue) => {
            if (!cardValue) {
                return (
                    <div className="w-[100px] h-[140px] glass-card rounded-xl flex items-center justify-center text-white cursor-pointer hover:bg-opacity-20 transition-all shadow-lg hover:shadow-2xl transform hover:-translate-y-1 duration-200 bg-gradient-to-br from-white/10 to-white/5">
                        <ChevronDown className="w-8 h-8" />
                    </div>
                );
            }

            const suit = cardValue.slice(-1);
            const rank = cardValue.slice(0, -1);

            return (
                <div className="relative w-[100px] h-[140px] glass rounded-xl flex flex-col items-center justify-between p-3 cursor-pointer hover:bg-opacity-80 transition-all shadow-xl hover:shadow-2xl transform hover:-translate-y-1 duration-200 bg-gradient-to-br from-white/20 to-white/5 border border-white/20">
                    <div className={`text-lg font-bold ${getCardColor(suit)} self-start`}>
                        {rank}
                    </div>
                    <div className={`text-4xl ${getCardColor(suit)}`}>
                        {suit}
                    </div>
                    <div className={`text-lg font-bold ${getCardColor(suit)} self-end rotate-180`}>
                        {rank}
                    </div>
                </div>
            );
        };

        return (
            <div className="card-selector relative" onClick={(e) => e.stopPropagation()}>
                <div onClick={() => setActiveSelector(activeSelector === id ? null : id)}>
                    {renderCard(value)}
                </div>
                
                {activeSelector === id && (
                    <div className="absolute z-50 mt-2 w-[280px] max-h-[400px] overflow-y-auto glass rounded-xl shadow-2xl grid grid-cols-4 gap-2 p-4 border border-white/20">
                        <div 
                            className="w-[50px] h-[70px] glass-card rounded-lg flex items-center justify-center cursor-pointer hover:bg-opacity-20 text-white transform hover:-translate-y-1 duration-200"
                            onClick={() => {
                                onChange('');
                                setActiveSelector(null);
                            }}
                        >
                            ?
                        </div>
                        {suits.map(suit => 
                            ranks.map(rank => {
                                const card = rank + suit;
                                const isUsed = usedCards.includes(card) && card !== value;
                                
                                if (!isUsed) {
                                    return (
                                        <div
                                            key={card}
                                            className="w-[50px] h-[70px] glass rounded-lg flex flex-col items-center justify-between p-1 cursor-pointer hover:bg-opacity-80 transform hover:-translate-y-1 duration-200"
                                            onClick={() => {
                                                onChange(card);
                                                setActiveSelector(null);
                                            }}
                                        >
                                            <span className={`text-xs font-bold ${getCardColor(suit)}`}>
                                                {rank}
                                            </span>
                                            <span className={`text-xl ${getCardColor(suit)}`}>
                                                {suit}
                                            </span>
                                        </div>
                                    );
                                }
                                return null;
                            })
                        )}
                    </div>
                )}
            </div>
        );
    }

    const usedCards = [...hand1Hole, ...hand2Hole, ...communityCards].filter(Boolean);

    return (
        <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-900 to-green-900 relative overflow-hidden">
            <div className="absolute inset-0 overflow-hidden">
                <div className="absolute inset-0 poker-pattern"></div>
                <div className="absolute -inset-[10px] opacity-50">
                    <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-green-500 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob"></div>
                    <div className="absolute top-1/2 left-1/3 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-blue-500 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-2000"></div>
                    <div className="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-purple-500 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-4000"></div>
                </div>
                <div className="noise absolute inset-0"></div>
            </div>

            <div className="relative max-w-6xl mx-auto p-6 space-y-8">
                <div className="flex justify-between items-center">
                    <div>
                        <h1 className="text-4xl font-bold text-white">Cactus Kev On-Chain Hand Evaluator</h1>
                        <p className="mt-2 text-gray-400">
                            This contract powers AI Agent Texas Holdem's Hand Evaluation. Play it on{' '}
                            <a 
                                href="https://houseof.ten.xyz/" 
                                target="_blank" 
                                rel="noopener noreferrer" 
                                className="text-blue-400 hover:text-blue-300 transition-colors"
                            >
                                houseof.ten.xyz
                            </a>
                        </p>
                    </div>
                    {account && chainId !== SEPOLIA_CHAIN_ID ? (
                        <button 
                            onClick={switchNetwork}
                            className="px-6 py-3 rounded-xl font-medium flex items-center gap-2 bg-yellow-500/20 text-yellow-300 hover:bg-yellow-500/30 transition-all"
                        >
                            <AlertTriangle className="w-5 h-5" />
                            Switch to Sepolia
                        </button>
                    ) : (
                        <button 
                            onClick={connectWallet}
                            disabled={loading}
                            className={`px-6 py-3 rounded-xl font-medium flex items-center gap-2 glass-card hover:bg-opacity-20 transition-all disabled:opacity-50 shadow-lg ${
                                account ? 'text-green-300' : 'text-white'
                            }`}
                        >
                            <Wallet className="w-5 h-5" />
                            {account ? `${account.slice(0,6)}...${account.slice(-4)}` : 'Connect Wallet'}
                        </button>
                    )}
                </div>

                <div className="relative glass rounded-[40px] shadow-2xl p-12 space-y-12">
                    <div className="space-y-6">
                        <h3 className="text-2xl font-semibold text-white text-center mb-8">Community Cards</h3>
                        <div className="flex justify-center gap-4">
                            {communityCards.map((card, i) => (
                                <CardSelector
                                    key={i}
                                    id={`community-${i}`}
                                    value={communityCards[i]}
                                    onChange={(newCard) => {
                                        const newCards = [...communityCards];
                                        newCards[i] = newCard;
                                        setCommunityCards(newCards);
                                    }}
                                    usedCards={usedCards}
                                />
                            ))}
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-16">
                        <div>
                            <h3 className="text-2xl font-semibold text-white text-center mb-8">Player 1</h3>
                            <div className="flex justify-center gap-4">
                                {hand1Hole.map((card, i) => (
                                    <CardSelector
                                        key={i}
                                        id={`hand1-${i}`}
                                        value={hand1Hole[i]}
                                        onChange={(newCard) => {
                                            const newHand = [...hand1Hole];
                                            newHand[i] = newCard;
                                            setHand1Hole(newHand);
                                        }}
                                        usedCards={usedCards}
                                    />
                                ))}
                            </div>
                        </div>

                        <div>
                            <h3 className="text-2xl font-semibold text-white text-center mb-8">Player 2</h3>
                            <div className="flex justify-center gap-4">
                                {hand2Hole.map((card, i) => (
                                    <CardSelector
                                        key={i}
                                        id={`hand2-${i}`}
                                        value={hand2Hole[i]}
                                        onChange={(newCard) => {
                                            const newHand = [...hand2Hole];
                                            newHand[i] = newCard;
                                            setHand2Hole(newHand);
                                        }}
                                        usedCards={usedCards}
                                    />
                                ))}
                            </div>
                        </div>
                    </div>

                    <div className="pt-8 flex justify-center">
                        <button 
                            onClick={evaluateHands}
                            disabled={loading || !testContract}
                            className="px-8 py-4 glass-card text-white text-xl font-medium rounded-xl hover:bg-opacity-20 transition-all disabled:opacity-50 disabled:cursor-not-allowed shadow-lg hover:shadow-2xl transform hover:-translate-y-1 duration-200 bg-gradient-to-r from-blue-500/20 to-purple-500/20"
                        >
                            {loading ? 'Evaluating...' : 'Compare Hands'}
                        </button>
                    </div>

                    {error && (
                        <div className="mt-6 p-4 glass-dark rounded-xl text-red-300 border border-red-500/30">
                            {error}
                        </div>
                    )}

                    {result && !error && (
                        <div className="mt-6 p-4 glass-dark rounded-xl text-green-300 text-center text-xl font-medium border border-green-500/30">
                            {result}
                        </div>
                    )}
                </div>
                <div className="flex justify-center mt-8">
                    <div className="flex items-center gap-2 text-white/60">
                        <span>Half cooked by</span>
                        <a
                            href="https://github.com/0xjba/cactus-kev-onchain"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="flex items-center gap-2 hover:text-white/80 transition-colors"
                        >
                            <Github className="w-5 h-5" />
                            <span>0xJba</span>
                        </a>
                    </div>
                </div>
            </div>
        </div>
    );
}

export default PokerEvaluator;
