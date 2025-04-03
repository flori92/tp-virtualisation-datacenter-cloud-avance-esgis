/**
 * Constantes pour les dimensions du jeu
 */
export const STAGE_WIDTH = 10;
export const STAGE_HEIGHT = 20;

/**
 * Crée un stage vide (la grille de jeu)
 * @returns {Array} Une matrice 2D représentant le stage
 */
export const createStage = () =>
  Array.from(Array(STAGE_HEIGHT), () =>
    new Array(STAGE_WIDTH).fill([0, 'clear'])
  );

/**
 * Vérifie s'il y a une collision
 * @param {Array} tetromino - La forme du tetromino
 * @param {Object} pos - La position {x, y} du tetromino
 * @param {Array} stage - L'état actuel du stage
 * @returns {boolean} True s'il y a collision, false sinon
 */
export const checkCollision = (tetromino, pos, stage) => {
  for (let y = 0; y < tetromino.length; y += 1) {
    for (let x = 0; x < tetromino[y].length; x += 1) {
      // 1. Vérifier que nous sommes sur une cellule du tetromino
      if (tetromino[y][x] !== 0) {
        if (
          // 2. Vérifier que notre mouvement est dans les limites de la hauteur du stage (y)
          !stage[y + pos.y] ||
          // 3. Vérifier que notre mouvement est dans les limites de la largeur du stage (x)
          !stage[y + pos.y][x + pos.x] ||
          // 4. Vérifier que la cellule vers laquelle nous nous déplaçons n'est pas définie comme 'clear'
          stage[y + pos.y][x + pos.x][1] !== 'clear'
        ) {
          return true;
        }
      }
    }
  }
  return false;
};
