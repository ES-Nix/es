from fl4sk import foo, app


def main():
    print('foo = ', foo)
    app.run(host="0.0.0.0", port=8080, debug=True)


if __name__ == '__main__':
    main()
