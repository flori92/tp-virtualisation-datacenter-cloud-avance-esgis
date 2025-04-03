import React from 'react';

const HangmanWord = ({ word, guessedLetters, reveal }) => {
  return (
    <div className="hangman-word">
      {word.split('').map((letter, index) => (
        <span className="letter-container" key={index}>
          <span 
            className={`letter ${guessedLetters.includes(letter) || reveal ? 'visible' : 'hidden'} ${
              reveal && !guessedLetters.includes(letter) ? 'incorrect' : ''
            }`}
          >
            {letter}
          </span>
          <span className="underscore">_</span>
        </span>
      ))}
    </div>
  );
};

export default HangmanWord;
