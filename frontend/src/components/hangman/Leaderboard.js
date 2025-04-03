import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Leaderboard = () => {
  const [scores, setScores] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Récupération des scores depuis l'API backend
  useEffect(() => {
    const fetchScores = async () => {
      try {
        setLoading(true);
        // L'URL de l'API est définie pour fonctionner avec Kubernetes
        // En développement local, vous pouvez utiliser http://localhost:5000/api/scores?game=hangman
        const response = await axios.get('/api/scores?game=hangman');
        setScores(response.data);
        setLoading(false);
      } catch (err) {
        console.error('Erreur lors de la récupération des scores:', err);
        setError('Impossible de charger le classement. Veuillez réessayer plus tard.');
        setLoading(false);
      }
    };

    fetchScores();
  }, []);

  if (loading) {
    return <div>Chargement du classement...</div>;
  }

  if (error) {
    return <div style={{ color: 'red' }}>{error}</div>;
  }

  return (
    <div className="leaderboard">
      <h2>Classement du Pendu</h2>
      {scores.length === 0 ? (
        <p>Aucun score enregistré pour le moment.</p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>Rang</th>
              <th>Joueur</th>
              <th>Score</th>
              <th>Date</th>
            </tr>
          </thead>
          <tbody>
            {scores.map((score, index) => (
              <tr key={score._id}>
                <td>{index + 1}</td>
                <td>{score.playerName}</td>
                <td>{score.score}</td>
                <td>{new Date(score.createdAt).toLocaleDateString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
};

export default Leaderboard;
