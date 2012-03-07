%start Request

%%

Request
  : SimpleRequest { return $1; }
  | FullRequest { return $1; }
  ;

SimpleRequest
  : METHOD SP PATH NEWLINE { $$ = {method: $1, url: $3, httpVersion: 0.9}; }
  ;

FullRequest
  : RequestLine NEWLINE
    HeaderList { $1.headers = {}; $3.forEach && $3.forEach(function(h){ $1.headers[h.name] = h.value; $$ = $1; }); }
  ;

RequestLine
  : METHOD SP PATH SP HttpVersion { $$ = {method: $1, url: $3, httpVersion: $5}; }
  ;

HeaderList
  : EOF { $$ = []; }
  | HEADER NEWLINE { $$ = [$1]; }
  | HEADER NEWLINE HeaderList { $$ = $3.concat([$1]); }
  ;

HttpVersion
  : HTTP NUMBER { $$ = $2; }
  ;