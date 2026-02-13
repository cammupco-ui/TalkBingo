#!/usr/bin/env python3
"""Direct line-based fix for penalty_kick_game.dart Bug 4"""

path = '/Users/anmijung/Desktop/TalkBingo/app/lib/games/penalty_kick/penalty_kick_game.dart'
with open(path, 'r') as f:
    lines = f.readlines()

# Print before state
print("BEFORE (lines 258-266):")
for i in range(257, 267):
    print(f"  {i+1}: {lines[i].rstrip()}")

# Replace lines 261-266 (0-indexed: 260-265) with the fixed version
# Line 261 currently: "         } else if (payload['eventType'] == 'game_pause') {\n"
# Line 262 currently: "         setState(() => _isPaused = true);\n"
# Line 263 currently: "      } else if (payload['eventType'] == 'game_resume') {\n"
# Line 264 currently: "         setState(() => _isPaused = false);\n"
# Line 265 currently: "      }\n"
# Line 266 currently: "      }\n"

new_lines_261_266 = [
    "         }\n",
    "      } else if (payload['eventType'] == 'game_pause') {\n",
    "         setState(() => _isPaused = true);\n",
    "      } else if (payload['eventType'] == 'game_resume') {\n",
    "         setState(() => _isPaused = false);\n",
    "      }\n",
]

lines[260:266] = new_lines_261_266

# Also fix Bug 1: touch area increase
for i, line in enumerate(lines):
    if 'ballRect.inflate(20)' in line:
        lines[i] = line.replace('ballRect.inflate(20)', 'ballRect.inflate(40)')
        print(f"\nBug 1: Touch area increased at line {i+1}")
        break

with open(path, 'w') as f:
    f.writelines(lines)

# Verify
with open(path, 'r') as f:
    verify_lines = f.readlines()

print("\nAFTER (lines 258-268):")
for i in range(257, min(268, len(verify_lines))):
    print(f"  {i+1}: {verify_lines[i].rstrip()}")

print("\nDone!")
