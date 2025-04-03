import React, { useState } from 'react';
import MainMenu from './components/MainMenu';
import GlobalLeaderboard from './components/GlobalLeaderboard';
import Tetris from './components/tetris/Tetris';
import HangmanGame from './components/hangman/Hangman';
import './index.css';

function App() {
  const [currentScreen, setCurrentScreen] = useState('menu');
  const [playerName, setPlayerName] = useState('');
  const [leaderboardType, setLeaderboardType] = useState('all');

  const handleSelectGame = (game, name) => {
    setPlayerName(name);
    setCurrentScreen(game);
  };

  const handleShowLeaderboard = (type) => {
    setLeaderboardType(type);
    setCurrentScreen('leaderboard');
  };

  const handleBackToMenu = () => {
    setCurrentScreen('menu');
  };

  return (
    <div className="App">
      {currentScreen === 'menu' && (
        <MainMenu 
          onSelectGame={handleSelectGame} 
          onShowLeaderboard={handleShowLeaderboard} 
        />
      )}
      
      {currentScreen === 'tetris' && (
        <Tetris 
          playerName={playerName} 
          onBackToMenu={handleBackToMenu}
        />
      )}
      
      {currentScreen === 'hangman' && (
        <HangmanGame 
          playerName={playerName} 
          onBackToMenu={handleBackToMenu}
        />
      )}
      
      {currentScreen === 'leaderboard' && (
        <GlobalLeaderboard 
          gameFilter={leaderboardType}
          onBackToMenu={handleBackToMenu}
        />
      )}
    </div>
  );
}

export default App;
