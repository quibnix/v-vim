" Vim syntax file for the V programming language
" Language:    V (vlang.io)
" Filenames:   *.v, *.vsh

if exists("b:current_syntax")
  finish
endif

" ═══════════════════════════════════════════════════════════════
"  PRIORITY MODEL (read this before editing)
"
"  Vim syn match: when two patterns start at the same column,
"  the one defined LATER in the file wins.  That means:
"
"    • broad / short patterns  →  defined early  (low priority)
"    • narrow / long patterns  →  defined late   (high priority)
"
"  Operators MUST come last among match rules so multi-char
"  tokens like := || == >= beat any earlier single-char match.
"  Comments come after even the operators because they must
"  override everything.
"
"  syn keyword always beats syn match for the same word, so
"  keyword order does not matter for priority purposes.
" ═══════════════════════════════════════════════════════════════


" ─────────────────────────────────────────────────────────────
"  STRINGS & INTERPOLATION
"
"  BUG FIX: vInterpolation previously used contains=TOP which
"  allowed vString to start inside ${...} and bleed past the
"  closing }, turning all subsequent code string-colored.
"  Fix: named cluster @vCode (excludes vString/vRawString) +
"       keepend on vInterpolation.
" ─────────────────────────────────────────────────────────────
syn match   vEscape          /\\[abfnrtv\\'"` 0-9xuU]/ contained

" Everything legal inside ${...} — notably no vString/vRawString
syn cluster vCode contains=
    \ vNumber,vBoolean,vConstant,
    \ vKeyword,vDeclaration,vStorage,vType,vBuiltin,vSelf,
    \ vTypeName,vTypeAlias,vTypeAliasRhs,vTypeAliasRhsT,
    \ vFuncDef,vFuncCall,
    \ vQualModule,vQualFunc,vQualType,vModulePrefix,
    \ vDotMethod,vDotField,
    \ vVarDecl,vStructField,vField,vParamName,
    \ vPunct,vArrow,vAssignOp,vLogicOp,vCompareOp,vOperator,
    \ vSimpleInterp,vEscape,vAttribute

syn region  vInterpolation   matchgroup=vInterpDelim
    \ start=/\${/ end=/}/
    \ contained keepend contains=@vCode,vInterpolation

syn match   vSimpleInterp    /\$\w\+/ contained

syn region  vString    start=/"/ skip=/\\./ end=/"/ contains=vInterpolation,vSimpleInterp,vEscape
syn region  vString    start=/`/  skip=/\\./ end=/`/ contains=vInterpolation,vSimpleInterp,vEscape
syn region  vString    start=/'/  skip=/\\./ end=/'/ contains=vInterpolation,vSimpleInterp,vEscape
syn region  vRawString start=/r"/ skip=/\\./ end=/"/
syn region  vRawString start=/r'/ skip=/\\./ end=/'/

" ─────────────────────────────────────────────────────────────
"  NUMBERS
" ─────────────────────────────────────────────────────────────
syn match   vNumber    /\<0x[0-9A-Fa-f_]\+\>/
syn match   vNumber    /\<0o[0-7_]\+\>/
syn match   vNumber    /\<0b[01_]\+\>/
syn match   vNumber    /\<[0-9][0-9_]*\(\.[0-9_]\+\)\?\([eE][+-]\?[0-9_]\+\)\?\>/

" ─────────────────────────────────────────────────────────────
"  COMPILER ATTRIBUTES / ANNOTATIONS
"
"  BUG FIX: anchored to line start; V attributes are always
"  there and this prevents matching arr["key"] as an attribute.
" ─────────────────────────────────────────────────────────────
syn match   vAttribute /^\s*@\?\[.\{-}\]/

" ─────────────────────────────────────────────────────────────
"  IMPORT STATEMENT
"    import os
"    import crypto.sha256
"    import mymod.sha256 as mysha256
"    import os { input, user_os }
" ─────────────────────────────────────────────────────────────
syn match   vImportSym   /\<\w\+\>/ contained

syn region  vImportLine  matchgroup=vDeclaration
    \ start=/\<import\>/ end=/$/
    \ contains=vImportMod,vImportDot,vImportSub,vImportAsKw,vImportAlias,vImportBraces,vComment
    \ keepend oneline

syn region  vImportBraces matchgroup=vImportBrace
    \ start=/{/ end=/}/
    \ contained contains=vImportSym

syn match   vImportMod   /\<[a-z][a-z0-9_]*\>/ contained nextgroup=vImportDot,vImportAsKw skipwhite
syn match   vImportDot   /\./ contained nextgroup=vImportSub
syn match   vImportSub   /\<[a-z][a-z0-9_]*\>/ contained nextgroup=vImportDot,vImportAsKw skipwhite
syn match   vImportAsKw  /\<as\>/ contained nextgroup=vImportAlias skipwhite
syn match   vImportAlias /\<\w\+\>/ contained

" ─────────────────────────────────────────────────────────────
"  MODULE DECLARATION
" ─────────────────────────────────────────────────────────────
syn region  vModuleLine  matchgroup=vDeclaration
    \ start=/\<module\>/ end=/$/
    \ contains=vModuleName,vComment
    \ keepend oneline

syn match   vModuleName  /\<[a-z][a-z0-9_]*\>/ contained

" ─────────────────────────────────────────────────────────────
"  TYPE ALIAS  –  type MyTime = time.Time
" ─────────────────────────────────────────────────────────────
syn match   vTypeAlias     /\<type\>\s\+\zs[A-Z]\w*/
syn match   vTypeAliasRhs  /\<type\>\s\+\w\+\s*=\s*\zs\w\+\ze\./
syn match   vTypeAliasRhsT /\<type\>\s\+\w\+\s*=\s*\(\w\+\.\)\?\zs[A-Z]\w*/

" ─────────────────────────────────────────────────────────────
"  FUNCTION DEFINITIONS
"  fn plain_func(...)
"  fn (recv Type) method(...)
"  fn (mut recv Type) method(...)
" ─────────────────────────────────────────────────────────────
syn match   vReceiverMut  /\<mut\>/ contained
syn match   vReceiverName /\<\w\+\>\ze\s\+\**[A-Z]/ contained
syn match   vReceiverType /\<[A-Z]\w*\>/ contained

syn region  vReceiver     matchgroup=vReceiverParen
    \ start=/\<fn\>\s*(/ end=/)/
    \ contained contains=vReceiverMut,vReceiverName,vReceiverType,vOperator,vPunct

syn match   vFuncDef
    \ /\<fn\>\s*\((\s*\(\<mut\>\s\+\)\?\w\+\s\+\**\w\+\s*)\s*\)\?\zs\w\+/
    \ contains=vReceiver,vDeclaration

" ─────────────────────────────────────────────────────────────
"  FUNCTION CALLS  –  word(
" ─────────────────────────────────────────────────────────────
syn match   vFuncCall /\<\w\+\ze\s*(/ contains=vDeclaration,vKeyword,vBuiltin

" ─────────────────────────────────────────────────────────────
"  QUALIFIED ACCESS  –  pkg.fn(  /  pkg.Type  /  obj.field
" ─────────────────────────────────────────────────────────────
syn match   vQualModule   /\<\w\+\ze\.\l\w*\s*(/
syn match   vQualFunc     /\.\zs\l\w*\ze\s*(/
syn match   vModulePrefix /\<\w\+\ze\.[A-Z]/
syn match   vQualType     /\.\zs[A-Z]\w*/
syn match   vDotMethod    /\.\zs\l\w*\ze\s*(/
syn match   vDotField     /\.\zs\l\w*/

" ─────────────────────────────────────────────────────────────
"  VARIABLE DECLARATIONS  –  name :=   /   mut name :=
" ─────────────────────────────────────────────────────────────
syn match   vVarDecl /\<\(mut\s\+\)\?\zs\w\+\ze\s*:=/

" ─────────────────────────────────────────────────────────────
"  STRUCT LITERAL FIELD NAMES  –  year: 2020
" ─────────────────────────────────────────────────────────────
syn match   vStructField /\<\l\w*\ze\s*:/

" ─────────────────────────────────────────────────────────────
"  STRUCT BODY FIELD DEFINITIONS
" ─────────────────────────────────────────────────────────────
syn match   vField
    \ /^\s*\zs\l\w*\ze\s\+\**\(\[\]\)*\([A-Z]\|\<map\>\|\<chan\>\|\<fn\>\|\[\)/

" ─────────────────────────────────────────────────────────────
"  PARAMETER NAMES  –  name Type  inside fn(...)
" ─────────────────────────────────────────────────────────────
syn match   vParamName
    \ /\((\|,\)\s*\zs\(\.\.\.\)\?\l\w*\ze\s\+\**\(\[\]\)*[A-Za-z]/

" ─────────────────────────────────────────────────────────────
"  PASCAL-CASE TYPE NAMES  (catch-all)
" ─────────────────────────────────────────────────────────────
syn match   vTypeName /\<[A-Z][A-Za-z0-9_]*\>/

" ─────────────────────────────────────────────────────────────
"  KEYWORDS
" ─────────────────────────────────────────────────────────────
syn keyword vKeyword    if else for in match return break continue goto
syn keyword vKeyword    defer unsafe lock rlock select
syn keyword vKeyword    go spawn as or is

syn keyword vDeclaration fn struct interface enum type union chan
syn keyword vDeclaration module import pub mut shared

syn keyword vStorage    const static volatile

syn keyword vBoolean    true false
syn keyword vConstant   none null

syn keyword vType       bool byte rune string
syn keyword vType       i8 i16 int i64 i128
syn keyword vType       u8 u16 u32 u64 u128
syn keyword vType       f32 f64
syn keyword vType       voidptr byteptr charptr
syn keyword vType       any map

syn keyword vBuiltin    println print eprintln eprint
syn keyword vBuiltin    len cap sizeof typeof isnil
syn keyword vBuiltin    exit error panic assert
syn keyword vBuiltin    make new delete

syn keyword vSelf       self it this

" ─────────────────────────────────────────────────────────────
"  PUNCTUATION & OPERATORS
"
"  Defined LAST among match rules (only comments come after).
"  Longer / more specific patterns are defined after shorter
"  ones so they win the priority race at the same column.
"
"  Groups:
"    vPunct      – structural delimiters  ( ) [ ] { }  . ? \
"    vAssignOp   – assignment variants    := = += -= *= /= etc.
"    vCompareOp  – comparisons            == != < > <= >=
"    vLogicOp    – logical                && || !
"    vOperator   – arithmetic / bitwise   + - * / % & | ^ ~ << >> ..
"    vArrow      – channel arrows         <- ->
" ─────────────────────────────────────────────────────────────

" ── Punctuation ─────────────────────────────────────────────
" Brackets/braces/parens — never part of an operator token.
syn match   vPunct      /[(){}\[\]]/
" Dot: qualified-access rules defined earlier win at ident.field,
" so only a bare dot (e.g. float prefix, lone separator) falls here.
syn match   vPunct      /\./
" Remaining structural chars
syn match   vPunct      /[?\\]/

" ── Arithmetic / bitwise (single-char base forms) ────────────
" Defined early in the operator block so compound forms below win.
syn match   vOperator   /[+\-*\/%]/
syn match   vOperator   /[&|^~]/
" NOTE: bare < and > are listed here; == != <= >= are redefined
" later as vCompareOp and win because they're defined after.
syn match   vOperator   /[<>]/

" ── Compound bitwise shift  << >> ───────────────────────────
syn match   vOperator   /<<\|>>/

" ── Range  .. ───────────────────────────────────────────────
syn match   vOperator   /\.\./

" ── Compound assignment  += -= *= /= %= &= |= ^= ────────────
syn match   vAssignOp   /[-+*\/%&|^]=/

" ── Shift assignment  <<= >>= ───────────────────────────────
syn match   vAssignOp   /<<=/
syn match   vAssignOp   />>=/

" ── Plain assignment  = (not ==) ────────────────────────────
syn match   vAssignOp   /=\ze[^=]/

" ── Short variable declaration  := ──────────────────────────
syn match   vAssignOp   /:=/

" ── Comparisons  == != <= >= ────────────────────────────────
" These are defined AFTER bare < > and bare = so they win.
syn match   vCompareOp  /==\|!=\|<=\|>=/

" ── Logical  && || ──────────────────────────────────────────
syn match   vLogicOp    /&&\|||/

" ── Logical NOT  ! (must come after != so != wins) ──────────
syn match   vLogicOp    /!\ze[^=]/

" ── Channel arrows  <- -> ───────────────────────────────────
syn match   vArrow      /<-\|->/

" ─────────────────────────────────────────────────────────────
"  COMMENTS — defined VERY LAST; override everything.
" ─────────────────────────────────────────────────────────────
syn keyword vTodo       TODO FIXME XXX HACK NOTE WARN contained
syn match   vDocTag     /@\w\+/ contained

syn region  vDocComment   start=/\/\/[\/!]/ end=/$/
    \ contains=vTodo,vDocTag,@Spell keepend

syn region  vComment      start=/\/\/\([^\/!]\|$\)/ end=/$/
    \ contains=vTodo,@Spell keepend

syn region  vBlockComment start=/\/\*/ end=/\*\//
    \ contains=vTodo,vDocTag,@Spell keepend fold

" ═══════════════════════════════════════════════════════════════
"  HIGHLIGHT DEFINITIONS
"
"  Palette — optimised for readability on dark backgrounds.
"
"  Semantic colour logic:
"   Functions / calls    warm reds & peaches   stand out as "actions"
"   Types / structs      cool blues             data shape
"   Variables / params   greens & rose          data values
"   Keywords             lavender bold           control flow
"   Operators (by role):
"     assignment         spring green           "write" — linked to vVarDecl
"     comparison         sky cyan               "test"
"     logical            orchid                 "combine"
"     arithmetic         warm white             "compute"
"   Punctuation          dim slate              scaffolding, unobtrusive
"   Strings              gold                   literals pop
"   Numbers              amber                  numeric literals
"   Comments             steel-grey italic      clearly secondary
" ═══════════════════════════════════════════════════════════════

" ── Functions ───────────────────────────────────────────────
hi! vFuncDef       guifg=#FF7F7F   ctermfg=209   gui=bold         cterm=bold
hi! vFuncCall      guifg=#FF9E7F   ctermfg=215   gui=NONE         cterm=NONE
hi! vDotMethod     guifg=#FF9E7F   ctermfg=215   gui=NONE         cterm=NONE
hi! vQualFunc      guifg=#FFBB88   ctermfg=216   gui=italic       cterm=NONE
hi! vQualModule    guifg=#56D0C5   ctermfg=80    gui=NONE         cterm=NONE

" ── Receiver ────────────────────────────────────────────────
hi! vReceiverParen guifg=#C3A6FF   ctermfg=183   gui=NONE         cterm=NONE
hi! vReceiverMut   guifg=#C3A6FF   ctermfg=183   gui=bold         cterm=bold
hi! vReceiverName  guifg=#FF9AC1   ctermfg=211   gui=NONE         cterm=NONE
hi! vReceiverType  guifg=#7EC8E3   ctermfg=117   gui=bold         cterm=bold

" ── Parameters & variables ──────────────────────────────────
hi! vParamName     guifg=#FF9AC1   ctermfg=211   gui=NONE         cterm=NONE
hi! vVarDecl       guifg=#98E4A3   ctermfg=114   gui=NONE         cterm=NONE

" ── Types ───────────────────────────────────────────────────
hi! vTypeName      guifg=#7EC8E3   ctermfg=117   gui=bold         cterm=bold
hi! vQualType      guifg=#7EC8E3   ctermfg=117   gui=bold         cterm=bold
hi! vTypeAlias     guifg=#7EC8E3   ctermfg=117   gui=bold,italic  cterm=bold
hi! vTypeAliasRhs  guifg=#56D0C5   ctermfg=80    gui=NONE         cterm=NONE
hi! vTypeAliasRhsT guifg=#7EC8E3   ctermfg=117   gui=bold         cterm=bold
hi! vType          guifg=#7EC8E3   ctermfg=117   gui=NONE         cterm=NONE
hi! vModulePrefix  guifg=#56D0C5   ctermfg=80    gui=NONE         cterm=NONE

" ── Fields ──────────────────────────────────────────────────
hi! vField         guifg=#B5D9F0   ctermfg=153   gui=NONE         cterm=NONE
hi! vStructField   guifg=#B5D9F0   ctermfg=153   gui=NONE         cterm=NONE
hi! vDotField      guifg=#B5D9F0   ctermfg=153   gui=NONE         cterm=NONE

" ── Import ──────────────────────────────────────────────────
hi! vImportMod     guifg=#56D0C5   ctermfg=80    gui=bold         cterm=bold
hi! vImportSub     guifg=#4EC9A0   ctermfg=43    gui=NONE         cterm=NONE
hi! vImportDot     guifg=#556677   ctermfg=60    gui=NONE         cterm=NONE
hi! vImportAsKw    guifg=#C3A6FF   ctermfg=183   gui=italic       cterm=NONE
hi! vImportAlias   guifg=#98E4A3   ctermfg=114   gui=bold         cterm=bold
hi! vImportSym     guifg=#FF9AC1   ctermfg=211   gui=NONE         cterm=NONE
hi! vImportBrace   guifg=#C3A6FF   ctermfg=183   gui=NONE         cterm=NONE

" ── Module ──────────────────────────────────────────────────
hi! vModuleName    guifg=#56D0C5   ctermfg=80    gui=bold         cterm=bold

" ── Keywords ────────────────────────────────────────────────
hi! vKeyword       guifg=#C3A6FF   ctermfg=183   gui=bold         cterm=bold
hi! vDeclaration   guifg=#C3A6FF   ctermfg=183   gui=bold         cterm=bold
hi! vStorage       guifg=#D4A5FF   ctermfg=177   gui=NONE         cterm=NONE
hi! vBuiltin       guifg=#56D0C5   ctermfg=80    gui=NONE         cterm=NONE
hi! vBoolean       guifg=#FFAB70   ctermfg=215   gui=bold         cterm=bold
hi! vConstant      guifg=#FFAB70   ctermfg=215   gui=NONE         cterm=NONE
hi! vSelf          guifg=#C3A6FF   ctermfg=183   gui=bold,italic  cterm=bold

" ── Strings ─────────────────────────────────────────────────
hi! vString        guifg=#FFD580   ctermfg=221   gui=NONE         cterm=NONE
hi! vRawString     guifg=#F4C97A   ctermfg=215   gui=NONE         cterm=NONE
hi! vInterpolation guifg=#E8E8E8   ctermfg=188   gui=NONE         cterm=NONE
hi! vInterpDelim   guifg=#FF9AC1   ctermfg=211   gui=bold         cterm=bold
hi! vSimpleInterp  guifg=#FF9AC1   ctermfg=211   gui=NONE         cterm=NONE
hi! vEscape        guifg=#FFB347   ctermfg=214   gui=bold         cterm=bold

" ── Numbers ─────────────────────────────────────────────────
hi! vNumber        guifg=#FFAB70   ctermfg=215   gui=NONE         cterm=NONE

" ── Operators ───────────────────────────────────────────────
"  Assignment  :=  =  +=  -=  …   →  spring green (echoes vVarDecl)
hi! vAssignOp    guifg=#7DD9A0   ctermfg=114   gui=bold         cterm=bold

"  Comparison  == != < > <= >=   →  bright sky cyan
hi! vCompareOp   guifg=#5FD7FF   ctermfg=81    gui=bold         cterm=bold

"  Logical  && || !               →  orchid / soft purple
hi! vLogicOp     guifg=#D48FFF   ctermfg=177   gui=bold         cterm=bold

"  Arithmetic / bitwise  + - * / % & | ^ ~ << >> ..
"  Warm off-white — readable, not competing with the bold groups above
hi! vOperator    guifg=#E8D8C0   ctermfg=223   gui=NONE         cterm=NONE

"  Channel arrows  <- ->          →  rose bold (rare, must pop)
hi! vArrow       guifg=#FF9AC1   ctermfg=211   gui=bold         cterm=bold

"  Structural punctuation  ( ) [ ] { }  .  ?  \
"  Deliberately dim — scaffolding, not information
hi! vPunct       guifg=#5A6A7A   ctermfg=60    gui=NONE         cterm=NONE

" ── Comments ────────────────────────────────────────────────
hi! vComment       guifg=#6B8096   ctermfg=66    gui=italic       cterm=NONE
hi! vBlockComment  guifg=#6B8096   ctermfg=66    gui=italic       cterm=NONE
hi! vDocComment    guifg=#8BA7BF   ctermfg=110   gui=italic       cterm=NONE
hi! vDocTag        guifg=#A9B8FF   ctermfg=147   gui=bold,italic  cterm=bold
hi! vTodo          guifg=#FFD580   ctermfg=221   gui=bold,italic  cterm=bold
                   \ guibg=#3A3020 ctermbg=236

" ── Attributes ──────────────────────────────────────────────
hi! vAttribute     guifg=#A9B8FF   ctermfg=147   gui=italic       cterm=NONE

" ─────────────────────────────────────────────────────────────
"  SYNC & FINISH
" ─────────────────────────────────────────────────────────────
syn sync fromstart

let b:current_syntax = "v"
