import curses

class Cycle():
    def __init__(self):
        self.now = 0
        self.limit = [0, 999]
        return

    def add_to_cycle(self, num):
        self.now += num
        if self.now < self.limit[0]:
            self.now = 0
        elif self.now > self.limit[1]:
            self.now = 999
        return

    def move_to_cycle(self, num):
        self.now = num
        if self.now < self.limit[0]:
            self.now = 0
        elif self.now > self.limit[1]:
            self.now = 999
        return

def new_window(title, nlines, ncols, begin_y, begin_x):
    win = curses.newwin(nlines, ncols, begin_y, begin_x)
    win.border()
    win.addstr(0, max(begin_x, (begin_x + ncols) // 2 - len(title) // 2), title, curses.A_BOLD | curses.COLOR_RED)
    win.refresh()
    return win


def main(stdscr):
    
    # initialization
    wins = {"main": stdscr}
    curses.curs_set(False)
    cycle = Cycle()
    wins["main"].clear()
    wins["main"].refresh()
    

    goto_input = ""
    recording = False

    # create window for Keys
    wins["keys"] = new_window(title="Keys", nlines=10, ncols=15, begin_y=0, begin_x=0)
    wins["keys"].addstr(1, 1, "Q: quit")
    wins["keys"].addstr(2, 1, "→: next cycle")
    wins["keys"].addstr(3, 1, "←: prev cycle")
    wins["keys"].addstr(4, 1, "↑: +10 cycles")
    wins["keys"].addstr(5, 1, "↓: -10 cycles")
    wins["keys"].addstr(6, 1, "G: go to     ")
    wins["keys"].addstr(7, 1, "T: end go to ")
    wins["keys"].refresh()


    # main loop
    while True:
        wins["main"].addstr(0, 17, f"Cycle: {cycle.now:3d}")
        wins["main"].refresh()

        key_press = wins["main"].getch()

        # quit the debugger
        if key_press == ord('q'):
            return
        
        # move cycle count
        elif key_press == curses.KEY_RIGHT:   
            cycle.add_to_cycle(1)
        elif key_press == curses.KEY_LEFT:   
            cycle.add_to_cycle(-1)
        elif key_press == curses.KEY_UP:   
            cycle.add_to_cycle(10)
        elif key_press == curses.KEY_DOWN:   
            cycle.add_to_cycle(-10)

        # go-to function
        elif key_press == ord('g'):
            recording = True
            wins["keys"].addstr(6, 1, "G: go to     ", curses.A_REVERSE)
        elif recording and key_press == 10: # ENTER
            recording = False
            wins["keys"].addstr(6, 1, "G: go to     ")
            if goto_input:
                cycle.move_to_cycle(int(goto_input[-3:]))
                goto_input = ""
        elif recording and key_press == 263: # BACKSPACE
            goto_input = goto_input[:-1]
            wins["keys"].addstr(6, 1, f"G: go to {goto_input[-3:]:3s}", curses.A_REVERSE)
        elif recording and 48 <= key_press <= 57: # numbers: 0-9
            char = str(int(chr(key_press)))
            goto_input += char
            wins["keys"].addstr(6, 1, f"G: go to {goto_input[-3:]:3s}", curses.A_REVERSE)


        wins["main"].addstr(20, 1, f"Key pressed: {str(key_press):3s}")

        # refresh for every window
        for win in wins.values():
            win.refresh()

curses.wrapper(main)