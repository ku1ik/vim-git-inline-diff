# Vim git inline diff

Adds signs on the left hand of your open buffer which mark the changed lines.

## Example
![_assets/example.png]

## Configuration

```vim
" Symbol for lines which have been added
let g:git_diff_added_symbol='+'

" Symbol for lines which have been removed
let g:git_diff_removed_symbol='-'

" Symbol for lines which have been changed
let g:git_diff_changed_symbol='<>'
```
