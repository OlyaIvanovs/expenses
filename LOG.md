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
+ Enter&validate date

# 26/06/2023
+ Pollishing
+ Dashboard tab: show categories + tick
+ Dashboard tab: add a graph

# 27/06/2023p
+ Polishing
+ Weekly column chart 

# 28/06/2023
+ Weekly column chart 

# 29/06/2023
+ show list of transactions on click: show all transactions + filter them 

# 30/06/2023
- monthly bar graph

# 01/07/2023

# 04/07/2023
+ monthly bar graph

# 05/07/2023
+ monthly bar graph: fix unfilter transactions
+ update monthly graph when update category & rules
+ dashboard_categories
+ create new structure for rules and categories and settings_transactions

# 06/07/2023
+ switch between monthly and weekly: unfilter;
+ categories: check adding category bug
+ categories : Transport bug
+ categories and rules bug
+ monthly graph: 12th month
+ show sub sum for chosen categories(?) dashboard & settings
+ rules: ad filter by category

# 07/07/2023
+ show sub sum of filtered transactions

# 10/07/2023
+ edit rule
+ rules: sort by name
+ color picker fix
+ predict category for rule

# 11/07/2023
+ do not save catetgory and rule without name
+ fix date validation

# 12/07/2023
+ settings_transactions struct

# 14/07/2023
+ Dropdown: Up and down
+ add edit category on dashboard page

+ Domino's & Pierrs
+ edit rule doesn't work
+ rules: sort by name
+ color picker bug: dark shade
+ check rules and transactions when remove category
+ categories: do not save category without name
+ date validation bug
+ add settings_transactions struct

- bug: dashboard dropdown crop by wrapper height
- style: Dialog's inputs
- decide on adding transaction: end or begin/ remove to_bottom
- Update style
? show date on week number hover 
