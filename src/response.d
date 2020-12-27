// ver 0.1

import std.json: JSONValue, parseJSON;

import std.array : split;
import std.conv: to;
import std.stdio: writeln, writefln;
import std.string: format, indexOf, lineSplitter, strip;
import std.typecons : Yes;

debug = RESPONSE;

struct Response {  // this structure will change to use some pointers probably later on
    int             status_code = 444;
    string[string]  headers;
    string         _headers;
    string[]        cookies;
    string          content;
    string         _content;
};

Response get(string url) {
    // url contains http schema, host, path, query string
    auto schema_end = 0;
    writeln(url[0..7]);
    bool is_http  = (url[0..7] == "http://");
    bool is_https = (url[0..8] == "https://");
    if  (is_http)   schema_end = 7;
    if  (is_https)  schema_end = 8;

    debug(RESPONSE)  writefln("Schema ended at %d", schema_end);
    auto host = url[schema_end..$]; // we start at calling everything host and then deduce it to port and path

    debug(RESPONSE)  writefln("Host ... %s", host);

    auto path = "/";
    long path_start = indexOf(host, '/');
    if (path_start != -1)  {
        path = host[path_start..$];
        host = host[0..path_start];

        debug(RESPONSE)  writefln("Host ... %s", host);
        debug(RESPONSE)  writefln("Path ... %s", path);
    }
    ushort port = 80;
    auto port_start = indexOf(host, ':');

    debug(RESPONSE)  writefln("Port start ... %s", port_start);

    if (port_start != -1) {
        host = host[0..port_start];
        port = to!ushort(host[port_start+1..$]);

        debug(RESPONSE)  writefln("Host ... %s", host);
        debug(RESPONSE)  writefln("Port ... %s", port);
    }

    auto query = "";
    if (path_start) {
        auto query_start = indexOf(path, '?');
        if (query_start != -1) {
            path = path[0..query_start];
            query = path[query_start+1..$];
        }
    }
    auto content = get_content(host, path, port);
    return make_Response(content);
}

string get_content(string host, string path, ushort port) {
    import std.socket: InternetAddress, Socket, TcpSocket;

    InternetAddress internet_adress = new InternetAddress(host, port);
    Socket socket = new TcpSocket(internet_adress);
    scope(exit) socket.close();

    debug (RESPONSE)  writefln("Connecting host \"%s\"...", host);

    socket.send("GET " ~ path ~ " HTTP/1.0\r\n" ~
                "Host: " ~ host ~ "\r\n" ~
                "\r\n"
                );

    char[] _response;
    while (true) {
        char[1] buf;
        while(socket.receive(buf))
        {
            _response ~= buf;
            // if (buf[0] == '\n')     break;
        }
        break;
        //  if (!_response.length) {  writeln("The line was not populated. Ending.");  }
    }
    debug (RESPONSE)  writeln("Receivied content:");
    return to!string(_response);
}


Response make_Response(string _content) {
    // Below is a copy of comment from dlang-requests

    // Proper HTTP uses "\r\n" as a line separator, but broken servers sometimes use "\n".
    // Servers that use "\r\n" might have "\n" inside a header.
    // For any half-sane server, the first '\n' should be at the end of the status line, so this can be used to detect the line separator.
    // In any case, all the interesting points in the header for now are at '\n' characters, so scan the newly read data for them


    auto http_standard = "";
    auto status_code = 444; //Response.status_code;
    string[string] headers;
    string[] cookies;
    auto _headers = "";
    string content;

    auto i = 0;
    bool finding_headers = true;
    foreach(line; lineSplitter!(Yes.keepTerminator)(_content))  //No.keepTerminator,
    {
        i++;
        if (i == 1) {
            auto first_string = line.split(' ');
            if (first_string.length < 2)  writeln("Malformed response;");
            auto http_standard_candidate = first_string[0];
            status_code = to!int(first_string[1]);
            writefln("Received status_code %d", status_code);
            string[4] http_standards = ["HTTP/1.0", "HTTP/1.1", "HTTP/2", "HTTP/3"]; // on http 1.0, close is assumed (unlike http/1.1 where we assume keep alive)
            foreach(standard; http_standards)
                {
                // writeln(h);
                if (http_standard_candidate==standard) {
                    http_standard = http_standard_candidate;
                    writefln("Found HTTP version, which is %s", http_standard);}
                }
            continue;
        }
        if (finding_headers)
        {
            if (line == "\n")    { finding_headers = false; continue;}
            if (line == "\r\n")  { finding_headers = false; continue;}

            _headers ~= line;

            auto delimiter_i = line.indexOf(':');
            if ((delimiter_i <= 2) || (delimiter_i == line.length)) writefln("Bad header '%s'", line);
            else {
                string key = line[0..delimiter_i];
                string value = line[delimiter_i+1..line.length];  // optimise to +2 and remove strip?
                value = value.strip();
                if (key == "cookie") {
                    cookies ~= value;
                    continue;
                }
                headers[key] = value;
                writefln("Found the headers '%s' with value '%s'", key, value);
            }
            continue;
        }
        content ~= line;
    }

    Response r = Response(status_code, headers, _headers, cookies, content, _content);
    return r;
}

void raise_for_status(Response r) {
    if (r.status_code >= 400 && r.status_code < 500) {
        throw new Exception(format("Client error: %d", r.status_code));
    }
    if (r.status_code >= 500 && r.status_code < 600) {
        throw new Exception(format("Server error: %d", r.status_code));
    }
}
alias throw_for_status = raise_for_status;


JSONValue json(Response r){
    return parseJSON(r.content);
};


int main(string[] args)
{


debug (RESPONSE)  writeln("Starting...");
auto url = "https://httpbin.org/get";
auto r = get(url);

r.raise_for_status();
JSONValue j = r.json();

writeln(j);


return 0;
}
