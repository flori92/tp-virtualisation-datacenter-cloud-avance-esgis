import React from 'react';

const KEYS = [
  ['A', 'Z', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
  ['Q', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M'],
  ['W', 'X', 'C', 'V', 'B', 'N']
];

const Keyboard = ({ activeLetters, inactiveLetters, disabled, onLetterClick }) => {
  return (
    <div className="keyboard">
      {KEYS.map((row, rowIndex) => (
        <div key={rowIndex} className="keyboard-row">
          {row.map(key => {
            const isActive = activeLetters.includes(key);
            const isInactive = inactiveLetters.includes(key);
            
            return (
              <button
                key={key}
                className={`key ${isActive ? 'active' : ''} ${isInactive ? 'inactive' : ''}`}
                disabled={isActive || isInactive || disabled}
                onClick={() => onLetterClick(key)}
              >
                {key}
              </button>
            );
          })}
        </div>
      ))}
    </div>
  );
};

export default Keyboard;
