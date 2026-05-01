from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import random
from typing import List, Dict, Any

app = Flask(__name__)
CORS(app)

class Game2048:
    def __init__(self):
        self.size = 4
        self.board = [[0 for _ in range(self.size)] for _ in range(self.size)]
        self.score = 0
        self.add_random_tile()
        self.add_random_tile()

    def add_random_tile(self):
        empty_cells = [(i, j) for i in range(self.size) for j in range(self.size) if self.board[i][j] == 0]
        if empty_cells:
            i, j = random.choice(empty_cells)
            self.board[i][j] = 2 if random.random() < 0.9 else 4

    def move_left(self):
        moved = False
        for i in range(self.size):
            row = [cell for cell in self.board[i] if cell != 0]
            
            j = 0
            while j < len(row) - 1:
                if row[j] == row[j + 1]:
                    row[j] *= 2
                    self.score += row[j]
                    row.pop(j + 1)
                j += 1
            
            row.extend([0] * (self.size - len(row)))
            
            if row != self.board[i]:
                moved = True
                self.board[i] = row
        
        return moved

    def rotate_board(self):
        self.board = [[self.board[self.size - 1 - j][i] for j in range(self.size)] for i in range(self.size)]

    def move(self, direction: str) -> bool:
        rotations = {'left': 0, 'up': 3, 'right': 2, 'down': 1}
        
        if direction not in rotations:
            return False
        
        for _ in range(rotations[direction]):
            self.rotate_board()
        
        moved = self.move_left()
        
        for _ in range(4 - rotations[direction]):
            self.rotate_board()
        
        if moved:
            self.add_random_tile()
        
        return moved

    def is_game_over(self) -> bool:
        for i in range(self.size):
            for j in range(self.size):
                if self.board[i][j] == 0:
                    return False
        
        for i in range(self.size):
            for j in range(self.size):
                current = self.board[i][j]
                if j < self.size - 1 and self.board[i][j + 1] == current:
                    return False
                if i < self.size - 1 and self.board[i + 1][j] == current:
                    return False
        
        return True

    def get_state(self) -> Dict[str, Any]:
        return {
            'board': self.board,
            'score': self.score,
            'gameOver': self.is_game_over()
        }

    def load_state(self, state: Dict[str, Any]):
        self.board = state.get('board', self.board)
        self.score = state.get('score', 0)

@app.route('/', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'message': '2048 Game API'})

@app.route('/', methods=['POST'])
def game_api():
    try:
        data = request.get_json()
        action = data.get('action', 'new')
        
        if action == 'new':
            game = Game2048()
            return jsonify({
                'success': True,
                'gameState': game.get_state()
            })
        
        elif action == 'move':
            direction = data.get('direction')
            game_state = data.get('gameState', {})
            
            if not direction:
                return jsonify({
                    'success': False,
                    'error': 'Direction is required'
                }), 400
            
            game = Game2048()
            game.load_state(game_state)
            
            moved = game.move(direction)
            
            return jsonify({
                'success': True,
                'moved': moved,
                'gameState': game.get_state()
            })
        
        else:
            return jsonify({
                'success': False,
                'error': 'Invalid action'
            }), 400
    
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)