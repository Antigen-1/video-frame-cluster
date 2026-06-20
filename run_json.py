import sys
from core import run
with open(sys.argv[1]) as f:
    run(f.read())
