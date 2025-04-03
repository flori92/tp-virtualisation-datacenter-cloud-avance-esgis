const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
require('dotenv').config();

// Initialisation de l'application Express
const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Connexion à MongoDB
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://mongodb-service:27017/games';

mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log('Connexion à MongoDB établie'))
  .catch(err => {
    console.error('Erreur de connexion à MongoDB:', err);
    // Ne pas quitter le processus pour permettre les tentatives de reconnexion
    // dans un environnement Kubernetes
  });

// Modèle de données pour les scores
const scoreSchema = new mongoose.Schema({
  playerName: {
    type: String,
    required: true,
    trim: true
  },
  score: {
    type: Number,
    required: true
  },
  game: {
    type: String,
    enum: ['tetris', 'hangman'],
    default: 'tetris',
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

const Score = mongoose.model('Score', scoreSchema);

// Routes API
app.get('/api/scores', async (req, res) => {
  try {
    const { game } = req.query;
    let query = {};
    
    // Filtrer par jeu si spécifié
    if (game && game !== 'all') {
      query.game = game;
    }
    
    const scores = await Score.find(query)
      .sort({ score: -1 })
      .limit(10);
    res.json(scores);
  } catch (err) {
    console.error('Erreur lors de la récupération des scores:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

app.post('/api/scores', async (req, res) => {
  try {
    const { playerName, score, game = 'tetris' } = req.body;
    
    if (!playerName || !score) {
      return res.status(400).json({ message: 'Le nom du joueur et le score sont requis' });
    }
    
    const newScore = new Score({
      playerName,
      score: Number(score),
      game
    });
    
    await newScore.save();
    res.status(201).json(newScore);
  } catch (err) {
    console.error('Erreur lors de l\'enregistrement du score:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// Route de santé pour Kubernetes
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Route de test
app.get('/', (req, res) => {
  res.json({ message: 'API de jeux fonctionnelle', games: ['tetris', 'hangman'] });
});

// Démarrage du serveur
app.listen(PORT, () => {
  console.log(`Serveur démarré sur le port ${PORT}`);
});
