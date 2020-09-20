if exists("g:loaded_linkztxt")
        finish
endif
let g:loaded_linkztxt = 1

let s:plugin_name = "linkztxt.nvim"

let s:linkztxt_filename = "linkz.txt"

function! s:exec_external_command(command)
        if has("nvim") == 1
                call jobstart(["bash", "-c", a:command])
        elseif v:version >= 800
                call job_start("bash -c " . a:command)
        else
                silent execute "!" . a:command
        endif
endfunction

function! s:read_file_as_string(filepath)
        let lines = readfile(a:filepath)
        return join(lines, "\n")
endfunction

function! s:file_exists(filepath)
        if filereadable(a:filepath)
                return 1
        else
                return 0
        endif
endfunction

function! s:is_line_empty(line)
	return match(a:line, '^\s*$') != -1
endfunction

function! s:is_line_not_empty(line)
	return match(a:line, '^\s*$') == -1
endfunction

function! s:linkztxt_file_available()
	if s:file_exists(s:linkztxt_filename)
		return 1
	else
		echom "linkz.txt not found."
		return 0
	endif
endfunction

function! s:get_linkztxt_dict()
	let s:file = readfile(s:linkztxt_filename)
	let s:i = 0
	let s:dict = {}
	let s:title = ''

	for s:line in s:file
		if s:is_line_not_empty(s:line)
			if s:i == 0
				let s:title = s:line
			else
				let s:dict[s:title] = s:line
			endif
			if s:i == 0
				let s:i += 1
			else
				let s:i = 0
			endif
		endif
	endfor

        return s:dict
endfunction

function! s:get_linkztxt_list()
	let s:list = []
	let s:links = s:get_linkztxt_dict()
	for [key, _] in items(s:links)
		call add(s:list, key)
	endfor
        return s:list
endfunction

function! s:linkztxt_completion(linkstring, line, pos)
	let s:links_list = []

	if s:linkztxt_file_available() == 1
		let s:links = s:get_linkztxt_dict()
		for [key, _] in items(s:links)
			call add(s:links_list, key)
		endfor
	endif

        return filter(s:links_list, 'v:val =~ "^'. a:linkstring .'"')
endfunction

function! linkztxt#link(...)
	if s:linkztxt_file_available() == 1
		let s:linkz_key = ""
		let s:index = 0
		for links_key_seg in a:000
			if s:index != 0
				let s:linkz_key = s:linkz_key . " "
			endif
			let s:linkz_key = s:linkz_key . links_key_seg
			let s:index += 1
		endfor

		let links = s:get_linkztxt_dict()
		let link = links[s:linkz_key]
		let cmd = "xdg-open '" . link . "'"
		call s:exec_external_command(cmd)
	endif
endfunction

function! s:fzf_format_link_list_item(item) abort
	return a:item
endfunction

function! s:fzf_link_list_handler(item) abort
	let links = s:get_linkztxt_dict()
	let link = links[a:item]
	let cmd = "xdg-open '" . link . "'"
	call s:exec_external_command(cmd)
endfunction

function! linkztxt#list()
	if s:linkztxt_file_available() == 1
		let s:linkztxt_dict =  s:get_linkztxt_dict()
		call fzf#run(fzf#wrap({
					\ 'source': map(s:get_linkztxt_list(), 's:fzf_format_link_list_item(v:val)'),
					\ 'sink': function('s:fzf_link_list_handler'),
					\ 'options': printf('--prompt="%s> "', ('Linkz'))
					\ }))
	endif
endfunction

command! LinkzList call linkztxt#list()

