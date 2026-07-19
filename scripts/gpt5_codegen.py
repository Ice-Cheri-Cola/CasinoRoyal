#!/usr/bin/env python3
"""
GPT-5 Code Generation Script for Casino Royal
Allows GPT-5 to create and edit files in the repository
"""

import os
import sys
import json
import base64
import requests
from typing import Optional, Dict, Any
from pathlib import Path
from datetime import datetime

# Configuration
AZURE_OPENAI_API_KEY = os.getenv('AZURE_OPENAI_API_KEY')
AZURE_OPENAI_ENDPOINT = os.getenv('AZURE_OPENAI_ENDPOINT', 'https://api.openai.com/v1')
AZURE_OPENAI_DEPLOYMENT = os.getenv('AZURE_OPENAI_DEPLOYMENT', 'gpt-5')
AZURE_OPENAI_API_VERSION = os.getenv('AZURE_OPENAI_API_VERSION', '2024-03-01-preview')
GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')
GITHUB_REPO = os.getenv('GITHUB_REPO', 'Ice-Cheri-Cola/casinoroyal')
GITHUB_BRANCH = os.getenv('GITHUB_BRANCH', 'main')


class GPT5CodeGenerator:
    """Handles GPT-5 API interactions for code generation"""
    
    def __init__(self):
        """Initialize the GPT-5 code generator"""
        if not AZURE_OPENAI_API_KEY:
            raise ValueError("AZURE_OPENAI_API_KEY environment variable not set")
        
        self.api_key = AZURE_OPENAI_API_KEY
        self.endpoint = AZURE_OPENAI_ENDPOINT.rstrip('/')
        self.deployment = AZURE_OPENAI_DEPLOYMENT
        self.api_version = AZURE_OPENAI_API_VERSION
        self.headers = {
            'Content-Type': 'application/json',
            'api-key': self.api_key
        }
    
    def generate_code(self, prompt: str, context: Optional[str] = None) -> str:
        """
        Generate code using GPT-5
        
        Args:
            prompt: The code generation prompt
            context: Optional context about the project
            
        Returns:
            Generated code as string
        """
        full_prompt = prompt
        
        if context:
            full_prompt = f"""Project Context:
{context}

Task:
{prompt}

Generate high-quality, well-commented code that follows the project conventions."""
        
        url = f"{self.endpoint}/deployments/{self.deployment}/chat/completions?api-version={self.api_version}"
        
        payload = {
            "messages": [
                {
                    "role": "system",
                    "content": "You are an expert Lua and game development programmer. Generate clean, well-commented code for the Casino Royal Minecraft project."
                },
                {
                    "role": "user",
                    "content": full_prompt
                }
            ],
            "temperature": 0.7,
            "max_tokens": 4096,
            "top_p": 0.95,
            "frequency_penalty": 0,
            "presence_penalty": 0
        }
        
        try:
            response = requests.post(url, headers=self.headers, json=payload, timeout=30)
            response.raise_for_status()
            
            result = response.json()
            code = result['choices'][0]['message']['content']
            return code
        
        except requests.exceptions.RequestException as e:
            print(f"Error calling GPT-5 API: {e}")
            raise


class GitHubManager:
    """Handles GitHub repository operations"""
    
    def __init__(self, repo: str, branch: str = 'main'):
        """Initialize GitHub manager"""
        if not GITHUB_TOKEN:
            raise ValueError("GITHUB_TOKEN environment variable not set")
        
        self.token = GITHUB_TOKEN
        self.repo = repo
        self.branch = branch
        self.headers = {
            'Authorization': f'token {self.token}',
            'Accept': 'application/vnd.github.v3+json',
            'Content-Type': 'application/json'
        }
        self.base_url = f'https://api.github.com/repos/{repo}'
    
    def get_file_content(self, path: str) -> Optional[Dict[str, Any]]:
        """Get file content from repository"""
        url = f'{self.base_url}/contents/{path}?ref={self.branch}'
        
        try:
            response = requests.get(url, headers=self.headers)
            
            if response.status_code == 404:
                return None
            
            response.raise_for_status()
            
            data = response.json()
            content = base64.b64decode(data['content']).decode('utf-8')
            
            return {
                'content': content,
                'sha': data['sha'],
                'path': data['path']
            }
        
        except requests.exceptions.RequestException as e:
            print(f"Error fetching file from GitHub: {e}")
            return None
    
    def create_or_update_file(self, path: str, content: str, message: str) -> bool:
        """Create or update a file in the repository"""
        url = f'{self.base_url}/contents/{path}'
        
        # Get existing file SHA if it exists
        sha = None
        existing = self.get_file_content(path)
        if existing:
            sha = existing['sha']
        
        payload = {
            'message': message,
            'content': base64.b64encode(content.encode()).decode(),
            'branch': self.branch
        }
        
        if sha:
            payload['sha'] = sha
        
        try:
            response = requests.put(url, headers=self.headers, json=payload)
            response.raise_for_status()
            
            print(f"✓ {'Updated' if sha else 'Created'} {path}")
            return True
        
        except requests.exceptions.RequestException as e:
            print(f"Error creating/updating file in GitHub: {e}")
            return False
    
    def create_branch(self, branch_name: str, from_branch: str = None) -> bool:
        """Create a new branch"""
        if not from_branch:
            from_branch = self.branch
        
        # Get the SHA of the source branch
        url = f'{self.base_url}/git/refs/heads/{from_branch}'
        
        try:
            response = requests.get(url, headers=self.headers)
            response.raise_for_status()
            
            sha = response.json()['object']['sha']
            
            # Create new branch
            create_url = f'{self.base_url}/git/refs'
            payload = {
                'ref': f'refs/heads/{branch_name}',
                'sha': sha
            }
            
            response = requests.post(create_url, headers=self.headers, json=payload)
            response.raise_for_status()
            
            print(f"✓ Created branch {branch_name}")
            return True
        
        except requests.exceptions.RequestException as e:
            print(f"Error creating branch: {e}")
            return False


def main():
    """Main entry point"""
    print("=" * 60)
    print("Casino Royal - GPT-5 Code Generator")
    print("=" * 60)
    print()
    
    if len(sys.argv) < 2:
        print("Usage: python gpt5_codegen.py <command> [options]")
        print()
        print("Commands:")
        print("  generate <file_path> <prompt>  - Generate code and save to file")
        print("  create-feature <feature_name>  - Create a new feature")
        print("  improve <file_path>            - Improve existing code")
        print()
        sys.exit(1)
    
    command = sys.argv[1]
    
    try:
        gpt5 = GPT5CodeGenerator()
        github = GitHubManager(GITHUB_REPO, GITHUB_BRANCH)
        
        if command == 'generate':
            if len(sys.argv) < 4:
                print("Usage: python gpt5_codegen.py generate <file_path> <prompt>")
                sys.exit(1)
            
            file_path = sys.argv[2]
            prompt = ' '.join(sys.argv[3:])
            
            print(f"Generating code for: {file_path}")
            print(f"Prompt: {prompt}")
            print()
            
            code = gpt5.generate_code(prompt)
            print("Generated code:")
            print("-" * 60)
            print(code)
            print("-" * 60)
            print()
            
            save = input("Save to repository? (y/n): ").lower() == 'y'
            if save:
                commit_msg = input("Commit message: ")
                success = github.create_or_update_file(
                    file_path,
                    code,
                    commit_msg or f"Add {file_path} via GPT-5"
                )
                
                if success:
                    print(f"✓ Successfully saved {file_path} to repository")
                else:
                    print("✗ Failed to save to repository")
        
        elif command == 'create-feature':
            if len(sys.argv) < 3:
                print("Usage: python gpt5_codegen.py create-feature <feature_name>")
                sys.exit(1)
            
            feature_name = sys.argv[2]
            
            print(f"Creating feature: {feature_name}")
            print()
            
            prompt = f"""Create a new feature module for the Casino Royal project called "{feature_name}".

The module should:
1. Follow the existing project structure in games/ or core/ directories
2. Include proper error handling
3. Have clear comments explaining functionality
4. Export a main table/module with necessary functions

Generate the complete Lua file content."""
            
            code = gpt5.generate_code(prompt)
            print("Generated module:")
            print("-" * 60)
            print(code)
            print("-" * 60)
            print()
            
            file_path = f"games/{feature_name}.lua"
            save = input(f"Save as {file_path}? (y/n): ").lower() == 'y'
            
            if save:
                success = github.create_or_update_file(
                    file_path,
                    code,
                    f"Add {feature_name} feature via GPT-5"
                )
                
                if success:
                    print(f"✓ Successfully created {file_path}")
                else:
                    print("✗ Failed to create feature")
        
        elif command == 'improve':
            if len(sys.argv) < 3:
                print("Usage: python gpt5_codegen.py improve <file_path>")
                sys.exit(1)
            
            file_path = sys.argv[2]
            
            print(f"Improving: {file_path}")
            
            existing = github.get_file_content(file_path)
            if not existing:
                print(f"✗ File not found: {file_path}")
                sys.exit(1)
            
            current_code = existing['content']
            
            prompt = f"""Review and improve the following Lua code from the Casino Royal project.

Current code:
```lua
{current_code}
```

Improvements should include:
1. Better error handling
2. Performance optimizations
3. Clearer variable names
4. Additional comments
5. Any bug fixes

Provide the improved code with explanations of changes made."""
            
            improved = gpt5.generate_code(prompt)
            print("Improved code:")
            print("-" * 60)
            print(improved)
            print("-" * 60)
            print()
            
            save = input("Save improvements? (y/n): ").lower() == 'y'
            if save:
                success = github.create_or_update_file(
                    file_path,
                    improved,
                    f"Improve {file_path} via GPT-5"
                )
                
                if success:
                    print(f"✓ Successfully updated {file_path}")
                else:
                    print("✗ Failed to update file")
        
        else:
            print(f"Unknown command: {command}")
            sys.exit(1)
    
    except Exception as e:
        print(f"✗ Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
