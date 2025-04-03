import React from 'react';

const HangmanDrawing = ({ wrongLetters }) => {
  const mistakes = wrongLetters.length;
  
  return (
    <div className="hangman-drawing">
      {/* Potence */}
      <div className="hangman-stand" style={{ 
        width: '10px', 
        height: '300px', 
        backgroundColor: '#333',
        position: 'absolute',
        left: '120px'
      }} />
      
      <div className="hangman-top" style={{ 
        width: '150px', 
        height: '10px', 
        backgroundColor: '#333',
        position: 'absolute',
        top: '0',
        right: '120px'
      }} />
      
      <div className="hangman-rope" style={{ 
        width: '10px', 
        height: '40px', 
        backgroundColor: '#333',
        position: 'absolute',
        top: '0',
        right: '120px'
      }} />
      
      {/* Tête */}
      {mistakes >= 1 && (
        <div className="hangman-head" style={{ 
          width: '50px', 
          height: '50px', 
          borderRadius: '50%',
          border: '10px solid #333',
          position: 'absolute',
          top: '40px',
          right: '95px'
        }} />
      )}
      
      {/* Corps */}
      {mistakes >= 2 && (
        <div className="hangman-body" style={{ 
          width: '10px', 
          height: '100px', 
          backgroundColor: '#333',
          position: 'absolute',
          top: '100px',
          right: '120px'
        }} />
      )}
      
      {/* Bras gauche */}
      {mistakes >= 3 && (
        <div className="hangman-arm-left" style={{ 
          width: '70px', 
          height: '10px', 
          backgroundColor: '#333',
          position: 'absolute',
          top: '120px',
          right: '130px',
          rotate: '-30deg',
          transformOrigin: 'right bottom'
        }} />
      )}
      
      {/* Bras droit */}
      {mistakes >= 4 && (
        <div className="hangman-arm-right" style={{ 
          width: '70px', 
          height: '10px', 
          backgroundColor: '#333',
          position: 'absolute',
          top: '120px',
          right: '50px',
          rotate: '30deg',
          transformOrigin: 'left bottom'
        }} />
      )}
      
      {/* Jambe gauche */}
      {mistakes >= 5 && (
        <div className="hangman-leg-left" style={{ 
          width: '70px', 
          height: '10px', 
          backgroundColor: '#333',
          position: 'absolute',
          top: '200px',
          right: '130px',
          rotate: '-30deg',
          transformOrigin: 'right top'
        }} />
      )}
      
      {/* Jambe droite */}
      {mistakes >= 6 && (
        <div className="hangman-leg-right" style={{ 
          width: '70px', 
          height: '10px', 
          backgroundColor: '#333',
          position: 'absolute',
          top: '200px',
          right: '50px',
          rotate: '30deg',
          transformOrigin: 'left top'
        }} />
      )}
    </div>
  );
};

export default HangmanDrawing;
