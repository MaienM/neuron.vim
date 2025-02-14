func! util#insert(zettelid, as_folgezettel)
	if a:as_folgezettel
		let l:formatted = "[[[".a:zettelid."]]]"
	else
		let l:formatted = "[[".a:zettelid."]]"
	endif

	let l:word_under = expand('<cword>')
	if !empty(l:word_under) && empty(trim(l:word_under, "[]<>"))
		" erase things like '[[]]' before adding
		execute "normal! diwi".l:formatted
	else
		execute "normal! a".l:formatted
	endif

	call neuron#add_virtual_titles()
	let g:must_refresh_on_write = 1
endf

func! util#is_zettelid_valid(zettelid)
	if empty(a:zettelid)
		return 0
	end
	if !empty(get(g:cache_titles, util#deform_zettelid(a:zettelid)))
		return 1
	else
		return 0
	end
endf

func! util#get_zettel_in_line(line)
	for zettel in g:cache_zettels
		let l:matched = matchstr(a:line, '\[\['.zettel['id'].'\]\]')
		if !empty(l:matched)
			return l:matched[2:-3]
		end
	endfor
	return ""
endf

func! util#get_zettel_from_fzf_line(line)
	return split(a:line, ":")[0]
endf

func! util#deform_zettelid(zettelid)
	if a:zettelid =~ "\[\[\[\?.*\]\]\]\?"
		return substitute(a:zettelid, '\[\[\[\?\([0-9a-zA-Z_-]\+\)\(?cf\)\?\]\]\]\?', '\1', 'g')
	else
		return a:zettelid
	end
endf

func! util#insert_shrink_fzf(line)
	call util#insert(util#get_zettel_from_fzf_line(a:line), 0)
endf

func! util#insert_shrink_fzf_folgezettel(line)
	call util#insert(util#get_zettel_from_fzf_line(a:line), 1)
endf

func! util#edit_shrink_fzf(line)
	call neuron#edit_zettel(util#get_zettel_from_fzf_line(a:line))
endf

func! util#remove_orphans(title)
	let l:count = 0
	let l:targetdir = '/tmp/orphan-zettels/'
	call mkdir(l:targetdir, 'p')
	for zettel in g:cache_zettels
		if zettel['title'] == a:title
			call system("mv ".g:zkdir.zettel['path']." ".l:targetdir)
			let l:count += 1
		end
	endfor
	echom l:count.' orphan zettels are moved to '.l:targetdir.'.'
	echom 'You can manually delete '.l:targetdir.' directory.'
endf

func! util#handlerr(errcode)
	let l:neuron_errors = deepcopy(g:neuron_errors)
	let l:err = l:neuron_errors[a:errcode]
	let l:errmsg='neuron: '.a:errcode.': '.l:err['problem']
	if len(l:err['suggestions']) > 0
		let l:errmsg .= '! suggestion(s): '.
			\ join(l:err['suggestions'], ' or ')
	end
	echoerr l:errmsg
endf

func! util#zettel_date_sorter(a, b)
	let l:ad = util#zettel_date_getter(a:a)
	let l:bd = util#zettel_date_getter(a:b)
	if l:ad == l:bd
		return 0
	elseif l:ad > l:bd
		return -1
	else
		return 1
	endif
endf

func! util#zettel_date_getter(z)
	let l:date = get(a:z, 'zettelDate', ['1970-01-01'])
	if type(l:date) != type([])
		let l:date = ['1970-01-01']
	endif
	return join(l:date)
endf

func! util#get_fzf_options()
	let l:ncol = (&columns - 4) / 2
	let l:ext = g:zextension

	return extend(deepcopy(g:fzf_options), [
		\ '--prompt', 'Search zettel: ',
		\ '--preview', "echo {} | sed 's/:.*/".l:ext."/' | xargs fold -w ".l:ncol." -s"
	\ ])
endf

func! util#current_zettel()
	return util#zettel_id_from_path(expand("%s"))
endf

func! util#zettel_id_from_path(path)
	return fnamemodify(a:path, ':t:r')
endf
