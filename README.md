# requests-core
Bare metal requests in dlang.

This repo implements common HTTP methods and clear interface with no extra abstractions and bullshit

example:
Response r = requests.get("http://www.pastebin.org/");

r.status_code         200;
r.headers             associative array over here with headers
r.cookies             list of cookies
r.content             string over here



// let's set a timeout
import std.datetime dur;

auto get_params = requests.RequestParams();
get_params.timeout = requests.Timeout(dur!"seconds"(1), dur!"seconds"(10));

Response r = requests.get("http://www.pastebin.org/", get_params);







