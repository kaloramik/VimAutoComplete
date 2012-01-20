" ============================================================================
" python_pydiction.vim - Module and Keyword completion for Python
" ============================================================================
"
" Author: Ryan Kulla (rkulla AT gmail DOT com)
" Version: 1.2, for Vim 7
" URL: http://www.vim.org/scripts/script.php?script_id=850
" Last Modified: July 22th, 2009
" Installation: On Linux, put this file in ~/.vim/after/ftplugin/
"               On Windows, put this file in C:\vim\vimfiles\ftplugin\
"                        (assuming you installed vim in C:\vim\).
"               You may install the other files anywhere. 
"               In .vimrc, add the following:
"                   filetype plugin on
"                   let g:pydiction_location = 'path/to/complete-dict'
"               Optionally, you set the completion menu height like:
"                   let g:pydiction_menu_height = 20
"               The default menu height is 15
"               To do case-sensitive searches, set noignorecase (:set noic).
" Usage: Type part of a Python keyword, module name, attribute or method,
"        then hit the TAB key and it will auto-complete (as long as it 
"        exists in the complete-dict file.
"        You can also use Shift-Tab to Tab backwards.
" License: BSD
" Copyright: Copyright (c) 2003-2009 Ryan Kulla
"            All rights reserved.
"
"            Redistribution and use in source and binary forms, with or without
"            modification, are permitted provided that the following conditions
"            are met:
"            1. Redistributions of source code must retain the above copyright
"               notice, this list of conditions and the following disclaimer.
"            2. Redistributions in binary form must reproduce the above
"               copyright notice, this list of conditions and the following
"               disclaimer in the documentation and/or other materials provided
"               with the distribution.
"            3. The name of the author may not be used to endorse or promote 
"               products derived from this software without specific prior 
"               written permission.
"
"            THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
"            OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
"            WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
"            ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
"            DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
"            DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
"            GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
"            INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
"            WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
"            NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
"            THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"
"

if v:version < 700
    echoerr "Pydiction requires vim version 7 or greater."
    finish
endif


" Make the Tab key do python code completion:
inoremap <silent> <buffer> <Tab> 
         \<C-R>=<SID>SetVals()<CR>
         \<C-R>=<SID>TabComplete('down')<CR>
         \<C-R>=<SID>RestoreVals()<CR>

" Make Shift+Tab do python code completion in the reverse direction:
inoremap <silent> <buffer> <S-Tab> 
         \<C-R>=<SID>SetVals()<CR>
         \<C-R>=<SID>TabComplete('up')<CR>
         \<C-R>=<SID>RestoreVals()<CR>




if !exists("*s:GetPreviousWord")
    function! s:GetPreviousWord()
      let lig = getline(line('.'))
      let lig = strpart(lig,0,col('.')-1)
      let exp = matchstr(lig, '\<\k*\>\s*$')
      let index = strridx(exp, '.')
      if index == -1
          return exp
      else 
          return exp[0:index]
    endfunction
endif

if !exists("*s:ParseCompleteInfo")
    function! s:ParseCompleteInfo(pystring)
        let mappings = {}
    for entry in split(a:pystring, '!')
        let key_kwd_pair = split(entry, '#')
        if len(key_kwd_pair) >= 2
            let key = key_kwd_pair[0]
            let kwds = key_kwd_pair[1]
            let kwd_list = split(kwds, '\$')
            let mappings[key] = kwd_list
        endif
    endfor
        return mappings
    endfunction
endif

""" if it doesnt exist, parse the mapping dict
if !exists("w:mapping_dict")
    let curr_file_name = expand('%:p')
    let curr_path = expand('%:p:h')

    let w:mapping_dict_string = system(printf('%s %s %s', g:py_parser_path, curr_file_name, curr_path)) 

    let w:mapping_dict = s:ParseCompleteInfo(w:mapping_dict_string)
    let w:test_mapping = w:mapping_dict

endif

if !exists("*s:TabComplete")
    function! s:TabComplete(direction)
        " Check if the char before the char under the cursor is an 
        " underscore, letter, number, dot or opening parentheses.
        " If it is, and if the popup menu is not visible, use 
        " I_CTRL-X_CTRL-K ('dictionary' only completion)--otherwise, 
        " use I_CTRL-N to scroll downward through the popup menu or
        " use I_CTRL-P to scroll upward through the popup menu, 
        " depending on the value of a:direction.
        " If the char is some other character, insert a normal Tab:
        if searchpos('[_a-zA-Z0-9.]\%#', 'nb') != [0, 0] 
            if !pumvisible()
                return "\<C-X>\<C-U>"
            else
                if a:direction == 'down'
                    return "\<C-N>"
                else
                    return "\<C-P>"
                endif
            endif
        else
            return "\<Tab>"
        endif
    endfunction
endif


if !exists("*g:PyCompleter")
    function g:PyCompleter(findstart, base)
        if a:findstart
            let line = getline('.')
            let start = col('.') - 1  
            while start > 0 && line[start - 1] =~ '\s'
                let start -= 1
            endwhile
            while start > 0 && line[start - 1] =~ '\w'
                let start -= 1
            endwhile
            return start
        else 
            let res = []
            if exists("w:mapping_dict")
                let prev_keyword = s:GetPreviousWord()
                " check if prev_keyword has dot, if so, remove it, other wise
                " use global
                let dot_index = strridx(prev_keyword, '.')
                if dot_index == -1
                    let dict_name = '@GLOBAL'
                else 
                    let dict_name = prev_keyword[0 : dot_index-1]
                endif 

                " TODO add check for dict_name existing
                if has_key(w:mapping_dict, dict_name)
                    for m in w:mapping_dict[dict_name]
                        if m =~ '^' . a:base
                            call add(res, m)
                        endif
                    endfor
                endif
            endif
            return res
        endif
    endfunction

endif

if !exists("*s:SetVals") 
    function! s:SetVals()
        "let g:test_dict = {'word' : 'basiermoot', 'abbr': 'basier', 'menu' : 'basier_menu', 'info' : 'basier_info', 'kind' : 'f' }
        "let g:results = []
        "call add(g:results, g:test_dict)
        " Save and change any config values we need.

        " Temporarily change isk to treat periods and opening 
        " parenthesis as part of a keyword -- so we can complete
        " python modules and functions:
        let s:pydiction_save_isk = &iskeyword
        setlocal iskeyword +=.

        set completefunc=g:PyCompleter

        " Save the ins-completion options the user has set:
        let s:pydiction_save_cot = &completeopt
        " Have the completion menu show up for one or more matches:
        let &completeopt = "menu,menuone"

        " Set the popup menu height:
        let s:pydiction_save_pumheight = &pumheight
        if !exists('g:pydiction_menu_height')
            let g:pydiction_menu_height = 15
        endif
        let &pumheight = g:pydiction_menu_height

        return ''
    endfunction
endif


if !exists("*s:RestoreVals")
    function! s:RestoreVals()
        " Restore the user's initial values.

        let &completeopt = s:pydiction_save_cot
        let &pumheight = s:pydiction_save_pumheight
        let &iskeyword = s:pydiction_save_isk

        return ''
    endfunction
endif

