import json
import random
from typing import List, Dict, Any

class Game2048:
    def __init__(self):
        self.size = 4
        self.board = [[0 for _ in range(self.size)] for _ in range(self.size)]
        self.score = 0
        self.add_random_tile()
        self.add_random_tile()

    def add_random_tile(self):
        """Add a random tile (2 or 4) to an empty cell"""
        empty_cells = [(i, j) for i in range(self.size) for j in range(self.size) if self.board[i][j] == 0]
        if empty_cells:
            i, j = random.choice(empty_cells)
            self.board[i][j] = 2 if random.random() < 0.9 else 4

    def move_left(self):
        """Move tiles left and merge"""
        moved = False
        for i in range(self.size):
            # Compress row
            row = [cell for cell in self.board[i] if cell != 0]
            
            # Merge adjacent equal tiles
            j = 0
            while j < len(row) - 1:
                if row[j] == row[j + 1]:
                    row[j] *= 2
                    self.score += row[j]
                    row.pop(j + 1)
                j += 1
            
            # Pad with zeros
            row.extend([0] * (self.size - len(row)))
            
            # Check if row changed
            if row != self.board[i]:
                moved = True
                self.board[i] = row
        
        return moved

    def rotate_board(self):
        """Rotate board 90 degrees clockwise"""
        self.board = [[self.board[self.size - 1 - j][i] for j in range(self.size)] for i in range(self.size)]

    def move(self, direction: str) -> bool:
        """Move in specified direction"""
        rotations = {'left': 0, 'up': 3, 'right': 2, 'down': 1}
        
        if direction not in rotations:
            return False
        
        # Rotate to make move equivalent to left
        for _ in range(rotations[direction]):
            self.rotate_board()
        
        moved = self.move_left()
        
        # Rotate back
        for _ in range(4 - rotations[direction]):
            self.rotate_board()
        
        if moved:
            self.add_random_tile()
        
        return moved

    def is_game_over(self) -> bool:
        """Check if game is over"""
        # Check for empty cells
        for i in range(self.size):
            for j in range(self.size):
                if self.board[i][j] == 0:
                    return False
        
        # Check for possible merges
        for i in range(self.size):
            for j in range(self.size):
                current = self.board[i][j]
                # Check right neighbor
                if j < self.size - 1 and self.board[i][j + 1] == current:
                    return False
                # Check bottom neighbor
                if i < self.size - 1 and self.board[i + 1][j] == current:
                    return False
        
        return True

    def get_state(self) -> Dict[str, Any]:
        """Get current game state"""
        return {
            'board': self.board,
            'score': self.score,
            'gameOver': self.is_game_over()
        }

    def load_state(self, state: Dict[str, Any]):
        """Load game state"""
        self.board = state.get('board', self.board)
        self.score = state.get('score', 0)

def lambda_handler(event, context):
    """AWS Lambda handler"""
    try:
        # Parse request
        body = json.loads(event.get('body', '{}'))
        action = body.get('action', 'new')
        
        if action == 'new':
            # Create new game
            game = Game2048()
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },
                'body': json.dumps({
                    'success': True,
                    'gameState': game.get_state()
                })
            }
        
        elif action == 'move':
            # Make a move
            direction = body.get('direction')
            game_state = body.get('gameState', {})
            
            if not direction:
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({
                        'success': False,
                        'error': 'Direction is required'
                    })
                }
            
            game = Game2048()
            game.load_state(game_state)
            
            moved = game.move(direction)
            
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },
                'body': json.dumps({
                    'success': True,
                    'moved': moved,
                    'gameState': game.get_state()
                })
            }
        
        else:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'error': 'Invalid action'
                })
            }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': str(e)
            })
        }

# For local testing
if __name__ == "__main__":
    # Test new game
    test_event = {
        'body': json.dumps({'action': 'new'})
    }
    result = lambda_handler(test_event, None)
    print("New game:", result)
    
    # Test move
    game_state = json.loads(result['body'])['gameState']
    test_event = {
        'body': json.dumps({
            'action': 'move',
            'direction': 'left',
            'gameState': game_state
        })
    }
    result = lambda_handler(test_event, None)
    print("Move result:", result)