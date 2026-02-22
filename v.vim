" Vim syntax file for the V programming language
" Language:    V (vlang.io)
" Filenames:   *.v, *.vsh
"
" Handles:
"   import os { input, user_os }
"   import crypto.sha256
"   import mymod.sha256 as mysha256
"   module def
"   type MyTime = time.Time
"   fn (mut t MyTime) century() int { ... }
"   mut my_time := MyTime{ year: 2020 ... }
"   println(time.new(my_time).utc_string())
"   println('Century: ${my_time.century()}')
"   m.close = true
"   td.Manager{ waiters: map[string]chan json2.Any{} }

if exists("b:current_syntax")
  finish
endif

" ═══════════════════════════════════════════════════════════════
"  ORDER MATTERS: more specific rules come FIRST so they win
"  over broader matches below.
" ═══════════════════════════════════════════════════════════════


" ─────────────────────────────────────────────────────────────
"  STRINGS & INTERPOLATION
" ─────────────────────────────────────────────────────────────
syn match   vEscape          /\\[abfnrtv\\'"`0-9xuU]/ contained

" ${expr} inside strings
syn region  vInterpolation   matchgroup=vInterpDelim
    \ start=/\${/ end=/}/
    \ contained contains=TOP

" $varname  (simple interpolation without braces)
syn match   vSimpleInterp    /\$\w\+/ contained

syn region  vString          start=/"/ skip=/\\./ end=/"/
    \ contains=vInterpolation,vSimpleInterp,vEscape
syn region  vString          start=/`/  skip=/\\./ end=/`/
    \ contains=vInterpolation,vSimpleInterp,vEscape
syn region  vString          start=/'/  skip=/\\./ end=/'/
    \ contains=vInterpolation,vSimpleInterp,vEscape
syn region  vRawString       start=/r"/ skip=/\\./ end=/"/
syn region  vRawString       start=/r'/  skip=/\\./ end=/'/

" ─────────────────────────────────────────────────────────────
"  NUMBERS
" ─────────────────────────────────────────────────────────────
syn match   vNumber          /\<0x[0-9A-Fa-f_]\+\>/
syn match   vNumber          /\<0o[0-7_]\+\>/
syn match   vNumber          /\<0b[01_]\+\>/
syn match   vNumber          /\<[0-9][0-9_]*\(\.[0-9_]\+\)\?\([eE][+-]\?[0-9_]\+\)\?\>/

" ─────────────────────────────────────────────────────────────
"  COMPILER ATTRIBUTES / ANNOTATIONS
" ─────────────────────────────────────────────────────────────
syn match   vAttribute       /@\[.\{-}\]/
syn match   vAttribute       /\[.\{-}\]/

" ─────────────────────────────────────────────────────────────
"  IMPORT STATEMENT  –  full grammar:
"
"    import os
"    import crypto.sha256
"    import mymod.sha256 as mysha256
"    import os { input, user_os }
"
"  Coloring:
"    'import'         vDeclaration  (lavender bold)
"    'os' / 'mymod'   vImportMod    (teal bold)
"    '.sha256'        vImportSub    (seafoam)
"    'as'             vImportAsKw   (lavender italic)
"    'mysha256'       vImportAlias  (mint bold)
"    'input,user_os'  vImportSym    (rose)
" ─────────────────────────────────────────────────────────────

" Individual symbol names inside { }
syn match   vImportSym       /\<\w\+\>/ contained

" Full import line – parse sub-matches within
syn region  vImportLine      matchgroup=vDeclaration
    \ start=/\<import\>/  end=/$/
    \ contains=vImportMod,vImportDot,vImportSub,vImportAsKw,vImportAlias,vImportBraces,vComment
    \ keepend oneline

" Braces and symbols  { input, user_os }
syn region  vImportBraces    matchgroup=vImportBrace
    \ start=/{/ end=/}/
    \ contained contains=vImportSym

" Root module name right after 'import'
syn match   vImportMod       /\<[a-z][a-z0-9_]*\>/ contained
    \ nextgroup=vImportDot,vImportAsKw skipwhite

" The dot separating module parts
syn match   vImportDot       /\./ contained nextgroup=vImportSub

" Sub-module name after a dot
syn match   vImportSub       /\<[a-z][a-z0-9_]*\>/ contained
    \ nextgroup=vImportDot,vImportAsKw skipwhite

" 'as' keyword inside an import
syn match   vImportAsKw      /\<as\>/ contained nextgroup=vImportAlias skipwhite

" The alias name after 'as'
syn match   vImportAlias     /\<\w\+\>/ contained

" ─────────────────────────────────────────────────────────────
"  MODULE DECLARATION  –  module name
" ─────────────────────────────────────────────────────────────
syn region  vModuleLine      matchgroup=vDeclaration
    \ start=/\<module\>/ end=/$/
    \ contains=vModuleName,vComment
    \ keepend oneline

syn match   vModuleName      /\<[a-z][a-z0-9_]*\>/ contained

" ─────────────────────────────────────────────────────────────
"  TYPE ALIAS  –  type MyTime = time.Time
"  'type' → vDeclaration, alias name → vTypeAlias, rhs → vTypeName/vModulePrefix
" ─────────────────────────────────────────────────────────────
syn match   vTypeAlias
    \ /\<type\>\s\+\zs[A-Z]\w*/

" RHS  = time.Time  (module.Type or plain Type)
syn match   vTypeAliasRhs
    \ /\<type\>\s\+\w\+\s*=\s*\zs\w\+\ze\./
syn match   vTypeAliasRhsT
    \ /\<type\>\s\+\w\+\s*=\s*\(\w\+\.\)\?\zs[A-Z]\w*/

" ─────────────────────────────────────────────────────────────
"  FUNCTION DEFINITIONS
"  fn plain_func(...)
"  fn (recv Type) method(...)
"  fn (mut recv Type) method(...)
" ─────────────────────────────────────────────────────────────

" Receiver parts (matched inside the (…) after fn)
syn match   vReceiverMut     /\<mut\>/ contained
syn match   vReceiverName    /\<\w\+\>\ze\s\+\**[A-Z]/ contained
syn match   vReceiverType    /\<[A-Z]\w*\>/ contained

syn region  vReceiver        matchgroup=vReceiverParen
    \ start=/\<fn\>\s*(/ end=/)/
    \ contained contains=vReceiverMut,vReceiverName,vReceiverType,vOperator

" The function name after  fn  or  fn (receiver)
syn match   vFuncDef
    \ /\<fn\>\s*\((\s*\(\<mut\>\s\+\)\?\w\+\s\+\**\w\+\s*)\s*\)\?\zs\w\+/
    \ contains=vReceiver,vDeclaration

" ─────────────────────────────────────────────────────────────
"  FUNCTION CALLS  –  word(
" ─────────────────────────────────────────────────────────────
syn match   vFuncCall        /\<\w\+\ze\s*(/
    \ contains=vDeclaration,vKeyword,vBuiltin

" ─────────────────────────────────────────────────────────────
"  QUALIFIED ACCESS  –  pkg.fn(  /  pkg.Type  /  obj.field
"
"  time.new(...)   math.trunc(...)   time.Time   m.close   t.year
" ─────────────────────────────────────────────────────────────

" Module prefix before a lowercase call:  time.new(
syn match   vQualModule      /\<\w\+\ze\.\l\w*\s*(/

" Qualified function name:  .new(   .trunc(
syn match   vQualFunc        /\.\zs\l\w*\ze\s*(/

" Module prefix before a PascalCase type:  time.Time  json2.Any  td.Manager
syn match   vModulePrefix    /\<\w\+\ze\.[A-Z]/

" Qualified type name:  .Time   .Any   .Manager
syn match   vQualType        /\.\zs[A-Z]\w*/

" Dot-accessed field on lowercase var:  m.close   t.year   my_time.century
" (method handled above by vQualFunc / vDotMethod)
syn match   vDotMethod       /\.\zs\l\w*\ze\s*(/
syn match   vDotField        /\.\zs\l\w*/

" ─────────────────────────────────────────────────────────────
"  VARIABLE DECLARATIONS  –  name :=   /   mut name :=
" ─────────────────────────────────────────────────────────────
syn match   vVarDecl
    \ /\<\(mut\s\+\)\?\zs\w\+\ze\s*:=/

" ─────────────────────────────────────────────────────────────
"  STRUCT LITERAL FIELD NAMES  –  year: 2020   waiters: ...
" ─────────────────────────────────────────────────────────────
syn match   vStructField     /\<\l\w*\ze\s*:/

" ─────────────────────────────────────────────────────────────
"  STRUCT BODY FIELD DEFINITIONS  –  field  Type / map / chan
" ─────────────────────────────────────────────────────────────
syn match   vField
    \ /^\s*\zs\l\w*\ze\s\+\**\(\[\]\)*\([A-Z]\|\<map\>\|\<chan\>\|\<fn\>\|\[\)/

" ─────────────────────────────────────────────────────────────
"  PARAMETER NAMES  –  name Type  inside fn(...)
" ─────────────────────────────────────────────────────────────
syn match   vParamName
    \ /\((\|,\)\s*\zs\(\.\.\.\)\?\l\w*\ze\s\+\**\(\[\]\)*[A-Za-z]/

" ─────────────────────────────────────────────────────────────
"  PASCAL-CASE TYPE NAMES  (standalone, catch-all)
" ─────────────────────────────────────────────────────────────
syn match   vTypeName        /\<[A-Z][A-Za-z0-9_]*\>/

" ─────────────────────────────────────────────────────────────
"  KEYWORDS
" ─────────────────────────────────────────────────────────────

syn keyword vKeyword         if else for in match return break continue goto
syn keyword vKeyword         defer unsafe lock rlock select
syn keyword vKeyword         go spawn as

syn keyword vDeclaration     fn struct interface enum type union chan
syn keyword vDeclaration     module import pub mut shared

syn keyword vStorage         const static volatile

syn keyword vBoolean         true false
syn keyword vConstant        none null

syn keyword vType            bool byte rune string
syn keyword vType            i8 i16 int i64 i128
syn keyword vType            u8 u16 u32 u64 u128
syn keyword vType            f32 f64
syn keyword vType            voidptr byteptr charptr
syn keyword vType            any map

syn keyword vBuiltin         println print eprintln eprint
syn keyword vBuiltin         len cap sizeof typeof isnil
syn keyword vBuiltin         exit error panic assert
syn keyword vBuiltin         make new delete

syn keyword vSelf            self it this

" ─────────────────────────────────────────────────────────────
"  OPERATORS
" ─────────────────────────────────────────────────────────────
syn match   vOperator        /[-+*/%&|^~<>!=]=\?/
syn match   vOperator        /\.\./
syn match   vOperator        /<<\|>>/
syn match   vOperator        /&&\|||/
syn match   vOperator        /[!?]/
syn match   vArrow           /<-\|->/

" ─────────────────────────────────────────────────────────────
"  COMMENTS  –  declared LAST so they override all other rules.
"  Keywords, types, calls etc. will NOT fire inside comments.
" ─────────────────────────────────────────────────────────────

" These sub-groups are only active when contained inside a comment:
syn keyword vTodo            TODO FIXME XXX HACK NOTE WARN contained
syn match   vDocTag          /@\w\+/ contained

" Doc comments  ///  and  //!
syn region  vDocComment      start=/\/\/[\/!]/ end=/$/
    \ contains=vTodo,vDocTag,@Spell keepend

" Regular line comment  //  (but NOT ///  or  //!)
syn region  vComment         start=/\/\/\([^\/!]\|$\)/ end=/$/
    \ contains=vTodo,@Spell keepend

" Block comment  /* ... */
syn region  vBlockComment    start=/\/\*/ end=/\*\//
    \ contains=vTodo,vDocTag,@Spell keepend fold

" ═══════════════════════════════════════════════════════════════
"  HIGHLIGHT DEFINITIONS
"
"  Palette (dark-background):
"   #FF7F7F  coral      fn definitions
"   #FF9E7F  peach      fn calls, dot-methods
"   #FF9AC1  rose       parameters, interp delimiters, import symbols
"   #98E4A3  mint       variable declarations, import alias
"   #B5D9F0  ice-blue   struct/dot fields
"   #7EC8E3  sky-blue   types (PascalCase, vType keywords)
"   #56D0C5  teal       builtins, module prefixes, import mod names
"   #4EC9A0  seafoam    qualified fn calls (pkg.fn), import sub-modules
"   #C3A6FF  lavender   keywords, declarations
"   #D4A5FF  lilac      storage/const
"   #FFD580  gold       strings
"   #FFAB70  amber      numbers, booleans
"   #FFB347  orange     escape sequences
"   #6B8096  steel-grey comments
"   #A9B8FF  periwinkle attributes
"   #E8E8E8  off-white  operators
" ═══════════════════════════════════════════════════════════════

" Functions & calls
hi! vFuncDef       guifg=#FF7F7F   ctermfg=209   gui=bold          cterm=bold
hi! vFuncCall      guifg=#FF9E7F   ctermfg=215
hi! vDotMethod     guifg=#FF9E7F   ctermfg=215
hi! vQualFunc      guifg=#4EC9A0   ctermfg=43    gui=italic        cterm=NONE
hi! vQualModule    guifg=#56D0C5   ctermfg=80

" Receiver parts
hi! vReceiverParen guifg=#C3A6FF   ctermfg=183
hi! vReceiverMut   guifg=#C3A6FF   ctermfg=183   gui=bold          cterm=bold
hi! vReceiverName  guifg=#FF9AC1   ctermfg=211
hi! vReceiverType  guifg=#7EC8E3   ctermfg=117   gui=bold          cterm=bold

" Parameters
hi! vParamName     guifg=#FF9AC1   ctermfg=211

" Variables
hi! vVarDecl       guifg=#98E4A3   ctermfg=114

" Types
hi! vTypeName      guifg=#7EC8E3   ctermfg=117   gui=bold          cterm=bold
hi! vQualType      guifg=#7EC8E3   ctermfg=117   gui=bold          cterm=bold
hi! vTypeAlias     guifg=#7EC8E3   ctermfg=117   gui=bold,italic   cterm=bold
hi! vTypeAliasRhs  guifg=#56D0C5   ctermfg=80
hi! vTypeAliasRhsT guifg=#7EC8E3   ctermfg=117   gui=bold          cterm=bold
hi! vType          guifg=#7EC8E3   ctermfg=117
hi! vModulePrefix  guifg=#56D0C5   ctermfg=80

" Fields
hi! vField         guifg=#B5D9F0   ctermfg=153
hi! vStructField   guifg=#B5D9F0   ctermfg=153
hi! vDotField      guifg=#B5D9F0   ctermfg=153

" Import
hi! vImportMod     guifg=#56D0C5   ctermfg=80    gui=bold          cterm=bold
hi! vImportSub     guifg=#4EC9A0   ctermfg=43
hi! vImportDot     guifg=#6B8096   ctermfg=66
hi! vImportAsKw    guifg=#C3A6FF   ctermfg=183   gui=italic        cterm=NONE
hi! vImportAlias   guifg=#98E4A3   ctermfg=114   gui=bold          cterm=bold
hi! vImportSym     guifg=#FF9AC1   ctermfg=211
hi! vImportBrace   guifg=#C3A6FF   ctermfg=183

" Module declaration
hi! vModuleName    guifg=#56D0C5   ctermfg=80    gui=bold          cterm=bold

" Keywords
hi! vKeyword       guifg=#C3A6FF   ctermfg=183   gui=bold          cterm=bold
hi! vDeclaration   guifg=#C3A6FF   ctermfg=183   gui=bold          cterm=bold
hi! vStorage       guifg=#D4A5FF   ctermfg=177
hi! vBuiltin       guifg=#56D0C5   ctermfg=80
hi! vBoolean       guifg=#FFAB70   ctermfg=215   gui=bold          cterm=bold
hi! vConstant      guifg=#FFAB70   ctermfg=215
hi! vSelf          guifg=#C3A6FF   ctermfg=183   gui=italic,bold   cterm=bold

" Strings
hi! vString        guifg=#FFD580   ctermfg=221
hi! vRawString     guifg=#F4C97A   ctermfg=215
hi! vInterpolation guifg=#E8E8E8   ctermfg=188
hi! vInterpDelim   guifg=#FF9AC1   ctermfg=211   gui=bold          cterm=bold
hi! vSimpleInterp  guifg=#FF9AC1   ctermfg=211
hi! vEscape        guifg=#FFB347   ctermfg=214   gui=bold          cterm=bold

" Numbers
hi! vNumber        guifg=#FFAB70   ctermfg=215

" Comments
" Use 'hi!' (not 'hi def') so these always win over the active color scheme.
hi! vComment       guifg=#6B8096   ctermfg=66    gui=italic        cterm=NONE
hi! vBlockComment  guifg=#6B8096   ctermfg=66    gui=italic        cterm=NONE
hi! vDocComment    guifg=#8BA7BF   ctermfg=110   gui=italic        cterm=NONE
hi! vDocTag        guifg=#A9B8FF   ctermfg=147   gui=bold,italic   cterm=bold
hi! vTodo          guifg=#FFD580   ctermfg=221   gui=bold,italic   cterm=bold
                   \ guibg=#3A3020 ctermbg=236

" Operators
hi! vOperator      guifg=#E8E8E8   ctermfg=253
hi! vArrow         guifg=#FF9AC1   ctermfg=211   gui=bold          cterm=bold

" Attributes
hi! vAttribute     guifg=#A9B8FF   ctermfg=147   gui=italic        cterm=NONE

" ─────────────────────────────────────────────────────────────
"  SYNC & FINISH
" ─────────────────────────────────────────────────────────────
syn sync fromstart

let b:current_syntax = "v"

