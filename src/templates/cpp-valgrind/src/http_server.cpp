#include <httplib.h>

int main() {
    httplib::Server svr;
    svr.Get("/", [](const httplib::Request&, httplib::Response& res) {
        res.set_content("Hello world!", "text/plain");
    });
    svr.listen("0.0.0.0", 8080);
    return 0;
}
