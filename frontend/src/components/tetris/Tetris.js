import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import { createTetromino, TETROMINOS } from '../../games/tetrominos';
import { checkCollision, createStage } from '../../games/gameHelpers';

const Tetris = ({ playerName, onBackToMenu }) => {
  const [dropTime, setDropTime] = useState(null);
  const [gameOver, setGameOver] = useState(false);
  const [score, setScore] = useState(0);
  const [rows, setRows] = useState(0);
  const [level, setLevel] = useState(1);
  const [stage, setStage] = useState(createStage());
  const [player, setPlayer] = useState({
    pos: { x: 0, y: 0 },
    tetromino: createTetromino().shape,
    collided: false,
  });
  const [nextTetromino, setNextTetromino] = useState(createTetromino());
  const [scoreSaved, setScoreSaved] = useState(false);
  
  const canvasRef = useRef(null);
  const nextPieceCanvasRef = useRef(null);
  
  // Constantes pour le jeu
  const STAGE_WIDTH = 10;
  const STAGE_HEIGHT = 20;
  const CELL_SIZE = 30;
  
  // Couleurs des tetrominos
  const colors = {
    I: '#00FFFF', // Cyan
    J: '#0000FF', // Bleu
    L: '#FF8000', // Orange
    O: '#FFFF00', // Jaune
    S: '#00FF00', // Vert
    T: '#800080', // Violet
    Z: '#FF0000', // Rouge
    0: '#000000', // Noir (cellule vide)
  };

  // Fonction pour dessiner le stage
  const drawStage = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // Dessiner le fond
    ctx.fillStyle = '#000000';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    // Dessiner la grille
    ctx.strokeStyle = '#333333';
    ctx.lineWidth = 1;
    
    for (let i = 0; i <= STAGE_WIDTH; i++) {
      ctx.beginPath();
      ctx.moveTo(i * CELL_SIZE, 0);
      ctx.lineTo(i * CELL_SIZE, STAGE_HEIGHT * CELL_SIZE);
      ctx.stroke();
    }
    
    for (let i = 0; i <= STAGE_HEIGHT; i++) {
      ctx.beginPath();
      ctx.moveTo(0, i * CELL_SIZE);
      ctx.lineTo(STAGE_WIDTH * CELL_SIZE, i * CELL_SIZE);
      ctx.stroke();
    }
    
    // Dessiner les cellules
    stage.forEach((row, y) => {
      row.forEach((cell, x) => {
        if (cell[0] !== 0) {
          ctx.fillStyle = colors[cell[0]];
          ctx.fillRect(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE);
          
          // Ajouter un effet 3D
          ctx.fillStyle = 'rgba(255, 255, 255, 0.3)';
          ctx.fillRect(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, 5);
          ctx.fillRect(x * CELL_SIZE, y * CELL_SIZE, 5, CELL_SIZE);
          
          ctx.fillStyle = 'rgba(0, 0, 0, 0.3)';
          ctx.fillRect(x * CELL_SIZE + CELL_SIZE - 5, y * CELL_SIZE, 5, CELL_SIZE);
          ctx.fillRect(x * CELL_SIZE, y * CELL_SIZE + CELL_SIZE - 5, CELL_SIZE, 5);
        }
      });
    });
  };
  
  // Fonction pour dessiner la prochaine pièce
  const drawNextPiece = () => {
    const canvas = nextPieceCanvasRef.current;
    if (!canvas) return;
    
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // Dessiner le fond
    ctx.fillStyle = '#000000';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    // Calculer le décalage pour centrer la pièce
    const shape = nextTetromino.shape;
    const width = shape[0].length;
    const height = shape.length;
    const offsetX = (4 - width) / 2;
    const offsetY = (4 - height) / 2;
    
    // Dessiner la pièce
    shape.forEach((row, y) => {
      row.forEach((value, x) => {
        if (value !== 0) {
          ctx.fillStyle = colors[value];
          ctx.fillRect(
            (x + offsetX) * CELL_SIZE, 
            (y + offsetY) * CELL_SIZE, 
            CELL_SIZE, 
            CELL_SIZE
          );
          
          // Ajouter un effet 3D
          ctx.fillStyle = 'rgba(255, 255, 255, 0.3)';
          ctx.fillRect((x + offsetX) * CELL_SIZE, (y + offsetY) * CELL_SIZE, CELL_SIZE, 5);
          ctx.fillRect((x + offsetX) * CELL_SIZE, (y + offsetY) * CELL_SIZE, 5, CELL_SIZE);
          
          ctx.fillStyle = 'rgba(0, 0, 0, 0.3)';
          ctx.fillRect((x + offsetX) * CELL_SIZE + CELL_SIZE - 5, (y + offsetY) * CELL_SIZE, 5, CELL_SIZE);
          ctx.fillRect((x + offsetX) * CELL_SIZE, (y + offsetY) * CELL_SIZE + CELL_SIZE - 5, CELL_SIZE, 5);
        }
      });
    });
  };

  // Mettre à jour le stage
  useEffect(() => {
    const sweepRows = (newStage) => {
      let rowsCleared = 0;
      return [
        newStage.reduce((acc, row) => {
          if (row.findIndex(cell => cell[0] === 0) === -1) {
            rowsCleared += 1;
            acc.unshift(new Array(newStage[0].length).fill([0, 'clear']));
            return acc;
          }
          acc.push(row);
          return acc;
        }, []),
        rowsCleared,
      ];
    };

    const updateStage = prevStage => {
      // Effacer le stage précédent
      const newStage = prevStage.map(row =>
        row.map(cell => (cell[1] === 'clear' ? [0, 'clear'] : cell))
      );

      // Dessiner le tetromino
      player.tetromino.forEach((row, y) => {
        row.forEach((value, x) => {
          if (value !== 0) {
            newStage[y + player.pos.y][x + player.pos.x] = [
              value,
              player.collided ? 'merged' : 'clear',
            ];
          }
        });
      });

      // Vérifier si on a touché quelque chose
      if (player.collided) {
        const [sweptStage, rowsCleared] = sweepRows(newStage);
        
        // Mettre à jour le score et les lignes
        if (rowsCleared > 0) {
          setRows(prev => prev + rowsCleared);
          setScore(prev => prev + (rowsCleared === 1 ? 40 : rowsCleared === 2 ? 100 : rowsCleared === 3 ? 300 : 1200) * level);
        }
        
        resetPlayer();
        return sweptStage;
      }

      return newStage;
    };

    setStage(prev => updateStage(prev));
  }, [player]);

  // Dessiner le stage et la prochaine pièce
  useEffect(() => {
    drawStage();
    drawNextPiece();
  }, [stage, nextTetromino]);

  // Mettre à jour le niveau en fonction du nombre de lignes
  useEffect(() => {
    const linePerLevel = 10;
    if (rows > level * linePerLevel) {
      setLevel(prev => prev + 1);
      // Augmenter la vitesse de chute
      setDropTime(1000 / level);
    }
  }, [rows, level]);

  // Gérer la chute automatique
  useEffect(() => {
    if (!gameOver) {
      const interval = setInterval(() => {
        drop();
      }, dropTime || 1000);
      
      return () => {
        clearInterval(interval);
      };
    }
  }, [dropTime, gameOver]);

  // Gérer les contrôles clavier
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (!gameOver) {
        if (e.keyCode === 37) { // Gauche
          movePlayer(-1);
        } else if (e.keyCode === 39) { // Droite
          movePlayer(1);
        } else if (e.keyCode === 40) { // Bas
          dropPlayer();
        } else if (e.keyCode === 38) { // Haut (rotation)
          rotatePlayer();
        } else if (e.keyCode === 32) { // Espace (chute instantanée)
          hardDrop();
        }
      }
    };
    
    document.addEventListener('keydown', handleKeyDown);
    
    return () => {
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [gameOver, player]);

  // Sauvegarder le score en fin de partie
  useEffect(() => {
    const saveScore = async () => {
      if (gameOver && !scoreSaved && score > 0) {
        try {
          await axios.post('/api/scores', {
            playerName,
            score,
          });
          setScoreSaved(true);
        } catch (err) {
          console.error('Erreur lors de l\'enregistrement du score:', err);
        }
      }
    };
    
    saveScore();
  }, [gameOver, scoreSaved, playerName, score]);

  // Réinitialiser le joueur
  const resetPlayer = () => {
    const newTetromino = nextTetromino;
    setNextTetromino(createTetromino());
    
    setPlayer({
      pos: { x: STAGE_WIDTH / 2 - 2, y: 0 },
      tetromino: newTetromino.shape,
      collided: false,
    });
    
    // Vérifier si le jeu est terminé
    if (checkCollision(newTetromino.shape, { x: STAGE_WIDTH / 2 - 2, y: 0 }, stage)) {
      setGameOver(true);
      setDropTime(null);
    }
  };

  // Déplacer le joueur horizontalement
  const movePlayer = (dir) => {
    if (!checkCollision(player.tetromino, { x: player.pos.x + dir, y: player.pos.y }, stage)) {
      setPlayer(prev => ({
        ...prev,
        pos: { ...prev.pos, x: prev.pos.x + dir },
      }));
    }
  };

  // Faire descendre le joueur
  const drop = () => {
    if (!checkCollision(player.tetromino, { x: player.pos.x, y: player.pos.y + 1 }, stage)) {
      setPlayer(prev => ({
        ...prev,
        pos: { ...prev.pos, y: prev.pos.y + 1 },
        collided: false,
      }));
    } else {
      // Collision détectée
      setPlayer(prev => ({
        ...prev,
        collided: true,
      }));
    }
  };

  // Faire descendre le joueur plus rapidement
  const dropPlayer = () => {
    drop();
  };

  // Chute instantanée
  const hardDrop = () => {
    let newY = player.pos.y;
    while (!checkCollision(player.tetromino, { x: player.pos.x, y: newY + 1 }, stage)) {
      newY += 1;
    }
    
    setPlayer(prev => ({
      ...prev,
      pos: { ...prev.pos, y: newY },
      collided: true,
    }));
  };

  // Rotation du joueur
  const rotatePlayer = () => {
    const rotate = (matrix) => {
      // Transposer la matrice
      const rotated = matrix.map((_, index) =>
        matrix.map(col => col[index])
      );
      // Inverser les colonnes
      return rotated.map(row => row.reverse());
    };
    
    const rotatedTetromino = rotate(player.tetromino);
    
    // Vérifier si la rotation est possible
    if (!checkCollision(rotatedTetromino, player.pos, stage)) {
      setPlayer(prev => ({
        ...prev,
        tetromino: rotatedTetromino,
      }));
    }
  };

  // Démarrer une nouvelle partie
  const startGame = () => {
    setStage(createStage());
    setDropTime(1000);
    setGameOver(false);
    setScore(0);
    setRows(0);
    setLevel(1);
    setScoreSaved(false);
    
    const firstTetromino = createTetromino();
    const secondTetromino = createTetromino();
    
    setNextTetromino(secondTetromino);
    setPlayer({
      pos: { x: STAGE_WIDTH / 2 - 2, y: 0 },
      tetromino: firstTetromino.shape,
      collided: false,
    });
  };

  return (
    <div className="game-container">
      <div>
        <canvas
          ref={canvasRef}
          width={STAGE_WIDTH * CELL_SIZE}
          height={STAGE_HEIGHT * CELL_SIZE}
          style={{ border: '2px solid #61dafb' }}
        />
        
        {gameOver && (
          <div className="game-over">
            <h2>Game Over!</h2>
            <p>Votre score: {score}</p>
            <button onClick={startGame}>Nouvelle partie</button>
            <button onClick={onBackToMenu}>Retour au menu</button>
          </div>
        )}
      </div>
      
      <div className="game-info">
        <h2>Joueur: {playerName}</h2>
        <p>Score: {score}</p>
        <p>Lignes: {rows}</p>
        <p>Niveau: {level}</p>
        
        <div>
          <h3>Prochaine pièce:</h3>
          <div className="next-piece-container">
            <canvas
              ref={nextPieceCanvasRef}
              width={4 * CELL_SIZE}
              height={4 * CELL_SIZE}
            />
          </div>
        </div>
        
        {!gameOver ? (
          <button onClick={() => setGameOver(true)}>Abandonner</button>
        ) : (
          <button onClick={startGame}>Nouvelle partie</button>
        )}
      </div>
    </div>
  );
};

export default Tetris;
