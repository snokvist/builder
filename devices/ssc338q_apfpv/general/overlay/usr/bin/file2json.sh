#!/bin/sh
# file2json.sh — INI→JSON object; or lines→{"<key>":[...]} (strings by default)
# Usage: file2json.sh [-k KEY] [--typed-lines] [FILE|-]  (FILE omitted or "-" = stdin)

key="values"
typed_lines=0

while [ $# -gt 0 ]; do
  case "$1" in
    -k|--key) key="$2"; shift 2 ;;
    --typed-lines) typed_lines=1; shift ;;
    -h|--help) echo "Usage: $0 [-k KEY] [--typed-lines] [FILE|-]"; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) break ;;
  esac
done

f="${1:--}"  # default to stdin

run_awk() {
awk -v arr_key="$key" -v typed_lines="$typed_lines" '
function trim(s){ sub(/^[ \t\r\n]+/,"",s); sub(/[ \t\r\n]+$/,"",s); return s }
function esc(s){ gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); gsub(/\t/,"\\t",s); gsub(/\r/,"\\r",s); gsub(/\n/,"\\n",s); return s }
function isnum(s){ return (s ~ /^-?[0-9]+([.][0-9]+)?$/) }
function isbool(s){ s=tolower(s); return (s=="true"||s=="false") }
function val_tojson(v,   vv,n,p,i,allnum,allbool,res){
  vv=trim(v)
  if (vv ~ /,/) {
    n = split(vv, p, /,/)
    allnum=1; allbool=1
    for (i=1;i<=n;i++){ p[i]=trim(p[i]); if(!isnum(p[i])) allnum=0; if(!isbool(p[i])) allbool=0 }
    res="["
    for (i=1;i<=n;i++){
      if(i>1) res=res ","
      if (allnum)      res=res p[i]
      else if(allbool) res=res tolower(p[i])
      else             res=res "\"" esc(p[i]) "\""
    }
    return res "]"
  }
  if (isnum(vv))  return vv
  if (isbool(vv)) return tolower(vv)
  return "\"" esc(vv) "\""
}
function line_tojson(v){ return "\"" esc(trim(v)) "\"" }
function strip_comments(s,   i,c,n,in_q,prev,out,j){
  sub(/\r$/,"",s)
  n=length(s); in_q=0; prev=""; out=""
  for(i=1;i<=n;i++){
    c=substr(s,i,1)
    if(c=="\"" && prev!="\\"){ in_q=!in_q; out=out c; prev=c; continue }
    if(!in_q){
      if(c=="/" && substr(s,i+1,1)=="/" && (i==1 || substr(s,i-1,1) ~ /[[:space:]]/)) return trim(out)
      if(c=="/" && substr(s,i+1,1)=="*"){
        j=index(substr(s,i+2),"*/"); if(j){ i+=j+1; prev=""; continue } else return trim(out)
      }
      if((c=="#"||c==";") && (i==1 || substr(s,i-1,1) ~ /[[:space:]]/)) return trim(out)
    }
    out=out c; prev=c
  }
  return trim(out)
}

BEGIN{ nkv=0; nln=0 }
/^[[:space:]]*($|[#;]|\/\/)/ { next }

{
  line=strip_comments($0)
  if(line=="") next
  pos=index(line,"=")
  if (pos>0) {
    k=trim(substr(line,1,pos-1)); v=trim(substr(line,pos+1))
    if(k!=""){ nkv++; K[nkv]=k; V[nkv]=v }
  } else {
    nln++; L[nln]=line
  }
}

END{
  if (nkv>0 && nln==0) {
    printf "{"
    for(i=1;i<=nkv;i++){ if(i>1) printf ","; printf "\"%s\":%s", esc(K[i]), val_tojson(V[i]) }
    print "}"
    next
  }
  if (nkv==0 && nln>0) {
    printf "{"
    printf "\"%s\":[", esc(arr_key)
    for(i=1;i<=nln;i++){
      if(i>1) printf ","
      if(typed_lines) printf "%s", val_tojson(L[i]); else printf "%s", line_tojson(L[i])
    }
    print "]}"
    next
  }
  printf "{"
  first=1
  for(i=1;i<=nkv;i++){
    if(!first) printf ","; first=0
    printf "\"%s\":%s", esc(K[i]), val_tojson(V[i])
  }
  if(nln>0){
    if(!first) printf ","
    printf "\"%s\":[", esc(arr_key)
    for(i=1;i<=nln;i++){ if(i>1) printf ","; if(typed_lines) printf "%s", val_tojson(L[i]); else printf "%s", line_tojson(L[i]) }
    printf "]"
  }
  print "}"
}
'
}

if [ "$f" = "-" ]; then
  run_awk
else
  run_awk <"$f"
fi
