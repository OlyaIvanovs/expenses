# What do wPe want?

- Know how much was spent on each category each week/month/year/arbitrary date range?
- How much money we have
    - Saved on purpose (for some category)
    - Available for use (not saved on any purpose)
- Be able to load a csv file from bank and
    - Record each transaction and guess the category (if unable to guess then be able to specify manually)
    - Add a note to each transaction if needed
- Draw some graphs:
    - Line graph for each category with the ability to choose one or more categories for comparison
    - (optional) Bar graph, where each bar is colored, displaying the percentage spent on each category that day/week/month


# TODO

- Text input:
    + Move cursor
    + Implement del and backspace
    + Implement selection
    + When text is selected:
        + Typing anything replaces selection
        + Pressing left removes the selection and moves the cursor to the left of the selection
        + Same for the right
    + Copy/paste (module Clipboard)
        + Paste replaces selection
    + Home
    + End
    + Cut
    - Various shortcuts:
        + Ctrl A to select all
        - Ctrl + Arrows to move by word
    + Del
    - Scroll:
        - When the cursor reaches the end on the right, start a snappy animation
        - Same on the left
    - Mouse support

- Adding categories:
    + Draw on paper what the UI will look like
    + List all categories
    - Draw an add button (or an input right away)
    - Add a category
    - Be able to choose color
    - Be able to add rules


# DONE

+ Open a window
+ Create a table
    + SQL query
    + find & bind function(s) from sqlite3 library
