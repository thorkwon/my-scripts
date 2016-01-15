set smartindent
set ai
set ts=8
set sw=8
set nu
set hls
set ic
set scs
set laststatus=2
set mouse=a

set tags+=./tags
set tags+=/home/khg/Projects/linux-exynos/tags

set csprg=/usr/bin/cscope
set csto=0
set cst
set nocsverb

if filereadable("./cscope.out")
	cs add cscope.out
else
	cs add /home/khg/Projects/linux-exynos/cscope.out
endif

set csverb

"Taglist
map <F4> :Tlist<cr>
