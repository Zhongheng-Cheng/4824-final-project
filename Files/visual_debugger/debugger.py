import curses

rob = []
prf = []

def read_pipeline_output(filepath):
    with open(filepath, 'r') as fo:
        while True:
            line = fo.readline()
            if not line:
                return len(rob) # total number of lines
            
            line = line.strip('\n')
            if line[:5] == "cycle":
                cycle = int(line.split()[-1])
                rob.append([])
                prf.append([])
            elif line == "ROB Table":
                for _ in range(32):
                    line = fo.readline().strip('\n')
                    rob[cycle].append(line)
            elif line == "Physical Register File":
                for _ in range(64):
                    line = fo.readline().strip('\n')
                    prf[cycle].append(line)

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

    def update_ui():

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
        wins["keys"].addstr(6, 1, f"G: go to {goto_input[-3:]:3s}", curses.A_REVERSE * recording)
        wins["keys"].addstr(7, 1, "T: end go to ")
        wins["keys"].addstr(8, 1, "B: backspace ")
        wins["keys"].refresh()

        # create window for Reorder Buffer (RoB)
        wins["rob"] = new_window(title="RoB", 
                                nlines=35, 
                                ncols=66, 
                                begin_y=0, 
                                begin_x=wins['keys'].getbegyx()[1] + wins['keys'].getmaxyx()[1]
                                )
        wins['rob'].addstr(1, 1, " No.| t  | to | ar | c | h | p | tar_pc |  dest_val  |   NPC    ")
        for i in range(32):
            wins['rob'].addstr(i + 2, 1, rob[min(cycle.now, len(rob) - 1)][i])
        wins["rob"].refresh()

        # create window for Physical Register File (PRF)
        wins["prf"] = new_window(title="PRF", 
                                 nlines=35, 
                                 ncols=37, 
                                 begin_y=0, 
                                 begin_x=wins['rob'].getbegyx()[1] + wins['rob'].getmaxyx()[1]
                                 )
        wins['prf'].addstr(1, 1, " No.|   value    | No.|   value    ")
        for i in range(32):
            wins['prf'].addstr(i + 2, 1, prf[min(cycle.now, max_cycle - 1)][i] + '|' + prf[min(cycle.now, max_cycle - 1)][i + 32])
        wins["prf"].refresh()

        # # create window for Map Table
        # wins["map_table"] = new_window(title="Map Table", 
        #                             nlines=10, 
        #                             ncols=10, 
        #                             begin_y=0, 
        #                             begin_x=wins['rob'].getbegyx()[1] + wins['rob'].getmaxyx()[1]
        #                             )
        # wins['map_table'].addstr(1, 1, "Reg|T+  ")
        # wins["map_table"].refresh()

        # # create window for Arch Table
        # wins["arch_table"] = new_window(title="Arch Table", 
        #                                 nlines=10, 
        #                                 ncols=10, 
        #                                 begin_y=0, 
        #                                 begin_x=wins['map_table'].getbegyx()[1] + wins['map_table'].getmaxyx()[1]
        #                                 )
        # wins['arch_table'].addstr(1, 1, "Reg|T+  ")
        # wins["arch_table"].refresh()

        # create window for Cycle
        wins["cycle"] = new_window(title="Cycle", 
                                nlines=3, 
                                ncols=15, 
                                begin_y=10, 
                                begin_x=0
                                )
        wins['cycle'].addstr(1, 1, f"     {cycle.now:3d}     ")
        wins['cycle'].refresh()
        
        # # create window for Reservation Stations (RS)
        # wins["rs"] = new_window(title="RS", 
        #                         nlines=10, 
        #                         ncols=35, 
        #                         begin_y=10, 
        #                         begin_x=wins['rob'].getbegyx()[1]
        #                         )
        # wins['rs'].addstr(1, 1, " #|FU |Busy|op   |T   |T1  |T2  ")
        # wins["rs"].refresh()

        # # create window for Free List
        # wins["free_list"] = new_window(title="Free List", 
        #                             nlines=10, 
        #                             ncols=15, 
        #                             begin_y=10, 
        #                             begin_x=wins['rs'].getbegyx()[1] + wins['rs'].getmaxyx()[1]
        #                             )
        # wins['free_list'].addstr(1, 1, "")
        # wins["free_list"].refresh()

        # # create window for Common Data Bus (CDB)
        # wins["cdb"] = new_window(title="CDB", 
        #                         nlines=5, 
        #                         ncols=8, 
        #                         begin_y=10, 
        #                         begin_x=wins['free_list'].getbegyx()[1] + wins['free_list'].getmaxyx()[1]
        #                         )
        # wins['cdb'].addstr(1, 1, "T  ")
        # wins["cdb"].refresh()

        # wins["main"].addstr(20, 1, f"Key pressed: {str(key_press):3s}")
        # wins["main"].addstr(21, 1, f"Window size: {height:3d} x {width:3d}")

        return
    

    # initialization
    wins = {"main": stdscr}
    curses.curs_set(False)
    wins["main"].clear()
    wins["main"].refresh()
    
    goto_input = ""
    recording = False
    key_press = ""

    # main loop
    while True:
        
        height, width = wins["main"].getmaxyx()
        if height < 25 or width < 100:
            wins['main'].clear()
            wins["main"].addstr(0, 0, "Not enough space!")
            wins["main"].refresh()
            wins["main"].getch()
            continue
        update_ui()

        
        key_press = wins["main"].getch()

        # quit the debugger
        if key_press == ord('q'):
            return
        
        # move cycle count
        if key_press == ord('l'):   
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
        elif recording and key_press == ord('t'): # end go-to
            recording = False
            if goto_input:
                cycle.move_to_cycle(int(goto_input[-3:]))
                goto_input = ""
        elif recording and key_press == ord('b'): # backspace
            goto_input = goto_input[:-1]
        elif recording and 48 <= key_press <= 57: # numbers: 0-9
            char = str(int(chr(key_press)))
            goto_input += char


if __name__ == "__main__":
    cycle = Cycle()
    max_cycle = read_pipeline_output("../pipeline.out")
    # for i in rob:
    #     for j in i:
    #         print(j)
    #     print()
    # for i in range(32):
    #     print(rob[cycle.now][i])
    # print(len(rob))
    # print(len(prf))
    curses.wrapper(main)