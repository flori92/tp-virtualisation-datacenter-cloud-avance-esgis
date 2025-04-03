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
      <h2>Bienvenue au jeu du Pendu</h2>
      
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

      <div className="rules-info">
        <h3>Règles du jeu :</h3>
        <ul>
          <li>Devinez le mot caché en proposant des lettres</li>
          <li>Chaque lettre incorrecte ajoute un élément au pendu</li>
          <li>Vous avez droit à 6 erreurs avant de perdre</li>
          <li>Votre score dépend de la difficulté du mot et du nombre d'erreurs</li>
        </ul>
      </div>
    </div>
  );
};

export default WelcomeScreen;
