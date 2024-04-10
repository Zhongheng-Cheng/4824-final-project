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
    win.addstr(0, max(0, (ncols - 1) // 2 - len(title) // 2), title, curses.A_BOLD)
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

    # set position of cycle count
    cycle_begin_y = 10
    cycle_begin_x = 1

    # create window for Keys
    wins["keys"] = new_window(title="Keys", 
                              nlines=10, 
                              ncols=15, 
                              begin_y=0, 
                              begin_x=0
                              )
    wins["keys"].addstr(1, 1, "Q: quit")
    wins["keys"].addstr(2, 1, "L: next cycle")
    wins["keys"].addstr(3, 1, "J: prev cycle")
    wins["keys"].addstr(4, 1, "I: +10 cycles")
    wins["keys"].addstr(5, 1, "K: -10 cycles")
    wins["keys"].addstr(6, 1, "G: go to     ")
    wins["keys"].addstr(7, 1, "T: end go to ")
    wins["keys"].addstr(8, 1, "B: backspace ")
    wins["keys"].refresh()

    # create window for Reorder Buffer (RoB)
    wins["rob"] = new_window(title="RoB", 
                             nlines=10, 
                             ncols=34, 
                             begin_y=0, 
                             begin_x=wins['keys'].getbegyx()[1] + wins['keys'].getmaxyx()[1] + 1
                             )

    # create window for Map Table
    wins["map_table"] = new_window(title="Map Table", 
                                   nlines=10, 
                                   ncols=15, 
                                   begin_y=0, 
                                   begin_x=wins['rob'].getbegyx()[1] + wins['rob'].getmaxyx()[1]
                                   )

    # create window for Arch Table
    wins["arch_table"] = new_window(title="Arch Table", 
                                    nlines=10, 
                                    ncols=15, 
                                    begin_y=0, 
                                    begin_x=wins['map_table'].getbegyx()[1] + wins['map_table'].getmaxyx()[1]
                                    )
    
    # create window for Common Data Bus (CDB)
    wins["cdb"] = new_window(title="CDB", 
                            nlines=8, 
                            ncols=15, 
                            begin_y=12, 
                            begin_x=0
                            )

    # create window for Reservation Stations (RS)
    wins["rs"] = new_window(title="RS", 
                            nlines=10, 
                            ncols=50, 
                            begin_y=10, 
                            begin_x=wins['cdb'].getbegyx()[1] + wins['cdb'].getmaxyx()[1]
                            )

    # create window for Free List
    wins["free_list"] = new_window(title="Free List", 
                                   nlines=10, 
                                   ncols=15, 
                                   begin_y=10, 
                                   begin_x=wins['rs'].getbegyx()[1] + wins['rs'].getmaxyx()[1]
                                   )





    # main loop
    while True:
        wins["main"].addstr(cycle_begin_y, cycle_begin_x, f"Cycle: {cycle.now:3d}")
        wins["main"].refresh()

        key_press = wins["main"].getch()

        # quit the debugger
        if key_press == ord('q'):
            return
        
        # move cycle count
        elif key_press == ord('l'):   
            cycle.add_to_cycle(1)
        elif key_press == ord('j'):   
            cycle.add_to_cycle(-1)
        elif key_press == ord('i'):   
            cycle.add_to_cycle(10)
        elif key_press == ord('k'):   
            cycle.add_to_cycle(-10)

        # go-to function
        elif key_press == ord('g'): # start go-to
            goto_input = ""
            recording = True
            wins["keys"].addstr(6, 1, "G: go to     ", curses.A_REVERSE)
        elif recording and key_press == ord('t'): # end go-to
            recording = False
            wins["keys"].addstr(6, 1, "G: go to     ")
            if goto_input:
                cycle.move_to_cycle(int(goto_input[-3:]))
        elif recording and key_press == ord('b'): # backspace
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