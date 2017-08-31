How to notes
===

## Goal

Use the [Gunicorn](http://gunicorn.org/) WSGI HTTP server to serve your application.

### Basic information

* The Gunicorn WSGI HTTP server is used to serve your application in the case that it is installed
    - The easiest way to install gunicorn fixing desidered version is using the `requirements.txt`
    - At the moment using `setup.py` strategy breaks installation raising [this exception](installing-gunicorn-using-setup.log):

        ```
        File "build/bdist.linux-x86_64/egg/gunicorn/workers/_gaiohttp.py", line 84
          yield from self.wsgi.close()
                   ^
        SyntaxError: invalid syntax
        ```    

* If a file named wsgi.py is present in your repository, it will be used by Gunicorn
    as the entry point to your application


References
===

* [Python Docker image README](https://github.com/sclorg/s2i-python-container/blob/master/2.7/README.md)
    - [Python Docker image _Run Strategies_ ](https://github.com/sclorg/s2i-python-container/blob/master/2.7/README.md#run-strategies)
