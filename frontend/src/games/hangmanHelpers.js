/**
 * Liste de mots pour le jeu du pendu
 * Différentes catégories de difficulté
 */
const WORDS = {
  easy: [
    'CHAT', 'CHIEN', 'MAISON', 'ARBRE', 'FLEUR', 'LIVRE', 'TABLE', 'PORTE',
    'ROUTE', 'POMME', 'BANANE', 'ORANGE', 'SOLEIL', 'LUNE', 'ETOILE', 'NUAGE',
    'PLUIE', 'NEIGE', 'VENT', 'FROID', 'CHAUD', 'JOUR', 'NUIT', 'MATIN',
    'SOIR', 'ECOLE', 'CRAYON', 'CAHIER', 'STYLO', 'GOMME'
  ],
  medium: [
    'ORDINATEUR', 'TELEPHONE', 'TELEVISION', 'INTERNET', 'CLAVIER', 'SOURIS',
    'MONTAGNE', 'RIVIERE', 'OCEAN', 'FORET', 'DESERT', 'PLAGE', 'VOYAGE',
    'VOITURE', 'AVION', 'TRAIN', 'BATEAU', 'VELO', 'CUISINE', 'CHAMBRE',
    'JARDIN', 'PISCINE', 'RESTAURANT', 'CINEMA', 'MUSIQUE', 'DANSE', 'SPORT',
    'FOOTBALL', 'TENNIS', 'NATATION'
  ],
  hard: [
    'ANTICONSTITUTIONNELLEMENT', 'PSYCHOPHYSIOLOGIQUE', 'ELECTROCARDIOGRAMME',
    'INCOMPREHENSIBLE', 'EXTRAORDINAIRE', 'DEVELOPPEMENT', 'ARCHITECTURE',
    'GOUVERNEMENT', 'INTERNATIONAL', 'ENVIRONNEMENT', 'TECHNOLOGIE', 'PHILOSOPHIE',
    'INTELLIGENCE', 'EXPERIENCE', 'CONNAISSANCE', 'IMAGINATION', 'COMMUNICATION',
    'AUTHENTIFICATION', 'INFRASTRUCTURE', 'VIRTUALISATION', 'KUBERNETES', 'MICROSERVICE',
    'ORCHESTRATION', 'CONTENEURISATION', 'PERSISTANCE', 'REPLICATION', 'SCALABILITE',
    'DISPONIBILITE', 'DEPLOIEMENT', 'CONFIGURATION'
  ]
};

/**
 * Sélectionne un mot aléatoire dans la liste
 * @returns {string} Un mot aléatoire
 */
export const getRandomWord = () => {
  // Choisir une catégorie aléatoire
  const categories = Object.keys(WORDS);
  const randomCategory = categories[Math.floor(Math.random() * categories.length)];
  
  // Choisir un mot aléatoire dans la catégorie
  const wordsInCategory = WORDS[randomCategory];
  const randomIndex = Math.floor(Math.random() * wordsInCategory.length);
  
  return wordsInCategory[randomIndex];
};

/**
 * Calcule le score en fonction de la difficulté du mot et du nombre d'erreurs
 * @param {string} word - Le mot à deviner
 * @param {Array} guessedLetters - Les lettres devinées
 * @param {number} mistakes - Le nombre d'erreurs
 * @returns {number} Le score calculé
 */
export const calculateScore = (word, guessedLetters, mistakes) => {
  // Facteurs de difficulté
  let difficultyFactor;
  if (word.length <= 5) {
    difficultyFactor = 1;
  } else if (word.length <= 8) {
    difficultyFactor = 2;
  } else if (word.length <= 12) {
    difficultyFactor = 3;
  } else {
    difficultyFactor = 4;
  }
  
  // Calculer le nombre de lettres correctement devinées
  const uniqueLettersInWord = [...new Set(word.split(''))];
  const correctGuesses = uniqueLettersInWord.filter(char => guessedLetters.includes(char));
  
  // Bonus pour les lettres correctes
  const correctLetterBonus = correctGuesses.length * 10;
  
  // Pénalité pour les erreurs
  const mistakePenalty = mistakes * 5;
  
  // Score de base pour avoir terminé le mot
  const baseScore = word.length * 10;
  
  // Bonus pour avoir gagné (si toutes les lettres sont devinées)
  const winBonus = correctGuesses.length === uniqueLettersInWord.length ? 50 : 0;
  
  // Calculer le score final
  const score = (baseScore + correctLetterBonus - mistakePenalty + winBonus) * difficultyFactor;
  
  // Assurer un score minimum de 0
  return Math.max(0, score);
};
