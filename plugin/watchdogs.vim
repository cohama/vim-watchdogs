if exists('g:loaded_watchdogs')
  finish
endif
let g:loaded_watchdogs = 1

let s:save_cpo = &cpo
set cpo&vim


function! s:watchdogs_type(filetype)
	return get(b:, "watchdogs_checker_type", a:filetype."/watchdogs_checker")
endfunction


function! s:run(type, args, ...)
	if !exists("g:quickrun_config")
		let g:quickrun_config = {}
	endif
	if !has_key(g:quickrun_config, "watchdogs_checker_dummy")
		call watchdogs#setup(g:quickrun_config)
	endif

	let is_output_msg = a:0 ? a:1 : 0

	let line_config = extend(deepcopy(get(g:quickrun_config, "watchdogs_checker/_", {})), quickrun#config(a:args))

	if !has_key(line_config, "type")
		let line_config.type = a:type
	endif

	if line_config.type =~# '^.\+/watchdogs_checker$'
\	&& empty(get(get(g:quickrun_config, a:type, {}), "type", ""))
		if is_output_msg
			echoerr "==watchdogs error== Empty type ".a:type
		endif
		return
	endif

	call quickrun#run(line_config)
endfunction


command! -nargs=* -range=0 -complete=customlist,quickrun#complete
\	WatchdogsRun call s:run(s:watchdogs_type(&filetype), <q-args>, 1)

command! -nargs=* -range=0 -complete=customlist,quickrun#complete
\	WatchdogsRunSilent call s:run(s:watchdogs_type(&filetype), <q-args>)

command! -nargs=0
\	WatchdogsRunSweep call quickrun#sweep_sessions()


let g:watchdogs_quickrun_running_check =
\	get(g:, "g:watchdogs_quickrun_running_check", 0)


let g:watchdogs_check_BufWritePost_enable =
\	get(g:, "watchdogs_check_BufWritePost_enable", 0)

let g:watchdogs_check_BufWritePost_enables =
\	get(g:, "watchdogs_check_BufWritePost_enables", {})


function! s:watchdogs_check_bufwrite(filetype)
	if exists("*quickrun#is_running")
		if quickrun#is_running()
			return
		endif
	else
		if g:watchdogs_quickrun_running_check
			return
		endif
	endif
	if (g:watchdogs_check_BufWritePost_enable
\	|| get(g:watchdogs_check_BufWritePost_enables, a:filetype, 0))
\	&& get(g:watchdogs_check_BufWritePost_enables, a:filetype, 1)
		WatchdogsRunSilent -hook/watchdogs_quickrun_running_checker/enable 0
	endif
endfunction


let g:watchdogs_check_CursorHold_enable =
\	get(g:, "watchdogs_check_CursorHold_enable", 0)

let g:watchdogs_check_CursorHold_enables =
\	get(g:, "watchdogs_check_CursorHold_enables", {})


function! s:watchdogs_check_cursorhold(filetype)
	if exists("*quickrun#is_running")
		if quickrun#is_running()
			return
		endif
	else
		if g:watchdogs_quickrun_running_check
			return
		endif
	endif
	if get(b:, "watchdogs_checked_cursorhold", 1)
		return
	endif
	if (g:watchdogs_check_CursorHold_enable
\	|| get(g:watchdogs_check_CursorHold_enables, a:filetype, 0))
\	&& get(g:watchdogs_check_CursorHold_enables, a:filetype, 1)
		WatchdogsRunSilent -hook/watchdogs_quickrun_running_checker/enable 0
		let b:watchdogs_checked_cursorhold=1
	endif
endfunction


augroup watchdogs-plugin
	autocmd!
	autocmd BufWritePost * call <SID>watchdogs_check_bufwrite(&filetype)

	autocmd BufWritePost * let b:watchdogs_checked_cursorhold = 0
	autocmd CursorHold   * call <SID>watchdogs_check_cursorhold(&filetype)
augroup END



let &cpo = s:save_cpo
unlet s:save_cpo
