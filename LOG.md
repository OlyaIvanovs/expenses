# What do we want?

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
        - Ctrl + Arrows to move by 5 letters at a time
    + Del
    + Scroll:
        + When the cursor reaches the end on the right, start a snappy animation
        + Same on the left
    - Replace prepare_text with get_text_width where we only need the width and nothing else
    - Mouse support
        + Modify Simp so that it returns character position based on provided width
        + Clicking to set cursor pos
        + Fix the left bias
        - Fix the get_cursor_pos function
        - Dragging to select (no shift required)
        - Continue dragging even if outside the rect

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


26/05/2023
Task: Add button to "Settings" page. We can add a new category by clicking on this button. 
27/05/2023 
Task: Category should be saved in db
Task: Add icon delete + removing category from db by clicking on it


Next:
categories:
Task: Remove category by clicking on icon + remove from db
Task: Edit category name
Task: Add rules for catgory. Remove rules. Edit rules 
Task: Choose color for category

Transactions:
Task:
Upload document with transactions
Show transactions in table
Give user a posibility to change category
Add note to transaction