define lsb
info breakpoints
end
document lsb
List breakpoints
end

define bp
set $SHOW_CONTEXT = 1
break * $arg0
end
document bp
Set a breakpoint on address
Usage: bp addr
end

define rmb
clear $arg0
end
document rmb
Clear breakpoint at function/address
Usage: rmb addr
end

define bpe
enable $arg0
end
document bpe
Enable breakpoint #
Usage: bpe num
end

define bpd
disable $arg0
end
document bpd
Disable breakpoint #
Usage: bpd num
end

define bpt
set $SHOW_CONTEXT = 1
tbreak $arg0
end
document bpt
Set a temporary breakpoint on address
Usage: bpt addr
end

define bpm
set $SHOW_CONTEXT = 1
awatch $arg0
end
document bpm
Set a read/write breakpoint on address
Usage: bpm addr
end

define argv
show args
end
document argv
Print program arguments
end

define stack
info stack
end
document stack
Print call stack
end

define frame
info frame
info args
info locals
end
document frame
Print stack frame
end

define lsgo
info goroutines
end
document lsgo
List Goroutines
end


define go
end
document go
Commands:
frame
lsgo
p $len(utf)
p $cap(utf)

end

source ~/dotfiles/runtime-gdb.py
skip malloc.goc:436