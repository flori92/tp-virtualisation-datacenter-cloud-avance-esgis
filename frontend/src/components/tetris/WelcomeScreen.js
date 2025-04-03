import React, { useState } from 'react';

const WelcomeScreen = ({ onStartGame, onShowLeaderboard }) => {
  const [playerName, setPlayerName] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    if (playerName.trim() === '') {
      setError('Veuillez entrer votre nom pour commencer');
      return;
    }
    onStartGame(playerName);
  };

  return (
    <div className="welcome-screen">
      <h2>Bienvenue au jeu Tetris</h2>
      
      <form onSubmit={handleSubmit}>
        <div>
          <input
            type="text"
            placeholder="Entrez votre nom"
            value={playerName}
            onChange={(e) => setPlayerName(e.target.value)}
          />
        </div>
        {error && <p style={{ color: 'red' }}>{error}</p>}
        <div>
          <button type="submit">Commencer à jouer</button>
          <button type="button" onClick={onShowLeaderboard}>Voir le classement</button>
        </div>
      </form>

      <div className="controls-info">
        <h3>Contrôles :</h3>
        <ul>
          <li>← → : Déplacer la pièce</li>
          <li>↑ : Rotation</li>
          <li>↓ : Descente rapide</li>
          <li>Espace : Chute instantanée</li>
        </ul>
      </div>
    </div>
  );
};

export default WelcomeScreen;
