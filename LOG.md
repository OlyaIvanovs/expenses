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


# 26/05/2023
+ Add button to "Settings" page. We can add a new category by clicking on this button. 

# 29/05/2023 
+ Category should be saved in db
+ Add 'delete' icon + removing category from db by clicking on it
+ Edit category name

# 30/05/2023
+ Add confirmation while deleting category
+ Add table with transactions(Date/Description/Amount)

# 31/05/2023
+ Add scroll bar
+ Limit text by line's width

# 01/06/2023
+ Add button upload transactions
+ Add icons for transactions(Remove, Edit, More Info)
+ Remove transaction
+ Add color icon to category

# 02/06/2023
+ Remove all transactions
+ Upload transactions

# 06/06/2023    
+ Edit transaction(Details & amount)

# 07/06/2023
+ Add dropdown for choosing category
+ Edit transaction(note)
+ Dialogs should be on the same level
+ Close dialog on click outside it
+ Show rules(add new table to db)
+ Edit rule
+ Remove rule

# 08/06/2023
+ Add rule
+ Add transaction
+ Edit category
+ Add category

# 09/06/2023
+ Add scrollbar for categories

# 12/06/2023

# 13/06/2023
+ Add scrollbar for rules
+ Change transaction's scrollbar
+ Update category dropdown

# 14/06/2023
+ Mouse scroll

# 15/06/2023
+ Add color picker

# 16/06/2023
+ Transactions filter

# 20/06/2023
+ Date sort
+ Category filter
+ Amount sort

# 21/06/2023
- Date picker
- Dialog's inputs

# Next:
Task: One size buttons(?)
Task: Validation forms(edit&create)
Task: Update style

Graphs:
Pie chart
Column chart(by month)
Column chart(by month/in 2 years)
Stacked area chart