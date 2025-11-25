#!/bin/bash

# Parry Loader Quick Test Script
# This script generates UIDs and runs the game

echo "🎮 Parry Loader Quick Test"
echo "=========================="
echo ""

# Navigate to project directory
cd /Users/fb/parryloader

# Step 1: Generate missing UIDs
echo "📝 Step 1: Generating missing UIDs..."
godot --headless --quit --path . 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ UID generation complete"
else
    echo "⚠️  UID generation had warnings (this is usually okay)"
fi
echo ""

# Step 2: Run the game
echo "🚀 Step 2: Launching game..."
echo "   (Press Ctrl+C to stop)"
echo ""
godot --path .

# Exit
echo ""
echo "👋 Game closed"
