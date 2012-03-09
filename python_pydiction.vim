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

