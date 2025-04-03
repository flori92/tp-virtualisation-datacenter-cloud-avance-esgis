import React, { useState, useEffect } from 'react';
import axios from 'axios';

const GlobalLeaderboard = ({ gameFilter = 'all', onBackToMenu }) => {
  const [scores, setScores] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Récupération des scores depuis l'API backend
  useEffect(() => {
    const fetchScores = async () => {
      try {
        setLoading(true);
        // L'URL de l'API est définie pour fonctionner avec Kubernetes
        let url = '/api/scores';
        if (gameFilter !== 'all') {
          url += `?game=${gameFilter}`;
        }
        
        const response = await axios.get(url);
        setScores(response.data);
        setLoading(false);
      } catch (err) {
        console.error('Erreur lors de la récupération des scores:', err);
        setError('Impossible de charger le classement. Veuillez réessayer plus tard.');
        setLoading(false);
      }
    };

    fetchScores();
  }, [gameFilter]);

  const getGameTitle = () => {
    switch (gameFilter) {
      case 'tetris':
        return 'Tetris';
      case 'hangman':
        return 'Pendu';
      default:
        return 'Global';
    }
  };

  if (loading) {
    return <div>Chargement du classement...</div>;
  }

  if (error) {
    return <div style={{ color: 'red' }}>{error}</div>;
  }

  return (
    <div className="global-leaderboard">
      <h2>Classement {getGameTitle()}</h2>
      {scores.length === 0 ? (
        <p>Aucun score enregistré pour le moment.</p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>Rang</th>
              <th>Joueur</th>
              <th>Jeu</th>
              <th>Score</th>
              <th>Date</th>
            </tr>
          </thead>
          <tbody>
            {scores.map((score, index) => (
              <tr key={score._id}>
                <td>{index + 1}</td>
                <td>{score.playerName}</td>
                <td>{score.game === 'tetris' ? 'Tetris' : 'Pendu'}</td>
                <td>{score.score}</td>
                <td>{new Date(score.createdAt).toLocaleDateString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
      
      <button onClick={onBackToMenu} className="back-button">
        Retour au menu
      </button>
    </div>
  );
};

export default GlobalLeaderboard;
