import React, { useState, useEffect } from 'react';
import HangmanDrawing from './HangmanDrawing';
import HangmanWord from './HangmanWord';
import Keyboard from './Keyboard';
import { getRandomWord, calculateScore } from '../../games/hangmanHelpers';
import axios from 'axios';

const Hangman = ({ playerName, onBackToMenu }) => {
  const [word, setWord] = useState('');
  const [guessedLetters, setGuessedLetters] = useState([]);
  const [wrongLetters, setWrongLetters] = useState([]);
  const [gameOver, setGameOver] = useState(false);
  const [gameWon, setGameWon] = useState(false);
  const [score, setScore] = useState(0);
  const [totalScore, setTotalScore] = useState(0);
  const [scoreSaved, setScoreSaved] = useState(false);
  const [consecutiveWins, setConsecutiveWins] = useState(0);
  
  // Nombre maximum d'erreurs avant de perdre
  const MAX_MISTAKES = 6;
  
  // Initialiser le jeu
  useEffect(() => {
    startGame();
  }, []);
  
  // Sauvegarder le score en fin de partie
  useEffect(() => {
    const saveScore = async () => {
      if (gameOver && !scoreSaved && totalScore > 0) {
        try {
          await axios.post('/api/scores', {
            playerName,
            score: totalScore,
            game: 'hangman'
          });
          setScoreSaved(true);
        } catch (err) {
          console.error('Erreur lors de l\'enregistrement du score:', err);
        }
      }
    };
    
    saveScore();
  }, [gameOver, scoreSaved, playerName, totalScore]);
  
  // Démarrer une nouvelle partie
  const startGame = () => {
    const newWord = getRandomWord();
    setWord(newWord);
    setGuessedLetters([]);
    setWrongLetters([]);
    setGameOver(false);
    setGameWon(false);
    setScore(0);
    
    // Ne réinitialise pas le score total lors d'une nouvelle partie
    if (scoreSaved) {
      setTotalScore(0);
      setConsecutiveWins(0);
      setScoreSaved(false);
    }
  };
  
  // Continuer avec un nouveau mot après une victoire
  const continueGame = () => {
    const newWord = getRandomWord();
    setWord(newWord);
    setGuessedLetters([]);
    setWrongLetters([]);
    setGameWon(false);
  };
  
  // Gérer les lettres devinées
  const handleGuess = (letter) => {
    if (gameOver || gameWon) return;
    
    // Si la lettre a déjà été devinée, ne rien faire
    if (guessedLetters.includes(letter)) return;
    
    // Ajouter la lettre aux lettres devinées
    setGuessedLetters(prev => [...prev, letter]);
    
    // Vérifier si la lettre est dans le mot
    if (!word.includes(letter)) {
      setWrongLetters(prev => [...prev, letter]);
      
      // Vérifier si le joueur a perdu
      if (wrongLetters.length + 1 >= MAX_MISTAKES) {
        setGameOver(true);
        // Le score total reste inchangé en cas de défaite
      }
    } else {
      // Vérifier si le joueur a gagné
      const uniqueLettersInWord = [...new Set(word.split(''))];
      const correctGuesses = uniqueLettersInWord.filter(char => 
        guessedLetters.includes(char) || letter === char
      );
      
      if (correctGuesses.length === uniqueLettersInWord.length) {
        setGameWon(true);
        const roundScore = calculateScore(word, [...guessedLetters, letter], wrongLetters.length);
        setScore(roundScore);
        
        // Augmenter le nombre de victoires consécutives
        setConsecutiveWins(prev => prev + 1);
        
        // Ajouter un bonus pour les victoires consécutives (10% par victoire)
        const consecutiveBonus = Math.floor(roundScore * (0.1 * (consecutiveWins + 1)));
        
        // Mettre à jour le score total
        setTotalScore(prev => prev + roundScore + consecutiveBonus);
      }
    }
  };
  
  return (
    <div className="hangman-container">
      <h2>Jeu du Pendu</h2>
      <p>Joueur: {playerName}</p>
      <p>Score Total: {totalScore}</p>
      {consecutiveWins > 0 && <p>Victoires consécutives: {consecutiveWins}</p>}
      
      <div className="hangman-game">
        <HangmanDrawing wrongLetters={wrongLetters} />
        
        <HangmanWord 
          word={word} 
          guessedLetters={guessedLetters} 
          reveal={gameOver} 
        />
        
        <div className="keyboard-container">
          <Keyboard 
            disabled={gameOver || gameWon}
            activeLetters={guessedLetters.filter(letter => word.includes(letter))}
            inactiveLetters={wrongLetters}
            onLetterClick={handleGuess}
          />
        </div>
        
        {gameOver && (
          <div className="game-result">
            <h3>Dommage!</h3>
            <p>Le mot était: {word}</p>
            <p>Score Total: {totalScore}</p>
            <div>
              <button onClick={startGame}>Nouvelle partie</button>
              <button onClick={onBackToMenu}>Retour au menu</button>
            </div>
          </div>
        )}
        
        {gameWon && (
          <div className="game-result">
            <h3>Félicitations!</h3>
            <p>Vous avez trouvé le mot: {word}</p>
            <p>Score de cette manche: {score}</p>
            <p>Score Total: {totalScore}</p>
            <div>
              <button onClick={continueGame}>Continuer</button>
              <button onClick={onBackToMenu}>Retour au menu</button>
            </div>
          </div>
        )}
      </div>
      
      {!gameOver && !gameWon && (
        <button onClick={() => setGameOver(true)}>Abandonner</button>
      )}
    </div>
  );
};

export default Hangman;
