import { useState, useEffect } from 'react'
import Game2048 from './components/Game2048'
import './App.css'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080'

function App() {
  const [gameState, setGameState] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const startNewGame = async () => {
    setLoading(true)
    setError(null)
    
    try {
      const response = await fetch(API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ action: 'new' })
      })
      
      const data = await response.json()
      
      if (data.success) {
        setGameState(data.gameState)
      } else {
        setError(data.error || 'Failed to start new game')
      }
    } catch (err) {
      setError('Network error: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  const makeMove = async (direction) => {
    if (!gameState || loading) return
    
    setLoading(true)
    setError(null)
    
    try {
      const response = await fetch(API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          action: 'move',
          direction,
          gameState
        })
      })
      
      const data = await response.json()
      
      if (data.success) {
        setGameState(data.gameState)
      } else {
        setError(data.error || 'Failed to make move')
      }
    } catch (err) {
      setError('Network error: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    startNewGame()
  }, [])

  return (
    <div className="App">
      <header className="App-header">
        <h1>2048 Game</h1>
        <p>AWS Portfolio Project - CodePipeline + Lambda + ECR</p>
      </header>
      
      <main>
        {error && (
          <div className="error">
            <p>Error: {error}</p>
            <button onClick={startNewGame}>Try Again</button>
          </div>
        )}
        
        {gameState && (
          <Game2048 
            gameState={gameState}
            onMove={makeMove}
            loading={loading}
          />
        )}
        
        <div className="controls">
          <button 
            onClick={startNewGame} 
            disabled={loading}
            className="new-game-btn"
          >
            {loading ? 'Loading...' : 'New Game'}
          </button>
        </div>
        
        <div className="instructions">
          <h3>How to Play:</h3>
          <p>Use arrow keys or swipe to move tiles. Combine tiles with the same number to reach 2048!</p>
          <div className="key-hints">
            <span>↑ Up</span>
            <span>↓ Down</span>
            <span>← Left</span>
            <span>→ Right</span>
          </div>
        </div>
      </main>
    </div>
  )
}

export default App