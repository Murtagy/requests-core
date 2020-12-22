import std.stdio: writeln, writefln;
import std_socket = std.socket;
import str = std.string;
import std.string: lineSplitter, indexOf, strip;
import std.conv: to;
import std.array : split;
import std.typecons : Yes;

debug = MYHTML;

struct Response {
    int status_code = 444;
    string[string] headers;
    string _headers; // to ptr
    string content;  // to ptr
    string _content; // to ptr
};

int main(string[] args)
{
// string url = args[1];
// auto i = indexOf(url, "://");
auto domain = "httpbin.org";
auto url_path = "/image/jpeg";
ushort port = 80;

debug (MYHTML)  writeln("Starting...");

std_socket.InternetAddress internet_adress = new std_socket.InternetAddress(domain, port);
std_socket.Socket socket = new std_socket.TcpSocket(internet_adress);
scope(exit) socket.close();

debug (MYHTML)  writefln("Connecting domain \"%s\"...", domain);

socket.send("GET " ~ url_path ~ " HTTP/1.0\r\n" ~
            "Host: " ~ domain ~ "\r\n" ~
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
    //  if (!_response.length) {
            //  writeln("The line was not populated. Ending.");
    //  }
}
writeln("Receivied content:");

Response make_Response(string _content) {
    // Below is a copy of comment from dlang-requests
    // Proper HTTP uses "\r\n" as a line separator, but broken servers sometimes use "\n".
    // Servers that use "\r\n" might have "\n" inside a header.
    // For any half-sane server, the first '\n' should be at the end of the status line, so this can be used to detect the line separator.
    // In any case, all the interesting points in the header for now are at '\n' characters, so scan the newly read data for them


    auto http_standard = "";
    auto status_code = 444; //Response.status_code;
    string[string] headers;
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
            string[4] http_standards = ["HTTP/1.0", "HTTP/1.1", "HTTP/2", "HTTP/3"];
            foreach(standard; http_standards)
                {
                // writeln(h);
                if (http_standard_candidate==standard) {
                    http_standard = http_standard_candidate;
                    writefln("Found HTTP version, which is %s", http_standard);}
                };
            continue;
        };
        if (finding_headers)
        {
            if (line == "\n")    { finding_headers = false; continue;}
            if (line == "\r\n")  { finding_headers = false; continue;}

            _headers ~= line;

            auto delimiter_i = line.indexOf(':');
            if ((delimiter_i <= 2) || (delimiter_i == line.length)) writefln("Bad header '%s'", line);
            else {
                string key = line[0..delimiter_i];
                string value = line[delimiter_i+1..line.length];
                value = value.strip();
                headers[key] = value;
                writefln("Found the headers '%s' with value '%s'", key, value);
            };
            continue;
        };
        content ~= line;
    }

    Response r = Response(status_code, headers, _headers, content, _content);
    return r;
};

auto _r = to!string(_response);
auto r = make_Response(_r);
writeln(r.content);
return 0;
}
