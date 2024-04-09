import curses

def main(stdscr):
    # Clear the screen
    stdscr.clear()

    # Turn off cursor display
    curses.curs_set(0)

    # Get screen dimensions
    height, width = stdscr.getmaxyx()

    # Calculate center of the screen
    center_y = height // 2
    center_x = width // 2

    # Define text to display
    message = "Hello, Terminal GUI!"

    # Calculate starting position of the text
    start_y = center_y - 1
    start_x = center_x - len(message) // 2

    # Display the message
    stdscr.addstr(start_y, start_x, message)

    # Wait for user input to exit
    stdscr.getch()

curses.wrapper(main)