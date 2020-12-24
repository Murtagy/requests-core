# requests-core
Bare metal requests in dlang.

This repo implements common HTTP methods and clear interface with no extra abstractions and bullshit

example:
Response r = requests.get("http://www.pastebin.org/");
// r.status_code
// r.headers
// r.cookies
// r.content
