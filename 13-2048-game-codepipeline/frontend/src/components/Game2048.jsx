import { useEffect } from 'react'
import './Game2048.css'

const Game2048 = ({ gameState, onMove, loading }) => {
  const { board, score, gameOver } = gameState

  useEffect(() => {
    const handleKeyPress = (e) => {
      if (loading || gameOver) return
      
      const keyMap = {
        'ArrowUp': 'up',
        'ArrowDown': 'down',
        'ArrowLeft': 'left',
        'ArrowRight': 'right'
      }
      
      if (keyMap[e.key]) {
        e.preventDefault()
        onMove(keyMap[e.key])
      }
    }

    window.addEventListener('keydown', handleKeyPress)
    return () => window.removeEventListener('keydown', handleKeyPress)
  }, [onMove, loading, gameOver])

  const getTileClass = (value) => {
    if (value === 0) return 'tile empty'
    return `tile tile-${value}`
  }

  return (
    <div className="game-container">
      <div className="game-header">
        <div className="score-container">
          <div className="score-label">Score</div>
          <div className="score">{score}</div>
        </div>
        {gameOver && (
          <div className="game-over">
            <div className="game-over-text">Game Over!</div>
          </div>
        )}
      </div>
      
      <div className={`game-grid ${loading ? 'loading' : ''}`}>
        {board.map((row, i) =>
          row.map((cell, j) => (
            <div
              key={`${i}-${j}`}
              className={getTileClass(cell)}
            >
              {cell !== 0 && cell}
            </div>
          ))
        )}
      </div>
      
      <div className="mobile-controls">
        <div className="control-row">
          <button 
            onClick={() => onMove('up')} 
            disabled={loading || gameOver}
            className="control-btn"
          >
            ↑
          </button>
        </div>
        <div className="control-row">
          <button 
            onClick={() => onMove('left')} 
            disabled={loading || gameOver}
            className="control-btn"
          >
            ←
          </button>
          <button 
            onClick={() => onMove('down')} 
            disabled={loading || gameOver}
            className="control-btn"
          >
            ↓
          </button>
          <button 
            onClick={() => onMove('right')} 
            disabled={loading || gameOver}
            className="control-btn"
          >
            →
          </button>
        </div>
      </div>
    </div>
  )
}

export default Game2048