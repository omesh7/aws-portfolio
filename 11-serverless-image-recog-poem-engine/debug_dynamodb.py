#!/usr/bin/env python3
"""
Debug script to check DynamoDB table contents
"""
import boto3
import json
from datetime import datetime

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb', region_name='ap-south-1')
table_name = 'project-11-poem-results'  # Update this with your actual table name
table = dynamodb.Table(table_name)

def scan_table():
    """Scan the entire table to see what's stored"""
    try:
        response = table.scan()
        items = response.get('Items', [])
        
        print(f"Found {len(items)} items in table '{table_name}':")
        print("-" * 50)
        
        for item in items:
            print(f"PoemId: {item.get('poemId')}")
            print(f"Status: {item.get('status')}")
            print(f"Labels: {item.get('labels')}")
            print(f"Poem: {item.get('poem', '')[:100]}...")
            print(f"Timestamp: {datetime.fromtimestamp(item.get('timestamp', 0))}")
            print("-" * 50)
            
    except Exception as e:
        print(f"Error scanning table: {e}")

def test_get_item(poem_id):
    """Test getting a specific item"""
    try:
        response = table.get_item(Key={'poemId': poem_id})
        
        if 'Item' in response:
            print(f"Found item for poemId '{poem_id}':")
            print(json.dumps(response['Item'], indent=2, default=str))
        else:
            print(f"No item found for poemId '{poem_id}'")
            
    except Exception as e:
        print(f"Error getting item: {e}")

if __name__ == "__main__":
    print("=== DynamoDB Debug Tool ===")
    
    # Scan all items
    scan_table()
    
    # Test specific poem ID (update this with an actual ID from your uploads)
    test_poem_id = input("\nEnter a poemId to test (or press Enter to skip): ").strip()
    if test_poem_id:
        test_get_item(test_poem_id)