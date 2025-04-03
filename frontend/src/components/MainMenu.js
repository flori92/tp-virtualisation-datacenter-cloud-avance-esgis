import React, { useState } from 'react';

const MainMenu = ({ onSelectGame, onShowLeaderboard }) => {
  const [playerName, setPlayerName] = useState('');
  const [error, setError] = useState('');

  const handleStartGame = (game) => {
    if (playerName.trim() === '') {
      setError('Veuillez entrer votre nom pour commencer');
      return;
    }
    onSelectGame(game, playerName);
  };

  return (
    <div className="main-menu">
      <h1>TP VIRTUALISATION DATACENTER ET CLOUD AVANCÉ ESGIS M1IRT</h1>
      <h2>Choisissez votre jeu</h2>
      
      <div className="player-name-input">
        <input
          type="text"
          placeholder="Entrez votre nom"
          value={playerName}
          onChange={(e) => setPlayerName(e.target.value)}
        />
        {error && <p className="error-message">{error}</p>}
      </div>
      
      <div className="game-selection">
        <div className="game-card" onClick={() => handleStartGame('tetris')}>
          <h3>Tetris</h3>
          <p>Le jeu de puzzle classique</p>
          <div className="game-preview tetris-preview">
            <div className="tetris-block"></div>
            <div className="tetris-block"></div>
            <div className="tetris-block"></div>
            <div className="tetris-block"></div>
          </div>
        </div>
        
        <div className="game-card" onClick={() => handleStartGame('hangman')}>
          <h3>Pendu</h3>
          <p>Devinez le mot caché</p>
          <div className="game-preview hangman-preview">
            <div className="hangman-icon">
              <div className="hangman-head"></div>
              <div className="hangman-body"></div>
              <div className="hangman-arms"></div>
              <div className="hangman-legs"></div>
            </div>
          </div>
        </div>
      </div>
      
      <div className="leaderboard-buttons">
        <button onClick={() => onShowLeaderboard('all')}>Classement Global</button>
        <button onClick={() => onShowLeaderboard('tetris')}>Classement Tetris</button>
        <button onClick={() => onShowLeaderboard('hangman')}>Classement Pendu</button>
      </div>
      
      <div className="tp-info">
        <h3>À propos de ce TP</h3>
        <p>
          Ce TP a pour objectif de vous familiariser avec les concepts avancés de virtualisation, 
          de conteneurisation et d'orchestration en utilisant Docker et Kubernetes.
        </p>
        <p>
          L'application est composée de trois microservices :
        </p>
        <ul>
          <li>Frontend (React) - Interface utilisateur des jeux</li>
          <li>Backend (Node.js/Express) - API pour la gestion des scores</li>
          <li>Base de données (MongoDB) - Stockage persistant des scores</li>
        </ul>
      </div>
    </div>
  );
};

export default MainMenu;
