import curses

def main(stdscr):
    stdscr.clear()
    curses.curs_set(False)

    while True:

        key_press = chr(stdscr.getch())

        # quit the debugger
        if key_press == "q":
            break
        else:
            stdscr.addstr(0, 0, key_press)
            stdscr.refresh()


curses.wrapper(main)