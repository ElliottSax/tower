#!/usr/bin/env python3
"""Entry point for running the pipeline as a module.

Usage:
    python -m pipeline [command] [args]
"""

import sys
from .cli import main

if __name__ == "__main__":
    sys.exit(main())
