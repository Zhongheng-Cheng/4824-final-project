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

def new_window(title, nlines, ncols, begin_y, begin_x):
    win = curses.newwin(nlines, ncols, begin_y, begin_x)
    win.border()
    win.addstr(0, max(begin_x, (begin_x + ncols) // 2 - len(title) // 2), title)
    return win

def main(stdscr):
    
    # initialization
    curses.curs_set(False)
    cycle = Cycle()
    stdscr.clear()
    stdscr.refresh()

    # create window for Keys
    win_keys = new_window(title="Keys", nlines=10, ncols=15, begin_y=0, begin_x=0)
    win_keys.addstr(1, 1, "Q: quit")
    win_keys.addstr(2, 1, "V: cycle-10")
    win_keys.addstr(3, 1, "B: cycle-1")
    win_keys.addstr(4, 1, "N: cycle+1")
    win_keys.addstr(5, 1, "M: cycle+10")
    win_keys.refresh()


    # main loop
    while True:
        stdscr.addstr(0, 17, f"Cycle: {cycle.now:3d}")
        stdscr.refresh()

        key_press = chr(stdscr.getch())
        if key_press == "q":
            # quit the debugger
            break
        elif key_press == 'v':   
            cycle.add_to_cycle(-10)
        elif key_press == 'b':   
            cycle.add_to_cycle(-1)
        elif key_press == 'n':   
            cycle.add_to_cycle(1)
        elif key_press == 'm':   
            cycle.add_to_cycle(10)
        


curses.wrapper(main)