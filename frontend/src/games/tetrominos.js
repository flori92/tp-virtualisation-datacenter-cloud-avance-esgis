/**
 * Définition des tetrominos (pièces du jeu Tetris)
 * Chaque tetromino est représenté par une matrice où:
 * - 0 représente une cellule vide
 * - Une lettre (I, J, L, O, S, T, Z) représente le type de tetromino
 */

export const TETROMINOS = {
  0: { shape: [[0]], color: '0' },
  I: {
    shape: [
      [0, 'I', 0, 0],
      [0, 'I', 0, 0],
      [0, 'I', 0, 0],
      [0, 'I', 0, 0]
    ],
    color: 'I',
  },
  J: {
    shape: [
      [0, 'J', 0],
      [0, 'J', 0],
      ['J', 'J', 0]
    ],
    color: 'J',
  },
  L: {
    shape: [
      [0, 'L', 0],
      [0, 'L', 0],
      [0, 'L', 'L']
    ],
    color: 'L',
  },
  O: {
    shape: [
      ['O', 'O'],
      ['O', 'O']
    ],
    color: 'O',
  },
  S: {
    shape: [
      [0, 'S', 'S'],
      ['S', 'S', 0],
      [0, 0, 0]
    ],
    color: 'S',
  },
  T: {
    shape: [
      [0, 0, 0],
      ['T', 'T', 'T'],
      [0, 'T', 0]
    ],
    color: 'T',
  },
  Z: {
    shape: [
      ['Z', 'Z', 0],
      [0, 'Z', 'Z'],
      [0, 0, 0]
    ],
    color: 'Z',
  }
};

/**
 * Fonction pour générer un tetromino aléatoire
 * @returns {Object} Un tetromino aléatoire
 */
export const createTetromino = () => {
  const tetrominos = 'IJLOSTZ';
  const randTetromino = tetrominos[Math.floor(Math.random() * tetrominos.length)];
  return TETROMINOS[randTetromino];
};
