#!/bin/bash
tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux

